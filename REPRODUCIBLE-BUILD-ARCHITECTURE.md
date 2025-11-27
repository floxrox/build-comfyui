# Reproducible Build Architecture for ComfyUI Flox Package

## Overview

This document describes the architecture pattern for ensuring long-term reproducibility of the ComfyUI Flox package build. The goal is that someone building `comfyui@0.3.75` in 2028 will get **exactly** the same binaries as building it in 2025.

## Core Principles

### 1. Hash-Based Source Pinning

Every external dependency MUST use cryptographic hashes to verify sources:

```nix
src = fetchFromGitHub {
  owner = "author";
  repo = "package";
  rev = "v1.2.3";  # Immutable git commit/tag
  hash = "sha256-abc123...";  # Cryptographic verification
};
```

**Why:** Git commits are immutable; hashes prove exact byte-for-byte source match.

### 2. Explicit Dependency Declaration

Never rely on:
- ❌ PyPI's "latest" version resolution
- ❌ Auto-downloaded wheels from transitive dependencies
- ❌ System packages or external package managers

Always declare:
- ✅ Every Python package explicitly in `.flox/pkgs/`
- ✅ Version pins with hashes
- ✅ Complete dependency tree

### 3. Multi-Layer Caching Strategy

Sources are cached at multiple levels:
1. **Nix binary cache** (`cache.nixos.org`) - mirrors sources indefinitely
2. **Flox catalog** - stores full build closures when you publish
3. **Git repository** - contains all `.nix` definitions
4. **Optional: Local vendoring** - `.flox/sources/` for critical dependencies

## Directory Structure

```
build-comfyui/
├── .flox/
│   ├── pkgs/                    # Custom Nix package definitions
│   │   ├── comfyui.nix         # Main package
│   │   ├── color-matcher.nix   # Custom Python package
│   │   ├── spandrel.nix        # Another custom package
│   │   └── ...
│   ├── sources/                 # (Optional) Vendored sources
│   │   ├── color-matcher-0.6.0.tar.gz
│   │   └── ...
│   └── env/
│       └── manifest.toml        # Flox environment config
├── assets/                      # Build assets (scripts, configs)
├── FLOX.md                      # Flox usage guide
├── REPRODUCIBLE-BUILD-ARCHITECTURE.md  # This file
└── USAGE.md
```

## Package Definition Pattern

### Template for Custom Python Packages

Use this template for every Python dependency not in nixpkgs:

```nix
# .flox/pkgs/<package-name>.nix
{ lib
, python3Packages
, fetchFromGitHub  # or fetchPypi
}:

python3Packages.buildPythonPackage rec {
  pname = "package-name";
  version = "1.2.3";
  format = "setuptools";  # or "pyproject", "wheel"

  # OPTION A: Fetch from GitHub (PREFERRED - more reliable)
  src = fetchFromGitHub {
    owner = "username";
    repo = "package-name";
    rev = "v${version}";  # or explicit commit: "abc123..."
    hash = "sha256-REPLACE_WITH_REAL_HASH";
  };

  # OPTION B: Fetch from PyPI (when GitHub not available)
  # src = fetchPypi {
  #   inherit pname version;
  #   hash = "sha256-REPLACE_WITH_REAL_HASH";
  # };

  # OPTION C: Use vendored source (maximum paranoia)
  # src = ../../.flox/sources/${pname}-${version}.tar.gz;

  # Declare ALL runtime dependencies explicitly
  propagatedBuildInputs = with python3Packages; [
    numpy
    scipy
    # ... all dependencies
  ];

  # Declare build-time dependencies
  nativeBuildInputs = with python3Packages; [
    setuptools
    wheel
  ];

  # Skip tests if no test suite or tests require network
  doCheck = false;

  # Verify package imports correctly
  pythonImportsCheck = [ "package_name" ];

  meta = with lib; {
    description = "Short description";
    homepage = "https://github.com/username/package-name";
    license = licenses.mit;  # or gpl3Only, etc.
    platforms = platforms.all;
  };
}
```

### How to Get the Hash

**Step 1:** Use a fake hash:
```nix
hash = lib.fakeHash;  # or "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
```

**Step 2:** Run the build:
```bash
flox build <package>
```

**Step 3:** Copy the correct hash from the error message:
```
error: hash mismatch in fixed-output derivation
  specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  got:        sha256-VNe0VBGCQ3w6Y/ky6mEmNBx4cJ8DnjHl1YoIj9LnInw=
```

**Step 4:** Replace `lib.fakeHash` with the correct hash.

## Main Package Architecture

### ComfyUI Package Structure

The main `comfyui.nix` should:

1. **Declare all custom packages** in the function signature:
```nix
{ lib
, python3
, fetchFromGitHub
, makeWrapper
, comfyui-frontend-package  # Custom package
, spandrel                   # Custom package
, color-matcher              # Custom package
# ... all custom packages
}:
```

2. **Pin the ComfyUI source** with hash:
```nix
src = fetchFromGitHub {
  owner = "comfyanonymous";
  repo = "ComfyUI";
  rev = "v${version}";
  hash = "sha256-T6O6UzcIcBsLWGHmgRnQB/EgsM5Mw2OTmMRq+BBtwsE=";
};
```

3. **List dependencies explicitly**:
```nix
propagatedBuildInputs = [
  # Custom packages built from .flox/pkgs/
  comfyui-frontend-package
  spandrel
  color-matcher
] ++ (with python3.pkgs; [
  # Packages from nixpkgs
  torch
  numpy
  # ...
]);
```

## Platform-Specific Handling

### Conditional Dependencies by Platform

For packages that don't work on certain platforms:

```nix
propagatedBuildInputs = [
  # ... common packages
] ++ lib.optionals (lib.elem python3.stdenv.hostPlatform.system ["x86_64-linux" "x86_64-darwin"]) (with python3.pkgs; [
  # x86-only packages
  some-x86-package
]) ++ lib.optionals (lib.elem python3.stdenv.hostPlatform.system ["aarch64-linux" "aarch64-darwin"]) (with python3.pkgs; [
  # ARM-only packages
  some-arm-package
]) ++ lib.optionals (!lib.elem python3.stdenv.hostPlatform.system ["aarch64-linux" "aarch64-darwin"]) (with python3.pkgs; [
  # Non-ARM packages (e.g., kornia excluded on ARM64)
  kornia
]);
```

## Dependency Discovery Process

When you encounter a missing dependency:

### 1. Check if it's in nixpkgs

```bash
# Search nixpkgs
nix search nixpkgs python3Packages.package-name

# Or use Flox
flox search package-name
```

**If found in nixpkgs:** Use it directly:
```nix
propagatedBuildInputs = with python3.pkgs; [
  package-name  # From nixpkgs
];
```

### 2. If not in nixpkgs, create custom package

**Step 1:** Find the source repository (prefer GitHub over PyPI)

**Step 2:** Create `.flox/pkgs/<package-name>.nix` using the template above

**Step 3:** Add to main package's function signature and dependencies

**Step 4:** Build and iterate until dependencies are satisfied

### 3. Handling Deep Dependency Trees

For packages with many transitive dependencies:

```bash
# Install package in a temporary venv to discover deps
uv venv temp-venv
source temp-venv/bin/activate
uv pip install package-name
uv pip freeze  # Lists all dependencies with versions

# Create .nix files for each dependency not in nixpkgs
```

## Building and Testing

### Local Build

```bash
# Build a specific package
flox build <package-name>

# Build main package
flox build comfyui

# Test the built package
./result-comfyui/bin/comfyui --help
```

### Iterative Development

1. Make changes to `.flox/pkgs/*.nix`
2. Run `flox build <package>`
3. Fix errors (usually missing dependencies or wrong hashes)
4. Repeat until build succeeds

### Common Build Errors

**Error:** Hash mismatch
```
Solution: Update hash in .nix file (see "How to Get the Hash" above)
```

**Error:** Module not found / Import error
```
Solution: Add missing dependency to propagatedBuildInputs
```

**Error:** Build fails on specific platform
```
Solution: Add platform constraints or conditional dependencies
```

## Publishing for Long-Term Reproducibility

### Before Publishing

1. **Verify all sources use hashes** (no dynamic fetching)
2. **Test build on clean system** (or use `sandbox = "pure"`)
3. **Commit all `.nix` files to git**
4. **Tag the release** in git

### Publishing Process

```bash
# 1. Ensure git is clean
git add .flox/
git commit -m "Add ComfyUI 0.3.75 with reproducible deps"
git tag v0.3.75
git push origin main --tags

# 2. Build locally to verify
flox build comfyui

# 3. Publish to Flox catalog
flox publish -o yourorg comfyui

# 4. (Optional) Publish custom dependencies
flox publish -o yourorg color-matcher
flox publish -o yourorg spandrel
# ... etc
```

### What Gets Stored in Flox Catalog

When you publish, Flox stores:
- ✅ The built artifacts (binaries, Python wheels, etc.)
- ✅ Full dependency closure (all packages needed to run)
- ✅ Source references (via hashes)
- ✅ Build metadata and manifest

**Result:** Anyone installing `yourorg/comfyui@0.3.75` gets exact same bits, indefinitely.

## Source Vendoring (REQUIRED for ComfyUI)

For true reproducibility, ALL PyPI sources MUST be vendored locally in the git repository. This is not optional—it's the core of the reproducibility strategy.

### 1. Create Sources Directory

```bash
mkdir -p .flox/sources
```

### 2. Download and Store Sources

```bash
# Download from PyPI
wget https://files.pythonhosted.org/packages/.../package-1.2.3.tar.gz \
  -O .flox/sources/package-1.2.3.tar.gz

# Or from GitHub
wget https://github.com/user/repo/archive/v1.2.3.tar.gz \
  -O .flox/sources/repo-1.2.3.tar.gz

# Commit to git
git add .flox/sources/
git commit -m "Vendor package sources for reproducibility"
```

### 3. Reference Vendored Sources

```nix
{ lib, python3Packages }:

python3Packages.buildPythonPackage rec {
  pname = "package";
  version = "1.2.3";

  # Use local vendored source - NO fetchurl or fetchFromGitHub here!
  src = ../../.flox/sources/${pname}-${version}.tar.gz;

  # Note: No hash needed when using local files
  # Hashes are verified via SHA256SUMS.txt in .flox/sources/

  # ... rest of definition
}
```

**Why vendoring is REQUIRED:**
- PyPI packages frequently disappear (we observed 404s during this build)
- Hash verification alone provides integrity, NOT availability
- Git provides true immutability and version control
- Building old versions years later requires all sources to be present

### Current Implementation Status

**ComfyUI v0.3.75 vendored sources** (as of 2025-11-27):
- ✅ All 11 PyPI packages vendored in `.flox/sources/`
- ✅ SHA256 checksums recorded in `.flox/sources/SHA256SUMS.txt`
- ✅ All `.nix` files updated to use `../../.flox/sources/` paths
- ✅ No external fetchurl dependencies for custom packages

**Vendored packages:**
1. comfyui_frontend_package-1.30.6-py3-none-any.whl (8.7M)
2. comfyui_embedded_docs-0.3.1-py3-none-any.whl (7.7M)
3. comfyui_workflow_templates-0.7.20-py3-none-any.whl (20K)
4. comfyui_workflow_templates_core-0.3.10-py3-none-any.whl (27K)
5. comfyui_workflow_templates_media_api-0.3.14-py3-none-any.whl (42M)
6. comfyui_workflow_templates_media_image-0.3.15-py3-none-any.whl (5.7M)
7. comfyui_workflow_templates_media_other-0.3.9-py3-none-any.whl (12M)
8. comfyui_workflow_templates_media_video-0.3.12-py3-none-any.whl (31M)
9. controlnet_aux-0.0.10-py3-none-any.whl (284K)
10. nunchaku-0.16.1-py3-none-any.whl (18K)
11. spandrel-0.4.0.tar.gz (223K)

**Total vendored size:** ~106MB

## Troubleshooting Guide

### Problem: Package not found during build

**Cause:** Custom package not added to function signature

**Solution:**
```nix
# Add to top of comfyui.nix
{ lib
, python3
, color-matcher  # ADD THIS
# ...
}:
```

### Problem: Cyclic dependency error

**Cause:** Package A depends on package B which depends on package A

**Solution:** Use `pythonPackagesExtensions` pattern (advanced) or restructure dependencies

### Problem: Build works locally but fails in CI/published build

**Cause:** Using system packages or network during build

**Solution:**
1. Set `sandbox = "pure"` in build definition
2. Pre-fetch all network resources
3. Declare all dependencies explicitly

### Problem: Platform-specific build failure

**Cause:** Dependency not available on target platform

**Solution:**
```nix
# Exclude on problematic platforms
++ lib.optionals (!lib.elem python3.stdenv.hostPlatform.system ["aarch64-linux"]) [
  problematic-package
]
```

## Verification Checklist

Before considering the package "reproducibly built":

- [ ] All sources use `fetchFromGitHub` or `fetchPypi` with hashes
- [ ] No `src = fetchurl "latest"` or dynamic URLs
- [ ] All Python dependencies explicitly declared
- [ ] No reliance on `pip install` at runtime
- [ ] Platform-specific dependencies properly conditionalized
- [ ] Build succeeds with `sandbox = "pure"` (for published packages)
- [ ] All `.nix` files committed to git
- [ ] Git repository tagged with version
- [ ] Published to Flox catalog
- [ ] Tested installation from catalog works

## Long-Term Maintenance

### Adding New Dependencies

When ComfyUI requires a new dependency:

1. Check if it exists in current nixpkgs
2. If not, create `.flox/pkgs/<new-dep>.nix` following template
3. Add to `comfyui.nix` dependencies
4. Test build
5. Commit and republish

### Updating ComfyUI Version

```bash
# 1. Update version in comfyui.nix
# 2. Update git rev and get new hash
# 3. Build and test
flox build comfyui

# 4. Commit changes
git commit -m "Update ComfyUI to v0.4.0"
git tag v0.4.0

# 5. Publish new version
flox publish -o yourorg comfyui
```

### Handling Deprecated Dependencies

If a dependency is removed from ComfyUI:
1. Remove from `propagatedBuildInputs`
2. Consider removing `.flox/pkgs/<dep>.nix` (or keep for history)
3. Rebuild and test
4. Publish new version

## References

- **Flox Documentation:** https://flox.dev/docs
- **FLOX.md in this repo:** See sections §9 (Build System) and §11 (Publishing)
- **Nix Pills:** https://nixos.org/guides/nix-pills/ (for deep Nix understanding)
- **nixpkgs Python docs:** https://nixos.org/manual/nixpkgs/stable/#python

## Example: Complete Workflow

Here's a complete example of adding a new dependency:

```bash
# 1. ComfyUI update adds dependency on "fancy-ml-lib"
# 2. Search nixpkgs
flox search fancy-ml-lib
# Result: Not found

# 3. Find on GitHub: https://github.com/author/fancy-ml-lib
# 4. Create package definition
cat > .flox/pkgs/fancy-ml-lib.nix << 'EOF'
{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonPackage rec {
  pname = "fancy-ml-lib";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "author";
    repo = "fancy-ml-lib";
    rev = "v${version}";
    hash = lib.fakeHash;
  };

  propagatedBuildInputs = with python3Packages; [
    numpy
    torch
  ];

  doCheck = false;
  pythonImportsCheck = [ "fancy_ml_lib" ];
}
EOF

# 5. Build to get real hash
flox build fancy-ml-lib
# Copy hash from error, update .nix file

# 6. Add to comfyui.nix
# In function signature: add "fancy-ml-lib"
# In propagatedBuildInputs: add "fancy-ml-lib"

# 7. Rebuild comfyui
flox build comfyui

# 8. Test
./result-comfyui/bin/comfyui --help

# 9. Commit and publish
git add .flox/pkgs/fancy-ml-lib.nix .flox/pkgs/comfyui.nix
git commit -m "Add fancy-ml-lib dependency"
flox publish -o yourorg comfyui
```

## Summary

This architecture ensures reproducibility through:

1. **Cryptographic hashing** of all sources
2. **Explicit declaration** of all dependencies
3. **Multi-tier caching** (Nix cache + Flox catalog + Git)
4. **Immutable references** (git commits, not branches)
5. **Complete closure publication** via Flox catalog

**Result:** Builds are reproducible across time, platforms, and environments.
