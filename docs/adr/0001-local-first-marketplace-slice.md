# ADR 0001: Local-first marketplace slice

- Status: Proposed
- Date: 2026-07-28

## Context

ViharLoop addresses small, time-sensitive exchanges around Vidyavihar. A
charger needed for two hours or notes available until tomorrow should be easy
to discover without a broad marketplace, exact address, hosted service, or
long transaction flow. The first engineering slice must make the product
credible while leaving storage and optional local AI replaceable.

## Product slice and decision

Build one neighbourhood feed and a read-only details screen first. Model a
real `Listing`, including the Need/Offer deadline and later mutation flags, but
do not implement create, save, contacted, close, persistence, or AI behaviour
before those behaviours can be tested.

Use a lightweight MVVM path:

```text
Feed view → FeedViewModel → ListingRepository
                              ↓
                    InMemoryListingRepository
```

Views own presentation and navigation. `FeedViewModel` owns loading, explicit
feed state, safe failure copy, and urgency ordering. `ListingRepository` owns
the data boundary, and the temporary in-memory implementation builds relative
sample data. Product labels and listing rules live with the domain model.

No use-case layer, service locator, generic repository, or third-party state
package is added because the current behaviour does not justify one.

## Why local-first and one neighbourhood

The intended core flow should continue without hosted services. Local-first
reduces initial infrastructure, data transfer, and demo dependence on network
conditions. It does not itself guarantee security, backup, synchronization,
or availability.

One neighbourhood creates a clear relevance boundary and supports broad areas
instead of precise location. Expanding geography can be considered after the
Vidyavihar flow is useful and safe.

## Current and planned data

Section 1 uses `InMemoryListingRepository`, returning unmodifiable,
clock-relative sample records. Widgets never import the seed builder. Section
2 will replace this with encrypted local storage behind the same repository
boundary and add only the operations required by implemented behaviour.

The planned random encryption key will live in platform secure storage, never
in Dart source, assets, or committed configuration. Storage migration, reset,
backup behaviour, corruption handling, and key-loss consequences need tests.

## Planned local AI isolation

A later `LocalAiService` will isolate Draft Assist from the create screen. A
Gemma implementation and deterministic fallback will both produce strictly
validated, editable suggestions that require user confirmation. No hosted AI
is part of the product slice.

## Accessibility implications

Read-only cards currently use one button-like semantic summary. Visible state
labels ensure meaning is not colour-only, and scalable layouts avoid fixed
card heights. When card actions are added, semantics and focus handling must
be redesigned so each action is independently named and operable. Automated
tests do not replace manual TalkBack verification.

## Security decisions

1. **Secrets:** none exist now; future local encryption keys belong in
   platform secure storage.
2. **Trust boundary:** there is no server; if one is added, it must distrust
   client input and enforce its own authorization and validation.
3. **Encryption at rest:** no persistence now; encrypted local storage with a
   random secure-storage key is planned.
4. **Certificate pinning:** not applicable without a server and explicitly
   deferred until a remote API has a threat and rotation plan.
5. **Telemetry:** no analytics, crash reporting, or telemetry leaves the
   device in this slice.

## Alternatives considered

- **Backend-first architecture:** rejected because it adds network
  availability, identity, deployment, and remote-data decisions before the
  small offline flow is validated.
- **Direct storage calls from widgets:** rejected because presentation would
  become coupled to encryption and migration choices.
- **Hosted AI:** rejected because it contradicts the offline goal and sends
  user draft content to a remote service.
- **A generic clean-architecture layer for every action:** rejected because
  Section 1 has one repository read and no domain workflow requiring those
  layers.
- **Building all marketplace features now:** rejected because it would make
  privacy, accessibility, storage, and demo failures harder to isolate.

## Consequences accepted

- Current records are fictional and disappear when the process ends.
- Feed and details can be tested before local storage is selected.
- There is no multi-device sync, recovery, identity, moderation, or remote
  availability.
- The repository contract will evolve when concrete mutations arrive.
- Manual accessibility and device verification remain required.

## Future change points and reversal cost

- Replacing the in-memory implementation should be low-cost for read-only
  views because they depend on `ListingRepository`; migrations and error
  states still add real work.
- Changing the listing model after persistence ships has a higher cost because
  stored records require migration.
- Introducing a backend reverses the local-only trust and telemetry
  assumptions and needs a new ADR.
- Introducing internal card actions requires semantic restructuring, not just
  new icons.
- Replacing Gemma should be contained by `LocalAiService`, but model packaging,
  latency, and output validation remain implementation-specific.
