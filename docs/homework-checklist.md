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
| Accessible controls | Section 5 | Feed/create/details widgets | Done | Official label/tap-target guidelines, semantic actions, traversal, keyboard, and representative API 36 TalkBack checks pass |
| Screen-reader cards | Section 5 | `lib/features/feed/listing_card.dart` | Done | Exposed node owns the tap action; semantic activation and TalkBack-enabled API 36 navigation open the correct listing |
| Visible form errors | Section 4–5 | Create form | Done | Visible errors, invalid deadline semantics, and six first-invalid focus cases pass |
| Tap targets | Section 5 | Critical feed/create/details states | Done | Official Flutter Android tap-target guideline passes; iOS guideline passes as automated source-level evidence |
| Text scaling | Section 5 | `test/accessibility/accessibility_guidelines_test.dart` | Done | 200% portrait/landscape tests and API 36 font-scale 1.3/density 560 pass |
| Focus order | Section 5 | `test/accessibility/accessibility_traversal_test.dart` | Done | Simulated traversal and keyboard forward/backward activation checks pass; representative TalkBack focus observed |
| Contrast | Section 5 | `test/accessibility/accessibility_guidelines_test.dart` | Done | Official Flutter contrast guideline passes tested light and dark states; Scanner unavailable |
| Manual TalkBack | Section 5 | `docs/accessibility-check.md` | Implemented, verification pending | Representative API 36 flow and Save speech observed; complete create/picker/progress/dialog script remains blocked by reliable remote gesture control |
| VoiceOver | Later | iOS runtime | Blocked | Full Xcode is unavailable |
| No committed secret | Section 1 onward | `.gitignore`, repository scan | Done | No secret or environment file added |
| No exact address | Section 1 onward; hardened Section 6 | Domain choices, `ListingPrivacyValidator`, form, repository | Done | Broad-area-only field plus precise-location heuristics, repository revalidation, matrix tests, and synthetic API 36 rejection pass; heuristic limitation remains |
| Input validation | Section 4 and 6 | Create form, validators, and repository | Done | Structural, direct-contact/payment, and precise-location checks use one shared boundary in UI and repository |
| Local data reset | Section 6 | Privacy route, repository, encrypted store, targeted key store | Done | UI and failure tests, real encrypted fresh-key lifecycle, nine-sample reseed, error-state recovery, and reopen proof pass |
| Encrypted local persistence | Section 2 | `lib/data/local/encrypted_hive_listing_store.dart` | Done | Real temporary-Hive encryption and reopen tests pass |
| Versioned record codec | Section 2 | `lib/data/local/listing_record_codec.dart` | Done | Full-field mapping and invalid-record tests pass |
| Secure encryption-key location | Section 2 | `lib/security/flutter_secure_encryption_key_store.dart` | Done | 32-byte Base64 lifecycle tested without MethodChannel |
| Android backup policy | Section 2 | Android manifest and `res/xml` rules | Done | Backup and transfer exclusions pass XML validation |
| iOS Keychain source configuration | Section 2 | Runner entitlements and Xcode project | Implemented, verification pending | Source plists validate; runtime requires full Xcode |
| Seed relaunch persistence | Section 2 | Encrypted store persistence test | Done | Nine records and clock-A timestamps survive close/reopen |
| Android force-stop persistence | Section 2 | API 36 emulator | Done | Nine records and the noted 4:47 AM deadline survived force-stop/relaunch; details reopened |
| Local storage documentation | Section 2 | `docs/local-storage-note.md` | Done | Names, versions, failures, backup, and limits documented |
| Local AI helper | Section 7 | Draft Assist UI and view model | Done | Preview, dismiss, explicit application, editability, failure, automated workflow, and API 36 airplane-mode flow pass |
| `LocalAiService` boundary | Section 7 | `lib/local_ai/` and constructor injection | Done | UI depends on the interface; production fallback is injected from `main.dart` |
| Deterministic fallback | Section 7 | `RuleBasedListingAssistant` | Done | 18 required evaluation cases, 15 invalid classes, and 10/10 determinism pass |
| Local model or fallback expected flow | Section 7–8 | Draft Assist workflow | Done using fallback | Expected guitar-capo flow works through fallback in tests and on API 36 with airplane mode; actual local model remains Planned for Section 8 |
| Editable Draft Assist output | Section 7 | Create preview and form | Done | Apply changes only Type, Title, Category; values remain editable and Post remains explicit |
| No hosted AI key | Section 7 | Production/repository audit | Done | No hosted client, secret, network, permission, model, or dependency added |
| AI privacy validation | Section 7 | Shared validators | Done | Description input and suggested Title output reuse `ListingDraftValidator`; API 36 rejects a precise-location draft without preview |
| Gemma | Section 8 | Future `LocalAiService` provider | Planned | No model path or inference is claimed in Section 7 |
| Repository/data-source boundary | Section 1–3 | `lib/data/listing_repository.dart`, `lib/data/local/` | Done | UI uses explicit product operations and has no Hive imports |
| ADR | Section 1–2 | `docs/adr/0001-local-first-marketplace-slice.md` | Done | Accepted storage decision and trade-offs recorded |
| Product document | Section 1 | `docs/product-slice.md` | Done | Target, boundary, workflow, scope recorded |
| Metrics document | Section 1–2 | `docs/success-metrics.md` | Done | Technical persistence proof stays separate from product targets |
| Accessibility document | Section 1 | `docs/accessibility-check.md` | Done | Automated and manual states distinguished |
| Release permissions | Section 6 | Release APK/merged manifest audit | Done | `apkanalyzer`/`aapt` show no product INTERNET or unnecessary sensitive permission; exported components reviewed |
| Logging/plaintext audit | Section 6 | Production scan, logcat/raw-Hive checks | Done | No production logging boundary; automated ciphertext/canary reset regressions pass; dynamic evidence limits documented |
| Security document | Section 1–6 | `docs/security-baseline.md` | Done | Data inventory, decisions, validation, reset, release, leakage, supply-chain, and residual-risk evidence current |
| Local-AI document | Section 7 | `docs/local-ai-note.md` | Done | Current fallback boundary, algorithm, validation, evidence, and Section 8 point documented |
| README | Section 1–7 | `README.md` | Done | Section 7 behaviour, offline boundary, and honest model gaps included |
| Three-minute demo | Section 7 draft | `docs/demo-script.md` | Implemented, verification pending | Draft Assist fallback steps are included; two timed human runs remain pending |
| Fresh checkout | Section 7 gate | README commands and a clean clone | Done | Isolated committed-history clone passes setup, analysis, 311 tests, 39 accessibility tests, and Android debug/release builds |
| Clean repository | Section 6 gate | `.gitignore`, `git status`, `git diff --check` | Done | Staged-file, generated-data, local-path, dependency, and secret-pattern audits pass |

## Current verification snapshot

Flutter 3.44.8 and Dart 3.12.2 are installed. Section 7 formatting, analysis,
311 unit/widget tests, the 39-test accessibility subset, and Android
debug/release builds pass. Official guidelines report no failures in tested
target, label, contrast, and scaled layout states.

Android XML and iOS source plists validate. Full Xcode, VoiceOver, Accessibility
Scanner, and completion of the full TalkBack script remain pending.
Draft Assist, `LocalAiService`, and deterministic fallback are implemented.
Actual Gemma, the complete human-driven TalkBack flow, VoiceOver, full iOS
runtime, and remaining later-section work are not claimed finished.
