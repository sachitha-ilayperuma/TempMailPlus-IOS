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
| **6** | Subscriptions (StoreKit 2) | ✅ Done |
| **7** | Menu, FAQ, Rate, localization | ✅ Done |
| **8** | Notifications + polish | ✅ Done |

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

## Phase 6 — Subscriptions (StoreKit 2) ✅ (2026-07-03)

**Deliverable met:** builds clean (Debug + Release, zero warnings), **46/46 tests pass** (8 new),
and a clean-install launch confirms the billing code handles an empty product catalog gracefully —
no crash, Home + the real UMP consent dialog still render correctly.

Done:
- **Domain:** `BillingRepository` protocol added (`Domain/Repository/Repositories.swift`).
  `SubscriptionStatus`/`SubscriptionInfo`/`BillingProducts` already existed from Phase 1.
- **`StoreKitBillingDataSource`**: the real StoreKit 2 port of Android's `BillingDataSource`.
  `queryProducts()` (loads `Product.products(for:)`, maps to `SubscriptionInfo` incl. free-trial /
  billing-period formatting, persists via `DataStoreManager.saveSubscriptions`), `queryActiveSubscriptions()`
  (`Transaction.currentEntitlements`), `launchSubscriptionPurchase(productId:)` (`product.purchase()`
  + `transaction.finish()`), and a `Transaction.updates` listener (Android's `PurchasesUpdatedListener`).
  Android's billing-client-connection/reconnect-with-backoff machinery has no StoreKit 2 equivalent
  (no connection step exists) and is intentionally not ported.
- **`BillingRepositoryImpl`**: thin delegate, matches Android exactly.
- **`SubscriptionViewModel`**: talks to `BillingRepository` directly, **not** through use-case
  wrappers — confirmed via grep that Android's `GetSubscriptionStatusUseCase`/
  `RefreshSubscriptionUseCase` are dead code (never constructed/injected anywhere); skipped porting
  them rather than porting unused wrappers, consistent with the Phase 3/5 dead-code findings.
- **`SubscriptionSheet`** (+ `PremiumFeaturesList`, `PlanCard`, `FeatureItem`): ported 1:1, including
  hardcoded (non-localized) strings Android itself hardcodes ("Experience More with Premium",
  "Cancel Anytime", "Activate Plan"/"Subscribed") and `PlanCard`'s selected-state border-only
  styling (Android's own `.background(background)` line is commented out in the source — matched,
  not "improved"). Crown icon uses an SF Symbol stand-in for Android's Lottie `twincle_crown`
  animation (`lottie-ios` is a clean SPM add, same tier as Phase 5's ad SDKs, but out of scope here —
  Phase 7 polish).
- Wired: `MainScaffold`'s Premium sheet now presents the real `SubscriptionSheet` (replacing the
  Phase 2 placeholder); `InboxView` gained an `onShowSubscription` closure (was a TODO) wired the
  same way `HomeView` already was.
- **`AppContainer`**: constructs `StoreKitBillingDataSource`/`BillingRepositoryImpl`;
  `makeSubscriptionViewModel()` factory (one per sheet presentation, matching the
  `makeCustomEmailViewModel()`/`makeEmailDetailViewModel()` pattern).
- **`TempMailPlus.storekit`**: a local StoreKit Configuration file (weekly/monthly/yearly matching
  `BillingProducts.activeProducts`, with trial periods) wired into the scheme's `TestAction` and
  `LaunchAction` via `<StoreKitConfigurationFileReference>` — lets the user test real purchases in
  Xcode/Simulator with zero App Store Connect setup. Excluded from the app bundle (membership
  exception, same pattern as `Info.plist`).

### Tooling limitation discovered (not a code bug) — documented for the record
`xcodebuild test`/`build` from the command line **does not honor Xcode scheme StoreKit
Configuration files** — this is a well-documented Apple/Xcode limitation: StoreKit local testing is
tied to Xcode's own process launching (GUI Run/Test), not raw `xcodebuild`/`simctl`. I originally
wrote `StoreKitBillingDataSourceTests.swift` (a true integration test against the local `.storekit`
catalog) and spent real effort chasing what looked like a path-resolution bug (fetched a working
open-source example's `.xcscheme` to confirm the correct relative-path convention, which did fix the
path) — but the catalog still came back empty under `xcodebuild test`, which is what led to
discovering the actual root cause via a documented community report. **Decision:** removed that
integration test (it cannot pass headless in this environment) and replaced it with
`SubscriptionViewModelTests` using a `FakeBillingRepository` — the same fake-repository pattern
already used for `CustomEmailViewModelTests` — which tests 100% of *this port's own logic*
(plan filtering/selection, purchase triggering, status observation) without needing real StoreKit.
The `.storekit` file + scheme wiring are kept in place since they're genuinely useful for the user's
own manual Xcode verification (confirmed the path itself is correct, per the fetched working
example's convention) — just not exercisable from this sandboxed CLI-only session.

### Post-hoc scare that turned out to be my own mistake (documented for transparency)
After the above, a `simctl launch` attempt failed with `FBSOpenApplicationServiceErrorDomain code=4`
and looked like a possible app crash. Investigation: `simctl listapps` showed the app wasn't
installed at all, and `simctl install` had thrown an *internal* `NSInternalInconsistencyException`
inside `simctl` itself (`Invalid parameter not satisfying: installURL`) — because my shell script's
`$APP` path variable had resolved to an empty string (the most recent build before that had been a
Release-configuration build, and the Debug `.app` bundle needed a fresh build). No crash report
existed anywhere on disk, which was the tell. Rebuilding Debug and re-running the install/launch
sequence with a verified non-empty path confirmed: **no crash** — the app installs, launches, and
renders correctly (Home + the real UMP dialog) even with an empty StoreKit product catalog
(`queryProducts`/`queryActiveSubscriptions` are guard/optional-safe throughout, no force-unwraps).

Verified:
- `xcodebuild … build` (Debug + Release) → zero warnings, zero errors.
- `xcodebuild … test` → **46/46 pass** (8 new `SubscriptionViewModelTests`).
- Clean-install launch (no local StoreKit catalog — the honest current-state path) → no crash, Home
  + UMP consent dialog render correctly.
- StoreKit 2 API usage (`Product`, `Transaction`, `FullScreenContentDelegate`-adjacent purchase
  APIs) compiled correctly on the first attempt with no rename/API surprises (unlike Phase 5's UMP
  renames) — validated against the actual pinned SDK, not assumed.

Deferred (documented, not silently dropped):
- Real purchase/restore flow can only be genuinely exercised by the user, manually, in Xcode with
  the `.storekit` config active (or against a real sandbox account) — flagged as part of the
  existing visual-check backlog (now also includes: subscription sheet UI, a real Watch-purchase-flow).
- Real App Store Connect subscription product IDs — must be confirmed/created to match
  `BillingProducts.activeProducts` before release (flagged since Phase 0/5).
- `lottie-ios` real crown animation — Phase 7 polish.
- Analytics (`ClickSubscriptionActivate`, `SubscriptionSuccess`) — Phase 7 stub, consistent with all
  other analytics deferrals.
- "Restore Purchases" UI — Android doesn't have an explicit restore button either (relies on
  `queryActiveSubscriptions` running on launch); matched, not added as a new feature.

## Phase 7 — Menu, FAQ, Rate, localization ✅ (2026-07-03)

**Deliverable met:** builds clean (Debug + Release, zero warnings), **48/48 tests pass** (2 new),
and real launches confirm: fresh install → real onboarding artwork renders and routes correctly;
returning user → lands on Home correctly across 4 repeated relaunches (see bug note below).

Done:
- **Localization, all 7 locales:** wrote a script to parse the Android app's actual `strings.xml`
  files (all locales) and generate `Localizable.strings` for `en/es/de/pt/ru/zh-Hans/zh-Hant` —
  **carrying over the existing professional translations verbatim**, not re-translating. Verified
  the `values-en` vs. default `values` key diff first (only `admob_app_id`, Android-only, already
  handled via Phase 5's `Info.plist`) so nothing was missed. Cross-diffed iOS vs. Android key sets:
  found only 2 iOS-only keys (`home`/`premium` bottom-nav labels) — confirmed via source read that
  **Android hardcodes these in English regardless of locale** (`BottomNavItem.kt` passes literal
  `"Home"`/`"Inbox"`/`"Premium"` strings, not `stringResource()`). Deliberately localized them
  properly in this port rather than matching the apparent oversight — the one intentional
  "improvement" this phase, documented rather than silent. `knownRegions` updated in the `.pbxproj`.
- **`FAQView`**: 11 Q&A items, single-expanded-at-a-time (matches Android's `Int` index, not a
  `Set`). Uses `NSLocalizedString(_:comment:)` for the dynamic `"faq\(i)"`/`"faqa\(i)"` keys —
  **not** `String(localized:)`, whose string-interpolation initializer treats interpolated
  segments as *format arguments*, not part of the lookup key (a real mistake caught before it
  shipped: first attempt used the wrong API and would have silently failed to resolve any FAQ
  text at runtime).
- **`AppDrawer`** (full rewrite): header, dark-mode toggle, FAQ/Help Center/Blog/Rate Us menu
  items, Try-our-Web/Support-Us, conditional Privacy Options row, subscription banner
  (non-subscribed users), social icon row, Privacy Policy/Terms footer + app version. Social/menu
  icons use SF Symbol stand-ins for Android's branded drawables (not copied into the asset
  catalog) — Phase 8 polish.
- **Onboarding — real artwork, not a stand-in:** converted the Android app's actual onboarding
  images (4× WebP + 1× JPEG) to PNG via `sips` (confirmed macOS's built-in tool decodes WebP
  natively) and imported them as proper asset-catalog imagesets, preserving Android's exact page
  order (`onboard_image_1`, `onboard_image_1_2.jpg`, `onboard_image_3`, `_4`, `_5` — note
  `onboard_image_2.webp` exists on disk but is genuinely unused dead artwork in Android too,
  confirmed via the page list — correctly not imported). `OnboardingView` ports the pager,
  indicator dots, Skip/Previous/Next/Finish controls, and bottom gradient overlay.
- **`RootView`**: gates Onboarding vs. `MainScaffold` on `isFirstLaunch`, ported from
  `MainActivity.kt`'s top-level `NavHost`. Found and fixed a real bug before it shipped: Android's
  `isFirstLaunch` is a **one-shot, non-reactive** fetch on both platforms — Android actually
  transitions off Onboarding via an *explicit navigation call* from the Finish button, not by that
  state variable changing. My first draft gated purely on `viewModel.isFirstLaunch`, which would
  never have flipped after Finish was tapped, leaving the user stuck on Onboarding forever. Fixed
  with a session-local `onboardingComplete` flag that mirrors Android's one-way-navigation
  semantics instead.
- **Confirmed dead code, not ported:** `SplashScreen.kt`'s composable is never referenced by any
  nav route (`Screen.kt` has no `Splash` destination; only the native Android 12 system splash API
  is used via `installSplashScreen()`). The iOS analog of that *native* splash is the
  `UILaunchScreen` already configured in `Info.plist` since Phase 0 — no custom splash view needed.
- **`RateAppBottomSheet`** + **`RateReviewChecker`**: ported Android's custom-sheet-then-native-
  review escalation with the same 1h/30-day cooldowns, using `scenePhase` background→active
  transitions as the iOS analog of `ON_PAUSE`→`ON_RESUME`, and `SKStoreReviewController` as the
  native review API. Ported the outer gate too (if already reviewed or clicked "later" in *any*
  prior session, the flow never activates) — checked fresh each call rather than replicating
  Android's one-time-at-mount gate, since nothing else can flip those flags mid-session so the
  observable behavior is identical. One deliberate text fix: "Play Store" → "App Store" in the
  rate copy (platform-correct necessity, not a preserved quirk).
- **`AnalyticsTracker`**: real event-name/param mapping ported from `AnalyticsEvent.kt`, backed by
  `os.Logger` rather than the Firebase SDK — no `GoogleService-Info.plist` exists yet (no iOS
  Firebase app registered), and integrating the real SDK without credentials would crash at
  `FirebaseApp.configure()`. Same protocol seam as Android (`AnalyticsTracker`), so swapping in a
  real `FirebaseAnalyticsTracker` later is a single new file + one `AppContainer` line. Wired real
  logging (replacing every previous phase's stub): `logCustomEmailClicked` (Phase 4),
  `ClickSubscriptionActivate` (Phase 6, confirmed it fires *before* the `selectedPlan` guard,
  matching Android exactly), `SubscriptionSuccess` (Phase 6 — placed in
  `StoreKitBillingDataSource.launchSubscriptionPurchase`'s success path specifically, **not** the
  general `Transaction.updates` listener, since Android's equivalent only fires off
  `launchBillingFlow` — logging in the general entitlement stream would over-fire on
  renewals/restores that aren't a user "click"), plus the drawer's Blog/Web/SupportUs/RateNow
  events.
- **Real bug found and fixed post-hoc:** during returning-user verification, one launch (out of 5)
  showed the Premium subscription sheet auto-open unexpectedly. Not reproduced in 4 follow-up
  attempts, so likely a one-off artifact of the rapid `defaults write` + relaunch test sequence —
  but stacking 4 independent `Bool` `@State` + `.sheet(isPresented:)`/`.fullScreenCover(isPresented:)`
  modifiers on one view is a known SwiftUI conflict source, so refactored `MainScaffold` to a
  single enum-driven `ActiveSheet` + `.sheet(item:)` for the three sheet-style modals (Premium,
  Custom Email, Rate), making "at most one sheet active" structurally true rather than relying on
  discipline across four booleans. FAQ stays its own `.fullScreenCover` (different presentation
  style; one extra modifier carries no such risk). Re-verified clean across 4 more relaunches after
  the fix.

Verified:
- `xcodebuild … build` (Debug + Release) → zero warnings, zero errors.
- `xcodebuild … test` → **48/48 pass**.
- Fresh-install launch → real onboarding artwork renders (not a placeholder), first-launch routing
  correct, no crash.
- Returning-user launch (×5, including a re-verification pass after the modal-state fix) → lands
  on Home correctly; only 1/5 showed the described anomaly, not reproduced after the fix.
- Bonus incidental confirmation: banner ad (Phase 5) genuinely renders in these screenshots
  ("APNIC… Test mode" — a real AdMob test creative loading), not just compiling.

Deferred (documented, not silently dropped):
- Real Firebase Analytics SDK — needs a `GoogleService-Info.plist` (no iOS Firebase app registered
  yet); `AnalyticsTrackerImpl` (os.Logger-backed) is the swap-in-ready seam.
- Real branded icons (drawer menu/social row) — SF Symbol stand-ins for now.
- Real App Store id in `openAppStoreListing()` — placeholder id, must be replaced once published.
- The "Skip" button on Onboarding renders a little low-contrast against the artwork's own baked-in
  branding near the top — cosmetic, flagged for a Phase 8 polish pass rather than blocking.
- FAQ/drawer/onboarding/rate-sheet interactive verification (tapping through, not just the
  auto-rendered states) — joins the existing deferred visual-check backlog (Inbox, Email detail,
  Custom Email sheet, StoreKit purchase flow).

## Phase 8 — Notifications + polish ✅ (2026-07-10)

**Deliverable met — final phase, all 8 phases now complete.** Builds clean (Debug + Release, zero
warnings), **48/48 tests pass**, and real launches confirm the **actual OS notification permission
dialog fires** (not a stub), the **real app icon renders on the springboard**, the app **runs
functionally on iPad**, and the **real Lottie crown animation is correctly bundled** and wired.

Done:
- **`LocalNotificationManager`**: wraps `UNUserNotificationCenter` — `requestAuthorization()`
  (ported from Android's `POST_NOTIFICATIONS` request, gated the same way: only prompts if not
  already declined) and `postNewMailNotification` (ported from
  `WebSocketService.showNotification` — sender name as title, subject as body). Wired into
  `HomeViewModel.startWebSocketService`'s existing WebSocket observer, so foreground-received mail
  now posts a real local notification, not just the in-app badge.
- **`BackgroundRefreshManager`** (`BGAppRefreshTask`, no Android equivalent — iOS's own answer to
  the no-backend-push constraint): registers a background task on `AppContainer` init, reschedules
  on every backgrounding (`MainScaffold`'s existing `scenePhase` observer), and on each opportunistic
  run fetches the selected mailbox, diffs against a persisted "seen ids" set
  (`DataStoreManager.getSeenEmailIds`/`setSeenEmailIds` — new, iOS-only, no Android source key —
  needed since a background launch has no live in-memory cache to diff against), and posts
  notifications for genuinely new mail (capped at 3 to avoid notification-spam on a big batch).
  `Info.plist`: `BGTaskSchedulerPermittedIdentifiers` + `UIBackgroundModes: fetch`.
- **Release polish:**
  - **Real AppIcon**: converted Android's 512×512 Play Store icon (best available source) to a
    1024×1024, alpha-free PNG (via a JPEG round-trip — `sips` has no direct "strip alpha" flag;
    JPEG's format definition has no alpha channel, so converting through it is a reliable way to
    flatten). Verified genuinely compiled into the asset catalog at the derived sizes Xcode needs
    (60×60@2x iPhone, 76×76@2x iPad) and confirmed rendering on the actual simulator springboard.
  - **Real Lottie crown animation**: added `lottie-ios` (4.6.1) via SPM — a clean add like Phase
    5/6's other SPM dependencies, no CocoaPods needed. `SubscriptionSheet` now uses
    `LottieView(animation: .named("twincle_crown"))` instead of the SF Symbol stand-in; verified
    the JSON is genuinely present in the built app bundle (not silently missing).
  - **`SKAdNetworkItems`**: pulled the real, complete 50-identifier list directly from Google's own
    sample `Info.plist` (`googleads-mobile-flutter` repo) via `curl` + `plistlib`, rather than
    hand-transcribing a list that size (Phase 5 deliberately deferred this exact risk — now closed
    out properly with a verified source).
  - **`ITSAppUsesNonExemptEncryption`**: set `false` — the app's only encryption use is AES to
    obscure a bundled config string (Phase 1) and standard HTTPS/TLS, both exempt categories.
  - **Accessibility**: focused (not exhaustive) pass — `.accessibilityLabel` added to the icon-only
    buttons that had no visible text (hamburger menu, FAQ/Email-detail back buttons, Home's copy
    button); the Inbox dropdown's chevron was left alone since its parent button already has a
    visible `Text(selectedEmail)` that VoiceOver reads automatically. Dynamic Type was already
    wired since Phase 0.
  - **iPad**: confirmed functional (builds clean, installs, generates a real email from the live
    backend, no crash) but **not visually optimized** — layout is the same phone-width design,
    not a dedicated iPad layout. Documented honestly rather than overclaiming "iPad support."

Verified:
- `xcodebuild … build` (Debug + Release, iPhone **and** iPad destinations) → zero warnings, zero
  errors.
- `xcodebuild … test` → **48/48 pass**.
- Real launch → **the actual native "TempMailPlus Would Like to Send You Notifications" dialog
  fires**, stacked on the Phase 5 UMP dialog — proves `requestAuthorization()` genuinely calls the
  OS, not a stub, and nothing crashed from the new BGTaskScheduler registration/notification
  code/Lottie dependency.
- Real launch on iPad Air (M4) simulator → generates a real email from the live backend, no crash.
- Springboard screenshot → the real converted app icon renders correctly with the "TempMailPlus"
  label.
- `Info.plist` validated with `plutil -lint` after the large `SKAdNetworkItems` addition.

Deferred (documented, not silently dropped — see IMPLEMENTATION_PLAN.md §8 for the consolidated
final list):
- Real AdMob production ad unit IDs, real App Store Connect subscription product IDs, real Firebase
  credentials — all need external account setup outside this session's scope.
- ironSource mediation — descoped by user decision in Phase 5 (CocoaPods-only, no SPM).
- Dedicated iPad layout (currently functional-but-unoptimized phone-width UI on the larger screen).
- Exhaustive accessibility audit (this was a focused pass on icon-only buttons, not a full
  VoiceOver/Dynamic-Type/contrast audit).
- Real branded drawer/social-row icons (SF Symbol stand-ins remain).

### Consolidated manual verification checklist (accumulated since Phase 3)
Everything below compiles, passes its automated tests where applicable, and has been verified via
real launches wherever a screenshot could prove it without tapping. What remains is **interactive
tap-through verification**, which needs either the user's own device/simulator testing or a future
session with computer-use access granted:
- **Inbox** (Phase 3): dropdown header/overlay with 2+ active emails, switching mailboxes, swipe/tap
  interactions, pull-to-refresh gesture.
- **Email detail** (Phase 3): tapping into a real received email, HTML rendering fidelity, opening
  an attachment.
- **Custom Email** (Phase 4): the full create-custom-email flow end-to-end, including the
  free-tier/rewarded-ad branch.
- **Ads** (Phase 5): actually watching a rewarded ad through to completion (banner/consent dialog
  are confirmed rendering for real; the rewarded video flow itself is untapped).
- **StoreKit purchase** (Phase 6): completing a purchase via the `TempMailPlus.storekit` local
  config in Xcode's own Run/Test (not `xcodebuild` — confirmed as a real Apple tooling limitation,
  not fixable from this session).
- **FAQ / drawer / rate sheet / onboarding** (Phase 7): tapping through FAQ items, every drawer row,
  the onboarding Next/Previous/Skip controls, the rate sheet's Later/Rate Now buttons.
- **Notifications** (Phase 8): granting the permission dialog and confirming a real notification
  banner appears (the dialog itself is confirmed firing; tapping "Allow" and receiving a real
  notification is untapped).

This is the natural next step once you're ready to do a hands-on pass, or a good scope for a future
session with computer-use enabled.
