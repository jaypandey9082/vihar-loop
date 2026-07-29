# ViharLoop

ViharLoop is an offline-first neighbourhood board for Vidyavihar where
students and residents can discover and post small, time-sensitive needs or
offers without sharing an exact address.

> Need nearby. Offer nearby. Today.

## Current status

This repository contains the Section 3 persistent-listing-interactions slice.
The feed and listing details load through `LocalListingRepository` from an
encrypted Hive CE box. People can save a listing and privately mark it
contacted; successful changes update details and the feed immediately and
survive relaunch. A random 32-byte database key is stored separately through
FlutterSecureStorage, using Android Keystore and iOS Keychain on their
respective platforms.

- Primary demo platform: Android
- Secondary supported shell: iOS
- Framework: Flutter with Material 3
- Product version: `0.3.0+3`
- Current data: nine fictional listings seeded only when seed version 1 is absent
- Persistence: complete versioned records in encrypted Hive CE
- Key storage: FlutterSecureStorage, with no key in source or the Hive box
- UI scope: feed, details, private Saved/Contacted markers, and owner-controlled
  Close/Reopen

Saved and Contacted are local device markers. Mark Contacted does not send a
message. Close/Reopen is available only for records whose origin is `local`;
the repository enforces that rule rather than relying on a hidden button.
Production seeds remain `sample` origin, so Close first becomes visible in the
live product after Section 4 adds creation of a real local listing.

Direct storage dependencies resolve to `hive_ce 2.19.3`,
`hive_ce_flutter 2.3.4`, and `flutter_secure_storage 10.3.1`.
Section 3 added or upgraded no dependency.

## Requirements

- A stable Flutter SDK compatible with Dart 3.3 or later
- Android Studio or Android SDK command-line tools for Android builds
- Xcode on macOS for the optional iOS shell
- An Android emulator/device or iOS simulator/device to run the app

The project does not upgrade Flutter or alter SDK versions during setup. No
model, backend, account, environment file, or network connection is required.

## Setup and run

```sh
flutter pub get
flutter run
```

Useful quality commands:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

## Structure

```text
lib/
  app/                  Material app and cohesive theme
  data/                 Repository boundary, local implementation, seeds
  data/local/           Encrypted Hive store and versioned record codec
  domain/               Listing and neighbourhood model
  features/feed/        Feed view, view model, and listing card
  features/listing_details/
                        Details view and mutation view model
  security/             Secure-storage encryption-key lifecycle
test/                   Codec, key, store, repository, UI, semantics tests
docs/                   Product, metrics, accessibility, security, AI, demo
docs/adr/               Architecture decision record
```

`main.dart` constructs the secure key store, encrypted listing store, and local
repository, then injects the repository into the app. Views do not import Hive,
secure storage, or seed data.

## Documents

- [Product slice](docs/product-slice.md)
- [Success metrics](docs/success-metrics.md)
- [Accessibility check](docs/accessibility-check.md)
- [Security baseline](docs/security-baseline.md)
- [Local storage note](docs/local-storage-note.md)
- [Local AI note](docs/local-ai-note.md)
- [Demo script](docs/demo-script.md)
- [Homework checklist](docs/homework-checklist.md)
- [ADR 0001: local-first marketplace slice](docs/adr/0001-local-first-marketplace-slice.md)

## Intended three-minute workflow

The final product demo is planned to run in airplane mode: open the Vidyavihar
feed, find an urgent post, inspect its details, save or mark it contacted,
create a new listing with editable on-device Draft Assist, relaunch to prove
local persistence, and close the listing. Section 3 demonstrates the feed and
details, encrypted persistence, immediate Saved/Contacted coordination, and
repository-enforced owner-only status changes.

Deleting ViharLoop or clearing its app data removes both the local encryption
key and listings. Android backup and device transfer are intentionally
disabled for this local-only slice.

## Known gaps

Section 3 does not yet include:

- Create listing
- A real local-origin listing visible in production
- User-facing local-data reset
- Full privacy validation
- Today Loop or Ending Soon filters
- A deterministic AI fallback
- Gemma or another local model
- Final accessibility verification, including manual TalkBack
- Full iOS runtime and Keychain verification

The Android and iOS project shells retain the
`com.jaypandey.viharloop` identifiers. Android is the verified primary
platform. The iOS Keychain entitlement source configuration is present, but a
runtime check remains pending because full Xcode is unavailable.
