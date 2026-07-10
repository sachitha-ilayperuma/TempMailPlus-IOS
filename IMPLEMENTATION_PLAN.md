# TempMailPlus — iOS Implementation Plan

A phased plan to port the existing **TempMailPlus** Android app (Kotlin / Jetpack Compose / Clean
Architecture) to a native **iOS** app (Swift / SwiftUI) with the **same UI and the same flows**.

> Source of truth for behavior: the Android project at `../TempMailPlus`. Every screen, string,
> color, expiry rule, API call, and analytics event below is derived from that codebase. When a
> detail is ambiguous during implementation, match the Android source exactly.

---

## 1. What the app does (feature inventory)

TempMailPlus is a **disposable / temporary email** client.

| Area | Behavior |
|------|----------|
| **Onboarding** | 5-image intro carousel, shown once on first launch. |
| **Splash** | Branded splash on launch. |
| **Home** | Generate a temp email, show the address, copy-to-clipboard (with "Copied" toast), Refresh (reset mailbox), Delete (regenerate), "Custom Email" button, "Try .com Domain" banner button, banner ad (free users). Logo turns red + "Email Expired" state on expiry. |
| **Inbox** | List of received mails; email-address dropdown to switch between multiple active mailboxes; swipe-to-delete; empty state ("Your inbox is empty / Waiting for new emails…"); new-email badge. |
| **Email detail** | Renders HTML body; lists + downloads attachments. |
| **Custom email** | Bottom sheet: username validation (3–15 chars, allowed `letters/numbers/._-`, forbidden-keyword filter), domain picker; free users gated behind a rewarded ad (1 free custom email / 25h) or subscription. |
| **Subscription / Premium** | Weekly / Monthly / Yearly plans, feature list, purchase + restore. |
| **Drawer menu** | Dark-mode toggle, FAQ, Help Center, Blog, Rate us, Try our Web, Support Us, Privacy Options form, Privacy Policy, Terms & Conditions. |
| **FAQ** | 11 Q&A items. |
| **Rate app** | Custom rate bottom sheet + native in-app review. |
| **New-mail delivery** | Android runs a foreground WebSocket service + posts a local notification. **(iOS differs — see §7.)** |
| **Ads** | Banner, Rewarded (gates custom-email / refresh for free users), App-Open, with UMP consent. |
| **Theming** | Light / Dark, ThemeBlue accent, Raleway + Pacifico fonts. |
| **Localization** | en, es, de, pt, ru, zh-Hans, zh-Hant. |
| **Expiry rules** | Normal 10 min; `.com` 5 min (free) / extended (subscribed); custom 24h. Server-time synced. |
| **Analytics** | Firebase events (subscription_success, click_custom_email, click_support_us, etc.). |

---

## 2. Backend contract (shared, unchanged)

The iOS app talks to the **same backend** as Android. Base URL and WebSocket URL are **AES/CBC
encrypted** in the source and decrypted at runtime.

### REST endpoints (`EmailApiService`)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `get-email` | Generate a random temp email (optional query params → `.com` domain). |
| POST | `activate-email` | Activate a generated email (body = `{email, reservationId}`). |
| GET | `get-emails-by-address?email=` | Fetch inbox messages for an address. |
| GET | `getEmailDomains` | List available domains (response body is a JSON string to parse). |
| POST | `customEmailAddAndValidate` | Validate a custom email request. |
| POST | `custom-email/create` | Create a custom email (`{prefix, domain, deviceId}`). |
| GET | `get-currenttimestamp` | Server epoch (for time-offset sync). |
| GET | `custom-email/list?deviceId=` | List a device's active custom emails. |

### WebSocket
- On open, send `{"action":"subscribeEmails","email":"<addr>"}`.
- On `{"action":"newEmailReceived","email":{…}}`, parse into an `Email` and surface it.

### Response models (Codable mirrors of the Android DTOs)
`TempEmailResponse{email,reservationId}`, `EmailsResponse{emails:[EmailDto]}`,
`EmailDto{id,from,fromName,subject,date,content,read,attachments}`,
`AttachmentDto{filename,contentType,size,url}`, `DomainResponse{statusCode,headers,body}`,
`CustomEmailRequest{prefix,domain,deviceId}`,
`CustomEmailResponse{message,code,email,reservationId,error,expiresAt}`,
`ActiveCustomEmailResponse{code,count,emails:[{email,expiresAt}]}`.

### Encryption
AES/CBC/PKCS7. Reuse the **same** base64 key/IV and the split ciphertext constants from
`SecretConstants.kt` (BURL/WURL/BKEY/BIV). iOS has no built-in AES-CBC in CryptoKit → use
**CommonCrypto** (`CCCrypt`) to implement `Decryptor.decryptBase64(...)`.

---

## 3. Technology mapping (Android → iOS)

| Android | iOS choice |
|---------|-----------|
| Kotlin | Swift 5.9+ |
| Jetpack Compose + Material3 | **SwiftUI** |
| MVVM + Clean Architecture (domain/data/presentation) | Same layering, Swift-idiomatic |
| Hilt (DI) | Lightweight `AppContainer` + protocol-based init injection (no 3rd-party DI needed) |
| ViewModel + StateFlow / `uiState` | `ObservableObject` + `@Published` (or `@Observable`, iOS 17+) |
| Retrofit + OkHttp + Gson | `URLSession` async/await + `Codable` |
| OkHttp WebSocket | `URLSessionWebSocketTask` |
| DataStore Preferences | `UserDefaults` (via a `DataStoreManager` wrapper) |
| Proto DataStore | `Codable` structs persisted to `UserDefaults`/file (proto not needed) |
| Coil (image loading) | `AsyncImage` |
| Lottie (Android) | **lottie-ios** (SPM) |
| Firebase Analytics + Crashlytics | **Firebase iOS SDK** (SPM) |
| Google Mobile Ads + UMP + ironSource | **Google-Mobile-Ads-SDK** + **UserMessagingPlatform** + ironSource iOS adapter |
| Google Play Billing | **StoreKit 2** |
| Play In-App Review | `SKStoreReviewController` / `requestReview` |
| Foreground WebSocket service + local notif | Foreground `URLSessionWebSocketTask` + `BGAppRefreshTask` best-effort (no APNs — no backend changes; see §7) |
| Fonts: Raleway, Pacifico | Same `.ttf` files, registered in Info.plist |
| `stringResource` / `strings.xml` (7 locales) | `Localizable.strings` (7 `.lproj`) |

### Design tokens to reproduce exactly (`Color.kt` / `AppTypography.kt`)
- `ThemeBlue #1C7DDD`, `LightBlue #1B1C7DDD`, `Red #E03131`, `Yellow #FFD400`,
  `DarkYellow #EF9600`, `TextSecondary #8E8E93`, `DarkGray #505050`, `LightAshBG #F1F1F1`, etc.
- Fonts: **Raleway** (Regular/Medium/SemiBold/Bold/ExtraBold) for body/labels, **Pacifico** for the
  brand/logo text. Type ramp: titleLarge 18/Bold, titleMedium 16/SemiBold, headlineMedium 20,
  labelMedium 18, labelSmall 16.
- Light/Dark schemes keyed off the persisted `dark_mode` flag (not system) — matches Android, which
  drives theme from the DataStore toggle.

---

## 4. Target project structure

```
TempMailPlus-IOS/
├── TempMailPlus.xcodeproj
├── TempMailPlus/
│   ├── App/
│   │   ├── TempMailPlusApp.swift        # @main, DI container wiring
│   │   ├── AppContainer.swift           # dependency graph (replaces Hilt modules)
│   │   └── Info.plist
│   ├── Core/
│   │   ├── Constants.swift              # AdMob unit IDs, test device id
│   │   ├── Extensions/                  # ensureEpochMillis, clipboard, etc.
│   │   └── TimeProvider.swift
│   ├── Data/
│   │   ├── Security/                    # SecretConstants + Decryptor (CommonCrypto)
│   │   ├── Remote/                      # EmailApiService, WebSocketManager
│   │   ├── DTO/                         # Codable response models
│   │   ├── Repository/                  # *RepositoryImpl
│   │   ├── DataStore/                   # DataStoreManager (UserDefaults), PreferenceKeys
│   │   ├── Ads/                         # Banner/Rewarded/AppOpen/Consent managers
│   │   ├── Billing/                     # StoreKit 2 data source
│   │   └── Analytics/                   # FirebaseAnalyticsTracker
│   ├── Domain/
│   │   ├── Model/                       # Email, TempEmail, Attachment, Subscription*
│   │   ├── Repository/                  # protocols
│   │   ├── UseCase/                     # Generate/GetEmails/CreateCustom/… use cases
│   │   └── Validation/                  # UsernameValidator, ForbiddenKeywords
│   ├── Presentation/
│   │   ├── Theme/                       # Colors, Typography, ThemeManager
│   │   ├── ViewModels/                  # HomeVM, CustomEmailVM, SubscriptionVM, EmailDetailVM
│   │   ├── Navigation/                  # Router / NavigationStack routes
│   │   ├── Components/                  # ConfirmSheet, WatchAdSheet, RateSheet, BannerAd, etc.
│   │   └── Screens/
│   │       ├── Splash/  Onboarding/  Home/  Inbox/  EmailDetail/
│   │       ├── CustomEmail/  Subscription/  FAQ/  Drawer(Menu)/
│   ├── Resources/
│   │   ├── Assets.xcassets              # icons/images (map from res/drawable + mipmap)
│   │   ├── Fonts/                       # Raleway*, Pacifico
│   │   ├── Lottie/                      # twincle_crown.json, lottie_btn_animation.json
│   │   └── *.lproj/Localizable.strings  # en, es, de, pt, ru, zh-Hans, zh-Hant
│   └── Notifications/                   # UNUserNotificationCenter + (optional) APNs handling
├── TempMailPlusTests/                   # port InboxViewModelTest etc.
└── README.md
```

---

## 5. Assumptions / defaults (change if needed)

- **Min iOS:** 16.0 (mature SwiftUI, StoreKit 2, ~full device coverage in 2026). Bump to 17 only if
  we want `@Observable`.
- **Bundle id:** `com.digitaldevs.tempmailplus` (mirror Android `applicationId`).
- **Monetization kept identical:** AdMob + ironSource mediation + Firebase, StoreKit for subs.
- **AdMob iOS ad-unit IDs are NOT reusable from Android** — new iOS ad units + a new AdMob iOS app
  ID are required (placeholder/test IDs used until provided).
- **StoreKit product IDs** should match the store configuration (Android used
  `weeklypremium_march2026`, `monthly.premium_v2`, `annual_permium_v2`). Confirm the App Store
  Connect product IDs; StoreKit prices/trials come from the store, not hardcoded.
- **Xcode project generation:** created via Xcode or XcodeGen/Tuist. Dependencies via **SPM**.

---

## 6. Phased delivery

Each phase is independently buildable and reviewable.

### Phase 0 — Project bootstrap
- Create Xcode project (SwiftUI lifecycle), configure bundle id, min iOS, signing.
- Add SPM deps: Firebase, Google-Mobile-Ads, UMP, lottie-ios, (ironSource adapter later).
- Register fonts (Raleway, Pacifico) in Info.plist; import Lottie JSON.
- Port color + typography tokens; build `ThemeManager` (dark-mode from persisted flag).
- Set up `AppContainer` DI skeleton.
- **Deliverable:** app launches to an empty themed shell.

### Phase 1 — Domain + Data core (no ads/billing)
- Port domain models, repository protocols, use cases, `Result`, `UsernameValidator`,
  `ForbiddenKeywords`.
- Implement `SecretConstants` + `Decryptor` (CommonCrypto) and verify decrypted base/WS URLs match
  Android output.
- Implement `EmailApiService` (URLSession) + all DTOs; `DataStoreManager` (UserDefaults) with the
  same keys; `DeviceIdProvider`; `TimeProvider` + server-time sync.
- **Deliverable:** unit tests hitting the API/decryption; port `InboxViewModelTest`.

### Phase 2 — Home flow
- `HomeViewModel` (mirror `HomeUiState` + all logic: generate, `.com`, expiry countdowns,
  active-emails refresh, selected-email persistence, migration of past-version emails).
- Home screen UI 1:1 (title, logo w/ new-mail badge, address pill + copy, Refresh/Delete,
  Custom Email button, "Try .com" banner button, expired state).
- Confirmation bottom sheet (reset/delete/.com), copy toast.
- Bottom navigation (Home / Inbox / Premium) + top bar + drawer scaffold.
- **Deliverable:** generate, copy, refresh, delete, switch to `.com` (without ad gating yet).

### Phase 3 — Inbox + Email detail + realtime
- `WebSocketManager` (`URLSessionWebSocketTask`): subscribe + parse `newEmailReceived`.
- Inbox screen: list, address dropdown (multi-mailbox), swipe-to-delete, empty/waiting states,
  new-email badge; wire `get-emails-by-address`.
- Email detail: HTML rendering (WKWebView or AttributedString), attachment list + download/share.
- **Deliverable:** receiving a mail while foregrounded updates inbox live.

### Phase 4 — Custom email
- `CustomEmailViewModel` (validation, create, free-user 1-per-25h gate, rewarded-ad / subscription
  branching).
- Add-custom-email bottom sheet: username field + validation messages, domain picker.
- Wire `getEmailDomains`, `custom-email/create`, `custom-email/list`.
- **Deliverable:** subscribed + free (post-ad) custom email creation.

### Phase 5 — Ads + consent
- UMP consent gathering + privacy-options form.
- Banner (home), Rewarded (gates refresh + custom email for free users), App-Open ads.
- ironSource mediation adapter.
- **Deliverable:** ad-gated flows match Android for free users; hidden for subscribers.

### Phase 6 — Subscriptions (StoreKit 2)
- `BillingRepository` on StoreKit 2: load products, purchase, restore, transaction listener,
  persist `is_subscribed`, refresh on launch.
- Subscription screen 1:1 (feature list, plan cards, CTA, price/trial from store).
- Gate premium features (unlimited `.com`, extended expiry, ad-free, multi-inbox).
- **Deliverable:** purchase/restore toggles premium behavior everywhere.

### Phase 7 — Menu, FAQ, Rate, misc
- Drawer: dark-mode toggle, FAQ, Help Center, Blog, Rate us, Try our Web, Support Us, Privacy
  Options, Privacy Policy, Terms.
- FAQ screen (11 items). Rate bottom sheet + `requestReview`. Onboarding carousel + splash.
- Analytics tracker + all events. Full localization (7 locales).
- **Deliverable:** feature-complete parity (foreground).

### Phase 8 — Notifications (see §7) + polish
- **Constraint: no backend changes → no APNs push.** Implement the best achievable with the
  existing backend only:
  - Local notifications for mails received while the app is active (WebSocket-driven).
  - `BGAppRefreshTask` best-effort background poll of `get-emails-by-address` for the active
    address; diff against stored mail and fire a local notification for new ones.
  - REST sync on every foreground so the inbox is always complete on open (never lose mail).
- Accessibility, iPad layout check, App Store assets, TestFlight, release checklist.
- **Deliverable:** submittable build (with the documented background-notification limitation).

---

## 7. ⚠️ Key platform difference: background new-mail notifications (NO backend changes)

Android keeps a **foreground service** with a persistent WebSocket and posts a local notification
when a mail arrives — even when the app is backgrounded. **iOS does not permit long-lived background
sockets**, and the project constraint is **no backend changes**, which rules out APNs push (APNs
requires the backend to send the message). Therefore **real-time notifications while the app is
backgrounded/closed are not achievable** — this is an accepted platform limitation, not a bug.

**Emails are never lost, though.** The WebSocket is only a real-time channel; all mail lives on the
backend and is pulled via `get-emails-by-address`. So the inbox is always complete when the app is
opened. What degrades is only *timeliness of alerts* while backgrounded.

Best achievable with the existing backend only:

| Scenario | Mechanism | Quality |
|----------|-----------|---------|
| App in foreground | `URLSessionWebSocketTask` (real-time) | ✅ Full parity with Android |
| App reopened / foregrounded | REST `get-emails-by-address` sync | ✅ Inbox always complete — no mail lost |
| App backgrounded (not killed) | `BGAppRefreshTask` polls REST + local notification | ⚠️ Best-effort only |
| App force-quit by user | — | ❌ Nothing runs until reopened |

**Why `BGAppRefreshTask` is a supplement, not a fix:** iOS schedules it opportunistically (typically
no sooner than ~15 min, throttled by usage) and it **does not run after a user force-quit**. Given
temp emails expire in **5–10 min**, it will frequently miss the window. Include it as a bonus; do not
rely on it for the time-sensitive "waiting for a verification code" case.

**Practical mitigation (usage-driven):** temp-mail is normally used actively — generate an address,
paste it into a signup elsewhere, return within a minute — so the app is usually foreground or very
recently used, exactly where WebSocket + fetch-on-open give full parity. The uncovered case is
narrowly "backgrounded/closed and passively waiting," which iOS platform rules prevent without
backend push.

**Not viable here:** long-lived background sockets (suspended in ~30s); PushKit/VoIP push (Apple
restricts to real VoIP — rejection risk); silent `content-available` pushes (still need the backend
to send them). All require either backend work or violate App Store rules.

---

## 8. Open items — final status (all 8 phases complete, see PROGRESS.md for the full log)
- ~~Min iOS version~~ — **resolved: 16.0**, used throughout.
- **iOS AdMob app ID + unit IDs** — still Google's public test IDs (`Constants.swift`,
  `Info.plist` `GADApplicationIdentifier`); real production IDs must be created in the AdMob
  console and swapped in before release. **ironSource** was descoped by user decision in Phase 5
  (no SPM support; would need CocoaPods + project restructure) — AdMob alone is fully wired.
- **App Store Connect subscription product IDs** — `BillingProducts.swift` IDs
  (`weeklypremium_march2026`, `monthly.premium_v2`, `annual_permium_v2`) must exist as real
  products in App Store Connect before real purchases can succeed; `TempMailPlus.storekit`
  (Phase 6) lets the user verify the purchase flow locally without them.
- ~~APNs / backend push~~ — **out of scope: no backend changes** (see §7). Implemented in Phase 8:
  foreground local notifications (real, verified via the actual OS permission dialog) + best-effort
  `BGAppRefreshTask` background polling. This is an accepted, documented limitation, not a gap.
- **Firebase iOS `GoogleService-Info.plist`** — still doesn't exist (no iOS Firebase app
  registered). `AnalyticsTrackerImpl` (Phase 7, `os.Logger`-backed) is the swap-in-ready seam;
  real Firebase Analytics is a single new file + one `AppContainer` line once credentials exist.
- ~~Whether a shared design spec exists~~ — **resolved: pixel-matched from the Compose source**
  throughout, including real converted assets where available (app icon, onboarding artwork,
  Lottie animation) and SF Symbol stand-ins clearly documented where not (drawer/social icons).

---

## 9. Testing & parity strategy
- Port `InboxViewModelTest` and add unit tests for `UsernameValidator`, expiry math, decryption,
  and time-offset sync.
- Snapshot/manual parity pass per screen against the Android build (light + dark, each locale).
- Verify expiry timings (10 min / 5 min / 24h) and subscriber overrides.
- Verify analytics events fire with the same names/params.
```
