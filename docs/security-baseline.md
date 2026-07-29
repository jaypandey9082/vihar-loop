# Security and privacy evidence

Section 7 remains a local-only product: there is no backend, application
network client, authentication, analytics, crash reporting, remote logging, or
hosted-service secret. This is reviewable engineering evidence, not MASVS,
OWASP, privacy, or security certification.

Draft Assist adds no network client, hosted API, model key, model file, model
runtime, permission, or dependency. It validates Description input and
suggested Title output with the existing validators, logs and caches neither,
keeps suggestions transient, and cannot call storage. Final repository
validation still runs before persistence.

## Data inventory

The encrypted local listing record contains title, description, category,
broad Vidyavihar area, contact preference, deadline, Open/Closed state,
Saved/Contacted markers, creation time, origin, stable ID, neighbourhood, and
schema version. The separate 32-byte database key is the only secret.

ViharLoop deliberately has no account, name, password, authentication token,
phone/email field, exact-address field, GPS/live location, images, payment
details, analytics identifier, remote user ID, or backend data. Contact
preference is stored; actual contact details are not collected as fields.

## Five MAL security decisions

### 1. Secrets

No long-lived secret ships inside the binary. A package-generated random
32-byte Hive key is Base64-encoded only for platform secure storage under
`vihar_loop.listings.encryption_key.v1`. It is absent from source, assets,
committed configuration, seed data, and Hive. Android uses standard
non-biometric secure-storage options backed by Android Keystore. iOS uses a
non-synchronizing `first_unlock_this_device` Keychain item.

### 2. Trust boundary

The form gives immediate errors, but `LocalListingRepository` normalizes and
revalidates every draft using the same `ListingDraftValidator` and
`ListingPrivacyValidator` before encrypted insertion. Persisted origin, status,
IDs, timestamps, and markers are repository-owned. UI visibility is not
authorization: local origin is only an offline device marker. A future backend
must authenticate ownership and revalidate all input server-side.

### 3. Data at rest and key

Complete schema-version-1 JSON records live in one encrypted Hive CE box. The
key lives separately in platform secure storage. Strict decoding rejects
unknown or malformed records; there is no plaintext or in-memory fallback.
Copied ciphertext without secure storage should not reveal normal content, but
encryption does not protect an unlocked, rooted, debugged, compromised, or
instrumented device while the app uses the data. It is not end-to-end
encryption.

### 4. Certificate pinning

Pinning is not applicable because no product transport exists. Adding it
without an endpoint, certificate lifecycle, and rotation plan would provide no
control. Revisit only with a real backend threat model.

### 5. Telemetry

No analytics, crash reporting, remote logs, or telemetry leaves the device.
Production source does not log listings, rejected text, records, or key
material. The trade-off is no automatic remote diagnostics for storage errors.

## Reversal cost

The repository/store/key boundaries keep a future storage replacement
contained. Versioned records make schema evolution explicit. In contrast,
introducing server identity, synchronization, telemetry, or model distribution
would reverse core privacy and trust assumptions and needs a new decision
review rather than a hidden incremental change.

## Threats and controls

| Threat | Current control | Limit |
| --- | --- | --- |
| Direct contact in free text | Deterministic phone/email/URL/social/payment patterns in UI and repository | Heuristics can be bypassed |
| Precise location in free text | Deterministic flat/room/house/shop/unit/door, wing/block/tower/floor, street/PIN/building/society/coordinate patterns | A landmark or unusual format may pass |
| Plaintext files | Encrypted Hive box; separate platform-secure key; raw-byte regression test | Runtime memory and compromised devices remain exposed |
| Sensitive logs | No production logging calls; exercised logcat canary scan | Exercised absence is evidence, not universal proof |
| Unusable restored ciphertext | Android backup/transfer disabled and excluded | OEM behaviour cannot be absolutely guaranteed |
| User cannot recover unreadable data | Privacy & data reset deletes the named box without opening it | Reset cannot recover the old content |
| Old key remains after reset | Box deletion precedes targeted key deletion | Key-deletion failure creates an honestly reported partial reset |
| Unrelated secure values deleted | `FlutterSecureStorage.delete(keyId)`, never `deleteAll()` | Platform secure-storage failure remains possible |

## Input-validation rules

Structural validation still requires a 5–80 character one-line title, a
15–500 character description, and a deadline from 15 minutes through seven
days ahead. Privacy checks then distinguish direct contact/payment from
precise location and show different corrective text. Ordinary numbers,
Unicode, Hindi, Marathi, punctuation, and broad phrases such as “Near
Vidyavihar station” remain allowed. Regex cannot prove free text is
address-free, so this is a deterministic guardrail rather than an address
parser.

## Key and reset lifecycle

Normal first access creates one random key only when the targeted secure value
is missing. Reset runs in the repository mutation queue:

1. Clear the cached box future and delete
   `vihar_loop_listings_v1` from disk without opening/decrypting it.
2. Delete only `vihar_loop.listings.encryption_key.v1`.
3. Clear repository initialization.
4. Run normal first-use seeding with the injected clock.
5. Generate a fresh key, write exactly nine fictional samples, and return the
   exact persisted unmodifiable collection.

`box.clear()` is intentionally insufficient because it keeps the physical box
and old key. If box deletion fails, key deletion does not run. If key deletion
fails after box deletion, the UI says reset could not finish and permits a
retry without falsely promising that old data is unchanged. Automated tests
cover both orders, retry, wrong/malformed keys, fresh key B, and rejection of
old key A. File/key deletion is a practical cryptographic reset, not guaranteed
physical flash overwrite.

## Backup policy

Android retains `allowBackup="false"` plus legacy and Android 12+ exclusion
rules for cloud backup and device transfer. The XML files validate and the
release merged manifest retains these declarations. The API 36 emulator listed
backup transports, but `bmgr backupnow com.jaypandey.viharloop` returned
`Backup is not allowed`; no restore was therefore possible or claimed. iOS
source entitlements retain the device-bound Keychain configuration; runtime
behaviour remains unverified because full Xcode is unavailable.

## Release permissions and components

The Section 6 release APK was inspected with the installed official Android SDK
`apkanalyzer` and `aapt`. It requests no location, contacts, phone, SMS,
camera, microphone, broad storage, notification, biometric, or INTERNET
permission. The only declared permission is AndroidX's app-specific
`DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, protected at signature level.
Debug/profile source sets alone contain Flutter's tooling INTERNET permission.

The launcher `MainActivity` is exported as required. AndroidX Startup's
provider is not exported. The AndroidX profile-install receiver is exported
but guarded by the signature-level `android.permission.DUMP`; no unexpected
exported service or provider was found.

## Logging, files, network, and telemetry

Static production scans found no `print`, `debugPrint`, `developer.log`,
logging package, record/key dump, `package:http`, Dio, `HttpClient`, socket,
WebSocket, Firebase, Sentry, analytics, crash-reporting, telemetry, or hosted
AI client. The existing workflow and upgrade check ran in airplane mode.
Certificate pinning remains inapplicable.

Temporary-Hive tests confirm known accepted title/description plaintext is
absent from raw box bytes, rejected privacy input is never inserted, reset
removes the old canary, and the old key does not normally open the new box.
On API 36, the exercised reset/relaunch logcat stream contained none of the
synthetic listing, email, phone, URL, payment, or address canaries. A targeted
`run-as` scan found none of the known listing canaries in the active Hive file,
and `/sdcard/Android/data/com.jaypandey.viharloop` contained no listing file.
These are regression checks, not proof that every system component can never
log UI content or a formal cryptographic audit.

## Supply chain and repository

| Direct package | Resolved version | Purpose and data handled |
| --- | --- | --- |
| `hive_ce` | 2.19.3 | Encrypted local listing records; no Android permission |
| `hive_ce_flutter` | 2.3.4 | Flutter path/init adapter for Hive; no user transport |
| `flutter_secure_storage` | 10.3.1 | Platform storage for only the database key; platform native code, no product permission |

Section 7 adds or upgrades no dependency and leaves `pubspec.lock`
semantically unchanged. `dart pub outdated` reported direct dependencies
current under the existing constraints; some transitive updates exist and
were deliberately not applied. This is a focused inventory, not
software-composition-analysis certification.

Tracked-file review found no API token, private key, certificate, keystore,
environment file, secure-storage value, Hive database, model, APK/AAB,
emulator snapshot, private screenshot, or absolute developer path. Box/key
identifiers and schema/seed versions are public identifiers, not secret key
material.

## Screenshot and Recents stance

`FLAG_SECURE` is deliberately not added. The product has no credential,
financial account, medical record, or private chat, and listings are intended
for local viewing. Blocking screenshots would not repair sensitive input and
would reduce ordinary utility. Background snapshots remain a residual risk if
a user bypasses validation; revisit if later scope adds credentials, private
messages, payments, or highly sensitive data.

## Residual risks and platform evidence

The Android API 36 upgrade preserved existing Section 5 records and markers,
showing no schema/seed migration. Automated Android/store tests prove reset
from unreadable data, fresh-key reseeding, and reopen persistence. The release
manifest, backup XML, dependencies, production source, and tracked repository
were audited as described above.

Remaining limits are heuristic validation, exposed runtime memory on an
unlocked/rooted/instrumented device, possible inaccessible flash remnants,
unauthenticated local origin, no server authorization, incomplete full
human-driven TalkBack coverage, and no full iOS Keychain runtime check.
