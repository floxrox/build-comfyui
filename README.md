# ComfyUI Flox Build Package

A rock-solid, publishable ComfyUI package for Flox with comprehensive dependency management and workflow support.

## Quick Start

### Build the Package

```bash
flox build comfyui-base
```

### Publish to Your Catalog

```bash
flox auth login
flox publish -o yourcatalog comfyui-base
```

### Install from Your Catalog

```bash
# Core ComfyUI
flox install yourcatalog/comfyui

# Optional: Custom node plugins (Impact Pack for face enhancement)
flox install yourcatalog/comfyui-plugins

# After installing plugins, activate them:
comfyui-activate-plugins
comfyui-download-impact-models  # Download required models
```

---

## Branching Strategy

This repository follows a three-branch strategy for version management:

- **`main`** - Stable version (v0.6.0) using standard toolchains from nixpkgs
- **`nightly`** - Latest upstream version (v0.9.1) with bleeding-edge features
- **`historical`** - Previous stable version (v0.6.0) maintained for compatibility

### Switching Branches

```bash
# Latest bleeding-edge version
git checkout nightly
flox build comfyui

# Stable version
git checkout main
flox build comfyui

# Historical version
git checkout historical
flox build comfyui
```

## Repository Structure

```
.flox/pkgs/
├── comfyui-base.nix              # Main ComfyUI package
├── comfyui-frontend-package.nix  # Web UI (PyPI package)
├── comfyui-workflow-templates.nix # Example workflows (PyPI package)
├── comfyui-embedded-docs.nix     # Documentation (PyPI package)
├── comfyui-plugins.nix           # Custom node plugins (Impact Pack, etc.)
├── segment-anything.nix          # SAM model support for plugins
└── spandrel.nix                  # Model loading library

assets/
├── download-sd15-enhanced.py     # SD 1.5 downloader
├── download-sdxl-enhanced.py     # SDXL downloader
├── download-sd35-enhanced.py     # SD 3.5 downloader
├── download-flux-enhanced.py     # FLUX downloader
└── comfyui-download-enhanced     # Wrapper script

USAGE.md                          # End-user documentation
UPDATE.md                         # Version update guide (this section below)
```

---

## Tracking Upstream Versions

This package tracks [ComfyUI upstream releases](https://github.com/comfyanonymous/ComfyUI/releases).

### Current Versions

| Component | Version | Source |
|-----------|---------|--------|
| ComfyUI | 0.9.1 | [GitHub](https://github.com/comfyanonymous/ComfyUI) |
| Frontend Package | 1.36.14 | [PyPI](https://pypi.org/project/comfyui-frontend-package/) |
| Workflow Templates | 0.8.4 | [PyPI](https://pypi.org/project/comfyui-workflow-templates/) |
| Embedded Docs | 0.4.0 | [PyPI](https://pypi.org/project/comfyui-embedded-docs/) |
| Spandrel | 0.4.0 | [PyPI](https://pypi.org/project/spandrel/) |
| **Nunchaku** | **0.16.1** | **[PyPI](https://pypi.org/project/nunchaku/)** (FLUX optimization) |
| **ControlNet Aux** | **0.0.10** | **[PyPI](https://pypi.org/project/controlnet-aux/)** (Advanced preprocessors) |
| **Impact Pack** | **8.28** | **[GitHub](https://github.com/ltdrdata/ComfyUI-Impact-Pack)** (Face enhancement plugin) |

### Updating to Latest Upstream

#### 1. Check for New Releases

```bash
# Check ComfyUI releases
curl -s https://api.github.com/repos/comfyanonymous/ComfyUI/releases/latest | jq -r '.tag_name'

# Check PyPI packages
curl -s https://pypi.org/pypi/comfyui-frontend-package/json | jq -r '.info.version'
curl -s https://pypi.org/pypi/comfyui-workflow-templates/json | jq -r '.info.version'
curl -s https://pypi.org/pypi/comfyui-embedded-docs/json | jq -r '.info.version'
```

#### 2. Update ComfyUI Core

Edit `.flox/pkgs/comfyui-base.nix`:

```nix
# Change this line:
version = "0.9.1";

# To new version (without 'v' prefix):
version = "0.9.2";  # or whatever the latest is
```

#### 3. Update the Hash

Build will fail with the actual hash - copy it:

```bash
flox build comfyui-base
# Error: hash mismatch, expected: sha256-XXXXXXXX
# Got:    sha256-YYYYYYYY

# Update the hash in comfyui-base.nix:
hash = "sha256-YYYYYYYY";
```

**Or use nix-prefetch to get hash directly:**

```bash
nix-prefetch-url --unpack https://github.com/comfyanonymous/ComfyUI/archive/v0.3.76.tar.gz
# Copy the resulting hash to comfyui-base.nix
```

#### 4. Update Dependency Packages

Check if upstream `requirements.txt` has updated dependency versions:

```bash
# Download latest requirements.txt
curl -s https://raw.githubusercontent.com/comfyanonymous/ComfyUI/v0.3.76/requirements.txt

# Look for these packages and compare versions:
# - comfyui-frontend-package
# - comfyui-workflow-templates
# - comfyui-embedded-docs
# - spandrel
```

Update each `.flox/pkgs/*.nix` file if versions changed (same hash update process as step 3).

#### 5. Build and Test

```bash
flox build comfyui-base

# Test the binary
./result-comfyui-base/bin/comfyui --help

# Test download tools
./result-comfyui-base/bin/comfyui-download
```

#### 6. Update Version Table

Update the "Current Versions" table in this README with new versions.

#### 7. Commit and Publish

```bash
git add .
git commit -m "Update ComfyUI to v0.6.1"
git tag v0.6.1
git push && git push --tags

flox publish -o yourcatalog comfyui-base
```

### Building Older Versions

To build a specific older version:

1. **Checkout the tagged version:**
   ```bash
   git checkout v0.6.0
   flox build comfyui-base
   ```

2. **Or manually edit the version** in `.flox/pkgs/comfyui-base.nix` and update hashes.

3. **Create version-specific branches** (optional):
   ```bash
   git checkout -b v0.6.x  # For 0.6.x series
   # Make updates specific to this version
   ```

### Automation (Optional)

Create a helper script to check for updates:

```bash
#!/usr/bin/env bash
# check-updates.sh

CURRENT_VERSION="0.6.0"
LATEST_VERSION=$(curl -s https://api.github.com/repos/comfyanonymous/ComfyUI/releases/latest | jq -r '.tag_name' | sed 's/^v//')

if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo "🆕 New version available: $LATEST_VERSION (current: $CURRENT_VERSION)"
    echo "Update instructions: https://github.com/comfyanonymous/ComfyUI/releases/tag/v$LATEST_VERSION"
else
    echo "✅ Already on latest version: $CURRENT_VERSION"
fi
```

---

## Package Features

- ✅ **Self-contained** - Works out of the box with generic PyTorch
- ✅ **Optimizable** - Override with CUDA-optimized packages in your environment
- ✅ **Complete dependencies** - All Python packages needed for common workflows
- ✅ **Interactive model downloads** - Smart token handling with multiple fallbacks
- ✅ **Cross-platform** - Works on Linux and macOS (CPU mode)

See [USAGE.md](./USAGE.md) for detailed usage instructions.

---

## Known Issues

See [KNOWN-ISSUES.md](./KNOWN-ISSUES.md) for platform-specific issues and workarounds.

**Current known issues:**
- **macOS**: Duplicate FFmpeg class warnings (harmless, can be ignored)

---

## Publishing Strategy

### Recommended Workflow

1. **Track stable releases** - Only update when ComfyUI releases a new stable version
2. **Tag your builds** - Create git tags matching upstream (e.g., `v0.6.0`)
3. **Test before publishing** - Always build and test locally first
4. **Document changes** - Note any breaking changes or new dependencies in commit messages

### Version Naming

- **Git tags**: Match upstream with `v` prefix (e.g., `v0.6.0`)
- **Package version**: In Nix expression, no `v` prefix (e.g., `0.6.0`)
- **Published name**: Use catalog namespacing (e.g., `yourcatalog/comfyui`)

---

## Contributing

Improvements to build process and dependency tracking welcome! Please open issues or pull requests.

## License

ComfyUI is GPL-3.0. This packaging follows the same license.
