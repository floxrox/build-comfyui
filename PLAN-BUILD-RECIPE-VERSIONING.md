# Plan: Fix Workflow Permissions + Build Recipe Versioning

## Overview

Three changes to `comfyui-complete.nix`:

1. **Fix workflow permissions** - Add `chmod -R u+w` after copying workflows from the Nix store
2. **Build recipe versioning** - Introduce `FLOX_BUILD_RUNTIME_VERSION` marker that tracks build recipe iterations
3. **Log version at startup** - Print version to logs for debugging (visible in `flox services logs`)

---

## Problem 1: Workflow Permission Denied

### Root Cause

Files copied from the Nix store retain read-only permissions. The custom nodes setup correctly runs `chmod -R u+w` after copying, but the workflows setup does not.

### Fix

Add `chmod -R u+w "$target" 2>/dev/null || true` after copying workflows (line ~392 in comfyui-setup script).

---

## Problem 2: No Build Recipe Versioning

### Current State

- `RUNTIME_VERSION="1.1.0"` exists but only controls runtime directory rebuild
- No way to track when the build recipe itself changes
- Users can't easily tell which build iteration they have
- Hard to debug Flox publishing issues without knowing which build is running

### Solution: FLOX_BUILD_RUNTIME_VERSION Marker

Create a metadata file in the build output that:
1. Has the version in its filename (easy to find with glob)
2. Contains version + metadata inside (human-readable)
3. Lives in a predictable location
4. Gets printed to logs at startup for debugging

### File Location and Format

```
$out/share/comfyui/.flox-build-v7
```

Contents:
```
FLOX_BUILD_RUNTIME_VERSION=7
description: Fix workflow permissions, add build recipe versioning
date: 2026-02-22
changes:
  - Add chmod -R u+w after copying workflows to fix permission denied errors
  - Introduce FLOX_BUILD_RUNTIME_VERSION marker files
  - Print build version to logs at startup
```

### Why This Approach?

- **Filename contains version**: Scripts can glob for `.flox-build-v*` to find current version
- **Content is human-readable**: `cat` the file to see what changed
- **Hidden file**: Doesn't clutter directory listings
- **In share/comfyui**: Co-located with the ComfyUI installation
- **Logged at startup**: Visible in `flox services logs comfyui --follow` for debugging

---

## Implementation Steps

### Step 1: Add FLOX_BUILD_RUNTIME_VERSION Marker (in installPhase)

After removing mutable directories (line 183) and before custom nodes setup, add:

```nix
# FLOX_BUILD_RUNTIME_VERSION marker
# This tracks iterations of the build recipe, not ComfyUI version.
# Increment this when changing the build/setup logic.
cat > $out/share/comfyui/.flox-build-v7 << 'FLOX_BUILD'
FLOX_BUILD_RUNTIME_VERSION=7
description: Fix workflow permissions, add build recipe versioning
date: 2026-02-22
changes:
  - Add chmod -R u+w after copying workflows to fix permission denied errors
  - Introduce FLOX_BUILD_RUNTIME_VERSION marker files
  - Print build version to logs at startup
FLOX_BUILD
```

### Step 2: Update RUNTIME_VERSION

Bump `RUNTIME_VERSION` from `"1.1.0"` to `"1.2.0"` to force re-initialization on existing installs.

### Step 3: Fix Workflow Permissions

In the WORKFLOWS SETUP section of comfyui-setup (line ~391), change:

```bash
# Before
if [ ! -d "$target" ]; then
  echo "Installing workflow: $workflow_name" >&2
  cp -r "$workflow_dir" "$target"
fi

# After
if [ ! -d "$target" ]; then
  echo "Installing workflow: $workflow_name" >&2
  cp -r "$workflow_dir" "$target"
  chmod -R u+w "$target" 2>/dev/null || true
fi
```

### Step 4: Print Version to Logs at Startup

At the beginning of `setup_comfyui()` function (after finding comfyui_source), add:

```bash
# Print FLOX_BUILD_RUNTIME_VERSION for debugging
# This appears in: flox services logs comfyui --follow
local flox_build_marker
flox_build_marker=$(ls "$comfyui_source"/.flox-build-v* 2>/dev/null | head -1)
if [ -n "$flox_build_marker" ]; then
  echo "=============================================="
  echo "FLOX_BUILD_RUNTIME_VERSION: $(basename "$flox_build_marker" | sed 's/.flox-build-v//')"
  echo "ComfyUI Version: ${comfyuiVersion:-unknown}"
  echo "=============================================="
fi
```

This will output something like:
```
==============================================
FLOX_BUILD_RUNTIME_VERSION: 7
ComfyUI Version: 0.14.2
==============================================
```

---

## Files to Modify

| File | Changes |
|------|---------|
| `.flox/pkgs/comfyui-complete.nix` | Add `.flox-build-v7` marker, bump RUNTIME_VERSION, fix workflow chmod, add version logging |

---

## Verification

1. Build the package:
   ```bash
   cd ~/dev/build-comfyui
   flox build
   ```

2. Check FLOX_BUILD_RUNTIME_VERSION marker exists:
   ```bash
   cat result-comfyui-complete/share/comfyui/.flox-build-v7
   ```

3. Test version logging:
   ```bash
   flox activate
   # Should see:
   # ==============================================
   # FLOX_BUILD_RUNTIME_VERSION: 7
   # ComfyUI Version: 0.14.2
   # ==============================================
   ```

4. Test via service logs:
   ```bash
   flox services start comfyui
   flox services logs comfyui --follow
   # Should see FLOX_BUILD_RUNTIME_VERSION in output
   ```

5. Test on Darwin - workflow permissions:
   - Clear ~/comfyui-work
   - Activate environment
   - Verify workflows are writable:
     ```bash
     ls -la ~/comfyui-work/user/default/workflows/FLUX/
     rm ~/comfyui-work/user/default/workflows/FLUX/flux-txt2img.json  # Should succeed
     ```

---

## Future Iterations

When changing the build recipe in the future:

1. Increment the version number (v7 → v8)
2. Update the marker filename: `.flox-build-v7` → `.flox-build-v8`
3. Update the marker contents with description of changes
4. Optionally bump RUNTIME_VERSION if runtime directory needs rebuilding

This creates a clear audit trail of build recipe changes, and the version is always visible in service logs for debugging Flox publishing issues.
