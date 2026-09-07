# Open Gaps

Identified gaps in the prizm codebase, each with a one-to-two sentence
description. Listed by category. Not all gaps need to be fixed — some
are deliberate YAGNI decisions (§VI). Gaps that violate the Constitution
are marked accordingly.

## Constitution violations

1. **Clipboard timeout is not configurable.** §III requires clipboard
   auto-clear to be "configurable," but the 30-second timeout is
   hardcoded as a literal in `VaultBrowserViewModel.copy()` and
   `PasswordGeneratorViewModel.copyToClipboard()`. Spec opened:
   `openspec/changes/configurable-clipboard-timeout/`.

2. **Sensitive UI data auto-clear is not implemented.** §III requires
   that "sensitive data shown in the UI MUST auto-clear after a
   configurable timeout." No such mechanism exists — revealed passwords
   and fields stay visible until manually re-masked or the app is
   locked.

## Missing features

3. **No passkey support.** The README states "Passkeys not supported."
   The `fido2Credentials` field is not parsed from API responses.
   Research and scenarios documented in `docs/passkeys/`.

4. **No "Copy as JSON" or "Copy Item ID" in context menus.** Item list
   context menus only offer Favorite/Unfavorite and Delete. There is no
   way to copy the raw cipher JSON or the item ID for debugging,
   scripting, or piping to external tools.

5. **No on-disk vault cache.** The vault is re-synced from the server on
   every launch. There is no local encrypted cache for offline access
   or faster startup. This may be a deliberate YAGNI decision.

6. **No bitwarden.com support.** v1 scope is self-hosted servers only
   (Vaultwarden or Bitwarden self-hosted). The Constitution explicitly
   defers bitwarden.com to v2.

7. **No browser extension or autofill integration.** Copy-paste is the
   only workflow for using credentials outside the app. No system
   Credential Provider Extension exists (see `docs/passkeys/scenarios.md`
   Scenario C).

## Code quality

8. **Duplicated clipboard copy logic.** The copy-to-clipboard +
   auto-clear pattern is duplicated in `VaultBrowserViewModel` and
   `PasswordGeneratorViewModel` with identical structure but hardcoded
   values. Meets the §VI threshold (two call sites; a third would
   trigger extraction).

9. **`AppContainer` instantiates all dependencies eagerly.** All use
   cases and repositories are created at launch with no lazy
   initialization. Fine for current app size but could affect startup
   time as the app grows.

## Fork-specific

10. **`main` branch tracks upstream `main`, not a release tag.** The
    fork strategy (`docs/FORK-STRATEGY.md`) specifies `main` should
    track the latest upstream release tag (`v1.4.3`), but `main`
    currently sits at upstream `main` HEAD with an additional revert
    commit.

11. **No patches yet.** The `.github/patches/` directory is empty. No
    custom features have been built on `dev.patch` yet — only the
    fork-strategy infrastructure and documentation commits exist.

## External blockers

12. **Apple Developer Program membership not activated.** Paid in
    February 2026, still not active after 7 months. Blocks Scenario C
    (system Credential Provider Extension) and Developer ID
    distribution. Does not block Scenarios A, B, or D from
    `docs/passkeys/scenarios.md`.
