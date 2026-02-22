# Plan: Backport comfyui-complete to Older Branches

## Overview

Port `comfyui-complete.nix` and all its dependencies from `latest` branch to:
- `main` (ComfyUI 0.13.0)
- `v0.11.0` (ComfyUI 0.11.0)
- `v0.10.0` (ComfyUI 0.10.0)
- `v0.9.2` (ComfyUI 0.9.2)
- `v0.9.1` (ComfyUI 0.9.1)

---

## Current State

### Latest Branch (source)
- ComfyUI version: **0.14.2**
- 31 nix files in `.flox/pkgs/`
- Has `sources/`, `scripts/`, `workflows/` directories
- Includes pyarrow Darwin fix

### Target Branches
| Branch | ComfyUI Version | Current pkgs |
|--------|-----------------|--------------|
| main | 0.13.0 | comfyui.nix only |
| v0.11.0 | 0.11.0 | comfyui.nix only |
| v0.10.0 | 0.10.0 | comfyui.nix only |
| v0.9.2 | 0.9.2 | comfyui.nix only |
| v0.9.1 | 0.9.1 | comfyui.nix only |

---

## Files to Port

### Core Package Files (31 total)
```
.flox/pkgs/
├── comfyui-complete.nix          # Main package - needs version adjustment
├── comfyui.nix                   # Already exists, may need updates
├── comfyui-extras.nix            # Python env bundle
├── comfyui-plugins.nix           # Impact Pack
├── comfyui-impact-subpack.nix    # Impact Subpack
├── comfyui-custom-nodes.nix      # Community nodes
├── comfyui-controlnet-aux.nix    # ControlNet preprocessors
├── comfyui-videogen.nix          # Video generation nodes
├── comfyui-workflows.nix         # Default workflows
│
├── # ML packages (torch-agnostic)
├── comfyui-ultralytics.nix
├── comfyui-accelerate.nix
├── comfyui-clip-interrogator.nix
├── comfyui-facexlib.nix
├── comfyui-peft.nix
├── comfyui-pixeloe.nix
├── comfyui-sam2.nix
├── comfyui-thop.nix
├── comfyui-transparent-background.nix
├── open-clip-torch.nix
├── segment-anything.nix
├── spandrel.nix
├── timm.nix
│
├── # Supporting packages
├── color-matcher.nix
├── colour-science.nix
├── comfy-aimdo.nix
├── cstr.nix
├── ffmpy.nix
├── img2texture.nix
├── onnxruntime-noexecstack.nix
├── pyloudnorm.nix
└── rembg.nix
```

### Supporting Directories
```
sources/
├── color_matcher-0.6.0-py3-none-any.whl
├── ComfyUI-SafeCLIP-SDXL/
├── cstr-*.tar.gz
├── img2texture-*.tar.gz
└── workflows/

scripts/
├── comfyui-download-*.py
├── comfyui-setup
└── start
```

### Other Files
- `flake.nix` - For nix build support with pyarrow fix

---

## Implementation Strategy

### Option A: Cherry-pick + Modify (Recommended)

For each target branch:
1. Create a working branch from target
2. Cherry-pick commits from `latest` that add the package files
3. Modify `comfyui-complete.nix` to use correct ComfyUI version
4. Update `comfyui.nix` if needed
5. Test build
6. Merge to target branch

**Pros:**
- Preserves git history
- Easy to track what changed

**Cons:**
- May have merge conflicts
- Multiple cherry-picks needed

### Option B: Copy Files Directly

For each target branch:
1. Checkout target branch
2. Copy all files from `latest`
3. Modify versions
4. Commit as single change
5. Push

**Pros:**
- Simpler, no merge conflicts
- Cleaner single commit

**Cons:**
- Loses granular history

---

## Version Modifications Required

For each branch, modify `comfyui-complete.nix`:

```nix
# Change this line to match target version:
comfyuiVersion = "X.Y.Z";
```

The `fetchFromGitHub` hash will need to be updated for each version.

### Version Hash Lookup

Need to fetch hashes for each ComfyUI version:
```bash
nix-prefetch-github comfyanonymous ComfyUI --rev vX.Y.Z
```

---

## Implementation Steps

### Phase 1: Prepare (on latest)

1. Document current commit hash on `latest` for reference
2. Create list of all commits that added package files
3. Verify all packages build on `latest`

### Phase 2: Port to Each Branch

For each branch (main, v0.11.0, v0.10.0, v0.9.2, v0.9.1):

#### Step 1: Setup
```bash
git checkout <branch>
git checkout -b <branch>-comfyui-complete
```

#### Step 2: Copy Package Files
```bash
# From latest branch, copy:
git checkout latest -- .flox/pkgs/
git checkout latest -- sources/
git checkout latest -- scripts/
git checkout latest -- flake.nix
```

#### Step 3: Update ComfyUI Version
Edit `.flox/pkgs/comfyui-complete.nix`:
- Change `comfyuiVersion` to match branch
- Update `fetchFromGitHub` hash

#### Step 4: Update FLOX_BUILD_RUNTIME_VERSION
Increment to v8 for backport tracking:
```nix
cat > $out/share/comfyui/.flox-build-v8 << 'FLOX_BUILD'
FLOX_BUILD_RUNTIME_VERSION=8
description: Backport comfyui-complete to version X.Y.Z
...
```

#### Step 5: Test Build
```bash
flox build
# Verify comfyui-complete builds successfully
```

#### Step 6: Commit and Merge
```bash
git add -A
git commit -m "Add comfyui-complete package for ComfyUI vX.Y.Z"
git checkout <branch>
git merge <branch>-comfyui-complete
git push
```

### Phase 3: Verify

For each branch:
1. Clone fresh
2. Run `flox build`
3. Verify `result-comfyui-complete` exists
4. Check version marker

---

## Potential Issues

### 1. ComfyUI API Changes
Older versions may have different:
- Directory structures
- Configuration options
- Node requirements

**Mitigation:** Test each version; adjust setup script if needed.

### 2. Custom Node Compatibility
Some custom nodes may not work with older ComfyUI:
- Impact Pack versions
- ControlNet-Aux versions
- Video nodes

**Mitigation:** Pin compatible node versions per branch.

### 3. Python Package Compatibility
Some packages may need version adjustments for older ComfyUI.

**Mitigation:** Test and adjust as needed.

### 4. fetchFromGitHub Hashes
Each version needs its own hash.

**Mitigation:** Pre-compute all hashes before starting.

---

## Pre-computed Version Info

All hashes verified from existing branch files:

| Branch | Version | Git Tag | fetchFromGitHub Hash |
|--------|---------|---------|----------------------|
| latest | 0.14.2  | v0.14.2 | `sha256-rrkVEnoWp0BBFZS4fMHo72aYZSxy0I3O8C9DMKXsr88=` |
| main | 0.13.0  | v0.13.0 | `sha256-W2+4avF0XUrTO2rCC/okrkpIXInhbIW4NcbD8fpWuE8=` |
| v0.11.0 | 0.11.0  | v0.11.0 | `sha256-CcA3xTVmBVLGMtM5F74R2LfwafFDxFHZ1uzx5MvrB/4=` |
| v0.10.0 | 0.10.0  | v0.10.0 | `sha256-WVWKMXXOls9lYiNWFj164DP96V8IhRfTfxBI9CRprkE=` |
| v0.9.2 | 0.9.2   | v0.9.2  | `sha256-/QuoChUV6dsTeOcxCRfZ4e20H55LlY7bxd4PkpOElAM=` |
| v0.9.1 | 0.9.1   | v0.9.1  | `sha256-tAbXhLoN3tuML3R1AdJ18stleFv4w0nZcUoySP6W9+0=` |

---

## Execution Order

1. **main** (0.13.0) - Closest to latest, least changes expected
2. **v0.11.0** - Recent version
3. **v0.10.0** - Recent version
4. **v0.9.2** - Older, may need more adjustments
5. **v0.9.1** - Oldest, most likely to need adjustments

---

## Success Criteria

For each branch:
- [ ] `flox build` succeeds
- [ ] `result-comfyui-complete` created
- [ ] `.flox-build-v8` marker present
- [ ] Version matches branch (check setup script output)
- [ ] Build works on both Linux and Darwin

---

## Rollback Plan

If a branch has issues:
1. Keep changes in feature branch (don't merge to target)
2. Document issues
3. Fix and re-test before merging

---

## Estimated Effort

| Branch | Complexity | Notes |
|--------|------------|-------|
| main | Low | Very close to latest |
| v0.11.0 | Low | Recent version |
| v0.10.0 | Low-Medium | Some API changes possible |
| v0.9.2 | Medium | Older, more testing needed |
| v0.9.1 | Medium | Oldest supported version |

Total: ~2-3 hours for all branches, assuming no major compatibility issues.
