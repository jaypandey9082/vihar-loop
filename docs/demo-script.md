# Demo script

## Final three-minute demo draft

The Section 7 Draft Assist path uses deterministic offline fallback. It does
not require a model or hosted API.

| Step | Demonstration | Section 4 status |
| --- | --- | --- |
| 1 | Enable airplane mode and launch ViharLoop | No network is required |
| 2 | Open the Vidyavihar feed | Implemented |
| 3 | Find an urgent listing within 10 seconds | Ordering implemented; timing planned |
| 4 | Open and read listing details | Implemented |
| 5 | Save a listing or mark it contacted | Implemented |
| 6 | Create a need or offer | Implemented |
| 7 | Use editable local Draft Assist | Implemented with deterministic fallback |
| 8 | Relaunch and show persistence | Created record and state persist |
| 9 | Close the created listing | Implemented for local-origin records |
| 10 | Point to architecture, accessibility, and security evidence | Section 7 automated evidence is current |

## Section 7 Draft Assist proof

1. Enable airplane mode.
2. Open Create and enter **Need a guitar capo for rehearsal near Somaiya
   today.**
3. Activate **Suggest type, title & category**.
4. Show the Need, **Guitar capo for rehearsal**, **Music, hobbies & sports**,
   and **Built-in offline rules** preview.
5. Dismiss once and show that no form value was changed or saved.
6. Suggest again and activate **Use suggestions**.
7. Edit the Title slightly.
8. Complete area, contact preference, and deadline manually.
9. Post and show the listing in the feed.
10. Point to `LocalAiService`, the 18-case deterministic evaluation, shared
    validation, and the absence of model/network dependencies.

## Section 4 creation and Today Loop demonstration

1. Enable airplane mode.
2. Launch ViharLoop.
3. Tap **Post a need or offer**.
4. Create **Foldable music stand for rehearsal** as a Need.
5. Choose **Music, hobbies & sports**, **Somaiya side**, **Meet at a public
   place**, and a deadline about two hours ahead.
6. Post and show **Your post** in the ten-listing feed.
7. Select **Ending soon** and show the created listing.
8. Open it and confirm **Close listing** is available.
9. Close it after confirmation.
10. Return and show that it no longer matches Ending soon.
11. Clear filters and show it as Closed.
12. Force-stop and relaunch; show that the exact created record remains Closed.
13. Reopen it.
14. Force-stop and relaunch again; confirm Open remains.
15. Point to encrypted persistence and the broad-area/obvious-contact
    validation boundary.

Do not inspect, display, or narrate the encryption key. The automated
persistence test separately creates, closes, reopens, and reopens storage
without changing the nine seeds, schema version 1, or seed version 1. Actual
on-device Gemma integration remains planned for Section 8.

## Section 5 accessibility evidence

Keep this proof to about 45 seconds inside the main demo:

1. Enable TalkBack and Display speech output.
2. Move to Type and activate **Offers**, then show the updated count.
3. Reach a listing card and activate it to open details.
4. Show the listing-title and **Your activity** headings, then toggle Save.
5. Return, open Create, submit an empty form, and show focus on Title with its
   visible correction.
6. Activate the Deadline control and briefly show the Material pickers.
7. Switch to the large Android font/display setting and show the vertical
   Need/Offer control.
8. Point to the official guideline, semantic-action, traversal, keyboard, and
   200% layout tests.

The current automated host could not reliably perform the complete TalkBack
multi-gesture create/picker/dialog walkthrough. Do not present that full manual
script as completed until it is run on a directly controlled emulator or
physical Android device.

## Section 6 privacy and reset proof

Keep this proof short and never display the encryption key:

1. Open Create, enter **Flat 302, Wing B**, and show the precise-location error.
2. Replace it with broad wording such as **Near Vidyavihar station** and create
   one synthetic local listing.
3. Save or mark the local flow Contacted.
4. Open **Privacy & data** and show the data inventory and encryption limit.
5. Tap **Reset local data**, choose **Keep data**, and show nothing changed.
6. Confirm reset on the second attempt.
7. Show the unfiltered feed with exactly nine fictional samples and no local
   listing or private marker.
8. Explain that the encrypted box was deleted before its targeted key, then a
   fresh key and samples were created through normal initialization. Call this
   a practical cryptographic reset, not forensic erasure.
