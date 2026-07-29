# Homework traceability checklist

Statuses mean:

- **Done:** implemented with available repository evidence.
- **Implemented, verification pending:** code exists but the required SDK,
  device, or manual verification has not run.
- **Planned:** deliberately belongs to a later section.
- **Blocked:** cannot currently progress because a required external tool or
  decision is unavailable.

| Requirement | Planned section | Evidence file or future code area | Status | Verification note |
| --- | --- | --- | --- | --- |
| One neighbourhood feed | Section 1 | `lib/features/feed/feed_screen.dart` | Done | Feed widget test passes |
| Create listing | Section 4 | `lib/features/create_listing/`, repository, encrypted store | Done | UI, repository create, encrypted insert, widget tests, encrypted-reopen proof, and API 36 production flow pass |
| Title | Section 4 create input | Create form and `ListingDraftValidator` | Done | Visible 5–80 character one-line validation and boundary tests pass |
| Category | Section 4 create input | Create form and `ListingDraft` | Done | Approved choices persist through the repository |
| Description | Section 4 create input | Create form and `ListingDraftValidator` | Done | Visible 15–500 character validation and boundary tests pass |
| Approximate area | Section 4 create input | Create form and domain choices | Done | Four broad choices only; no exact-address field |
| Contact preference | Section 4 create input | Create form and domain choices | Done | Approved preferences persist; no phone/email field |
| Details | Section 1 | `lib/features/listing_details/listing_details_screen.dart` | Done | Navigation and details widget test passes |
| Saved | Section 3 | Repository, details view model/UI, encrypted store | Done | Unit, widget, encrypted-reopen, and API 36 force-stop checks pass |
| Contacted | Section 3 | Repository, details view model/UI, encrypted store | Done | Unit, widget, encrypted-reopen, and API 36 force-stop checks pass |
| Closed | Section 3 mutation; Section 4 production origin | Repository, details UI, encrypted persistence | Done | A production-created local record was closed, relaunched, reopened, and relaunched on API 36 |
| Personal feature: Today Loop | Section 4 | Domain timing helper, feed view model/UI | Done | Filter rules, combinations, badges, widget tests, and API 36 Ending Soon flow pass |
| Accessible controls | Section 1 baseline; final verification later | Feed/details widgets | Implemented, verification pending | Standard Material controls used; manual device pass pending |
| Screen-reader cards | Section 1 | `lib/features/feed/listing_card.dart` | Implemented, verification pending | Semantics test passes; manual TalkBack run pending |
| Visible form errors | Section 4 | Create form | Done | Required errors are visible and widget tested; incomplete API 36 form check passes |
| Tap targets | Section 1 baseline; final verification later | Listing card and Retry button | Implemented, verification pending | Padded card and 48dp button minimum; manual check pending |
| Text scaling | Section 1 baseline; final verification later | `test/features/feed/feed_screen_test.dart` | Done | Approximately 200% layout test passes |
| No committed secret | Section 1 onward | `.gitignore`, repository scan | Done | No secret or environment file added |
| No exact address | Section 1 onward | Domain choices and sample data | Done | Only approved broad areas used |
| Input validation | Section 4 | Create form, validator, and repository | Done | Structural and obvious phone/email/URL rejection pass; broader exact-address hardening remains Section 6 |
| Local data reset | Later | Persistent repository/settings | Planned | Persistence exists; no reset method or UI is implemented |
| Encrypted local persistence | Section 2 | `lib/data/local/encrypted_hive_listing_store.dart` | Done | Real temporary-Hive encryption and reopen tests pass |
| Versioned record codec | Section 2 | `lib/data/local/listing_record_codec.dart` | Done | Full-field mapping and invalid-record tests pass |
| Secure encryption-key location | Section 2 | `lib/security/flutter_secure_encryption_key_store.dart` | Done | 32-byte Base64 lifecycle tested without MethodChannel |
| Android backup policy | Section 2 | Android manifest and `res/xml` rules | Done | Backup and transfer exclusions pass XML validation |
| iOS Keychain source configuration | Section 2 | Runner entitlements and Xcode project | Implemented, verification pending | Source plists validate; runtime requires full Xcode |
| Seed relaunch persistence | Section 2 | Encrypted store persistence test | Done | Nine records and clock-A timestamps survive close/reopen |
| Android force-stop persistence | Section 2 | API 36 emulator | Done | Nine records and the noted 4:47 AM deadline survived force-stop/relaunch; details reopened |
| Local storage documentation | Section 2 | `docs/local-storage-note.md` | Done | Names, versions, failures, backup, and limits documented |
| Local AI helper | Later | Draft Assist | Planned | Documented only |
| `LocalAiService` boundary | Later | Local AI feature | Planned | Architecture recorded; no placeholder class |
| Deterministic fallback | Later | Local AI feature | Planned | Required behaviour documented |
| Local model or fallback expected flow | Later | Draft Assist integration tests | Planned | No model or fallback in Section 2 |
| Repository/data-source boundary | Section 1–3 | `lib/data/listing_repository.dart`, `lib/data/local/` | Done | UI uses explicit product operations and has no Hive imports |
| ADR | Section 1–2 | `docs/adr/0001-local-first-marketplace-slice.md` | Done | Accepted storage decision and trade-offs recorded |
| Product document | Section 1 | `docs/product-slice.md` | Done | Target, boundary, workflow, scope recorded |
| Metrics document | Section 1–2 | `docs/success-metrics.md` | Done | Technical persistence proof stays separate from product targets |
| Accessibility document | Section 1 | `docs/accessibility-check.md` | Done | Automated and manual states distinguished |
| Security document | Section 1–2 | `docs/security-baseline.md` | Done | Implemented key, encryption, backup, and failure decisions addressed |
| Local-AI document | Section 1 | `docs/local-ai-note.md` | Done | Clearly marked not implemented |
| README | Section 1–4 | `README.md` | Done | Section 4 creation, Today Loop, persistence, and honest gaps included |
| Three-minute demo | Draft in Section 1; final later | `docs/demo-script.md` | Implemented, verification pending | Non-AI Section 4 flow works; final demo still lacks Draft Assist |
| Fresh checkout | Section 2 gate | README commands and a clean copy | Done | Committed-history clone passes setup, analysis, 44 tests, and Android debug build |
| Clean repository | Section 2 gate | `.gitignore`, `git status`, `git diff --check` | Done | Staged-file, generated-data, local-path, and secret-pattern audits pass |

## Current verification snapshot

Flutter 3.44.8 and Dart 3.12.2 are installed. Section 4 formatting, analysis,
116 unit/widget tests, and Android debug build pass. Automated coverage proves
draft validation, time boundaries, duplicate-safe encrypted insertion, and
encrypted create/close/reopen persistence. API 36 verifies incomplete errors,
creation, Ending Soon discovery, close, reopen, and 3-out-of-3 relaunch
persistence.

Android XML and iOS source plists validate. Full Xcode and manual TalkBack
remain pending. User-facing reset, local AI, `LocalAiService`, deterministic
fallback, and Gemma remain Planned; the complete MAL homework is not claimed
finished.
