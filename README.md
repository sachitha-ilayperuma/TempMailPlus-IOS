# TempMailPlus — iOS

Native iOS (SwiftUI) port of the TempMailPlus Android app. See
[`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md) for the full phased plan and the
Android→iOS mapping, and [`PROGRESS.md`](PROGRESS.md) for the detailed per-phase log.

## Requirements
- Xcode 16+ (developed on Xcode 26.5)
- iOS 16.0+ deployment target
- Swift Package Manager dependencies (resolved automatically on first build):
  Google Mobile Ads, Google User Messaging Platform (UMP), lottie-ios.

## Build & run

Open in Xcode:
```
open TempMailPlus.xcodeproj
```

Or from the command line:
```bash
xcodebuild -project TempMailPlus.xcodeproj -scheme TempMailPlus \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

Run tests:
```bash
xcodebuild -project TempMailPlus.xcodeproj -scheme TempMailPlus \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO test
```

To test real StoreKit purchases against the local product catalog (`TempMailPlus.storekit`), run
via Xcode's own Run/Test (not `xcodebuild` — StoreKit Configuration files are an Xcode-GUI-only
mechanism; see PROGRESS.md Phase 6).

The Xcode project uses **file-system-synchronized groups** (Xcode 16+), so new files added
under `TempMailPlus/` are picked up automatically — no `.pbxproj` edits needed.

## Project layout
```
TempMailPlus/
├── App/            # @main entry, AppContainer (DI root), Info.plist
├── Core/           # Constants, extensions, TimeProvider, link/UIKit bridges
├── Data/           # DataStore, Remote (REST+WebSocket), DTO, Repositories, Ads,
│                   # Billing (StoreKit 2), Analytics, Notifications, Security
├── Domain/         # Models, repository protocols, use cases, validation, analytics
├── Presentation/
│   ├── Theme/      # AppColors, AppTypography, ThemeManager (ported from Compose)
│   ├── Components/ # Shared UI pieces (sheets, HTML view, feature list, …)
│   ├── ViewModels/ # HomeViewModel, CustomEmailViewModel, SubscriptionViewModel, …
│   └── Screens/    # Home, Inbox, Email detail, Custom Email, Subscription, FAQ,
│                   # Onboarding, Main scaffold + drawer
└── Resources/      # Fonts, Lottie JSON, onboarding artwork, app icon, 7-locale
                    # Localizable.strings, TempMailPlus.storekit
```

## Status

**All 8 planned phases are complete** — see [`PROGRESS.md`](PROGRESS.md) for the full log,
including what's genuinely verified (real backend calls, real OS dialogs, real converted
assets) vs. what's deliberately deferred (real production credentials for AdMob/App Store
Connect/Firebase, ironSource mediation, a dedicated iPad layout, exhaustive accessibility
audit, and interactive tap-through verification of a few flows — see PROGRESS.md's
consolidated manual verification checklist at the end of Phase 8).

The app builds clean (Debug + Release, zero warnings) and passes 48 automated tests. Every
phase's real backend/system integrations have been verified via actual launches: live email
generation, live WebSocket delivery, the real UMP consent dialog, the real StoreKit product
catalog, the real notification permission prompt, and the real app icon.
