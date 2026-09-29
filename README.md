# Shuffle Master

Shuffle Master is a cross-platform Flutter app for exploring a standard 52-card deck, visualizing perfect Faro shuffles, emulating six-bit shuffle sequences, testing card-position predictions, and playing five-hand Black Jack from Faro-ordered decks.

## Features

- Browse a complete 52-card deck grouped by suit.
- Step through in-Faro and out-Faro shuffles with animated card movement.
- Run shuffles automatically at one-second intervals or advance them manually, and stop automatically when the cycle completes.
- Follow narrated cycle messages, including the in-Faro halfway point where the deck appears most random before snapping back into order.
- Track the 8-step out-Faro and 52-step in-Faro cycles, then reset the deck to its original order.
- Convert values from 0 to 51 into six-bit in-Faro and out-Faro sequences, see which places are ignored, and emulate each processed step.
- Choose Out, In, or Binary in the Faro Challenge, predict positions 1 through 52, then flip individual cards to check the result.
- Apply an In, Out, or Binary deck order before playing five hands of Black Jack against an automatic dealer.
- Continue Black Jack rounds while at least 12 cards remain and restore the current game after restarting the app.
- Select from 10 card-back designs and retain the selection between sessions.
- Use responsive layouts across Android, iOS, web, Windows, macOS, and Linux.
- Scroll the tab bar horizontally on narrow windows or with large text scaling when all nine tabs do not fit.
- Contact the developer with app diagnostics and view app-filtered inquiries from the Information tab.

## App Tabs

- **Card Backs:** Select the design used by face-down cards.
- **Card Deck:** Browse all 52 cards grouped by suit.
- **Out-Faro Shuffle:** Step through or automatically run the 8-shuffle cycle while the original top card stays on top.
- **In-Faro Shuffle:** Step through or automatically run the 52-shuffle cycle while the lower half leads each interlace, with cycle narration from separation through the halfway point to the final snap back.
- **Binary Shuffle:** Enter `0` to `51` and emulate a six-bit sequence where each processed `0` means out-Faro and `1` means in-Faro; higher unused places are ignored.
- **Faro Challenge:** Configure Out (`1-8`), In (`1-52`), or Binary shuffles and reveal numbered positions to verify a prediction.
- **Black Jack:** Configure In (`1-52`), Out (`1-8`), or Binary (`1-51`), deal five player hands, and play each in turn with Hit or Stand. The dealer hits on 17 or less after all players finish.
- **Information:** Two sub-tabs, **Contact** and **Inquiries**. Contact sends your name, email, question, and the displayed app diagnostics to the developer. Inquiries lists app-filtered submission details without names or email addresses. Both require an internet connection.
- **Help:** Read in-app guidance for every feature.

Tabs appear in the order above. The bar becomes horizontally scrollable when the widest label and active text scaling would overflow the available width, so every tab stays reachable.

## Shuffle Behavior

- An **out-Faro** perfectly interlaces equal deck halves while keeping the original top and bottom cards in place. A 52-card deck returns to its starting order after 8 out-shuffles.
- An **in-Faro** starts the interlace with the lower half, moving the original top card to position 2. A 52-card deck returns to its starting order after 52 in-shuffles.
- Both shuffle tabs keep a shuffle counter that returns to `0` as soon as the deck regains its initial order, and they describe the notable stages of each cycle instead of only showing the raw count.
- A **binary shuffle** processes six place values (`32`, `16`, `8`, `4`, `2`, `1`). Set bits apply in-Faro shuffles, clear processed bits apply out-Faro shuffles, and places above the selected value are ignored. Value `0` leaves the deck unchanged.

## Black Jack Rules

Black Jack uses one ordered 52-card deck and deals two cards round-robin to five players and the dealer. A player turn ends on Stand, a bust, or 21. Once all players finish, the dealer hits while its best total is 17 or less, except when every player has busted, and then each non-busted hand is marked Win, Lose, or Push.

The active deck, hands, turn, results, and shuffle settings are kept in local app storage. **Continue** deals another 12-card round from the remaining deck. **Shuffle** rebuilds the selected Faro order and clears the current round. When fewer than 12 cards remain, the app asks for a new shuffle.

## Card Backs

Ten designs ship with the app: Crimson Lattice, Midnight Star, Emerald Crown, Black Diamond, Royal Sun, Violet Constellation, Ocean Chevron, Burgundy Orbit, Silver Mosaic, and Teal Current. The selection is stored by name in local preferences, so it survives restarts and upgrades, and it drives the face-down cards in the Faro Challenge and Black Jack tables.

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) with Dart SDK 3.13.2 or later
- Platform tooling for each intended build target

## Getting Started

Install dependencies:

```powershell
flutter pub get
```

Run the app on an available device:

```powershell
flutter run
```

List connected devices when selecting a specific target:

```powershell
flutter devices
flutter run -d <device-id>
```

## Quality Checks

Run static analysis and tests before creating a release:

```powershell
flutter analyze
flutter test
```

## Release Builds

Standard Flutter release commands:

```powershell
flutter build apk --release
flutter build appbundle --release
flutter build web --release
flutter build windows --release
```

PowerShell helpers are also available for versioned Android and Windows builds:

```powershell
./scripts/build-release.ps1 -Target apk
./scripts/build-release.ps1 -Target appbundle
./scripts/build-release.ps1 -Target msix
```

For an Android APK build that first clears common locked build outputs:

```powershell
./scripts/build-apk-release.ps1 -KillFlutterProcesses
```

The app version is defined in `pubspec.yaml` using Flutter's `major.minor.patch+build` format.

## Store Listing

Google Play descriptions are maintained in:

- `store_listing/google_play_short_synopsis.txt`
- `store_listing/google_play_long_synopsis.txt`

## Project Layout

- `lib/main.dart` is the application entry point.
- `lib/app/` contains startup state, splash presentation, and tab composition.
- `lib/features/card_backs/` contains the card-back selection experience.
- `lib/features/deck/` contains the standard deck reference view.
- `lib/features/faro/` contains the animated Faro shuffles and prediction challenge.
- `lib/features/binary_shuffle/` contains binary Faro sequence emulation.
- `lib/features/black_jack/` contains the ordered-deck Black Jack table.
- `lib/features/help/` contains in-app guidance.
- `lib/shared/` contains shared card models, Faro logic, and presentation widgets.
- `lib/features/information/` contains the top-level Information tab.
- `lib/contact/` contains the reusable contact form and inquiry views.
- `test/app/` covers tab composition and overflow behavior.
- `test/features/` covers the Faro Challenge and Black Jack flows.
- `test/shared/` contains focused tests for shared domain behavior.
- `scripts/` contains maintenance, versioning, and release helpers.
- `tool/` contains additional release automation.
- `store_listing/` contains publishing copy for the app stores.
