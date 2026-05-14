# 🎸 Guitar Pro - Flutter App

A realistic guitar app with full functionality built with Flutter.

## Features

- **Realistic Guitar Neck** — 12 visible frets, scrollable to fret 24
- **6 Strings** — Visual thickness and color like real strings (wound + plain)
- **Sound Hole** — Animated strum area on the guitar body
- **Chord Library** — 10 common chords (Em, Am, C, G, D, E, A, F, Dm, B7)
  - Mini chord diagrams
  - Up/Down strum buttons
  - Auto-highlights frets on the neck
- **Scale Explorer** — 6 scales (Major, Minor, Pentatonic, Blues, Dorian)
  - Highlights scale notes on the neck in green
  - Shows interval names
- **Tuner** — Visual needle tuner with 6-string selector (simulated; real needs mic)
- **Capo Support** — Set capo from 0–7 (visual capo drawn on neck)
- **Multiple Tunings** — Standard, Drop D, Open G, Open D, DADGAD
- **Recording** — Tap Rec to record your playing, Play to replay
- **Volume Control** — Slider + mute button
- **Settings** — Fret numbers, note names, left-handed mode, vibration
- **Haptic Feedback** — Vibration on note/strum

## Screenshots (Landscape Mode)
```
[Guitar Body] ←→ [Guitar Neck - 12 frets] ←→ [Controls]
  Sound hole        Strings + frets             Chords
  Strum area        Inlay dots                  Scales
  Volume            Note highlights             Tuner
  Record            Capo indicator              Settings
```

## Setup

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code with Flutter plugin

### Install

```bash
# Clone or unzip the project
cd guitar_app

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run
```

### For best experience, run on:
- Android device/emulator (landscape mode)
- iOS device/simulator (landscape mode)

### Build APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build for iOS
```bash
flutter build ios --release
```

## Audio

This app uses `audioplayers` package. For real guitar sounds:

1. Download guitar note samples (MP3) from freesound.org or similar
2. Name them: `note_40.mp3`, `note_41.mp3`, ... `note_88.mp3` (MIDI numbers)
3. Place in `assets/sounds/`
4. The AudioService will auto-load them

Without audio files, the app will run silently (tap still shows visual feedback).

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| audioplayers | ^5.2.1 | Guitar sound playback |
| provider | ^6.1.1 | State management |
| shared_preferences | ^2.2.2 | Save settings |
| vibration | ^1.8.4 | Haptic feedback |
| wakelock_plus | ^1.1.4 | Keep screen on while playing |

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── guitar_models.dart       # Strings, chords, scales, tunings
├── providers/
│   └── guitar_provider.dart     # State management
├── screens/
│   └── guitar_screen.dart       # Main screen
├── services/
│   └── audio_service.dart       # Audio playback
└── widgets/
    ├── guitar_body_widget.dart   # Guitar body + sound hole
    ├── guitar_neck_widget.dart   # Neck with frets + strings
    ├── control_panel_widget.dart # Right side buttons
    ├── chord_panel_widget.dart   # Chord library
    ├── scale_panel_widget.dart   # Scale explorer
    ├── tuner_widget.dart         # Chromatic tuner
    └── settings_panel_widget.dart# App settings
```

## License
MIT — Free to use and modify
