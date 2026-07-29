# Success metrics

Product targets remain distinct from Section 7 technical and developer
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
| Accessibility semantics | Critical controls expose meaningful executable actions | Zero official labeled-target failures in tested states | 39 accessibility tests cover actions, headings, states, focus, traversal, Privacy & data, and Draft Assist | Automatically verified |
| Accessibility targets | Critical active controls meet platform target guidance | Zero Android/iOS target failures in tested states | Official Flutter Android and iOS tap-target guidelines pass | Automatically verified |
| Accessibility contrast | Tested text meets Flutter guideline | Zero failures in tested light/dark states | Official Flutter text-contrast guideline passes | Automatically verified |
| Invalid focus | First invalid create field receives focus | Six of six required field scenarios | Independent Title, Description, Category, Area, Contact, and Deadline focus tests pass | Automatically verified |
| Accessibility scaling | Core screens remain usable at 200% and large Android settings | Zero overflow in covered states | Automated portrait/landscape tests plus API 36 font-scale 1.3/density 560 pass | Verified |
| TalkBack emulator | Core feed/details controls work with TalkBack | Representative flow without app crash | Feed filtering, listing navigation, Save state, and “Saved on this device.” observed on TalkBack 16.0/API 36 | Partially verified |
| Direct-contact guardrail | Obvious phone/email/URL/social/payment values are rejected | Nine required direct-contact cases plus integration/error-copy coverage | Deterministic validator matrix passes in the 311-test suite | Automatically verified |
| Precise-location guardrail | Obvious address/coordinate patterns are rejected while broad wording passes | 24 required precise cases and 20 ordinary/Unicode/limit cases | Deterministic validator matrix and synthetic API 36 rejection pass | Verified |
| Reset records and markers | Reset removes local records, Saved/Contacted, and local status changes | Exactly nine sample-origin records, seed defaults, no duplicate/local record | Repository and encrypted end-to-end reset tests pass | Automatically verified |
| Reset key lifecycle | Box deletion precedes targeted key deletion; next open uses a different key | Key A deleted, key B generated, A cannot normally open new box | Real temporary-Hive lifecycle and failure-order tests pass | Automatically verified |
| Reset recovery | Unreadable/failed feed can reset without decryption | Ready/empty/failed UI state replacement and wrong/malformed-key deletion | Store, repository, view-model, and widget tests pass | Automatically verified |
| Release permissions | Production manifest is permission-minimal | No product INTERNET or listed sensitive permission | Official SDK `apkanalyzer` and `aapt` release audit pass | Statically verified |
| Log/raw-file canaries | No exercised plaintext leak | No production logging; known content absent from raw Hive bytes and API 36 logcat | Static scan, encrypted-file tests, `run-as` Hive scan, and reset/relaunch logcat scan pass; scope is not universal proof | Verified with stated limit |
| Shared storage | Listings remain app-private | No product shared/external write path | Source/manifest review and API 36 shared-directory scan found no listing file | Verified |
| Android reset relaunch | Reset survives three relaunches | Nine samples and no old marker/local canary after each force-stop | Three of three API 36 post-reset relaunch dumps report nine listings | Manually verified |
| Local Draft Assist | Editable Type, Title, and Category work without network or model | Suggest, preview, dismiss, apply, edit, complete, Post; nothing persists before Post | Real fallback workflow widget test and API 36 airplane-mode flow pass; item 10 survives relaunch | Verified |
| Fallback expected cases | Stable required Kind/Category/title behaviour | 18 of 18 curated cases | Table-driven unit evaluation passes | Automatically verified |
| Fallback privacy rejection | Invalid Description produces no suggestion | 15 of 15 invalid classes | Shared-validator unit matrix passes with secret-safe errors; precise-location draft rejected without preview on API 36 | Verified |
| Fallback determinism | Same input produces identical result | 10 of 10 repetitions | Kind, Title, Category, and source remain identical | Automatically verified |
| Assistant architecture | UI and assistant can change independently; repository stays unaware | Explicit interface injection and no suggestion storage path | Constructor, view-model, workflow, and static dependency review | Automatically verified |
| Modularity | UI remains independent of storage | No Hive/secure-storage imports in UI | Repository/data-source dependency review | Automatically verified |
| Non-AI core-loop reliability | Create/filter/close/reopen loop remains stable | No crash or duplicate across persistence checks | Automated suite plus API 36 workflow and three relaunches pass | Verified |
| Complete-demo reliability | Main demo including Draft Assist runs twice | 2 consecutive complete-product runs | Automated workflow passes; two timed human demo runs not recorded | Implemented, timing pending |
| Discovery | Urgent listing can be found | Within 10 seconds | Today/Ending Soon work; no timed lookup recorded | Implemented, timing unmeasured |
| Reproducibility | Fresh checkout runs from README | Setup, analysis, 311 tests, 39 accessibility tests, and both APK builds pass | Isolated committed-history clone passed every gate on Flutter 3.44.8 and Dart 3.12.2 | Verified |

These are developer, automated widget-test, and TalkBack-emulator results. No
person with a disability participated in a usability study.
