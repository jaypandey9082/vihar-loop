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
| Create listing | Later | Create feature | Planned | Not present in Section 2 |
| Title | Section 1 model; later create | `lib/domain/listing.dart` | Done | Immutable field and sample content present |
| Category | Section 1 model; later create | `lib/domain/listing.dart` | Done | Approved enum and user-facing labels present |
| Description | Section 1 model; later create | `lib/domain/listing.dart` | Done | Full description shown on details |
| Approximate area | Section 1 | `lib/domain/listing.dart`, feed/details | Done | Four broad Vidyavihar choices; no exact address |
| Contact preference | Section 1 | `lib/domain/listing.dart`, details | Done | Natural user-facing wording present |
| Details | Section 1 | `lib/features/listing_details/listing_details_screen.dart` | Done | Navigation and details widget test passes |
| Saved | Later | Repository mutation and UI action | Planned | Flag modeled; no mutation or visible control |
| Contacted | Later | Repository mutation and UI action | Planned | Flag modeled; no mutation or visible control |
| Closed | Later mutation; Section 1 display | Domain/repository and future UI action | Planned | Closed sample is readable; closing behaviour absent |
| Personal feature: Today Loop | Later | Feed filters using `activeUntil` | Planned | Time field and wording modeled only |
| Accessible controls | Section 1 baseline; final verification later | Feed/details widgets | Implemented, verification pending | Standard Material controls used; manual device pass pending |
| Screen-reader cards | Section 1 | `lib/features/feed/listing_card.dart` | Implemented, verification pending | Semantics test passes; manual TalkBack run pending |
| Visible form errors | Later | Create form | Planned | No form in Section 2 |
| Tap targets | Section 1 baseline; final verification later | Listing card and Retry button | Implemented, verification pending | Padded card and 48dp button minimum; manual check pending |
| Text scaling | Section 1 baseline; final verification later | `test/features/feed/feed_screen_test.dart` | Done | Approximately 200% layout test passes |
| No committed secret | Section 1 onward | `.gitignore`, repository scan | Done | No secret or environment file added |
| No exact address | Section 1 onward | Domain choices and sample data | Done | Only approved broad areas used |
| Input validation | Later | Create form and repository | Planned | No user input in Section 2 |
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
| Repository/data-source boundary | Section 1–2 | `lib/data/listing_repository.dart`, `lib/data/local/` | Done | UI retains one narrow read operation and no Hive imports |
| ADR | Section 1–2 | `docs/adr/0001-local-first-marketplace-slice.md` | Done | Accepted storage decision and trade-offs recorded |
| Product document | Section 1 | `docs/product-slice.md` | Done | Target, boundary, workflow, scope recorded |
| Metrics document | Section 1–2 | `docs/success-metrics.md` | Done | Technical persistence proof stays separate from product targets |
| Accessibility document | Section 1 | `docs/accessibility-check.md` | Done | Automated and manual states distinguished |
| Security document | Section 1–2 | `docs/security-baseline.md` | Done | Implemented key, encryption, backup, and failure decisions addressed |
| Local-AI document | Section 1 | `docs/local-ai-note.md` | Done | Clearly marked not implemented |
| README | Section 1–2 | `README.md` | Done | Section 2 setup, storage, structure, warning, and gaps included |
| Three-minute demo | Draft in Section 1; final later | `docs/demo-script.md` | Planned | Section 2 persistence demo exists; full flow remains unimplemented |
| Fresh checkout | Section 2 gate | README commands and a clean copy | Done | Committed-history clone passes setup, analysis, 44 tests, and Android debug build |
| Clean repository | Section 2 gate | `.gitignore`, `git status`, `git diff --check` | Done | Staged-file, generated-data, local-path, and secret-pattern audits pass |

## Current verification snapshot

Flutter 3.44.8 and Dart 3.12.2 are installed. Section 1 baseline checks passed
before persistence work. Section 2 formatting is unchanged, analysis reports
no issues, all 44 tests pass, and Android debug builds pass in both the
workspace and a clean committed-history clone. API 36 clear-data,
force-stop/relaunch, nine-record, stable-deadline, and details checks pass.
Android XML and iOS source plists validate. Full Xcode and manual TalkBack
verification remain separate environment/manual checks.
