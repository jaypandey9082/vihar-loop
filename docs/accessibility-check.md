# Accessibility check

## Scope and target

Section 5 audits the existing feed, filters, cards, create form, deadline,
details actions, dialogs, temporary messages, and route transitions. It adds no
product feature and changes no repository, record, encryption, seed, or
security behaviour. Android/API 36 is the primary runtime target; iOS receives
source-level widget and guideline coverage.

## Evidence

| Requirement | Implementation | Automated evidence | Manual evidence | Status |
| --- | --- | --- | --- | --- |
| Feed structure and states | Level 1/2 headings, one loading live region, readable counts, named recovery actions, decorative icons excluded | Loading, ready, filtered/genuine empty, error, Retry, headings, count, and traversal tests | Ready and filtered feed rendered with TalkBack active | Done |
| Listing-card action | One concise button node owns `SemanticsAction.tap`; visual InkWell remains pointer-operable | Semantic tap opens the correct listing; label/state tests pass | API 36 opened the USB-C listing with TalkBack active and showed “Listing details” | Done |
| Filters | Standard ChoiceChip selected state and actions retained; groups wrap | Offers, Ending soon, Clear filters, selected-state, keyboard, and traversal tests pass | Offers and Ending soon changed the feed on the TalkBack-enabled AVD | Done |
| Heading navigation | Shared level 1–6 wrapper sets both `header` and `headingLevel` | Feed, empty/error, create, listing-title, and activity heading tests pass; body copy is not marked heading | TalkBack focus visibly reached feed and details context | Done |
| First-invalid focus | Dedicated nodes for all six required fields; validation waits for the rendered frame, scrolls, and requests focus | Independent Title, Description, Category, Area, Contact, and Deadline focus tests pass | Complete TalkBack invalid-field walkthrough could not be controlled reliably from the host | Implemented, manual verification pending |
| Deadline | One focusable semantic button exposes label, value, hint, action, and `SemanticsValidationResult` | Semantic action opens picker; invalid/valid and focus-return tests pass; keyboard Space works | Date/time picker TalkBack walkthrough not completed | Implemented, manual verification pending |
| Posting and failures | One disabled live-region status; children excluded; failure restores Post focus and values | Pending, disabled, failure, recovery, and valid semantic-submit tests pass | Posting speech not manually observed | Implemented, manual verification pending |
| Details and actions | Title/activity headings; one state summary; label/value metadata rows; existing action boundaries retained | Save, Contacted, Close, Keep open, confirm, Reopen, pending, SnackBar, and dialog traversal tests pass | Save changed to Saved and Display speech output showed “Saved on this device.” | Done |
| Tap targets and labels | Actual target geometry and semantics fixed where needed | Official Android, iOS, and labeled-target guidelines pass across critical states | Visual device inspection found no inaccessible small product target | Done |
| Contrast | Existing ColorScheme roles retained | Official text-contrast guideline passes tested light and dark states | No Accessibility Scanner or manual ratio claim | Done |
| Traversal and keyboard | Natural widget order retained; no numeric focus order | Simulated feed/create/details/empty/dialog traversal and Tab/Shift+Tab/Enter/Space tests pass | Emulator keyboard was usable; complete Switch Access pass not performed | Done |
| Large text and display | Segmented control measures scaled labels and becomes vertical; cards/dialogs remain flexible/scrollable | 320×568 and 568×320 at 200%, long content, form errors, pending, and dialog tests pass | API 36 at font scale 1.3 and density 560 showed vertical create choices without crash/overflow | Done |

## Automated checks

The dedicated `test/accessibility/` suite contains 31 tests. It uses
`tester.ensureSemantics()`, official Flutter accessibility guidelines,
`simulatedAccessibilityTraversal`, semantic actions, focus assertions, and
logical keyboard events. The full repository suite contains 148 tests.

Guideline coverage runs `androidTapTargetGuideline`,
`iOSTapTargetGuideline`, `labeledTapTargetGuideline`, and
`textContrastGuideline` across representative feed, create, details, pending,
dialog, empty/error, light, and dark states. The tests initially exposed a
200%-scale card-chip overflow and a short-landscape dialog overflow; flexible
chip text and a scrollable dialog fixed those observed issues.

## TalkBack environment and observations

- AVD/device: `vihar_loop_api_36`, `sdk_gphone64_arm64`, Android API 36,
  1080×2400, physical density 420
- TalkBack: `com.google.android.marvin.talkback`, version
  `16.0.0.738667889` (`60149341`)
- App: ViharLoop `0.5.0` (`5`)
- Normal settings: font scale 1.0, density 420
- Large-settings pass: font scale 1.3, override density 560
- Display speech output: enabled for the pass
- Network: airplane mode for the cleared-data launch

Observed, not inferred:

- TalkBack was bound and its green accessibility focus was visible on feed and
  details.
- Offers and Ending soon updated their selected state and count; Clear filters
  recovered the feed.
- Activating the first card opened the matching USB-C details screen.
- Details metadata remained visible as label/value pairs with no icon-only
  action.
- Saving changed the visible control to Saved, and speech output displayed
  “Saved on this device.”
- At font scale 1.3/density 560, the create Need/Offer control became vertical;
  required content remained reachable by scrolling and no app crash/ANR was
  logged.

This is representative real-emulator TalkBack evidence, not a claim that the
entire manual acceptance script passed. ADB-injected gestures did not provide
reliable TalkBack swipe/double-tap control, the visible emulator window was not
addressable by the available Mac automation layer, and the windowed AVD also
encountered the previously observed System UI responsiveness issue. Therefore
invalid-field speech, both pickers, posting, Contacted, and close-dialog speech
remain manual verification pending. Their semantics actions, traversal,
keyboard behaviour, states, and messages are covered automatically.

Google Accessibility Scanner was not installed on the AVD. No random or
unofficial APK was downloaded, so Scanner verification is unavailable.
Grayscale/color-correction manual inspection was not completed.

VoiceOver was not tested because full Xcode is unavailable. No assistive-
technology user study was performed, and this document does not claim WCAG
certification.
