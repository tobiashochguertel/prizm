# Patch Promotion Policy (dev.patch → main)

`main` is the stable branch. A patch moves from `dev.patch` to `main` only
when all gates below pass and a human approves the promotion. Promotion is
**manual** — never automated.

## When to promote

- The patch has been live on `dev.patch` long enough to be validated in real
  use (no minimum duration, but at least one full sync cycle should have
  passed without the sync workflow failing).
- `main` is synced to the latest upstream release tag before the merge.
- Breaking changes (cipher format, keychain schema, app bundle identifiers)
  require explicit user sign-off and a note in the merge commit.
- Patches based on unmerged upstream PRs are promoted only on explicit
  decision — the fork then owns maintaining them against future upstream
  releases.

## Mandatory gates (all must pass)

1. **Test suite green:**
   ```bash
   xcodebuild test \
     -project "Prizm/Prizm.xcodeproj" \
     -scheme "Prizm" \
     -destination "platform=macOS" \
     CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
   ```

2. **Production build clean:**
   ```bash
   xcodebuild \
     -project "Prizm/Prizm.xcodeproj" \
     -scheme "Prizm" -configuration Release \
     CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
     build
   ```

3. CI test workflow green on `dev.patch`

4. `git apply --check` + `git apply --reverse --check` against a clean
   checkout of `main`

5. Full sync simulation in a scratch worktree: revert patched files →
   merge upstream → `apply_patches.sh` re-applies (what a real sync run
   does). If patches overlap (multiple `.patch` files touching the same
   files), verify them in order: revert → apply 001 → apply 002 → …

6. **Documentation gate** — every promoted feature ships with:
   - Updated user-facing docs (README, guides) if the feature changes
     behavior, config keys, or app surface
   - A note in the merge commit describing the change

## Process

```bash
git checkout main
git fetch upstream --tags
# 1. main must be at the latest upstream release tag (sync via workflow if behind)

# 2. Merge dev.patch
git merge --no-ff dev.patch -m "merge: promote <description> to main

Breaking changes: <none | list>
Approved by: <name>"

# 3. Update the fork's patch table in FORK-STRATEGY.md (Branch column -> main + dev.patch)

# 4. Push and verify
git push origin main
git worktree add --detach /tmp/prizm-promo-check main
# run apply_patches.sh there: all promoted patches must report "already applied"
```

## Rollback

If a promoted patch breaks on `main`, revert it there without touching
`dev.patch`:

```bash
git checkout main
git revert <merge-commit> -m 1
git push origin main
```

The patch stays on `dev.patch` until fixed, then the promotion process
repeats.

## Checklist

- [ ] Sync cycle passed on `dev.patch` (workflow green)
- [ ] `main` at latest upstream release tag
- [ ] Tests green (gate 1)
- [ ] Production build clean (gate 2)
- [ ] CI green on `dev.patch` (gate 3)
- [ ] Apply + reverse checks against clean `main` (gate 4)
- [ ] Sync simulation in scratch worktree (gate 5)
- [ ] Overlapping patches (same files in multiple .patch files) verified in
      order: revert → apply each patch sequentially
- [ ] User-facing docs updated (gate 6)
- [ ] Breaking changes noted + approved
- [ ] Patch table in FORK-STRATEGY.md updated (main + dev.patch)
- [ ] `apply_patches.sh` reports "already applied" on `main` after push
