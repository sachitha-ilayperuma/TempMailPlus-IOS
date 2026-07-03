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
| **4** | Custom email | ⬜ Not started |
| **5** | Ads + consent | ⬜ Not started |
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
build success + code review, not by looking at it. Flag for manual check in Xcode, or grant
computer-use in a future session to close this out.

Deferred to their phases (hooks in place):
- Ad gating on the expired-state refresh (Phase 5).
- Branded empty-inbox/logo icons use SF Symbols as stand-ins (Phase 7 polish).
- Full HTML CSS parity with Android's `HtmlText` (Phase 7 polish, if needed after visual QA).

## Phase 4 — Custom email ⏳

_Next._ `CustomEmailViewModel` (validation, create, free-user 1-per-25h gate, rewarded-ad /
subscription branching — ad gating itself lands in Phase 5), add-custom-email bottom sheet
(username field + domain picker), wiring `getEmailDomains`/`custom-email/create`/`custom-email/list`.
