# Demo script

## Draft final three-minute demo

The complete-product demo remains planned. Create, save/contacted, Draft
Assist, and close behaviors are not implemented in Section 2.

| Step | Demonstration | Section 2 status |
| --- | --- | --- |
| 1 | Enable airplane mode and launch ViharLoop | No network is required |
| 2 | Open the Vidyavihar feed | Implemented |
| 3 | Find an urgent listing within 10 seconds | Ordering implemented; timing planned |
| 4 | Open and read listing details | Implemented |
| 5 | Save a listing or mark it contacted | Planned |
| 6 | Create a need or offer | Planned |
| 7 | Use editable local Draft Assist | Planned |
| 8 | Relaunch and show persistence | Seed persistence implemented |
| 9 | Close the created listing | Planned |
| 10 | Point to architecture, accessibility, and security evidence | Documents updated |

## Section 2 persistence demonstration

1. Clear ViharLoop application data.
2. Launch the app and show all nine fictional records.
3. Note one exact listing title and its visible deadline.
4. Open its read-only details and return to the feed.
5. Force-stop ViharLoop without clearing data.
6. Relaunch it.
7. Show the same nine records, title, and unchanged deadline.
8. Open details again.
9. Explain that production reads versioned records from encrypted local Hive
   using a key stored separately through platform secure storage.
10. Explain that listing mutations arrive in later sections.

Do not inspect, display, or narrate the encryption key. The automated
persistence test separately reopens the same encrypted directory with a later
clock and confirms the original timestamps remain unchanged.
