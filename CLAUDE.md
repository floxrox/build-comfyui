# Claude Code Assistant Guide for build-comfyui

This document provides context and guidelines for Claude Code when working with this repository.

## Repository Overview

This is a Flox-based build system for ComfyUI using Nix expressions. The repository builds ComfyUI packages that can be published to Flox catalogs and provides reproducible, versioned builds of ComfyUI with all dependencies.

## Key Principles

1. **Reproducibility First**: All builds must be reproducible. Use vendored dependencies and fixed-output derivations.
2. **Version Preservation**: Every ComfyUI release gets preserved in its own branch for future rebuilding.
3. **Modular Architecture**: Core ComfyUI is separate from plugins, extras, and workflow templates.
4. **Testing Pipeline**: Changes flow through testing → staging → production branches.

## Branching Strategy

### Current Structure
- `main`: Stable release (currently v0.9.1)
- `latest`: Newest version for testing (currently v0.9.2)
- `v0.x.x`: Historical versions preserved forever
- `*-testing`: For build validation
- `*-staging`: For UAT before promotion

### Version Rotation
When ComfyUI releases a new version:
1. `latest` → `main`
2. `main` → `v<version>`
3. New release → `latest`

## Build Commands

### Essential Commands
```bash
# Build ComfyUI package
flox build comfyui

# Test the build
./result-comfyui/bin/comfyui --help

# Run in Flox environment
flox activate -- comfyui
```

### Updating to New Version
1. Edit `.flox/pkgs/comfyui.nix` - update version
2. Run build to get hash mismatch
3. Update hash in the nix file
4. Test build succeeds
5. Update documentation

## File Structure

### Core Build Files
- `.flox/pkgs/comfyui.nix` - Main ComfyUI package
- `.flox/pkgs/comfyui-plugins.nix` - Impact Pack and other plugins
- `.flox/pkgs/*.nix` - Supporting packages

### Documentation
- `ABOUT_THIS_REPO.md` - Repository purpose and strategy
- `NIX_PYTHON_BUILD_GUIDE.md` - Python packaging in Nix
- `FLOX-PYTHON.md` - Flox Python environment setup
- `README.md` - User-facing documentation

## Important Patterns

### Python Dependencies
```nix
propagatedBuildInputs = [
  # Flox-specific packages
  spandrel
  nunchaku
  # Standard packages
] ++ (with python3.pkgs; [
  torch
  torchvision
  # ...
]);
```

### Platform-Specific Builds
```nix
++ lib.optionals (!lib.elem python3.stdenv.hostPlatform.system ["aarch64-linux" "aarch64-darwin"]) (with python3.pkgs; [
  kornia  # Exclude on ARM64
])
```

## Common Tasks

### Adding a New Python Dependency
1. Add to `propagatedBuildInputs` in `comfyui.nix`
2. Check if custom build needed (see `spandrel.nix` for example)
3. Test on both Linux and Darwin

### Updating ComfyUI Version
1. Check latest release: `curl -s https://api.github.com/repos/Comfy-Org/ComfyUI/releases/latest | jq -r '.tag_name'`
2. Update version in `comfyui.nix`
3. Get new hash: `nix-prefetch-url --unpack https://github.com/comfyanonymous/ComfyUI/archive/v<VERSION>.tar.gz`
4. Update hash in `comfyui.nix`
5. Build and test

### Creating Historical Branch
```bash
git checkout main
git checkout -b v0.9.1
git push origin v0.9.1
```

## Testing Requirements

Before committing:
1. Build succeeds: `flox build comfyui`
2. Binary runs: `./result-comfyui/bin/comfyui --help`
3. Downloads work: `./result-comfyui/bin/comfyui-download`

## Known Issues

### Darwin (macOS)
- FFmpeg duplicate class warnings (harmless)
- Some packages need Darwin-specific overrides

### ARM64
- kornia excluded due to kornia-rs build issues
- May need architecture-specific handling

## Commit Message Conventions

```
Update ComfyUI to v0.9.3

- Updated version and hash in comfyui.nix
- Tested on Linux x86_64
- All download scripts functional
```

## Publishing Workflow

1. Build locally: `flox build comfyui`
2. Test thoroughly
3. Commit with descriptive message
4. Tag if major version: `git tag v0.9.3`
5. Push to appropriate branch
6. Publish: `flox publish -o catalog comfyui`

## Repository URLs

- Main repo: https://github.com/floxrox/build-comfyui
- Upstream ComfyUI: https://github.com/Comfy-Org/ComfyUI
- Old upstream: https://github.com/comfyanonymous/ComfyUI

## Important Notes

1. **Never skip testing** - Always run `flox build` before pushing
2. **Preserve reproducibility** - Don't use floating versions or unpinned dependencies
3. **Document changes** - Update README.md when versions change
4. **Check dependencies** - Verify requirements.txt changes in upstream
5. **Test cross-platform** - Ensure builds work on Linux and Darwin when possible

## Helper Scripts

### Check for Updates
```bash
CURRENT=$(grep 'version =' .flox/pkgs/comfyui.nix | head -1 | sed 's/.*"\(.*\)".*/\1/')
LATEST=$(curl -s https://api.github.com/repos/Comfy-Org/ComfyUI/releases/latest | jq -r '.tag_name' | sed 's/^v//')
echo "Current: $CURRENT, Latest: $LATEST"
```

### Quick Version Info
```bash
git branch --show-current
grep 'version =' .flox/pkgs/comfyui.nix | head -1
```

## Contact & Resources

- Flox documentation: https://flox.dev/docs
- Nix Python guide: nixpkgs manual
- ComfyUI issues: upstream GitHub

---

*This file helps Claude Code understand the repository structure and maintain consistency across all operations.*