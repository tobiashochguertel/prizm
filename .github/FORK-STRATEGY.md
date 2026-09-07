# Fork Maintenance Strategy

This fork of [b0x42/prizm](https://github.com/b0x42/prizm) is kept
mergeable with upstream using a **revert-then-repatch** strategy.

## Branch model

| Branch | Tracks | Purpose |
|--------|--------|---------|
| `main` | Latest upstream release tag (e.g. `v1.4.3`) | Stable — well-tested patches only |
| `dev.patch` | `upstream/main` (latest development) | Unstable — experimental patches welcome |
| `feature/*` | Branched from `dev.patch` | Feature development (merged back when stable) |

**Always branch from `dev.patch`**, never from `main`.

## What lives where

### Tier 1: Per-developer config (NOT in this repo)

User-level config lives in `Prizm/LocalConfig.xcconfig` and is git-ignored:

- `DEVELOPMENT_TEAM` — Apple Developer Team ID
- Signing configuration

**Never commit this to the fork.** It's user-specific and would conflict.

### Tier 2: Source patches (in this repo)

Actual changes to upstream source files. These are the only things that risk
merge conflicts. Each patch has:

1. **A `.patch` file** in `.github/patches/` (named `NNN-description.patch`)
2. **An entry in `PATCHED_FILES`** in the sync workflow env var (modified files only — new files don't need listing)

Patches are applied by `.github/scripts/apply_patches.sh`, which loops over
all `.patch` files in `.github/patches/` in alphabetical order.

Current patches: _(none yet)_

## How the sync works

The `sync-upstream-and-fix.yml` workflow runs daily at 07:00 UTC (or manually).
It syncs both branches in parallel — `main` from the latest upstream release
tag, `dev.patch` from `upstream/main`.

### The revert-then-repatch sequence

For each branch, the workflow executes these steps:

```bash
# 1. Fetch upstream
git remote add upstream https://github.com/b0x42/prizm.git
git fetch upstream --tags --quiet

# 2. Determine what to merge
#    main:       latest upstream release tag (e.g. v1.4.3)
#    dev.patch:  upstream/main

# 3. Skip if already up to date
git merge-base --is-ancestor "$UPSTREAM_SHA" HEAD  # → nothing to do

# 4. Revert all PATCHED_FILES to upstream's version, then commit
#    This removes our custom changes from the working tree so the merge
#    won't conflict on those files.
.github/scripts/revert_patched_files.sh "$UPSTREAM_SHA" "$MERGE_REF"
#    → git checkout "$UPSTREAM_SHA" -- <each patched file>
#    → git commit -m "chore: revert patched files to upstream …"

# 5. Merge upstream (normal merge, no strategy override)
git merge "$MERGE_REF" --no-edit -m "chore: merge upstream …"
#    If this conflicts on non-patched files → FAIL LOUDLY (merge --abort, exit 1)

# 6. Re-apply all patches via apply_patches.sh
.github/scripts/apply_patches.sh
#    For each .github/patches/*.patch:
#      - If git apply --reverse --check passes → already applied, skip
#      - If git apply --check passes → git apply, continue
#      - Otherwise → FAIL LOUDLY (exit 1)

# 7. Commit the re-applied patches
git add -A
git commit -m "fix: re-apply custom patches after upstream merge …"

# 8. Push
git push origin <branch>
```

### Why revert-then-repatch instead of `--strategy-option=theirs`?

`--strategy-option=theirs` silently lets upstream overwrite custom patches.
The revert-then-repatch approach:

- **Guarantees patches are always re-applied** on the latest upstream code
- **Fails loudly** if upstream changed the surrounding code (`git apply` fails)
- **Fails loudly** if there are conflicts on files we don't patch
- **Never silently drops** a custom change

### Helper scripts

| Script | Purpose |
|--------|---------|
| `.github/scripts/revert_patched_files.sh` | Checks out each `PATCHED_FILES` entry from the upstream SHA, commits the revert |
| `.github/scripts/apply_patches.sh` | Loops over `.github/patches/*.patch`, applies each with idempotency check |

## Feature development

### Strategy A: New files only (no upstream conflicts)

**When:** Feature creates entirely new Swift files, no existing upstream files modified.

```bash
git checkout dev.patch
git checkout -b feature/my-feature
# ... develop (direct commits) ...
# Test
xcodebuild test -project "Prizm/Prizm.xcodeproj" -scheme "Prizm" -destination "platform=macOS"
# Merge back
git checkout dev.patch
git merge --no-ff feature/my-feature
git branch -d feature/my-feature
```

**No `.patch` file needed.** New files don't exist in upstream, so the sync
workflow never touches them.

### Strategy B: Modifies upstream files (needs `.patch` file)

**When:** Feature modifies files that already exist in upstream.

```bash
git checkout dev.patch
git checkout -b feature/my-feature
# ... develop (direct commits on feature branch) ...

# Generate the patch from the feature branch
MERGE_BASE=$(git merge-base feature/my-feature dev.patch)
git diff "$MERGE_BASE"..feature/my-feature -- <modified-files-only> \
    > .github/patches/NNN-description.patch

# Test
git apply --check .github/patches/NNN-description.patch
git apply --reverse --check .github/patches/NNN-description.patch

# Apply to dev.patch
git checkout dev.patch
git apply .github/patches/NNN-description.patch
git add .github/patches/NNN-description.patch <new-files>
git commit -m "feat: integrate <description> via .patch"

# Add modified files to PATCHED_FILES in:
#   .github/workflows/sync-upstream-and-fix.yml

# Clean up
git branch -d feature/my-feature
```

**Rules:**
- Modified files (exist in upstream) → go into the `.patch` file
- New files (don't exist in upstream) → committed directly to `dev.patch`
- Add modified files to `PATCHED_FILES` so the sync workflow reverts them

## Adding a new patch

### 1. Generate the `.patch` file

```bash
# From a feature branch
MERGE_BASE=$(git merge-base feature/my-feature dev.patch)
git diff "$MERGE_BASE"..feature/my-feature -- <modified-files-only> \
    > .github/patches/NNN-description.patch
```

### 2. Test the patch applies cleanly

```bash
# Dry-run
git apply --check .github/patches/NNN-description.patch

# Apply for real
git apply .github/patches/NNN-description.patch

# Verify the build
xcodebuild -project "Prizm/Prizm.xcodeproj" \
           -scheme "Prizm" -configuration Debug build

# Verify idempotency (reverse check should pass)
git apply --reverse --check .github/patches/NNN-description.patch

# Verify apply_patches.sh works with the new patch
.github/scripts/apply_patches.sh
```

### 3. Add modified files to `PATCHED_FILES`

In `.github/workflows/sync-upstream-and-fix.yml`, add each **modified** file
(not new files — those don't exist in upstream and don't need reverting) to
the `PATCHED_FILES` env var:

```yaml
env:
  PATCHED_FILES: |
    Prizm/Presentation/SomeView.swift
    Prizm/Data/SomeService.swift
```

### 4. Commit and push

```bash
git add -A
git commit -m "feat: integrate <description> via .patch"
git push origin dev.patch
```

## Patch promotion (dev.patch → main)

See [PROMOTION-POLICY.md](./PROMOTION-POLICY.md) for the full promotion
process and gates.

## Rules

- **Always branch from `dev.patch`** — not from `main`
- **Never edit upstream files directly on `dev.patch`** — use `.patch` files
- **New files don't need patches** — commit them directly
- **Test patches before committing** — `git apply --check` + build + idempotency
- **Add modified files to `PATCHED_FILES`** — in the workflow YAML
- **Keep feature branches short-lived** — merge back to `dev.patch` when stable
- **One logical change per `.patch` file** — don't combine unrelated changes
- **Name patches with zero-padded numbers** — `NNN-description.patch` (applied in alphabetical order)
- **Verify idempotency** — `git apply --reverse --check` must pass
- **Never use `--strategy-option=theirs`** — it silently drops changes
- **Follow the Constitution** — all patches must respect [CONSTITUTION.md](../CONSTITUTION.md) principles
