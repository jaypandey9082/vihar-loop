# ADR 0001: Local-first marketplace slice

- Status: Accepted
- Date: 2026-07-28
- Accepted: 2026-07-29

## Context

ViharLoop supports small, time-sensitive exchanges around Vidyavihar without
requiring an exact address, hosted service, or long transaction flow. The
read-only slice needs to survive relaunch while keeping storage replaceable,
failure visible, and the UI independent of database details.

## Decision

Keep the lightweight MVVM boundary:

```text
FeedScreen → FeedViewModel → ListingRepository
                                  ↓
                         LocalListingRepository
                                  ↓
                          ListingLocalStore
                                  ↓
                    EncryptedHiveListingStore
                       ├── ListingRecordCodec
                       └── EncryptionKeyStore
                                  ↓
                       FlutterSecureStorage
```

`ListingRepository` exposes the feed read, create, and explicit Saved,
Contacted, Status, and `resetLocalData` operations. A widget-independent
`ListingDraft` carries
only user-controlled create values. The repository normalizes and revalidates
that boundary, then constructs protected fields including a stable
`local-<UTC microseconds>-<secure random hex>` ID, local origin, open status,
creation time, and initial private markers.

`LocalListingRepository` coordinates retryable first-run initialization,
serializes all mutations, rereads the latest value for updates, and owns the
rule that sample listings cannot change status. The store lazily opens one
encrypted `Box<String>` named `vihar_loop_listings_v1`; its exact-key insert
rejects duplicates and cannot silently upsert.

Listing values are explicit schema-version-1 JSON records. Stable text codes,
UTC ISO-8601 timestamps, complete validation, and matching `listing:<id>` keys
keep the persisted contract independent of UI labels and Dart enum order.
Generated Hive adapters were not selected because they would couple the domain
model and stored representation and add generation tooling for nine flat
records.

One package-generated random 32-byte key is Base64-encoded only for platform
secure storage. Missing key material is generated once; malformed or
inaccessible existing material fails. The encrypted box is never replaced by
temporary memory or plaintext after failure.

A dedicated widget-independent `ListingPrivacyValidator` classifies obvious
direct-contact/payment identifiers and precise-location patterns. The create
form and repository use the same injected validator; a future AI suggestion
must pass it as well. It remains a heuristic guardrail, not an address parser.

Seed version 1 is stored at `meta:seed_version`. Stable listing records are
written before the marker. Hive does not provide a cross-record transaction
for this flow, so an interrupted seed may replay the same idempotent keys on
the next launch. Once the marker exists, an empty collection stays empty and
dates are not regenerated.

One invalid record fails the whole read. Partial presentation would conceal
possible data loss when no telemetry, repair UI, or user-controlled recovery
exists. Newer seed/schema versions fail rather than being overwritten.

Android backup and device transfer are disabled and explicitly excluded
because restoring the encrypted box without its secure key produces unusable
data. iOS uses device-bound, non-synchronizing Keychain accessibility and
committed Keychain entitlements.

The UI never treats an optimistic copy as persisted. A details view model
receives an immutable result from the repository, updates the visible listing
only after storage succeeds, and sends that result back to the feed. Local
origin is sufficient for this offline slice; future server identity and
ownership checks must be server-authoritative.

Feed time logic lives in a domain timing helper and `FeedViewModel`, using the
same injected clock as creation. Today and Ending Soon are presentation
queries over stored values and do not rewrite them. Filtered navigation passes
the selected immutable `Listing` value rather than a display-list index, so a
filtered order cannot open the wrong record.

Accessibility remains a UI-layer concern. Standard Material controls retain
their framework semantics, while custom composite controls own one deliberate
semantic boundary and executable action. A small heading widget sets both the
Flutter 3.44 `header` property and `headingLevel` for later engine behaviour.
Focus, traversal, and live-region changes do not cross the repository or
storage boundaries.

Reset is a repository product operation, not a generic settings clear. The
store deletes the complete named box without opening/decrypting it, then
deletes only the matching secure-storage key. Box deletion happens first so a
failure cannot strand ciphertext after discarding its only usable key. Normal
initialization generates a fresh key and restores the existing nine samples;
schema version 1 and seed version 1 do not migrate. Partial failure is
reported and remains retryable. This is practical cryptographic reset, not
forensic physical erasure.

The release remains permission-minimal and has no product network permission.
Screenshot blocking remains deliberately deferred because the current product
has no credentials, payments, medical record, or private chat.

## Alternatives considered

- **In-memory fallback after failure:** rejected because it would hide
  persistence loss and weaken the security decision.
- **SQLite/Drift:** not selected because the current dataset is nine flat
  records with one full read; relational queries, joins, and schema tooling do
  not yet justify the additional surface.
- **Direct storage calls from widgets:** rejected because presentation would
  become coupled to encryption, seeding, and migration.
- **Hive object adapters/code generation:** rejected to keep the immutable
  domain model persistence-agnostic and the stored schema explicit.
- **Backend-first storage:** deferred because it adds identity, network
  availability, authorization, and remote-data decisions before the local flow
  is validated.
- **Hosted AI or broad architecture layers:** outside this slice and contrary
  to the narrow offline boundary.
- **Widget-built persisted listings:** rejected because protected fields,
  validation, IDs, and mutation ordering belong at the repository boundary.
- **`box.clear()` reset:** rejected because it retains the same physical box
  and encryption key and cannot provide the intended fresh-key recovery.
- **Delete all secure values:** rejected because reset owns only the ViharLoop
  database key and must preserve unrelated future secure values.

## Consequences accepted

- The feed and details expose persistent private markers, and local-origin
  records expose owner-controlled Close/Reopen.
- Local records and timestamps survive normal close/reopen with the same key.
- Clearing data or uninstalling loses both key and listings. The in-product
  reset deliberately replaces them with a fresh key and fictional samples;
  there is still no sync or multi-device migration.
- Wrong-key, malformed-key, unknown-version, and corrupt-record conditions
  produce the existing retryable friendly failure state without repair.
- Encryption reduces plaintext exposure at rest but does not protect a rooted,
  unlocked, compromised, or instrumented device.
- Android is the verified primary platform. iOS source configuration exists,
  but runtime Keychain verification needs a full Xcode environment.

## Future change points

Future mutations should continue to add only workflow-backed methods. Schema or seed changes need explicit
migrations at the codec/store boundary. A backend would reverse local-only
trust, backup, and telemetry assumptions and requires a new ADR.

Future Draft Assist may create an editable `ListingDraft`, but it and any
deterministic fallback must pass `ListingPrivacyValidator` and the repository
path and can never persist directly. A future backend must also replace the
current local-origin ownership assumption with authenticated,
server-authoritative validation and authorization.
