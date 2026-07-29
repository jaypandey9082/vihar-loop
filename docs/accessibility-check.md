# Accessibility check

Section 4 adds a full labeled creation form and filter controls while retaining
the separate Saved and Contacted controls on details. Visible errors remain in
the form, posting exposes progress, and controls are disabled only while a
submission or mutation is finishing.

## Section 1 baseline

Section 1 uses standard Material navigation and controls, visible Need/Offer
and Open/Closed wording, comfortably padded cards, a logical top-to-bottom
reading order, and no image-based text. Loading, empty, and error states
contain explicit readable copy. Text scaling is not manually capped.

Each listing card is exposed as one button-like semantic node. Its label
includes the listing kind, title, category, broad area, relevant time wording,
status, and the action to open details. Visible descendants are excluded from
the semantics tree to prevent the same information being announced twice.

The card remains one semantic button because its only action is Open details.
Its summary conditionally includes Saved, Contacted, and Your post when those
states are active. Save and Contacted live on the details screen as separate
focusable controls rather than adding competing card actions.

## Check status

| Check | Planned | Implemented | Verified |
| --- | --- | --- | --- |
| Need, Offer, Open, and Closed are visible text | Yes | Yes | Automated widget assertion passed |
| Listing card has a meaningful button semantic summary | Yes | Yes | Semantics test and API 36 UI-hierarchy smoke passed |
| Loading state has a readable live-region label | Yes | Yes | Manual screen-reader verification pending |
| Empty state has a heading and supporting copy | Yes | Yes | Automated widget assertion passed |
| Error copy hides technical details and Retry is named | Yes | Yes | Retry widget test passed |
| Feed supports approximately 200% text scaling | Yes | Yes | Layout test passed without exceptions |
| Details supports approximately 200% text scaling | Yes | Yes | Action layout test passed without exceptions |
| Create form supports approximately 200% text scaling | Yes | Yes | Widget layout and completion test passed |
| Card tap target is comfortably large | Yes | Yes | Visual/manual measurement pending |
| Logical focus and reading order | Yes | Yes | Manual TalkBack verification pending |
| Dark-theme contrast | Yes | Theme-derived colours used | Manual contrast verification pending |
| Create fields have persistent visible labels | Yes | Yes | Automated structure assertions passed |
| Create-form errors are visible text | Yes | Yes | Widget validation and API 36 incomplete-submit checks passed |
| Keyboard flow reaches multiline description and Next/Done actions | Yes | Yes | Input actions configured; physical-keyboard manual pass pending |
| Deadline control has an understandable label and value | Yes | Yes | Widget semantics/visible-text coverage passed |
| Posting progress is meaningful and blocks duplicate input | Yes | Yes | View-model and widget pending-state tests passed |
| Type/time filters expose selected states | Yes | Yes | Material ChoiceChip selected state and interaction tests passed |
| Filtered empty state explains how to recover | Yes | Yes | Automated widget assertion passed |
| Separate Save and Contacted semantics and toggled state | Yes | Yes | Automated semantics and interaction tests passed |
| Active Saved, Contacted, and Your post in card summary | Yes | Yes | Automated semantics test passed |
| Accessible Close confirmation | Yes | Yes for local records | Dialog test and production-created API 36 flow pass |

Automatically verified checks include visible create labels/errors, pending and
duplicate-submission behavior, filter interaction/empty state, semantic card
summaries, and create/feed/details layouts at approximately 200% text scale.
Manual API 36 verification covered the visual create, filter, close/reopen, and
relaunch flow without visible overflow or crash.

No manual TalkBack or VoiceOver verification has been performed through Section 4.
The Android emulator confirmed that cards are exposed as buttons with the
expected combined descriptions, but this is not a substitute for listening to
the flow with TalkBack. Before final submission, test the complete flow with
TalkBack on the target Android device, including create field-error focus,
date/time picker announcements, filter selected states, posting progress,
filtered empty recovery, and close confirmation. Also inspect large-text
layouts beyond 200%, check contrast, and verify focus after navigation.
