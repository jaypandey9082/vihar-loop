# Demo script

## Draft final three-minute demo

| Step | Demonstration | Section 1 status |
| --- | --- | --- |
| 1 | Enable airplane mode and launch ViharLoop | Planned device verification |
| 2 | Open the Vidyavihar feed | Implemented |
| 3 | Find an urgent listing within 10 seconds | Implemented ordering; timed verification planned |
| 4 | Open and read listing details | Implemented |
| 5 | Save a listing or mark it contacted | Planned |
| 6 | Create a need or offer | Planned |
| 7 | Use editable local Draft Assist | Planned |
| 8 | Relaunch and show persistence | Planned |
| 9 | Close the created listing | Planned |
| 10 | Point to the ADR and accessibility/security evidence | Documents created; final evidence planned |

## Section 1 demo

1. Launch the app.
2. Show **ViharLoop**, **Vidyavihar, Mumbai**, and the mixed read-only feed.
3. Point out visible Need/Offer, Open/Closed, broad area, and deadline wording.
4. Open one urgent Need card and use the back route.
5. Open one Offer card and show description, contact preference, and broad
   location without an exact address.
6. Show the empty, failure, and working Retry paths through widget tests or
   development fakes; there are no non-functional controls in the live UI.
7. Point to `ListingRepository`, `InMemoryListingRepository`, this
   documentation set, and the semantics/text-scale tests.

The automated Section 1 checks and the feed → details → back route pass on an
Android API 36 emulator. Empty and failure states are covered through widget
tests. Manual TalkBack and airplane-mode runs remain for final accessibility
and offline verification.
