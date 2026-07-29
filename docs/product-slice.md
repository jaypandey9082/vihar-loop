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

The intended complete workflow is:

```text
Feed → details → create → save/contact/close → local persistence
     → optional local AI assistance → continued offline use
```

Section 3 implements this currently available workflow:

```text
Feed → details → save/contact markers → encrypted persistence
```

Saved and Contacted are private markers stored only on this device. Contacted
does not perform communication. Details and feed receive the successfully
persisted result without requiring a restart.

Status mutation is owner-controlled. Sample records cannot be closed. Records
created locally will be closeable and reopenable after Section 4 adds Create;
all current production seeds deliberately remain sample records. Create and
local AI remain later work.

## Today Loop

Every need has a **Needed by** time and every offer has an **Available until**
time. A later section will use this field for Today and Ending Soon discovery.
The domain model and persisted sample records include the time now, but
Section 3 does not expose filters.

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
- Sample content is sufficient to validate navigation, markers, and encrypted
  mutation persistence before Create begins.
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
