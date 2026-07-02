import Foundation
import Combine

/// Ported from Android `presentation/viewModel/HomeViewModel.kt`.
/// Ads (Phase 5), billing/subscription UI (Phase 6), custom-email creation (Phase 4) and
/// the WebSocket service (Phase 3) are represented by hooks/stubs marked below; the core
/// email lifecycle (generate, .com, expiry countdowns, active-email refresh, cold-start
/// migration) is ported in full.
struct HomeUiState {
    var tempEmail: TempEmail?
    var emails: [Email] = []
    var isLoading = false
    var error: String?
    var errorMessage: String?
    var isExpired = false
    var newEmailFlag = false
    var isSubscribed = false
    var activeEmailsList: [TempEmail] = []
    var isActiveEmailsLoading = false
    var domains: [String] = []
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var uiState = HomeUiState()
    @Published private(set) var isFirstLaunch: Bool?

    private let tempEmailUseCases: TempEmailUseCases
    private let dataStore: DataStoreManager
    private let timeProvider: TimeProvider
    private let onboardRepository: OnboardRepository

    // Expiry windows (epoch millis), matching Android.
    private let expiredTime = 10 * 60 * 1000
    private let expiredTimeForComMail = 5 * 60 * 1000
    private let expiredTimeForCustomMail = 24 * 60 * 60 * 1000 // 1 day

    private var normalExpirationTask: Task<Void, Never>?
    private var customExpirationTask: Task<Void, Never>?
    private var fetchCustomEmailsTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private var isSubscribed = false
    private var activeEmailsList: [TempEmail] = []
    private(set) var isInitCalled = false   // used by the scaffold to gate ad/consent init (Phase 5)

    init(
        tempEmailUseCases: TempEmailUseCases,
        dataStore: DataStoreManager,
        timeProvider: TimeProvider,
        onboardRepository: OnboardRepository
    ) {
        self.tempEmailUseCases = tempEmailUseCases
        self.dataStore = dataStore
        self.timeProvider = timeProvider
        self.onboardRepository = onboardRepository

        observeNewEmailFlag()
        observeSubscriptionStatus()
        observeFirstLaunch()
        getEmailDomains()

        Task { await coldStart() }
        // Phase 5: rewardedAdManager.loadAd()
    }

    // MARK: - Cold start / migration

    private func coldStart() async {
        await tempEmailUseCases.syncServerTimeUseCase()
        if !dataStore.isEmailLoadedOnFirstLaunch() {
            let past = dataStore.getTempEmail() // legacy key
            if past.email.isEmpty {
                generateNewEmail(loadComEmail: false)
            } else {
                await setupPastVersionNormalEmail(past)
                await refreshActiveEmails(.coldStart)
            }
            dataStore.setEmailLoadedOnFirstLaunch(true)
        } else {
            await refreshActiveEmails(.coldStart)
        }
    }

    private func setupPastVersionNormalEmail(_ past: TempEmail) async {
        var past = past
        if !past.isCustomEmail {
            dataStore.saveNormalTempEmail(past)
        } else if past.loadedTimestamp < (await timeProvider.now()) {
            past.expiredTimestamp = past.loadedTimestamp + expiredTimeForCustomMail
            dataStore.savePastVersionCustomEmail(past)
        }
        dataStore.saveSelectedTempEmail(past)
        dataStore.clearTempEmail() // one-time migration
    }

    // MARK: - Generate

    func generateNewEmail(loadComEmail: Bool) {
        Task {
            uiState.isLoading = true
            uiState.error = nil
            uiState.isExpired = false
            do {
                var tempEmail = try await tempEmailUseCases.generateTempEmail(loadComEmail: loadComEmail)
                tempEmail.isCustomEmail = false
                tempEmail.isComMail = tempEmail.email.lowercased().hasSuffix(".com")
                tempEmail.loadedTimestamp = await timeProvider.now()

                uiState.tempEmail = tempEmail
                uiState.isLoading = false
                uiState.error = nil

                await updateSelectedEmailOnDataStore(tempEmail, triggerUIState: false)
                await refreshActiveEmails(.newNormalEmail)
                startNormalEmailExpirationCountdown(savedTime: nil, tempEmail: tempEmail)
            } catch {
                uiState.isLoading = false
                uiState.error = error.localizedDescription
            }
        }
    }

    /// Set a custom email (used by the Phase 4 custom-email flow).
    func updateCustomEmail(email: String, reservationID: String, expiresAt: Int) {
        var tempEmail = TempEmail(email: email, reservationId: reservationID)
        uiState.tempEmail = tempEmail
        uiState.isLoading = false
        uiState.error = nil
        uiState.isExpired = false

        Task {
            tempEmail.isCustomEmail = true
            tempEmail.expiredTimestamp = expiresAt
            tempEmail.loadedTimestamp = await timeProvider.now()
            await updateSelectedEmailOnDataStore(tempEmail, triggerUIState: false)
            await refreshActiveEmails(.newCustomEmail)
            startCustomEmailExpirationCountdown(tempEmail)
        }
    }

    // MARK: - Emails

    func loadEmails(_ address: String) {
        Task {
            uiState.isLoading = true
            do {
                let emails = try await tempEmailUseCases.getEmailsByAddress(address)
                uiState.emails = emails
                uiState.isLoading = false
                uiState.error = nil
            } catch {
                uiState.isLoading = false
                uiState.error = error.localizedDescription
            }
        }
    }

    /// Switch mailbox from the inbox dropdown (Phase 3).
    func setSelectedEmailFromDropdown(_ tempEmail: TempEmail) {
        Task {
            await updateSelectedEmailOnDataStore(tempEmail, triggerUIState: true)
            if tempEmail.isCustomEmail {
                await refreshActiveEmails(.newCustomEmail)
                startCustomEmailExpirationCountdown(tempEmail)
            } else {
                await refreshActiveEmails(.newNormalEmail)
                startNormalEmailExpirationCountdown(savedTime: nil, tempEmail: tempEmail)
            }
        }
    }

    // MARK: - Active emails

    func refreshActiveEmails(_ reason: ActiveEmailRefreshReason) async {
        uiState.isActiveEmailsLoading = true
        let isColdStart = reason == .coldStart
        if isColdStart {
            uiState.isLoading = true
            uiState.error = nil
            uiState.isExpired = false
        }

        let stored = dataStore.getSelectedTempEmail()
        let selectedEmail: TempEmail? = stored.email.isEmpty ? nil : stored
        let normalEmail = await validateNormalEmail(isColdStart: isColdStart)
        let refreshReason = await shouldSkipFetchingCustomEmails(reason)

        switch refreshReason {
        case .coldStart, .customEmailExpired, .newCustomEmail, .manualRefresh:
            await fetchActiveCustomEmails(normalEmail: normalEmail, selectedEmail: selectedEmail, isColdStart: isColdStart)
        case .skipFetchingEmail, .newNormalEmail, .normalEmailExpired:
            let local = buildLocalActiveEmails(normalEmail: normalEmail, now: await timeProvider.now())
            await handleActiveEmails(local, selectedEmail: selectedEmail, isColdStart: isColdStart)
        }
    }

    private func shouldSkipFetchingCustomEmails(_ reason: ActiveEmailRefreshReason) async -> ActiveEmailRefreshReason {
        if isSubscribed { return reason }
        let expiredAt = dataStore.getFreeCustomEmailExpiredTimestamp()
        let now = await timeProvider.now()
        let shouldSkip = expiredAt == 0 || expiredAt <= now
        return shouldSkip ? .skipFetchingEmail : reason
    }

    private func buildLocalActiveEmails(normalEmail: TempEmail?, now: Int) -> [TempEmail] {
        var emails: [TempEmail] = []
        if let normalEmail { emails.append(normalEmail) }
        emails.append(contentsOf: activeEmailsList.filter { $0.isCustomEmail })

        let past = dataStore.getPastVersionCustomEmail()
        if !past.email.isEmpty {
            if past.expiredTimestamp <= now {
                dataStore.clearPastVersionCustomEmail()
            } else if !emails.contains(where: { $0.email == past.email }) {
                emails.append(past)
            }
        }
        return emails
    }

    private func validateNormalEmail(isColdStart: Bool) async -> TempEmail? {
        let normal = dataStore.getNormalTempEmail()
        if normal.email.isEmpty { return nil }
        let elapsed = (await timeProvider.now()) - normal.loadedTimestamp
        if elapsed <= getExpiredTime(normal) {
            if isColdStart {
                startNormalEmailExpirationCountdown(savedTime: normal.loadedTimestamp, tempEmail: normal)
            }
            return normal
        } else {
            dataStore.clearNormalTempEmail()
            return nil
        }
    }

    private func fetchActiveCustomEmails(normalEmail: TempEmail?, selectedEmail: TempEmail?, isColdStart: Bool) async {
        fetchCustomEmailsTask?.cancel()
        let task = Task { @MainActor in
            var active: [TempEmail] = []
            if let normalEmail { active.append(normalEmail) }

            let now = await timeProvider.now()
            let past = dataStore.getPastVersionCustomEmail()
            if !past.email.isEmpty {
                if past.expiredTimestamp <= now {
                    dataStore.clearPastVersionCustomEmail()
                } else {
                    active.append(past)
                }
            }

            if let customs = try? await tempEmailUseCases.getActiveCustomEmailsUseCase() {
                for c in customs {
                    active.append(TempEmail(
                        email: c.email,
                        reservationId: "",
                        expiredTimestamp: c.expiresAt.ensureEpochMillis,
                        isCustomEmail: true
                    ))
                }
            }
            if Task.isCancelled { return }
            await handleActiveEmails(active, selectedEmail: selectedEmail, isColdStart: isColdStart)
        }
        fetchCustomEmailsTask = task
        await task.value
    }

    private func handleActiveEmails(_ activeEmails: [TempEmail], selectedEmail: TempEmail?, isColdStart: Bool) async {
        uiState.activeEmailsList = activeEmails
        uiState.isLoading = false
        activeEmailsList = activeEmails

        if let selectedEmail, activeEmails.contains(where: { $0.email == selectedEmail.email }) {
            if isColdStart {
                uiState.tempEmail = selectedEmail
                startCustomEmailExpirationCountdown(selectedEmail)
            }
        } else if !activeEmails.isEmpty {
            let first = activeEmails[0]
            await updateSelectedEmailOnDataStore(first, triggerUIState: true)
            startCustomEmailExpirationCountdown(first)
        } else {
            dataStore.clearSelectedTempEmail()
            uiState.errorMessage = "Disconnected. Please regenerate email."
            uiState.isExpired = true
        }

        uiState.isActiveEmailsLoading = false
    }

    private func updateSelectedEmailOnDataStore(_ tempEmail: TempEmail, triggerUIState: Bool) async {
        if triggerUIState {
            uiState.tempEmail = tempEmail
            uiState.isLoading = false
            uiState.isExpired = false
        }
        dataStore.saveSelectedTempEmail(tempEmail)
        if !tempEmail.isCustomEmail {
            dataStore.saveNormalTempEmail(tempEmail)
        }
    }

    // MARK: - Expiry

    private func getExpiredTime(_ tempEmail: TempEmail) -> Int {
        if tempEmail.isCustomEmail {
            return expiredTimeForCustomMail
        } else if tempEmail.isComMail && !isSubscribed {
            return expiredTimeForComMail
        } else {
            return expiredTime
        }
    }

    func checkAndHandleEmailExpiration() {
        Task {
            let saved = dataStore.getSelectedTempEmail()
            guard !saved.email.isEmpty, saved.loadedTimestamp > 0 else { return }
            let now = await timeProvider.now()
            if (now - saved.loadedTimestamp) > getExpiredTime(saved) {
                uiState.errorMessage = "Disconnected. Please regenerate email."
                uiState.isExpired = true
                uiState.newEmailFlag = false
            }
        }
    }

    private func startNormalEmailExpirationCountdown(savedTime: Int?, tempEmail: TempEmail) {
        normalExpirationTask?.cancel()
        normalExpirationTask = Task { @MainActor in
            let now = await timeProvider.now()
            let delayMs: Int
            if let savedTime {
                delayMs = max(0, getExpiredTime(tempEmail) - (now - savedTime))
            } else {
                delayMs = getExpiredTime(tempEmail)
            }
            try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
            if Task.isCancelled { return }
            await refreshActiveEmails(.normalEmailExpired)
        }
    }

    private func startCustomEmailExpirationCountdown(_ tempEmail: TempEmail) {
        customExpirationTask?.cancel()
        customExpirationTask = Task { @MainActor in
            let now = await timeProvider.now()
            let remaining = tempEmail.expiredTimestamp.ensureEpochMillis - now
            let delayMs = max(0, remaining)
            try? await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
            if Task.isCancelled { return }
            await refreshActiveEmails(.customEmailExpired)
        }
    }

    // MARK: - Observers

    private func observeNewEmailFlag() {
        dataStore.hasNewEmailSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] hasNew in
                guard let self else { return }
                self.uiState.newEmailFlag = hasNew
                if let email = self.uiState.tempEmail?.email, !email.isEmpty {
                    self.loadEmails(email)
                }
            }
            .store(in: &cancellables)
    }

    private func observeSubscriptionStatus() {
        dataStore.isSubscribedSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] subscribed in
                self?.uiState.isSubscribed = subscribed
                self?.isSubscribed = subscribed
            }
            .store(in: &cancellables)
    }

    private func observeFirstLaunch() {
        Task { isFirstLaunch = await onboardRepository.isFirstLaunch() }
    }

    func clearNewEmailFlag() {
        dataStore.setHasNewEmail(false)
    }

    func completeOnboarding() {
        Task { await onboardRepository.setFirstLaunch(false) }
    }

    func getEmailDomains() {
        Task {
            if let domains = try? await tempEmailUseCases.getEmailDomainsUseCase() {
                uiState.domains = domains
            }
        }
    }

    // MARK: - WebSocket (Phase 3 stub)

    func startWebSocketService(email: String) {
        // Phase 3: start the URLSessionWebSocketTask listener + load emails.
        loadEmails(email)
    }
}
