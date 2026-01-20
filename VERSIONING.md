# ComfyUI Package Versioning Strategy

This document describes the versioning strategy for ComfyUI Flox packages.

## Overview

We use a **two-tier versioning system** that balances compatibility tracking with upstream dependency management.

## Package Categories

### 1. Lock-step Packages (Our Wrapper Packages)

These packages **always** match the ComfyUI version to indicate compatibility:

```
comfyui.nix              → Matches ComfyUI version
comfyui-plugins.nix      → Matches ComfyUI version
comfyui-manager.nix      → Matches ComfyUI version (when integrated)
comfyui-ultralytics.nix  → Matches ComfyUI version (when integrated)
comfyui-impact-subpack.nix → Matches ComfyUI version (when integrated)
```

**Example:**
- When ComfyUI is at version 0.9.1, all lock-step packages are versioned 0.9.1
- When ComfyUI updates to 0.9.2, all lock-step packages update to 0.9.2

**Rationale:**
- Provides clear compatibility matrix at a glance
- Users know that comfyui-plugins 0.9.2 works with ComfyUI 0.9.2
- Simplifies branch management and testing

### 2. Independent Packages (Vendored Dependencies)

These packages maintain their **actual upstream versions**:

```
comfyui-frontend-package.nix → 1.36.14 (PyPI version)
comfyui-workflow-templates.nix → 0.8.4 (PyPI version)
comfyui-embedded-docs.nix → 0.4.0 (PyPI version)
spandrel.nix → 0.4.0 (PyPI version)
nunchaku.nix → 0.16.1 (PyPI version)
controlnet-aux.nix → 0.0.10 (PyPI version)
gguf.nix → 0.11.0 (PyPI version)
accelerate.nix → 1.2.1 (PyPI version)
```

**Rationale:**
- These are external dependencies with their own release cycles
- Tracking upstream versions prevents confusion
- Updates only when upstream releases new versions

## Implementation

### In Nix Expressions

Lock-step packages include a comment:
```nix
version = "0.9.1";  # Match ComfyUI version
```

For packages with both wrapper and upstream versions:
```nix
version = "0.9.1";  # Match ComfyUI version (our wrapper)
rev = "8.28";       # Upstream Impact Pack version
```

### Branch Consistency

Each branch maintains consistent lock-step versioning:
- **main branch**: All lock-step packages at 0.9.1
- **latest branch**: All lock-step packages at 0.9.2
- **v0.6.0 branch**: All lock-step packages at 0.6.0

## Version Update Process

### When ComfyUI Releases a New Version

1. **Update latest branch:**
   ```bash
   git checkout latest
   # Update all lock-step packages to new version
   sed -i 's/version = "0.9.2"/version = "0.9.3"/' .flox/pkgs/comfyui*.nix
   ```

2. **Test compatibility:**
   - Build all packages
   - Verify plugins still work with new ComfyUI
   - Check activation scripts function correctly

3. **Rotate branches** (when stable):
   - latest → main
   - main → historical branch (e.g., v0.9.1)
   - Update latest with newest version

### When Upstream Dependencies Update

1. **Check for updates:**
   ```bash
   curl -s https://pypi.org/pypi/comfyui-frontend-package/json | jq -r '.info.version'
   ```

2. **Update only the specific package:**
   ```nix
   # In comfyui-frontend-package.nix
   version = "1.36.15";  # New upstream version
   ```

3. **Keep lock-step packages unchanged**

## Handling Incompatibility

When a plugin becomes incompatible with new ComfyUI:

1. **Stop updating its version:**
   ```nix
   # In comfyui-plugins.nix
   version = "0.9.1";  # Last compatible ComfyUI version
   # NOTE: Not compatible with ComfyUI > 0.9.1
   ```

2. **Document in PACKAGES.md:**
   ```markdown
   ### comfyui-plugins.nix
   - **Version**: 0.9.1 (last compatible version)
   - **Note**: Not compatible with ComfyUI > 0.9.1
   ```

3. **Consider moving to historical branch**

## Examples

### Correct Version Alignment

**main branch (ComfyUI 0.9.1):**
```
comfyui.nix: 0.9.1
comfyui-plugins.nix: 0.9.1
comfyui-frontend-package.nix: 1.36.14
spandrel.nix: 0.4.0
```

**latest branch (ComfyUI 0.9.2):**
```
comfyui.nix: 0.9.2
comfyui-plugins.nix: 0.9.2
comfyui-frontend-package.nix: 1.36.14
spandrel.nix: 0.4.0
```

### Incorrect Version Alignment (Bug)

```
comfyui.nix: 0.9.2
comfyui-plugins.nix: 0.9.1  # BUG: Should be 0.9.2
```

## Benefits

1. **Clear Compatibility**: Version number immediately shows compatibility
2. **Simple Mental Model**: "All our packages match ComfyUI version"
3. **Easy Branch Management**: Each branch has consistent versions
4. **Upstream Tracking**: Independent packages stay current with upstream
5. **Graceful Degradation**: Can freeze incompatible packages at last working version

## Testing Checklist

When updating versions:

- [ ] All lock-step packages have matching ComfyUI version
- [ ] Independent packages have correct upstream versions
- [ ] Version comments include "# Match ComfyUI version"
- [ ] PACKAGES.md reflects current versions
- [ ] README version table is updated
- [ ] All packages build successfully
- [ ] Activation scripts work correctly

## Common Commands

```bash
# Check all lock-step versions
grep "version = " .flox/pkgs/comfyui*.nix | grep -v workflow | grep -v frontend | grep -v embedded

# Update all lock-step packages
sed -i 's/version = "0.9.1"/version = "0.9.2"/' .flox/pkgs/comfyui.nix
sed -i 's/version = "0.9.1"/version = "0.9.2"/' .flox/pkgs/comfyui-plugins.nix

# Verify version consistency
for f in comfyui.nix comfyui-plugins.nix; do
  echo "$f: $(grep 'version = ' .flox/pkgs/$f | head -1)"
done
```