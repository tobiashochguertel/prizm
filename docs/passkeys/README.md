# Passkey Support Research

Research into what it would take to add passkey support to prizm,
covering the Apple Developer Program requirements, how the official
Bitwarden app and Vaultwarden handle passkeys, and which implementation
scenarios are feasible today.

## Two distinct features

"Passkey support" means different things. This document separates them
because the requirements differ dramatically.

### Touch ID / Face ID biometric unlock (already implemented)

Prizm already supports biometric vault unlock via `LocalAuthentication`
and `SecAccessControlCreateWithFlags(.biometryCurrentSet)`. The
biometric keychain item stores the vault key, and Touch ID gates access
to it.

**No paid Apple Developer Program membership required for local
development.** A free Apple ID (Personal Team) is sufficient.

The `keychain-access-groups` entitlement in `Prizm.entitlements` works
with a free Apple ID — Xcode auto-manages the provisioning profile. The
only limitation is the profile is machine-bound, so the app only runs on
the Mac that signed it. For a single-Mac "only me" setup this is
irrelevant.

Prizm already handles the unsigned-build case gracefully:
`KeychainService` probes whether the data protection keychain is
writable and falls back to the legacy login keychain for teamless builds
(e.g. Homebrew distribution without a Team ID).

| Scenario | Free Apple ID | Paid Developer Program |
|----------|--------------|----------------------|
| Local dev/build | Works | Works |
| Biometric keychain access | Works (data protection keychain) | Works |
| Distribute to other Macs | No (machine-bound profile) | Yes (Developer ID signing) |
| Homebrew/unsigned distribution | Falls back to login keychain (no biometric) | N/A |

### Platform Passkeys (not yet implemented)

This is the feature prizm's README explicitly lists as "not supported."
Adding it has several possible architectures, each with different
requirements. See [scenarios.md](./scenarios.md) for the full analysis.

## Apple Developer Program membership

A paid Apple Developer Program membership ($99/year) is required for
some passkey-related features but not all. The key differentiator is
whether the feature needs an Apple **entitlement** that only a paid
provisioning profile can include.

Entitlements that require a paid membership:
- `com.apple.developer.associated-domains` — needed for
  `ASAuthorizationPlatformPublicKeyCredential` (native platform
  authenticator)
- `com.apple.developer.authentication-services.autofill-credential-provider`
  — needed for system AutoFill Credential Provider Extension

Entitlements/features that work with a free Apple ID:
- `LocalAuthentication` (Touch ID / Face ID) — no special entitlement
- `Security` framework keychain with `keychain-access-groups` — works
  with free Apple ID (machine-bound profile)
- `CryptoKit` — no entitlement needed
- `AuthenticationServices` (software authenticator, not platform
  authenticator) — no entitlement needed

## Current developer situation

The developer (tobiashochguertel) paid for an Apple Developer Program
membership in February 2026 but it has not been activated after 7
months. Apple was contacted again on the most recent Saturday. Normal
activation time is 24-48 hours, so this is an abnormal delay — likely an
identity verification hold or billing mismatch.

Actions to pursue:
1. Check status at developer.apple.com/account
2. Look for pending identity verification actions
3. Apple Developer Support: +1-408-974-4897 (option 3, then 4)
4. Use the Contact Us form with "Membership" category
5. Last resort: credit card dispute for services not rendered

## References

- [Apple: Accessing Keychain Items with Face ID or Touch ID](https://developer.apple.com/documentation/localauthentication/accessing-keychain-items-with-face-id-or-touch-id)
- [Apple: Supported capabilities (macOS)](https://developer.apple.com/help/account/reference/supported-capabilities-macos/)
- [Apple: Connecting to a service with passkeys](https://developer.apple.com/documentation/authenticationservices/connecting-to-a-service-with-passkeys)
- [Apple Developer Forums: Passkeys in apps require Associated Domains](https://developer.apple.com/forums/thread/714440)
- [Apple: AutoFill Credential Provider entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.authentication-services.autofill-credential-provider)
- [Bitwarden: Storing passkeys](https://bitwarden.com/help/storing-passkeys/)
- [Bitwarden clients: Fido2AuthenticatorService](https://github.com/bitwarden/clients/blob/main/libs/common/src/vault/services/fido2/fido2-authenticator.service.ts)
- [Bitwarden clients: macOS autofill extension PR #13051](https://github.com/bitwarden/clients/pull/13051)
- [Bitwarden clients: macOS Native Passkey Provider PR #13963](https://github.com/bitwarden/clients/pull/13963)
- [Bitwarden clients: Passkey provider not appearing in macOS dialog — issue #19974](https://github.com/bitwarden/clients/issues/19974)
- [Vaultwarden: Passkey storage PR #3593](https://github.com/dani-garcia/vaultwarden/pull/3593)
- [Vaultwarden: WebAuthn login PR #7297](https://github.com/dani-garcia/vaultwarden/pull/7297)
- [Vaultwarden forum: fido2Credentials JSON structure](https://vaultwarden.discourse.group/t/importing-passkeys-from-keepassxc-to-vaultwarden/4985)
- [flutter_secure_storage: keychain-access-groups with free Apple ID](https://github.com/juliansteenbakker/flutter_secure_storage/issues/1176)
