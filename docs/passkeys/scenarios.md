# Passkey Implementation Scenarios

Four implementation scenarios for adding passkey support to prizm, with
requirements, feasibility, and trade-offs for each.

## Scenario A: Store and display passkey cipher items

**What it does:** Parse `fido2Credentials` from the Vaultwarden/Bitwarden
API, display passkey credentials in the UI, sync them back to the server.

**How Bitwarden does this:** The server stores passkeys as
`fido2Credentials` arrays on login cipher items. The data structure is:

```json
"login": {
  "fido2Credentials": [
    {
      "credentialId": "...",
      "keyType": "public-key",
      "keyAlgorithm": "ECDSA",
      "keyCurve": "P-256",
      "keyValue": "...",
      "rpId": "www.passkeys.io",
      "userHandle": "...",
      "userName": "...",
      "counter": "0",
      "rpName": "passkeys.io",
      "userDisplayName": "...",
      "discoverable": "true",
      "creationDate": "2024-06-14T12:34:05.183Z"
    }
  ]
}
```

Vaultwarden supports this via PR #3593 (merged). The config flag
`fido2-vault-credentials: true` enables it.

**What prizm needs to do:**
- Parse the `fido2Credentials` field from cipher API responses
- Add a UI to display passkey credentials (credential ID, RP ID, user
  name, creation date)
- Sync changes back to the server

**Requirements:**

| Requirement | Needed? |
|-------------|---------|
| Paid Developer Program | No |
| Apple entitlements | No |
| AASA file | No |
| Associated Domains | No |

**Feasibility:** Build now with free Apple ID. This is the most
straightforward feature — it's vault data management, not cryptography.

---

## Scenario B: Software authenticator (in-app key generation)

**What it does:** Prizm generates an ECDSA P-256 keypair using CryptoKit,
signs WebAuthn challenges, and stores the encrypted private key as a
`fido2Credentials` entry on the login cipher.

**How Bitwarden does this:** The browser extension implements a
software WebAuthn authenticator in TypeScript
(`Fido2AuthenticatorService`). It intercepts
`navigator.credentials.create()` / `navigator.credentials.get()` calls,
generates keypairs in JavaScript, signs challenges, and stores the
encrypted private key in the vault. No Secure Enclave, no
`ASAuthorizationPlatformPublicKeyCredential`, no Associated Domains.

**What prizm needs to do:**
- Generate ECDSA P-256 keypairs using `CryptoKit`
- Construct WebAuthn `authenticatorData` + `clientDataHash` and sign
  with the private key
- Build CBOR-encoded `attestationObject` for registration
- Store the encrypted private key as `fido2Credentials` on the login
  cipher
- Sync to Vaultwarden

**Limitation:** A native macOS app cannot intercept browser WebAuthn
ceremonies the way a browser extension can. Prizm can create and store
passkeys, and display/use them, but the browser won't automatically
offer prizm-stored passkeys during website login unless prizm is also
registered as a system Credential Provider Extension (Scenario C).

**Practical use:** Create passkeys in prizm, sync to vault, use them
via the Bitwarden browser extension (which reads the same vault) or by
exporting the credential.

**Requirements:**

| Requirement | Needed? |
|-------------|---------|
| Paid Developer Program | No |
| Apple entitlements | No |
| AASA file | No |
| Associated Domains | No |

**Feasibility:** Build now with free Apple ID. Pure cryptography + vault
sync. No Apple platform integration needed.

---

## Scenario C: System AutoFill / Credential Provider Extension

**What it does:** Prizm registers with macOS as a system-level
credential provider. When a user focuses a login field in Safari or
another app, macOS offers prizm-stored credentials (passwords and
passkeys) in the system dialog.

**How Bitwarden does this:** Bitwarden has been building a native macOS
Credential Provider Extension using `ASCredentialProviderViewController`
and `ASCredentialIdentityStore`. The extension communicates with the
desktop app via IPC. Both the host app and the extension require the
`com.apple.developer.authentication-services.autofill-credential-provider`
entitlement.

**Status in Bitwarden:** As of April 2026, users report that Bitwarden
still does not appear in the macOS system-level passkey provider dialog
(issue #19974). Only iCloud Keychain shows up. This is an active area of
development for Bitwarden itself.

**What prizm needs to do:**
- Create a Credential Provider Extension target (`*.appex`)
- Implement `ASCredentialProviderViewController`
- Add `com.apple.developer.authentication-services.autofill-credential-provider`
  entitlement to both the host app and the extension
- Set up IPC between the extension and the main app
- Publish credential identities to `ASCredentialIdentityStore`
- Handle passkey assertion and registration requests via
  `ASCredentialProviderExtensionContext`

**Domain setup:** For passkey support, the relying party domain must be
declared as an Associated Domain
(`webcredentials:example.com`) and an AASA file must be hosted at
`https://<domain>/.well-known/apple-app-site-association`.

For prizm connecting to user-specified Vaultwarden servers, this is
architecturally challenging:
- Associated Domains has a 100-entry limit per app
- Each Vaultwarden domain would need its own AASA file
- The AASA file must list prizm's App ID (Team ID + bundle ID)

With 2-3 domains (official Bitwarden + private Vaultwarden on
`hochguertel.work`), this is feasible. The AASA file for
`vaultwarden.hochguertel.work` would look like:

```json
{
  "webcredentials": {
    "apps": [ "TEAMID.com.prizm" ]
  }
}
```

**Requirements:**

| Requirement | Needed? |
|-------------|---------|
| Paid Developer Program | **Yes** |
| `autofill-credential-provider` entitlement | **Yes** |
| `associated-domains` entitlement | **Yes** (for passkeys) |
| AASA file on relying party domain | **Yes** (for passkeys) |
| Credential Provider Extension target | **Yes** |

**Feasibility:** Blocked until Apple Developer Program membership is
activated. Even Bitwarden hasn't fully shipped this on macOS yet.

---

## Scenario D: YubiKey / hardware security key (CTAP2 client)

**What it does:** Prizm acts as a CTAP2 client, communicating with a
YubiKey over USB or NFC. The YubiKey generates and stores the private
key in its secure element. Prizm mediates the WebAuthn ceremony: sends
the challenge to the YubiKey, receives the signed assertion, and stores
the credential metadata (credential ID, RP ID, user handle) in the
vault. The private key never leaves the YubiKey.

**How this works:** This is the standard FIDO2 security key flow. The
authenticator is the hardware key, not the platform. No Apple
entitlements are needed because the OS is not involved in the WebAuthn
ceremony — prizm talks directly to the YubiKey via USB HID.

**What prizm needs to do:**
- Add a Swift CTAP2 library or implement CTAP2 over USB HID
- Implement WebAuthn client logic (construct `clientDataJSON`,
  `authenticatorData`, verify responses)
- Store credential metadata in the vault as `fido2Credentials`
- Support multiple YubiKeys and credential discovery

**Requirements:**

| Requirement | Needed? |
|-------------|---------|
| Paid Developer Program | No |
| Apple entitlements | No |
| AASA file | No |
| Associated Domains | No |
| CTAP2 library for Swift | Needed (may need to write or port) |

**Feasibility:** Build now with free Apple ID. The main work is
implementing or porting a CTAP2 client library to Swift. No Apple
platform integration needed.

---

## Summary comparison

| Scenario | What | Paid license? | Apple entitlements? | AASA file? | Works now? |
|----------|------|--------------|--------------------|-----------| -----------|
| A | Store/display passkeys from vault | No | No | No | Yes |
| B | Software authenticator (in-app keygen) | No | No | No | Yes |
| C | System AutoFill/Passkey provider | **Yes** | Yes | Yes | No (blocked) |
| D | YubiKey CTAP2 client | No | No | No | Yes (needs CTAP2 lib) |

## Recommendation

For the "only me, one MacBook" case without an active paid Developer
Program membership:

- **Start with Scenario A** — most useful, least work, no license
  needed. Users want to see and manage their passkey credentials in the
  vault.
- **Scenario B** can be built alongside A — it adds the ability to
  create passkeys inside prizm using CryptoKit.
- **Scenario D** is a natural extension if YubiKey support is desired —
  the private key stays on the hardware, prizm just mediates.
- **Scenario C** is blocked on the Developer Program activation and is
  architecturally the hardest (even Bitwarden hasn't fully shipped it
  on macOS). It can wait.
