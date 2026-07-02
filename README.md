# TempMailPlus — iOS

Native iOS (SwiftUI) port of the TempMailPlus Android app. See
[`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md) for the full phased plan and the
Android→iOS mapping.

## Requirements
- Xcode 16+ (developed on Xcode 26.5)
- iOS 16.0+ deployment target
- No third-party dependencies yet — added per-phase via Swift Package Manager
  (Firebase, Google Mobile Ads, lottie-ios, …).

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

The Xcode project uses **file-system-synchronized groups** (Xcode 16+), so new files added
under `TempMailPlus/` are picked up automatically — no `.pbxproj` edits needed.

## Project layout
```
TempMailPlus/
├── App/            # @main entry, AppContainer (DI root), Info.plist
├── Core/           # Constants, shared utilities
├── Data/           # DataStore, Remote, DTO, Repositories, Ads, Billing (grows per phase)
├── Domain/         # Models, use cases, validation (added Phase 1+)
├── Presentation/
│   ├── Theme/      # AppColors, AppTypography, ThemeManager (ported from Compose)
│   └── Screens/    # RootShellView (Phase 0) → real screens replace it
└── Resources/      # Fonts (Raleway, Pacifico), Lottie JSON, Assets, *.lproj
```

## Status

Progress is tracked in [`PROGRESS.md`](PROGRESS.md) (per-phase log, decisions, follow-ups).
Currently: **Phase 0 done** — the app builds, launches, and renders the themed shell; Phase 1 next.
