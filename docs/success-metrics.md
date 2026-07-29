# Success metrics

Product targets remain distinct from Section 4 technical and developer
evidence. One developer verification is not a user study.

| Area | Metric | Target | Current evidence | Status |
| --- | --- | --- | --- | --- |
| Core task | Create and find a listing | Under 3 minutes | Working developer/reviewer flow; no separately timed run recorded | Implemented, timing unmeasured |
| Learnability | First listing created without assistance | 4 of 5 representative users | No five-person study performed | Unmeasured |
| Product persistence | User-created listing survives relaunch | 3 out of 3 relaunches | Exact production-created record retained on API 36 across three force-stop/relaunch checks | Manually verified |
| Technical persistence | Seed records and timestamps survive close/reopen | Nine records; exact times unchanged with a later launch clock | Real temporary encrypted Hive test passes | Automatically verified |
| Saved persistence | Saved state survives encrypted reopen | Exact marker retained without immutable-field change or duplicate | Real temporary encrypted Hive repository/store test passes | Automatically verified |
| Contacted persistence | Contacted state survives encrypted reopen | Exact marker retained without immutable-field change or duplicate | Real temporary encrypted Hive repository/store test passes | Automatically verified |
| Local status persistence | Local-origin Closed/Open survives encrypted reopen | User-created record closes, survives relaunch, reopens, and survives relaunch | Encrypted end-to-end test and API 36 workflow pass | Verified |
| Wrong-key handling | Existing box cannot normally open with a different key | Controlled failure; no recovery to empty/plaintext | Real encrypted Hive regression test passes | Automatically verified |
| Raw-file regression | Known title and description absent from raw box bytes | No known fixture plaintext | Temporary-file byte scan passes; not a cryptographic audit | Automatically verified |
| Android relaunch | Saved and Contacted survive force-stop; removal survives another force-stop | USB-C listing markers remain after first relaunch and remain removed after the second on API 36 | Clear-data, save/contact, force-stop/relaunch, remove, force-stop/relaunch check passed | Manually verified |
| Complete close workflow | Create, close, relaunch, reopen, and relaunch | Exact values and state persist without duplicates | Production-created API 36 listing completed the full loop | Manually verified |
| Accessibility semantics | Critical controls expose meaningful executable actions | Zero official labeled-target failures in tested states | 31 accessibility tests cover actions, headings, states, focus, and traversal | Automatically verified |
| Accessibility targets | Critical active controls meet platform target guidance | Zero Android/iOS target failures in tested states | Official Flutter Android and iOS tap-target guidelines pass | Automatically verified |
| Accessibility contrast | Tested text meets Flutter guideline | Zero failures in tested light/dark states | Official Flutter text-contrast guideline passes | Automatically verified |
| Invalid focus | First invalid create field receives focus | Six of six required field scenarios | Independent Title, Description, Category, Area, Contact, and Deadline focus tests pass | Automatically verified |
| Accessibility scaling | Core screens remain usable at 200% and large Android settings | Zero overflow in covered states | Automated portrait/landscape tests plus API 36 font-scale 1.3/density 560 pass | Verified |
| TalkBack emulator | Core feed/details controls work with TalkBack | Representative flow without app crash | Feed filtering, listing navigation, Save state, and “Saved on this device.” observed on TalkBack 16.0/API 36 | Partially verified |
| Privacy | No exact address, precise location, or committed key | Zero occurrences in model, fixtures, repository, or Hive key location | Broad-area, tracked-file, generated-data, local-path, and secret-pattern audits pass | Automatically verified |
| Local AI | Editable suggestion works without network | Expected Draft Assist flow completes offline | No AI implementation | Planned |
| Modularity | UI remains independent of storage | No Hive/secure-storage imports in UI | Repository/data-source dependency review | Automatically verified |
| Non-AI core-loop reliability | Create/filter/close/reopen loop remains stable | No crash or duplicate across persistence checks | Automated suite plus API 36 workflow and three relaunches pass | Verified |
| Complete-demo reliability | Main demo including Draft Assist runs twice | 2 consecutive complete-product runs | AI is not implemented | Planned |
| Discovery | Urgent listing can be found | Within 10 seconds | Today/Ending Soon work; no timed lookup recorded | Implemented, timing unmeasured |
| Reproducibility | Fresh checkout runs from README | Setup, full and accessibility test suites, and Android debug build pass | Section 5 clean-clone verification is a release gate | Verification gate |

These are developer, automated widget-test, and TalkBack-emulator results. No
person with a disability participated in a usability study.
