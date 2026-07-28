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
| Create listing | Later | Create feature | Planned | Not present in Section 1 |
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
| Visible form errors | Later | Create form | Planned | No form in Section 1 |
| Tap targets | Section 1 baseline; final verification later | Listing card and Retry button | Implemented, verification pending | Padded card and 48dp button minimum; manual check pending |
| Text scaling | Section 1 baseline; final verification later | `test/features/feed/feed_screen_test.dart` | Done | Approximately 200% layout test passes |
| No committed secret | Section 1 onward | `.gitignore`, repository scan | Done | No secret or environment file added |
| No exact address | Section 1 onward | Domain choices and sample data | Done | Only approved broad areas used |
| Input validation | Later | Create form and repository | Planned | No user input in Section 1 |
| Local data reset | Later | Persistent repository/settings | Planned | No persistent data yet |
| Local AI helper | Later | Draft Assist | Planned | Documented only |
| `LocalAiService` boundary | Later | Local AI feature | Planned | Architecture recorded; no placeholder class |
| Deterministic fallback | Later | Local AI feature | Planned | Required behaviour documented |
| Local model or fallback expected flow | Later | Draft Assist integration tests | Planned | No model or fallback in Section 1 |
| Repository/data-source boundary | Section 1 | `lib/data/listing_repository.dart` | Done | UI depends on one narrow repository operation |
| ADR | Section 1 | `docs/adr/0001-local-first-marketplace-slice.md` | Done | Status is honestly Proposed |
| Product document | Section 1 | `docs/product-slice.md` | Done | Target, boundary, workflow, scope recorded |
| Metrics document | Section 1 | `docs/success-metrics.md` | Done | Targets are not reported as results |
| Accessibility document | Section 1 | `docs/accessibility-check.md` | Done | Automated and manual states distinguished |
| Security document | Section 1 | `docs/security-baseline.md` | Done | All five MAL decisions addressed |
| Local-AI document | Section 1 | `docs/local-ai-note.md` | Done | Clearly marked not implemented |
| README | Section 1 | `README.md` | Done | Setup, structure, docs, workflow, gaps included |
| Three-minute demo | Draft in Section 1; final later | `docs/demo-script.md` | Planned | Section 1 steps identified; full flow not implemented |
| Fresh checkout | Section 1 gate | README commands and a clean machine | Done | Staged-file export passes setup, analysis, tests, and Android debug build |
| Clean repository | Section 1 gate | `.gitignore`, `git status`, `git diff --check` | Done | Staged-file audit is clean; build output and machine configuration are ignored |

## Current verification snapshot

Flutter 3.44.8 and Dart 3.12.2 are installed. Dependency resolution, formatting,
analysis, and all 20 automated tests pass. The Android 36 debug build and
emulator smoke test of the feed, details, semantic hierarchy, and back route
also pass. A clean staged-file export passes setup, analysis, tests, and the
Android debug build. Full Xcode and manual TalkBack verification remain
separate environment/manual checks.
