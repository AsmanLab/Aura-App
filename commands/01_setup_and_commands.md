# 01 · Setup & Commands

Everything you type into a terminal, in order. Tested against **Flutter 3.x (Dart 3)**.

---

## 0. Prerequisites

```bash
flutter --version          # expect Flutter 3.19+ / Dart 3.3+
flutter doctor             # resolve every ❌ before continuing
```

You need: Flutter SDK, Xcode (iOS), Android Studio + SDK (Android), CocoaPods (`sudo gem install cocoapods`).

---

## 1. Create the project

```bash
flutter create \
  --org com.aprd \
  --project-name aura \
  --platforms=ios,android \
  aura

cd aura
```

> `--org com.aprd` → bundle id `com.aprd.aura`. Change if APRD uses a different reverse domain.

Remove the demo counter app in `lib/main.dart` — Stage 0 replaces it with the app shell.

---

## 2. Dependencies

```bash
# State management
flutter pub add flutter_riverpod

# Routing (shell + nested tabs + pushed routes)
flutter pub add go_router

# Fonts (Manrope + Space Grotesk, pulled at build time)
flutter pub add google_fonts

# Persistence (theme + language + notification prefs)
flutter pub add shared_preferences

# Nice-to-haves
flutter pub add flutter_animate        # declarative entrance/heart animations (optional)
flutter pub add intl                    # number/date formatting (1,840 / Jun 3)
```

Dev dependencies:

```bash
flutter pub add --dev flutter_lints
flutter pub add --dev build_runner       # only if you adopt codegen (freezed/json)
```

Resulting `pubspec.yaml` dependency block (verify versions after `pub get`):

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:        # add this manually (see §4)
    sdk: flutter
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  google_fonts: ^6.2.0
  shared_preferences: ^2.2.0
  intl: ^0.19.0
  flutter_animate: ^4.5.0
```

---

## 3. Fonts

Two options — pick **A** (simplest) unless the app must work fully offline.

### A. `google_fonts` (recommended)
No asset files. In `app_typography.dart`:

```dart
import 'package:google_fonts/google_fonts.dart';

// Manrope for UI/body (full Cyrillic support)
GoogleFonts.manrope(...);
// Space Grotesk for numerals/Aura values
GoogleFonts.spaceGrotesk(...);
```

To avoid first‑run network fetch, pre‑bundle by enabling the runtime cache or vendor the files (option B).

### B. Bundled assets (offline‑safe)
Download Manrope (400–800) + Space Grotesk (400–700), drop into `assets/fonts/`, then in
`pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  fonts:
    - family: Manrope
      fonts:
        - asset: assets/fonts/Manrope-Regular.ttf
        - asset: assets/fonts/Manrope-Medium.ttf
          weight: 500
        - asset: assets/fonts/Manrope-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Manrope-Bold.ttf
          weight: 700
        - asset: assets/fonts/Manrope-ExtraBold.ttf
          weight: 800
    - family: SpaceGrotesk
      fonts:
        - asset: assets/fonts/SpaceGrotesk-Medium.ttf
          weight: 500
        - asset: assets/fonts/SpaceGrotesk-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/SpaceGrotesk-Bold.ttf
          weight: 700
```

> ⚠️ **Cyrillic:** Manrope ships Cyrillic — good for RU. Space Grotesk is **Latin/numerals only**;
> only ever use it for digits (Aura values, ranks, dates). Any Cyrillic text uses Manrope.

---

## 4. Localization (RU + EN)

```bash
flutter pub add intl:any
```

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter

flutter:
  generate: true
```

Create `l10n.yaml` at the project root:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

Then `lib/l10n/app_en.arb` and `lib/l10n/app_ru.arb` (see `06_screens.md` for the string keys).
Generated on `flutter gen-l10n` (auto‑runs on build when `generate: true`).

---

## 5. Everyday commands

```bash
flutter pub get                 # after editing pubspec
flutter gen-l10n                # regenerate localization (or just `flutter run`)
flutter run                     # run on the connected device/sim
flutter run -d ios              # force iOS simulator
flutter run -d emulator-5554    # force a specific Android emulator
flutter devices                 # list targets

flutter analyze                 # static analysis — keep this clean
dart format lib/                 # format
flutter test                    # unit/widget tests

# Hot reload: press r in the run console · Hot restart: R
```

---

## 6. Build artifacts

```bash
# Android
flutter build apk --release
flutter build appbundle --release        # for Play Store

# iOS
flutter build ipa --release               # requires signing set up in Xcode
open ios/Runner.xcworkspace               # configure signing & capabilities
```

---

## 7. Suggested git hygiene

```bash
git init
# .gitignore already created by `flutter create`; confirm it ignores:
#   /build/  .dart_tool/  .flutter-plugins  ios/Pods/  *.iml
git add .
git commit -m "Stage 0: project scaffold"
```

Tag each stage from `00_project_overview.md` as you complete it (`git tag stage-1-design-system`).
