# TempMailPlus iOS — Progress Log

Running log of what's been done, per phase. Plan lives in
[`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md). Newest entries at the top of each phase.

## Phase status overview

| Phase | Scope | State |
|-------|-------|-------|
| **0** | Bootstrap: project, theme, fonts, DI skeleton, themed shell | ✅ Done |
| **1** | Domain + Data core (models, API, decryption, DataStore, tests) | ✅ Done |
| **2** | Home flow | ✅ Done |
| **3** | Inbox + Email detail + realtime WebSocket | ✅ Done |
| **4** | Custom email | ✅ Done |
| **5** | Ads + consent | ✅ Done |
| **6** | Subscriptions (StoreKit 2) | ⬜ Not started |
| **7** | Menu, FAQ, Rate, localization | ⬜ Not started |
| **8** | Notifications + polish | ⬜ Not started |

Legend: ✅ done · 🚧 in progress · ⏳ next · ⬜ not started

---

## Phase 0 — Bootstrap ✅ (2026-07-02)

**Deliverable met:** app builds, installs, and launches on the iOS Simulator to a themed shell.

### Post-review fixes (2026-07-02)
Reviewed Phase 0 and applied the following before starting Phase 1:
- **#1 Dynamic Type** — `AppTypography` now uses `Font.custom(_:size:relativeTo:)` so text scales
  with the system font-size setting (parity with Android `.sp` + accessibility).
- **#2 Single source of truth for prefs** — added `Data/DataStore/PreferenceKeys.swift` (mirrors
  Android `PreferenceKeys.kt`); `ThemeManager` now uses `PreferenceKeys.darkMode`. Phase 1's
  `DataStoreManager` will own these keys.
- **#3 Color init** — dropped the fragile alpha heuristic in `Color(argb:)`; top byte is always
  alpha (matches Compose `Color(Long)`; all tokens carry an explicit alpha byte).
- **#4 Launch screen** — `Info.plist` `UILaunchScreen` is now an empty dict (removed the empty
  `UIColorName` reference).
- **#9 Version control** — `git init` + Phase 0 baseline commit (`aac50bc`), branch `main`.
- Rebuilt clean after changes (no warnings); dark mode verified in the simulator.

Deferred to their scheduled phases (intentional, not oversights):
- Orientation: iPhone portrait-only (Android doesn't lock) — kept as a deliberate choice for the
  vertical-scroll layouts.
- Real AppIcon image → before TestFlight. `ITSAppUsesNonExemptEncryption` → Phase 8 (once AES lands).
- Unit-test target (needs a second target in the `.pbxproj`) → scoped into Phase 1.


Done:
- Created sibling project folder `TempMailPlus-IOS` with layered structure
  (`App / Core / Data / Domain / Presentation / Resources`).
- Hand-wrote the Xcode project (`.pbxproj`, objectVersion 77) using **Xcode 16+ file-system-
  synchronized groups** — new files under `TempMailPlus/` are auto-included, no `.pbxproj` edits
  needed going forward. Added shared scheme + workspace.
- Ported theme from Android: `AppColors.swift` (1:1 from `Color.kt`), `AppTypography.swift`
  (Compose ramp), `ThemeManager.swift` (persisted `dark_mode`, default light).
- Set up `AppContainer.swift` DI root (replaces Hilt) + `TempMailPlusApp.swift` entry +
  `RootShellView.swift` themed shell.
- Copied reusable assets: Raleway + Pacifico fonts, both Lottie JSON files, asset catalog,
  `en.lproj` scaffold, `Info.plist` with `UIAppFonts`.
- Config: iOS 16.0 min, bundle id `com.digitaldevs.tempmailplus`, Swift 5.0, MARKETING_VERSION 1.2.0.

Verified:
- `xcodebuild … build` → **BUILD SUCCEEDED**.
- Installed + launched on iPhone 17 simulator; screenshot confirmed Pacifico + Raleway fonts,
  ThemeBlue accent, light theme, dark-mode toggle.
- Bundle contains: 6 `.ttf` fonts, 2 Lottie JSON, `Assets.car`, `en.lproj`.

Decisions / notes:
- Font PostScript names verified via CoreText: `Raleway-{Regular,Medium,SemiBold,Bold,ExtraBold}`,
  `Pacifico-Regular`.
- Theme is app-controlled (mirrors Android's DataStore-driven theme), not system-driven.
- `Constants.swift` uses Google **test** AdMob IDs — must be replaced with real iOS units in Phase 5.
- No third-party dependencies added yet (kept build green offline); SPM deps added per-phase.

Open follow-ups (from plan §5/§8, not blocking):
- Confirm min iOS version (assumed 16.0).
- Real iOS AdMob app ID + unit IDs; ironSource iOS app key.
- App Store Connect subscription product IDs + pricing/trial.
- Firebase iOS `GoogleService-Info.plist`.
- ⚠️ No-backend-changes constraint → no APNs push → background notifications limited (plan §7).

---

## Phase 1 — Domain + Data core ✅ (2026-07-02)

**Deliverable met:** headless domain + data layer, all unit tests green (**26/26**).

Done:
- **Domain models:** `Email`, `TempEmail` (resilient Codable), `Attachment`, `ActiveCustomEmail`,
  `SubscriptionInfo`, `SubscriptionStatus`, `BillingProducts`.
- **Domain utils/validation:** `Resource` (maps Android `Result`), `CustomEmailError`,
  `ForbiddenKeywords` (full list), `UsernameValidator` + `ValidationResult`.
- **Repository protocols + use cases:** REST + validation use cases and `TempEmailUseCases`
  aggregator. WebSocket + billing use cases deferred to Phases 3/6.
- **Security:** `SecretConstants` (same blobs) + `Decryptor` (CommonCrypto AES/CBC/PKCS7).
- **Remote:** `EmailApi`/`EmailApiService` (URLSession, base URL decrypted at init), DTOs (Codable),
  `Mappers`.
- **Storage:** `DataStoreManager` (UserDefaults, keys mirror Android via `PreferenceKeys`).
- **Repos:** `TempEmailRepositoryImpl`, `TimeRepositoryImpl`, `EmailLimitRepositoryImpl`,
  `DeviceIdProviderImpl` (identifierForVendor + persisted UUID), `OnboardRepositoryImpl`,
  `ResourceProviderImpl`.
- **Core:** `Extensions` (ensureEpochMillis, file size, time-ago, UTC date), `TimeProvider`.
- **DI:** `AppContainer` builds the full Phase-1 graph.
- **Tests:** added a unit-test target to the hand-written `.pbxproj` (hosted, `@testable`), scheme
  wired for `xcodebuild test`. Suites: Decryptor, UsernameValidator, Extensions, DataStoreManager,
  Mapper.

Verified:
- `xcodebuild … test` → **TEST SUCCEEDED**, 26 tests, 0 failures.
- **Decryption confirmed**: `Decryptor` produces a valid `http(s)` base URL and `ws(s)` socket URL
  from the ported constants — the CommonCrypto port matches Android output.

Notes / faithful quirks captured by tests:
- Forbidden-keyword match is first-in-list-wins (e.g. "mypaypal" → "pay", not "paypal") — matches
  Android's in-order iteration.
- `EmailDto` with a missing `date` maps to `receivedAt == 0`; a present-but-invalid date falls back
  to now — matches Android `date?.let { … } ?: 0`.
- Repositories are `async throws` (Android's `Flow` `Loading` emission becomes the view model
  setting `isLoading` before the `await`); `Resource` retained for tri-state VM state.
- `InboxViewModelTest` in Android was entirely commented out; real coverage was added at the
  data/domain layer instead (the view model arrives in Phase 2).

### Review carry-ins (from Phase 1 review, 2026-07-02)
- **[Phase 2]** Add a request-URL construction test for `EmailApiService` (stub `URLProtocol`;
  assert path + query for e.g. `custom-email/create`). `url(_:query:)` is currently untested.
- **[Phase 3]** `TempEmailRepositoryImpl.cachedEmails` is unsynchronized mutable state — safe now
  (MainActor-driven), but revisit when the WebSocket writes emails off the main actor / when strict
  concurrency is enabled.

## Phase 2 — Home flow ✅ (2026-07-02)

**Deliverable met:** launched on the simulator and generated a **real temp email from the live
backend** (`…@evrioli.xyz`); Home renders 1:1 with Android. Tests: **29/29 green**, zero warnings.

Done:
- **`HomeViewModel`** (full port): `HomeUiState`, cold-start + legacy-email migration, server-time
  sync, `generateNewEmail`, `updateCustomEmail` (for Phase 4), `loadEmails`,
  `setSelectedEmailFromDropdown` (for Phase 3), the whole active-emails refresh machinery
  (`shouldSkipFetchingCustomEmails` / `validateNormalEmail` / `buildLocalActiveEmails` /
  `fetchActiveCustomEmails` / `handleActiveEmails`), normal/custom expiry countdowns
  (`Task.sleep`, cancellable), `checkAndHandleEmailExpiration`. Coroutine jobs → cancellable Tasks;
  `Flow` `Loading` → `isLoading` set before `await`.
- **`ActiveEmailRefreshReason`** enum ported.
- **`DataStoreManager`** reactive publishers (`hasNewEmailSubject`, `isSubscribedSubject`) for the
  observed values.
- **Home UI** (`HomeView`) 1:1: title, logo + new-mail badge, email pill + copy + "Copied" toast,
  Refresh/Delete (Delete hidden for custom), Custom Email button, "Try .com" banner, expired state.
- **`ConfirmSheet`** + `ConfirmationAction` (reset/delete/.com) as bottom sheets.
- **Navigation scaffold** (`MainScaffold`): top bar (hamburger + Pacifico logo), bottom nav
  (Home/Inbox/Premium), left drawer overlay (`AppDrawer`, dark-mode toggle functional), Inbox
  placeholder, Premium placeholder sheet.
- **DI:** `AppContainer` builds and owns the shared `HomeViewModel`; app roots at `MainScaffold`.
  Removed the Phase-0 `RootShellView` (dead code).
- **Carry-in #2 done:** `EmailApiTests` (stubbed `URLProtocol`) asserts path/query/method
  construction and 4xx → `APIError`.

Deferred to their phases (hooks in place):
- Ad gating on refresh/delete/.com (Phase 5) — confirm actions currently regenerate directly.
- Custom Email button opens nothing yet (Phase 4 sheet).
- Premium button shows a placeholder (Phase 6 StoreKit).
- Inbox tab is a placeholder (Phase 3).
- Full drawer menu rows (Phase 7); branded logo/icons use SF Symbols as stand-ins.

Post-review fixes (2026-07-02):
- Ported `EmailValidityObserver`: `MainScaffold` observes `scenePhase == .active` and calls
  `checkAndHandleEmailExpiration()` so a backgrounded-then-expired email flips to expired on return.
- "Copied" toast now animates (wrapped in `withAnimation`).

Carry-ins:
- **[Phase 3]** `TempEmailRepositoryImpl.cachedEmails` unsynchronized (still open).
- **[Phase 3]** Wire `startWebSocketService` (currently just calls `loadEmails`).

## Phase 3 — Inbox + Email detail + realtime ✅ (2026-07-02)

**Deliverable met:** builds clean, 29/29 tests pass, WebSocket connects without crashing, and Home
was re-verified generating a real backend email after the WS wiring landed (`…@vecroniyt.com`).

Done:
- **`WebSocketManager`** (`URLSessionWebSocketTask`, replacing OkHttp): decrypts the WS URL via the
  same `SecretConstants`/`Decryptor`, sends `subscribeEmails` on connect, parses
  `newEmailReceived` into `Email` via an `AsyncStream`. `connect()` now drops any prior socket
  first (Android's service does this implicitly by reconnecting on email change).
- **`TempEmailRepository`** extended with `observeEmails`/`connectWebSocket`/`disconnectWebSocket`;
  new `ObserveEmailsUseCase`/`ConnectWebSocketUseCase`/`DisconnectWebSocketUseCase`, folded into
  `TempEmailUseCases`.
- **`HomeViewModel.startWebSocketService`** now really connects the socket and observes it once;
  incoming mail sets `hasNewEmail`, which (via the Phase 2 observer) triggers a live inbox reload —
  mirrors Android's service → notification-flag → reload chain. (Local/background notifications are
  out of scope per plan §7 — no backend push.)
- **`MainScaffold`** reactively calls `startWebSocketService` via `onChange(of: tempEmail.email)` —
  ports Android's `LaunchedEffect(tempEmail.email)`.
- **`InboxView`** (replaces the Phase 2 placeholder): dropdown header + overlay (normal/custom
  email sections, ported from `EmailDropdownHeader`/`EmailDropdownOverlay`), email list (`List` +
  `.refreshable`, sorted newest-first), empty state, expired state (`ConnectionLost`), loading
  spinner, tap-to-open detail.
- **`EmailDetailView`** + **`EmailDetailViewModel`**: subject, sender avatar/name/address/time,
  `HTMLView` (WKWebView) body, expandable attachments card that opens URLs via
  `UIApplication.open` (iOS analog of Android's DownloadManager).
- **`HTMLView`** (WKWebView wrapper, light/dark aware via `prefers-color-scheme`) replaces Android's
  `HtmlText`; `String.strippedHTML` gives inbox-row previews without a full HTML parse per row.
- **Carry-ins closed:**
  - `TempEmailRepositoryImpl.cachedEmails` is now guarded by an `NSLock` (read/write computed
    property), closing the Phase 1/2 concurrency carry-in now that the repository has a second
    caller path (WebSocket-adjacent code).
  - `startWebSocketService` is fully wired (was a stub in Phase 2).
- **`AppContainer`**: constructs `WebSocketManager`, wires it into the repository, adds
  `makeEmailDetailViewModel()` factory.

Investigated / confirmed non-issue:
- Android's `SwipeToDeleteButton`/`DeleteBottomSheet` are **dead code** — `DeleteBottomSheet` is
  never invoked anywhere in the Android app, and `InboxScreen.kt`'s `onDeleteEmail` callback is a
  literal no-op. Per-email swipe-to-delete is not a live Android feature, so the iOS port
  intentionally does not implement it either — this is faithful parity, not a gap. (The
  `IMPLEMENTATION_PLAN.md` Phase 3 description overstated this based on file names; noting here for
  the record rather than editing the plan retroactively.)

Verified:
- `xcodebuild … build` (Debug + Release) → zero warnings, zero errors.
- `xcodebuild … test` → **29/29 pass**.
- Clean-install launch → real temp email generated from the live backend
  (`brxva00961@vecroniyt.com`), Home renders correctly, process stays alive after the WebSocket
  connects (no crash from the new socket/task code).

**Verification gap (honest note):** the Inbox tab, dropdown overlay, and Email detail screen were
code-reviewed against the Android source and compile cleanly, but were **not visually screenshotted
in this session** — computer-use access (needed to tap simulator tabs) was requested and declined.
Home was re-confirmed working end-to-end after the Phase 3 wiring landed, which exercises the same
`AppContainer`/`HomeViewModel` machinery the Inbox screen depends on, but the Inbox-specific SwiftUI
layout (dropdown overlay positioning, list rendering, sheet presentation) has only been verified by
build success + code review, not by looking at it.

**User decision (2026-07-02):** visual check deferred to after Phase 4 — user will verify Inbox +
Email detail together with the Phase 4 custom-email flow in one pass. Checklist handed off:
dropdown header (single vs multi-email chevron), dropdown overlay sectioning/highlight/dismiss,
empty/loaded/expired inbox states + pull-to-refresh, detail screen back button/sender
card/**HTML body rendering (highest risk — new WKWebView code)**, attachments card expand +
open-in-Safari, and live-arrival badge on the Inbox tab icon.

Deferred to their phases (hooks in place):
- Ad gating on the expired-state refresh (Phase 5).
- Branded empty-inbox/logo icons use SF Symbols as stand-ins (Phase 7 polish).
- Full HTML CSS parity with Android's `HtmlText` (Phase 7 polish, if needed after visual QA).

## Phase 4 — Custom email ✅ (2026-07-03)

**Deliverable met:** builds clean (Debug + Release, zero warnings), **38/38 tests pass** (9 new),
Home re-verified generating a real backend email after the wiring landed
(`uzak62724@vecroniyt.com`).

Done:
- **`CustomEmailViewModel`** (full port): `createCustomEmail` (validate via `ValidateUsernameUseCase`
  first, then call the create use case), success/error-code branching (`SUCCESS` vs. server
  `error` field), `CustomEmailError` → localized message mapping (409/400/other),
  `handleLockedUserCustomEmail` (routes to the ad-confirm popup or the subscription dialog),
  `refreshCanCreateForLockedUser` (free-tier 1-per-25h gate: free iff no prior free usage AND no
  active custom email), `showRewardAd` (stub — creates directly, same tier as Phase 2/3 ad
  stubbing), `updateFreeEmailExpiredTimestamp` (25h), `resetCustomEmailState` (ported **exactly**:
  only 4 fields reset, `reservationID`/`expiresAt`/`canCreateForLockedUser` intentionally left
  as-is, matching a quirk in the Android source rather than "fixing" it).
- **`WatchAdBottomSheet`** component ported (title/description/Watch-ad button/"or unlock premium").
- **`AddCustomEmailSheet`**: username field + `@` + native `Menu`-based domain picker (replaces
  Compose `DropdownMenu`), Continue button (disabled without username, "Processing.." state, crown
  badge for free users), inline error toast that auto-dismisses after 1.4s, domain
  auto-selects-first-on-load, reactively refreshes `canCreateForLockedUser` when the active-emails
  list changes.
- Wired end-to-end: `HomeView`'s existing `onOpenCustomEmail` hook (from Phase 2) now presents the
  sheet via `MainScaffold`; success calls the existing `HomeViewModel.updateCustomEmail` (Phase 2).
- **`AppContainer.makeCustomEmailViewModel()`** factory (one instance per sheet presentation, like
  Android's `hiltViewModel()` scoping).
- **Tests:** `CustomEmailViewModelTests` (9 cases) — invalid-username short-circuits before any
  network call, success populates state, server-error and thrown-`CustomEmailError` paths, the
  free-tier gate logic (default-free / blocked-by-existing-custom-email / blocked-after-free-used),
  ad-vs-subscription routing, and the exact 4-field reset semantics.

Deferred to their phases (hooks in place):
- Real rewarded-ad SDK call (Phase 5) — `showRewardAd` currently creates the email directly.
- Analytics (`logCustomEmailClicked`) is a documented no-op stub (Phase 7).
- Daily 5/day limit (`ValidateDailyEmailLimitUseCase`, built in Phase 1) is not wired into this
  screen — matches Android, where it's also unused by `AddCustomEmailBottomSheet`.

**Verification gap (same as Phase 3):** the sheet is code-reviewed + compiles clean + has 9 unit
tests over its view-model logic, but was **not visually screenshotted** — computer-use access was
declined again this session. Home was re-confirmed working end-to-end after the wiring landed.
Added to the deferred visual-check list (now: Inbox, Email detail, **Add Custom Email sheet**,
domain picker menu, inline error toast, watch-ad sheet).

## Phase 5 — Ads + consent ✅ (2026-07-03)

**Deliverable met:** real Google Mobile Ads + UMP SDKs integrated via SPM, zero warnings
(Debug + Release), 38/38 tests pass, and **verified live on the simulator** — a clean install
shows Google's actual UMP consent dialog ("Our app wants to stay free for you…"), proving the
full pipeline (consent request → Google's servers → real form presentation) genuinely works, not
just compiles.

### Scope decision
Presented the user a 3-way choice on how deep to go, since ironSource's iOS SDK has no SPM
support (CocoaPods/manual only) and would restructure the whole project (Podfile, `.xcworkspace`).
User chose: **real AdMob + UMP via SPM now, defer ironSource** (no project restructure needed).

Done:
- **Dependencies:** added `swift-package-manager-google-mobile-ads` (13.6.0) and
  `swift-package-manager-google-user-messaging-platform` (3.1.0) as `XCRemoteSwiftPackageReference`s
  in the hand-written `.pbxproj`, linked only to the app target (not the test target — hosted tests
  run inside the already-linked app process, no separate link needed). `Info.plist` gained
  `GADApplicationIdentifier` (Google's iOS test app ID — flagged for replacement before release)
  and `NSUserTrackingUsageDescription`. `SKAdNetworkItems` deliberately **not** added — it's a long
  Google-maintained list that's an App Store/attribution requirement, not a build/simulator
  requirement; flagged as a Phase 8 pre-release checklist item rather than risk transcribing it
  wrong from a search snippet.
- **`GoogleMobileAdsConsentManager`**: wraps UMP's `ConsentInformation`/`ConsentForm`/
  `RequestParameters`/`DebugSettings` (careful: these are the *renamed*, non-`UMP`-prefixed Swift
  API names as of UMP 3.x — confirmed by the compiler's own deprecation-rename diagnostics, not
  guessed). `gatherConsent`, `showPrivacyOptionsForm`, `canRequestAds`, `isPrivacyOptionsRequired`.
- **`RewardedAdManager`** + **`AppOpenAdManager`**: ported using GoogleMobileAds 13.x's Swift-idiomatic
  names (`RewardedAd`, `AppOpenAd`, `Request`, `FullScreenContentDelegate`, `FullScreenPresentingAd`
  — dropped the old `GAD`-prefixed names, confirmed against the actual pinned SDK version, not
  assumed). `AppOpenAdManager` is ported for parity but **intentionally not wired to any trigger** —
  matching Android, where `showAppOpenAd(activity)` is commented out at every call site in
  `MainScaffold.kt`. This is a discovered fact about the source app, not an omission in the port.
- **`BannerAdView`** (`UIViewRepresentable` wrapping `BannerView`) — shown on Home for
  `canRequestAds && !isSubscribed`, matching Android.
- **`UIKitBridge.rootViewController`**: small helper resolving the presenting `UIViewController`
  from the active scene's key window — the iOS analog of the `Activity` reference Android's ad APIs
  take (SwiftUI has no first-class handle to "current view controller").
- **`HomeViewModel`**: `initAdsAndConsent`, `showPrivacyOptionsForm`, `showRewardAd`, `showAppOpenAd`
  (ported/dormant per above), `isInitCalled` gating (mirrors Android's `LaunchedEffect(Unit)` guard),
  new `HomeUiState` fields (`canRequestAds`, `isMobileAdsInitialized`, `isPrivacyOptionsRequired`).
- **Real ad-gating wired into `HomeView`**, replacing the Phase 2/3 direct-regenerate stubs:
  Refresh/Delete/.com confirm actions and the expired-state refresh now show `WatchAdBottomSheet`
  for free users and call the real rewarded ad. **Ported exactly** (not "cleaned up") a real Android
  quirk: `showRewardedAd`'s `onReward` **and** `noAdAvailableYet` callbacks both generate the email —
  Android's own fail-open design, where gating happens via the sheet tap, not the ad completion
  signal.
- **`CustomEmailViewModel.showRewardAd`** now calls the real `RewardedAdManager` (was a Phase 4 stub).
- **`AppDrawer`**: added a conditional "Show Privacy Options Form" row (shown only when
  `isPrivacyOptionsRequired`), wired to the real consent manager.
- **`AppContainer`**: constructs and wires `GoogleMobileAdsConsentManager`, `RewardedAdManager`,
  `AppOpenAdManager`.

### Discovered Android quirk — Inbox ad-gating is inconsistent with Home (ported faithfully)
Verified against the Android source directly: Inbox's expired-state refresh (`ConnectionLost`)
**always** shows the watch-ad sheet regardless of `isSubscribed`, and tapping "watch ad" **always**
calls `generateNewEmail(false)` directly — `onAdCountdownFinished` never touches the real ad SDK at
all, unlike Home's equivalent flow which does. This is a genuine inconsistency in the Android app
(subscribed users hit an unnecessary ad-sheet tap in Inbox but not in Home; the Inbox "ad" is
cosmetic). Ported exactly as observed, documented in `InboxView.swift` and here rather than
"fixed" — changing it would be a silent behavior deviation from the source app.

Verified:
- `xcodebuild -resolvePackageDependencies` → both packages resolved cleanly over network.
- Debug (app + tests) and Release builds → **zero warnings, zero errors**.
- `xcodebuild … test` → **38/38 pass**.
- Clean-install launch → **Google's real UMP consent dialog renders**, proving the consent request
  actually reached Google's servers and the form actually presented from the resolved root view
  controller. No crash from any of the new ad/consent/banner code paths.
- Two real compiler-caught bugs fixed before commit: a redundant/always-true `responseInfo != nil`
  check in `AppOpenAdManager` (not present in Android's `isAdAvailable()` either — removed to match
  exactly) and an unused `self` capture in the consent manager's closure.

Deferred (documented, not silently dropped):
- **ironSource mediation** — needs CocoaPods (no SPM support), by user decision this phase.
- **Real iOS AdMob app ID + ad unit IDs** — still Google's public test IDs; must be replaced with
  real production IDs from AdMob console before release (flagged since Phase 0).
- **`SKAdNetworkItems`** — Phase 8 pre-release checklist (App Store/attribution requirement, not a
  build requirement).
- **Firebase analytics event logging on consent status** (Android logs `ad_consent_status` /
  `ad_consent_error`) — Phase 7, alongside the rest of analytics.
- App-open ad triggering — ported but dormant, matching Android's own commented-out usage.

**Visual-check backlog note:** unlike Phases 3/4, this phase got a genuine (if partial) visual
verification "for free" — the UMP consent dialog auto-presents on launch, so a static screenshot
proved the SDK pipeline works without needing any simulator taps. The rewarded-ad flow itself
(tapping "Watch ad" and seeing a real video ad) still requires taps and joins the existing deferred
visual-check list.

## Phase 6 — Subscriptions (StoreKit 2) ⏳

_Next._ `BillingRepository` on StoreKit 2 (load products, purchase, restore, transaction listener,
persist `is_subscribed`), Subscription screen 1:1 (feature list, plan cards, price/trial from
store), gating premium features. Will replace the Premium placeholder sheet in `MainScaffold` and
the subscription-dialog hooks left across Phases 2–5.
