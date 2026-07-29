# Success metrics

Product targets remain distinct from Section 3 technical evidence. A seeded
fixture surviving storage reopen is not evidence that the future create flow
works for users.

| Area | Metric | Target | Current evidence | Status |
| --- | --- | --- | --- | --- |
| Core task | Create and find a listing | Under 3 minutes | Create is not implemented | Planned |
| Learnability | First listing created without assistance | 4 of 5 representative users | Not measurable yet | Planned |
| Product persistence | User-created listing survives relaunch | 3 out of 3 relaunches | Create is not implemented | Planned |
| Technical persistence | Seed records and timestamps survive close/reopen | Nine records; exact times unchanged with a later launch clock | Real temporary encrypted Hive test passes | Automatically verified |
| Saved persistence | Saved state survives encrypted reopen | Exact marker retained without immutable-field change or duplicate | Real temporary encrypted Hive repository/store test passes | Automatically verified |
| Contacted persistence | Contacted state survives encrypted reopen | Exact marker retained without immutable-field change or duplicate | Real temporary encrypted Hive repository/store test passes | Automatically verified |
| Local status persistence | Local-origin Closed survives encrypted reopen | Closed retained and can reopen; fixture is not user-created content | Real temporary encrypted Hive repository/store test passes | Automatically verified |
| Wrong-key handling | Existing box cannot normally open with a different key | Controlled failure; no recovery to empty/plaintext | Real encrypted Hive regression test passes | Automatically verified |
| Raw-file regression | Known title and description absent from raw box bytes | No known fixture plaintext | Temporary-file byte scan passes; not a cryptographic audit | Automatically verified |
| Android relaunch | Saved and Contacted survive force-stop; removal survives another force-stop | USB-C listing markers remain after first relaunch and remain removed after the second on API 36 | Clear-data, save/contact, force-stop/relaunch, remove, force-stop/relaunch check passed | Manually verified |
| Complete close workflow | Create, close, relaunch, and reopen a user-created listing | 3 out of 3 relaunches | Create is not implemented; local fixtures are not user-created content | Planned |
| Accessibility | Feed/details and actions remain operable | Marker semantics and 200% text-scale tests | Automated regression tests pass; TalkBack pending | Partially verified |
| Privacy | No exact address, precise location, or committed key | Zero occurrences in model, fixtures, repository, or Hive key location | Broad-area, tracked-file, generated-data, local-path, and secret-pattern audits pass | Automatically verified |
| Local AI | Editable suggestion works without network | Expected Draft Assist flow completes offline | No AI implementation | Planned |
| Modularity | UI remains independent of storage | No Hive/secure-storage imports in UI | Repository/data-source dependency review | Automatically verified |
| Reliability | Main demo runs twice without crash | 2 consecutive complete-product runs | Full product workflow does not exist | Planned |
| Discovery | Urgent listing can be found | Within 10 seconds | Ordering exists; no timed usability result | Planned |
| Reproducibility | Fresh checkout runs from README | Setup, full test suite, and Android debug build pass | Clean clone verification is required at the Section 3 commit | Verification gate |
