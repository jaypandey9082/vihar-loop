# Success metrics

These targets were defined before the complete product was implemented. A
target is not evidence that the result has been achieved.

| Area | Metric | Target | How it will be checked | Current result | Status |
| --- | --- | --- | --- | --- | --- |
| Core task | Create and find a listing | Under 3 minutes | Timed usability session from app launch | Not measured | Planned |
| Learnability | First listing created without assistance | 4 of 5 representative users | Observed usability sessions | Not measured | Planned |
| Persistence | Listing survives relaunch | 3 out of 3 relaunches | Create once, force-close, relaunch three times | Not measured | Planned |
| Accessibility | Core flow usable with accessibility tooling | Feed, details, create, validation, and actions remain operable | Automated semantics/text-scale tests plus manual TalkBack pass | Not measured | Planned |
| Privacy | No exact address, precise location, or secret stored | Zero occurrences in model, storage, logs, or repository | Model review, fixtures review, repository scan, storage inspection | Not measured | Planned |
| Local AI | Editable suggestion works without network | Expected Draft Assist flow completes in airplane mode | Scripted model and deterministic-fallback tests | Not measured | Planned |
| Modularity | UI, storage, and AI can change independently | Each boundary can be replaced without editing the other two | Dependency and focused-test review | Not measured | Planned |
| Reliability | Main demo runs twice without crash | 2 consecutive successful runs | Repeat final three-minute demo on demo device | Not measured | Planned |
| Discovery | Urgent listing can be found | Within 10 seconds | Timed task on seeded and user-created data | Not measured | Planned |
| Reproducibility | Fresh checkout can run from README | One clean setup with no undocumented step | Fresh clone, README commands, Android smoke run | Not measured | Planned |
