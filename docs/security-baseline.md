# Security baseline

Section 1 has no backend, HTTP client, API key, authentication token,
analytics, telemetry, or persistent database. Listing data is fictional and
contains broad areas only: no exact address or precise location.

## Five security decisions

### 1. Where secrets live

There are no secrets in Section 1 and no `.env` file. A future random
encryption key will live in platform secure storage. It will not be placed in
Dart source, assets, generated configuration committed to Git, or sample data.

**Consequence:** there is currently no secret lifecycle to validate. Adding
any service credential later requires a new threat and configuration review.

### 2. Client/server trust boundary

There is no server. All current data is bundled sample data behind a local
repository boundary. A future remote API must treat every client-supplied
value as untrusted and enforce authorization and validation server-side.

**Consequence:** Section 1 does not provide identity, authorization, abuse
controls, or server-backed integrity.

### 3. Encryption at rest and key location

No persistent data is written in Section 1. Section 2 plans an encrypted local
store behind `ListingRepository`, using a random encryption key held by
platform secure storage.

**Consequence:** the current in-memory sample data disappears with the
process. The later design still cannot protect data while the device is
unlocked and the app is legitimately accessing it; backup and reset behaviour
also require explicit tests.

### 4. Certificate-pinning stance

Certificate pinning is not applicable because there is no remote API or HTTP
client. It is explicitly deferred. If a server is introduced, the transport
threat model, certificate rotation, recovery path, and whether platform TLS is
sufficient must be reviewed before choosing pinning.

**Consequence:** no pin or network-security configuration is claimed.

### 5. Telemetry leaving the device

No analytics, crash reporting, logging backend, or telemetry package exists.
Nothing is intentionally sent off-device.

**Consequence:** maintainers receive no remote operational diagnostics. Any
future telemetry must be opt-in where appropriate, minimized, documented, and
checked for listing content or location leakage.

## Current limits

Section 1 does not yet validate user-entered content because it has no create
flow. It also does not implement encrypted persistence, key loss recovery,
local data reset, screenshot protection, or a complete privacy review. The
sample records must not be treated as evidence that later user data is safe.
