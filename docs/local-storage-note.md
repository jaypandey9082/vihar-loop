# Local storage note

ViharLoop uses Hive CE because the current product has one small, flat local collection
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
records fail the whole read. Nothing is silently repaired, reseeded, or moved
to plaintext. The visible Privacy & data route provides the explicit recovery
operation described below.

Encryption is a regression-tested at-rest control: known fixture plaintext is
absent from raw box bytes, and a wrong key cannot normally open the box. This
is not a formal cryptographic audit and does not protect an unlocked, rooted,
compromised, or instrumented device.

`ListingLocalStore` provides exact-key `readById`, `insert`, `update`, and
`deleteAllData` operations. Insert rejects an existing `listing:<id>` key and never upserts;
it writes one complete schema-version-1 encrypted record and does not create
or change `meta:seed_version`. Update requires an existing key, validates the
current record, and replaces one complete versioned encrypted record without
touching seed metadata.

Created records therefore share record schema version 1 with seeds. The
repository constructs the local ID, local origin, open status, Vidyavihar
neighbourhood, creation time, and false Saved/Contacted markers, then calls
insert. Those records can use the existing update operation for Saved,
Contacted, Close, and Reopen. `LocalListingRepository` serializes create and
other mutations in call order; a failed mutation does not poison later work.

## Recoverable local-data reset

`deleteAllData` initializes Hive if needed and calls
`Hive.deleteBoxFromDisk('vihar_loop_listings_v1')` without `_openBox`, so a
wrong key, malformed key, or unreadable record cannot prevent removal. It
clears the cached box future, deletes the box first, and only then calls the
key store's targeted `deleteKey`. The secure value adapter uses
`FlutterSecureStorage.delete` with the same platform options as reads and
writes; it never calls `deleteAll`, so unrelated future secure values remain.

Box deletion failure leaves the key in place and reports a controlled storage
failure. If box deletion succeeds but key deletion fails, reset is reported as
incomplete and remains retryable; no samples are recreated until a later
successful attempt. This order avoids deleting the only usable key while its
ciphertext still exists.

The repository runs reset through the existing mutation queue. After both
deletions succeed it clears cached initialization and uses the normal seed path
and injected clock. Opening the new box creates a fresh random 32-byte key and
persists exactly the nine version-1 fictional samples. No local records,
Saved/Contacted markers, or local status changes are copied. `box.clear()` is
not used because it would retain both the physical box and key.

Record schema version 1, seed version 1, box name, key identifier, and seed
content remain unchanged. Reset is a practical cryptographic deletion
boundary, not certified physical erasure: inaccessible remnants may remain in
flash. Uninstall and app-data clearing also remove app-local data; reset is the
in-product recovery route that then reseeds fictional content.
