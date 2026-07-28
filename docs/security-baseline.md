# Security baseline

Section 2 remains local-only: there is no backend, HTTP client, authentication,
analytics, telemetry, or hosted-service secret. Listing data uses broad
Vidyavihar areas and does not contain an exact address.

## Five security decisions

### 1. Secrets

The app has no API keys or service credentials. It generates one random
32-byte Hive database key and stores its Base64 representation under
`vihar_loop.listings.encryption_key.v1` through FlutterSecureStorage. The key
is not in Dart source, assets, committed configuration, seed data, or Hive.

Android uses the package's standard non-biometric `AndroidOptions`, backed by
Android Keystore. iOS uses a non-synchronizing,
`first_unlock_this_device` Keychain item so the key is device-bound and is not
synchronized through iCloud.

### 2. Client/server trust boundary

There is still no server. All records are local fictional product data.
Client-side flags must not become authoritative for future identity, payment,
permission, or moderation decisions. A future server needs independent
authentication, authorization, and input validation.

### 3. Data at rest

Listing values are schema-versioned JSON strings inside an encrypted Hive CE
box. The database key is held separately by platform secure storage. Decoding
validates every persisted field, code, date, neighbourhood, and key/ID
relationship. Unsupported, corrupt, or wrong-key data fails the complete read;
there is no plaintext or in-memory fallback and no automatic deletion.

This protects copied database bytes from casual inspection without the key. It
does not protect data while the app reads it on an unlocked device, or against
a rooted, compromised, debugged, or instrumented device. It is not end-to-end
encryption.

### 4. Certificate pinning

Certificate pinning is not applicable because ViharLoop has no remote API or
network client. It is deferred until a real transport threat model and
certificate-rotation plan exist.

### 5. Telemetry

No analytics, crash reporting, screenshots, remote logs, or telemetry leave
the device. This also means corrupt-data failures have no automatic diagnostic
channel.

## Backup, key loss, and platform status

Android sets `allowBackup="false"` and excludes app-data domains from legacy
backup and Android 12+ cloud-backup/device-transfer rules. Local data therefore
does not intentionally migrate through Android backup. OEM behavior cannot be
guaranteed by `allowBackup` alone, which is why explicit extraction rules are
also committed.

Uninstalling or clearing app data removes the local key and listings. A lost
or malformed key makes the existing encrypted box unreadable and is not
silently replaced. An explicit user-controlled reset is a future feature.

iOS Debug/Profile and Release entitlements declare Keychain access. Source
configuration is validated, but runtime Keychain behavior remains unverified
because full Xcode is unavailable.

Section 2 has schema and seed version 1 but no migration framework. A future
schema change needs an explicit, tested migration or repair path; corruption
must not be hidden by reseeding.
