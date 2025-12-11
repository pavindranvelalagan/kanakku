# Kanakku — Shared Expenses & Subscriptions

Kanakku is a Flutter app for tracking what friends owe each other, including recurring subscriptions. It is offline-first (local Hive storage) and tuned for quick entry on mobile.

## Features
- Ledger by friend: single net balance per friend with drill-down history and settle-up shortcut.
- Transaction types: I Paid (they owe you), I Borrowed (you owe them), Partial Payment, and Auto Subscription entries.
- Subscriptions: plans can be paid by you or by a friend; monthly charges post automatically to the right party.
- Theming: light/dark support with cohesive typography and components.
- Offline: all data is stored locally via Hive; no network required after install.

## Architecture
- Flutter (Dart 3.8+) with Material 3 theming.
- Local persistence via Hive (`LedgerRepository`) and a `LedgerController` `ChangeNotifier` for UI reactivity.
- Screens: dashboard, friend detail, subscriptions, transactions list, and profile.
- UI kit: shared components (`PremiumCard`, nav bar, headers) to keep styling consistent.

## Getting started
Prerequisites:
- Flutter SDK 3.24+ (Dart 3.8+)
- Android Studio / Xcode toolchains for device targets

Setup & run:
```bash
flutter pub get
flutter run
```

## Testing
```bash
flutter test
```

## Data
- Stored locally with Hive boxes (`friends`, `transactions`, `subscriptions`, `settings`).
- No cloud sync. Back up by copying the app’s local storage if needed.

## Contributing
- Feel free to contribute to this repo if you have any sort of interest :)
- Open a PR with a clear description, screenshots for UI changes, and include test results.
- Just make sure to keep components theme-aware (light/dark) and prefer shared widgets/styles before adding new ones.

## License
Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0) License.

You are free to copy, redistribute, and adapt this work for any purpose, including commercial, provided you give appropriate credit. See the full text at https://creativecommons.org/licenses/by/4.0/.
