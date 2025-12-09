# Kanakku – Student Finance Tracker

Kanakku is a minimalist, offline-first Flutter app for tracking shared expenses and recurring subscriptions with friends.

## Core features
- Friend ledger: home screen lists all friends with a single net balance (green if they owe you, red if you owe them).
- Detailed history: per-friend timeline with required reasons for every entry and a Settle Up shortcut.
- Transaction types: I Paid (they owe you), I Borrowed (you owe them), Partial Payment (reduces the outstanding balance), Auto Subscription.
- Smart subscriptions: define a plan (name, amount per member, members). On a new month, the app automatically posts charges for every member.
- Offline + local: data is stored locally with Hive; no cloud or network needed after install.

## Running
```bash
flutter pub get
flutter run
```

## Tests
```bash
flutter test
```
