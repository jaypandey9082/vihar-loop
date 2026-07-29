# ViharLoop

ViharLoop is an offline-first neighbourhood board for Vidyavihar where
students and residents can discover and post small, time-sensitive needs or
offers without sharing an exact address.

> Need nearby. Offer nearby. Today.

## Current status

This repository contains the Section 5 accessibility-hardened core flow.
The feed, creation form, and listing details use `LocalListingRepository` with
an encrypted Hive CE box. People can create a need or offer, find it with
Today or Ending Soon filters, save it, privately mark it contacted, and
close/reopen their own post. Persisted changes update the feed immediately and
survive relaunch. A random 32-byte database key is stored separately through
FlutterSecureStorage.

- Primary demo platform: Android
- Secondary supported shell: iOS
- Framework: Flutter with Material 3
- Product version: `0.5.0+5`
- Current data: nine fictional listings seeded only when seed version 1 is absent
- Persistence: complete versioned records in encrypted Hive CE
- Key storage: FlutterSecureStorage, with no key in source or the Hive box
- UI scope: feed filters, creation, details, private Saved/Contacted markers,
  and owner-controlled Close/Reopen

Saved and Contacted are local device markers. Mark Contacted does not send a
message. Close/Reopen is available only for records whose origin is `local`;
the repository enforces that rule. Created records use local origin, while all
production seeds remain sample origin.

Create requires Need/Offer, a 5–80 character one-line title, a 15–500
character description, category, approximate broad area, contact preference,
and a deadline from 15 minutes through seven days ahead. Obvious phone, email,
and URL content is rejected in both the form and repository. Unsubmitted
drafts are not saved. A successful create writes one complete encrypted record
with protected ID, ownership, status, timestamp, and marker fields supplied by
the repository.

Today means open, not past, and on the same local calendar date. Ending Soon
means open, strictly after the current time, and no more than three hours away.
Need/Offer and time filters combine.

Direct storage dependencies resolve to `hive_ce 2.19.3`,
`hive_ce_flutter 2.3.4`, and `flutter_secure_storage 10.3.1`.
Section 5 added or upgraded no dependency and left `pubspec.lock` unchanged.

Section 5 keeps product and persistence behaviour unchanged while adding
deliberate heading structure, executable listing-card semantics, first-invalid
form focus, one coherent keyboard-accessible deadline control, and adaptive
Need/Offer layout. Official Flutter guideline tests cover Android and iOS tap
targets, labels, and light/dark text contrast. Dedicated tests also exercise
semantic actions, traversal order, keyboard input, validation focus, and
representative 200% text layouts.

Android TalkBack 16.0 on the existing API 36 emulator exposed feed and details
focus, opened a listing, and announced the Save success message. The same AVD
was checked at `font_scale 1.3` and density `560`; the create segmented control
adapted vertically without a crash or overflow. Reliable remote TalkBack
multi-gesture control was not available for the complete create, picker,
progress, and close-dialog walkthrough, so those manual items remain pending
even though their automated semantics and keyboard checks pass. Google
Accessibility Scanner was not installed on the AVD; no unofficial APK was
sideloaded.

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
  core/                 Shared production clock boundary
  domain/               Listing, draft validation, and timing rules
  features/create_listing/
                        Create form and submission view model
  features/feed/        Feed view, view model, and listing card
  features/listing_details/
                        Details view and mutation view model
  security/             Secure-storage encryption-key lifecycle
test/                   Codec, key, store, repository, UI, semantics tests
docs/                   Product, metrics, accessibility, security, AI, demo
docs/adr/               Architecture decision record
```

`main.dart` constructs one shared clock, the secure key store, encrypted
listing store, and local repository, then injects the boundaries into the app.
Views do not import Hive, secure storage, or seed data.

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

The current core demo runs in airplane mode: open the Vidyavihar feed, create
a listing, find it under Ending Soon, inspect it, close it, relaunch to prove
encrypted persistence, reopen it, and relaunch again. Saved and Contacted
remain available as private local markers. Android creation, close/reopen, and
force-stop/relaunch were manually checked in the Section 4 verification pass.
Section 5 adds the automated and partial TalkBack evidence described above.
Draft Assist remains planned and is not part of this working loop.

Deleting ViharLoop or clearing its app data removes both the local encryption
key and listings. Android backup and device transfer are intentionally
disabled for this local-only slice.

## Known gaps

The current slice does not yet include:

- User-facing local-data reset
- Broader exact-address and privacy hardening
- A deterministic AI fallback
- Gemma or another local model
- Completion of the full manual TalkBack create/picker/progress/dialog pass
- Manual VoiceOver verification
- Full iOS runtime and Keychain verification
- Editing or deleting one listing
- Draft persistence

The Android and iOS project shells retain the
`com.jaypandey.viharloop` identifiers. Android is the verified primary
platform. The iOS Keychain entitlement source configuration is present, but a
runtime check remains pending because full Xcode is unavailable.
