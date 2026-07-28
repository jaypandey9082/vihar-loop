# Success metrics

Product targets remain distinct from Section 2 technical evidence. A seeded
fixture surviving storage reopen is not evidence that the future create flow
works for users.

| Area | Metric | Target | Current evidence | Status |
| --- | --- | --- | --- | --- |
| Core task | Create and find a listing | Under 3 minutes | Create is not implemented | Planned |
| Learnability | First listing created without assistance | 4 of 5 representative users | Not measurable yet | Planned |
| Product persistence | User-created listing survives relaunch | 3 out of 3 relaunches | Create is not implemented | Planned |
| Technical persistence | Seed records and timestamps survive close/reopen | Nine records; exact times unchanged with a later launch clock | Real temporary encrypted Hive test passes | Automatically verified |
| Wrong-key handling | Existing box cannot normally open with a different key | Controlled failure; no recovery to empty/plaintext | Real encrypted Hive regression test passes | Automatically verified |
| Raw-file regression | Known title and description absent from raw box bytes | No known fixture plaintext | Temporary-file byte scan passes; not a cryptographic audit | Automatically verified |
| Android relaunch | Seed feed survives force-stop and relaunch | Same nine records; USB-C listing retained its 4:47 AM deadline; details reopened on API 36 | Clear-data, launch, force-stop, and relaunch check passed | Manually verified |
| Accessibility | Read-only feed/details remain operable | Existing semantics and 200% text-scale tests | Automated regression tests pass; TalkBack pending | Partially verified |
| Privacy | No exact address, precise location, or committed key | Zero occurrences in model, fixtures, repository, or Hive key location | Broad-area, tracked-file, generated-data, local-path, and secret-pattern audits pass | Automatically verified |
| Local AI | Editable suggestion works without network | Expected Draft Assist flow completes offline | No AI implementation | Planned |
| Modularity | UI remains independent of storage | No Hive/secure-storage imports in UI | Repository/data-source dependency review | Automatically verified |
| Reliability | Main demo runs twice without crash | 2 consecutive complete-product runs | Full product workflow does not exist | Planned |
| Discovery | Urgent listing can be found | Within 10 seconds | Ordering exists; no timed usability result | Planned |
| Reproducibility | Fresh checkout runs from README | Setup, 44 tests, and Android debug build pass | Clean local clone from committed history passed without key, database, or `.env` | Automatically verified |
