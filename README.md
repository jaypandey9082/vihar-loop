# ViharLoop

ViharLoop is an offline-first neighbourhood board for Vidyavihar where
students and residents can discover and post small, time-sensitive needs or
offers without sharing an exact address.

> Need nearby. Offer nearby. Today.

## Current status

This repository contains the Section 1 walking skeleton: a read-only
Vidyavihar feed, listing details, an in-memory repository, initial
accessibility behaviour, focused tests, and the Mobile Architecture Lab
documentation set. Persistence and all listing mutations remain planned.

- Primary demo platform: Android
- Secondary supported shell: iOS
- Language: Dart
- Framework: Flutter with Material 3
- Product version: `0.1.0+1`
- Current data: realistic sample records from `InMemoryListingRepository`
- Planned Section 2 data: encrypted local storage behind `ListingRepository`

## Requirements

- A stable Flutter SDK compatible with Dart 3.3 or later
- Android Studio or Android SDK command-line tools for Android builds
- Xcode on macOS for the optional iOS shell
- An Android emulator/device or iOS simulator/device to run the app

The project does not upgrade Flutter or alter SDK versions during normal setup.

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
  data/                 Repository boundary, in-memory implementation, seeds
  domain/               Listing and neighbourhood model
  features/feed/        Feed view, view model, and listing card
  features/listing_details/
                        Read-only details view
test/                   Domain, repository, view-model, widget, semantics tests
docs/                   Product, metrics, accessibility, security, AI, demo
docs/adr/               Architecture decision record
```

`main.dart` constructs the temporary repository and injects it into the app.
Views do not import seed data or know how listing storage works.

## Documents

- [Product slice](docs/product-slice.md)
- [Success metrics](docs/success-metrics.md)
- [Accessibility check](docs/accessibility-check.md)
- [Security baseline](docs/security-baseline.md)
- [Local AI note](docs/local-ai-note.md)
- [Demo script](docs/demo-script.md)
- [Homework checklist](docs/homework-checklist.md)
- [ADR 0001: local-first marketplace slice](docs/adr/0001-local-first-marketplace-slice.md)

## Intended three-minute workflow

The final product demo will run in airplane mode: open the Vidyavihar feed,
find an urgent post, inspect its details, save or mark it contacted, create a
new listing with editable on-device Draft Assist, relaunch to prove local
persistence, and close the listing. Section 1 demonstrates only opening the
feed and reading listing details.

## Known gaps

Section 1 does not yet include:

- Persistent or encrypted storage
- Create listing
- Save, contacted, or closed updates
- Full privacy validation
- A deterministic AI fallback
- Gemma or any other local model
- Final accessibility verification, including manual TalkBack checks

The Android and iOS project shells are included with
`com.jaypandey.viharloop` identifiers. Automated formatting, analysis, and
widget tests pass on Flutter 3.44.8. The Android debug build and an API 36
emulator smoke test of the feed, details, and back route also pass. A clean
export containing only repository files passes setup, analysis, tests, and the
Android debug build.
