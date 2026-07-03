import Foundation

/// Composition root — the iOS replacement for Hilt's DI modules
/// (`NetworkModule`, `DataStoreModule`, `RepoModule`, `AnalyticsModule`, …).
///
/// Dependencies are constructed here and injected into view models via initializers.
///   • Phase 1 (this): DataStore, decrypted API client, repositories, TimeProvider,
///     REST + validation use cases.
///   • Phase 2: HomeViewModel factory.
///   • Phase 3: WebSocketManager + WS use cases.
///   • Phase 5: Ads managers + consent.
///   • Phase 6: BillingRepository (StoreKit 2).
///   • Phase 7: AnalyticsTracker.
@MainActor
final class AppContainer: ObservableObject {
    // Presentation
    let themeManager = ThemeManager()

    // Data
    let dataStore: DataStoreManager
    let resourceProvider: ResourceProvider
    let api: EmailApi
    let deviceIdProvider: DeviceIdProvider

    // Repositories
    let tempEmailRepository: TempEmailRepository
    let timeRepository: TimeRepository
    let emailLimitRepository: EmailLimitRepository
    let onboardRepository: OnboardRepository

    // Core
    let timeProvider: TimeProvider

    // Use cases
    let tempEmailUseCases: TempEmailUseCases
    let validateUsernameUseCase: ValidateUsernameUseCase
    let validateDailyEmailLimitUseCase: ValidateDailyEmailLimitUseCase

    // Ads / consent (Phase 5)
    let adsConsentManager: GoogleMobileAdsConsentManager
    let rewardedAdManager: RewardedAdManager
    let appOpenAdManager: AppOpenAdManager

    // View models (shared across screens, like the Android activity-scoped HomeViewModel)
    let homeViewModel: HomeViewModel

    init() {
        let dataStore = DataStoreManager()
        self.dataStore = dataStore
        self.resourceProvider = ResourceProviderImpl()

        // Base URL is AES-decrypted from SecretConstants. This is deterministic and
        // covered by unit tests; a failure here means the bundled constants are broken.
        guard let api = try? EmailApiService() else {
            fatalError("TempMailPlus: failed to decrypt the API base URL — check SecretConstants/Decryptor.")
        }
        self.api = api

        let deviceIdProvider = DeviceIdProviderImpl(dataStore: dataStore)
        self.deviceIdProvider = deviceIdProvider

        let tempEmailRepository = TempEmailRepositoryImpl(
            api: api,
            deviceIdProvider: deviceIdProvider,
            webSocketManager: WebSocketManager()
        )
        self.tempEmailRepository = tempEmailRepository
        let timeRepository = TimeRepositoryImpl(api: api, dataStore: dataStore)
        self.timeRepository = timeRepository
        self.emailLimitRepository = EmailLimitRepositoryImpl(api: api, dataStore: dataStore)
        self.onboardRepository = OnboardRepositoryImpl(dataStore: dataStore)

        self.timeProvider = TimeProvider(timeRepository: timeRepository)

        self.tempEmailUseCases = TempEmailUseCases(
            generateTempEmail: GenerateTempEmailUseCase(repository: tempEmailRepository),
            activateEmail: ActivateEmailUseCase(repository: tempEmailRepository),
            getEmailsByAddress: GetEmailsByAddressUseCase(repository: tempEmailRepository),
            getEmailById: GetEmailByIDUseCase(repository: tempEmailRepository),
            getEmailDomainsUseCase: GetEmailDomainsUseCase(repository: tempEmailRepository),
            getActiveCustomEmailsUseCase: GetActiveCustomEmailsUseCase(repository: tempEmailRepository),
            createCustomEmailUseCase: CreateCustomEmailUseCase(repository: tempEmailRepository),
            syncServerTimeUseCase: SyncServerTimeUseCase(repository: timeRepository),
            observeEmailsUseCase: ObserveEmailsUseCase(repository: tempEmailRepository),
            connectWebSocketUseCase: ConnectWebSocketUseCase(repository: tempEmailRepository),
            disconnectWebSocketUseCase: DisconnectWebSocketUseCase(repository: tempEmailRepository)
        )
        self.validateUsernameUseCase = ValidateUsernameUseCase(
            validator: UsernameValidator(),
            resourceProvider: resourceProvider
        )
        self.validateDailyEmailLimitUseCase = ValidateDailyEmailLimitUseCase(
            repository: emailLimitRepository
        )

        let adsConsentManager = GoogleMobileAdsConsentManager()
        self.adsConsentManager = adsConsentManager
        let rewardedAdManager = RewardedAdManager()
        self.rewardedAdManager = rewardedAdManager
        self.appOpenAdManager = AppOpenAdManager()

        self.homeViewModel = HomeViewModel(
            tempEmailUseCases: tempEmailUseCases,
            dataStore: dataStore,
            timeProvider: timeProvider,
            onboardRepository: onboardRepository,
            adsConsentManager: adsConsentManager,
            rewardedAdManager: rewardedAdManager,
            appOpenAdManager: appOpenAdManager
        )
    }

    /// Factory for the email-detail view model (resolves the email from the shared
    /// repository cache via `getEmailById`).
    func makeEmailDetailViewModel() -> EmailDetailViewModel {
        EmailDetailViewModel(getEmailByIDUseCase: GetEmailByIDUseCase(repository: tempEmailRepository))
    }

    /// Factory for the custom-email view model (one per sheet presentation, like Android's
    /// `hiltViewModel()`-scoped `CustomEmailViewModel`).
    func makeCustomEmailViewModel() -> CustomEmailViewModel {
        CustomEmailViewModel(
            createCustomEmailUseCase: CreateCustomEmailUseCase(repository: tempEmailRepository),
            validateUsernameUseCase: validateUsernameUseCase,
            dataStore: dataStore,
            timeProvider: timeProvider,
            rewardedAdManager: rewardedAdManager
        )
    }
}
