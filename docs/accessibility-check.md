# Accessibility check

Section 3 adds separate Saved and Contacted controls on details. Each has a
meaningful visible and semantic label, button role, enabled state, and toggled
state. Pending progress is exposed as a live semantic update, and all actions
are disabled while one mutation is finishing.

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
| Card tap target is comfortably large | Yes | Yes | Visual/manual measurement pending |
| Logical focus and reading order | Yes | Yes | Manual TalkBack verification pending |
| Dark-theme contrast | Yes | Theme-derived colours used | Manual contrast verification pending |
| Create-form errors are visible and announced | Yes | No, create is later | Planned |
| Separate Save and Contacted semantics and toggled state | Yes | Yes | Automated semantics and interaction tests passed |
| Active Saved, Contacted, and Your post in card summary | Yes | Yes | Automated semantics test passed |
| Accessible Close confirmation | Yes | Yes for local records | Dialog widget test passes; production flow awaits Create |

No manual TalkBack or VoiceOver verification has been performed through Section 3.
The Android emulator confirmed that cards are exposed as buttons with the
expected combined descriptions, but this is not a substitute for listening to
the flow with TalkBack. Before final submission, test the complete flow with
TalkBack on the target Android device, inspect large-text layouts beyond 200%,
check contrast, and verify focus after navigation and validation errors.
