# Local storage note

ViharLoop uses Hive CE because Section 2 has one small, flat local collection
and no relational query requirement. Records are JSON strings rather than Hive
objects so the domain model stays persistence-agnostic and the stored contract
has an explicit version.

## Names and versions

- Encrypted box: `vihar_loop_listings_v1`
- Listing key: `listing:<listing-id>`
- Seed marker: `meta:seed_version`
- Secure-storage identifier:
  `vihar_loop.listings.encryption_key.v1`
- Record schema version: 1
- Seed version: 1
- Dates: UTC ISO-8601 strings, decoded to the appropriate local `DateTime`
- Enums: explicit stable codes, never enum indexes or UI labels

On first access, a missing secure value causes Hive's secure generator to
create one random 32-byte key. Its Base64 form is saved through
FlutterSecureStorage; the key is never stored in Hive. Android uses the
standard non-biometric Keystore path. iOS uses a non-synchronizing,
device-bound `first_unlock_this_device` Keychain item.

When no seed marker exists, all nine stable-ID records are encoded and written
before marker version 1. A stopped write may safely be replayed with the same
keys. Once the marker exists, records and timestamps are not regenerated, even
if the collection is empty.

Android backup, cloud restore, and device transfer are deliberately excluded.
iOS Keychain entitlement files are wired for Debug/Profile and Release, though
runtime verification awaits full Xcode.

Malformed keys, wrong keys, unsupported versions, unexpected keys, and corrupt
records fail the whole read. Nothing is deleted, repaired, reseeded, or moved
to plaintext automatically. Uninstall, clear-data, or key loss makes local
records unavailable. Future work needs an explicit user-controlled reset and
tested migration/repair paths.

Encryption is a regression-tested at-rest control: known fixture plaintext is
absent from raw box bytes, and a wrong key cannot normally open the box. This
is not a formal cryptographic audit and does not protect an unlocked, rooted,
compromised, or instrumented device.

Create, save, contacted, close, reset, and migration methods are intentionally
absent until their product workflows are implemented.
