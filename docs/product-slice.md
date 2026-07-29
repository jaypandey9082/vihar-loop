# Product slice

## Product and user

ViharLoop is for a student or resident around Vidyavihar and the Somaiya area
who needs something small nearby or has something useful to lend, give, or
offer. Small local requests are easily lost in noisy group chats, while broad
marketplaces add distance and transaction ceremony that do not fit a charger
needed for two hours or notes needed before tomorrow.

The geographical boundary is one neighbourhood: Vidyavihar, Mumbai. Listings
use only broad areas such as the Somaiya side or a side of Vidyavihar station.
They do not include exact addresses, flat numbers, precise distances, or GPS
coordinates.

## Main product job

Help someone notice a relevant, time-sensitive local need or offer and decide
whether to respond, without requiring a hosted service or revealing a precise
location.

The currently implemented core workflow is:

```text
Feed → create → encrypted persistence → details
     → save/contact/close/reopen → relaunch
     → Privacy & data → reset → fictional samples
```

Saved and Contacted are private markers stored only on this device. Contacted
does not perform communication. Details and feed receive the successfully
persisted result without requiring a restart.

Status mutation is owner-controlled. Records created on this installation have
local origin and can be closed or reopened. Sample records cannot be closed.
Local origin is only an offline product distinction, not proof of a person's
identity; a future backend must replace that ownership assumption.

## Today Loop

Every need has a **Needed by** time and every offer has an **Available until**
time. Today Loop is implemented in the feed:

- **Today:** open, not past, and ending on the same local calendar date as now.
- **Ending soon:** open, strictly after now, and ending within three hours.
- **Need/Offer:** an independent type filter that combines with either time
  filter.

Closed and past listings remain visible under All but are excluded from Today
and Ending Soon. Cards show at most one time badge, prioritizing Ending soon
over Today.

## Creation and privacy boundary

The create form accepts only Need/Offer, title, description, approved category,
broad approximate area, approved contact preference, and deadline. It has no
exact-address, phone, email, GPS, or live-location field. A shared deterministic
validator rejects obvious direct-contact/payment identifiers and precise
flat, room, floor, street, PIN-code, and coordinate patterns. The repository
revalidates before persistence. Broad location descriptions remain allowed;
heuristics cannot prove every free-text description is address-free.

Privacy & data is reachable from normal, empty, and storage-error feeds. It
states that there is no account, backend, analytics, or remote telemetry.
Reset removes the encrypted database and its current key, then restores only
the nine fictional samples with a fresh key. It therefore also recovers an
unreadable local database without decrypting it.

## Why the product is intentionally small

One neighbourhood, broad location choices, and a short listing model make the
core exchange easy to explain and test. The narrow slice also allows privacy,
offline behaviour, accessibility, and storage decisions to be evaluated
before marketplace breadth is added.

## Assumptions

- People can coordinate through an existing community group or agree to meet
  in a public place.
- A broad neighbourhood area is enough to judge local relevance.
- Needs and offers are short-lived more often than permanent.
- Local creation is sufficient to exercise the real owner-only close/reopen
  path without adding accounts or a backend.
- A listing is not a promise of availability, identity, quality, or safety.

## Explicitly out of scope

- Login
- Backend
- Payments
- Delivery
- Real chat
- KYC
- Precise location
- Image uploads
- Push notifications
- Admin dashboard
- Hosted AI
