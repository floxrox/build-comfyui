# Claude Code Assistant Guide for build-comfyui

This document provides a quick reference for Claude Code when working with this repository.

## IMPORTANT: Read These First

Before working on this repository, you MUST read these authoritative documentation files (in order):

1. **`ABOUT_THIS_REPO.md`** - Complete repository philosophy, branching strategy, and build architecture (LODESTAR DOCUMENT)
2. **`FLOX.md`** - Flox fundamentals and philosophy (LODESTAR DOCUMENT)
3. **`FLOX-PYTHON.md`** - Flox Python environment setup and runtime configuration (LODESTAR DOCUMENT)
4. **`NIX_PYTHON_BUILD_GUIDE.md`** - Deep dive into Python packaging with Nix, vendoring strategies (LODESTAR DOCUMENT)
5. **`REPRODUCIBLE-BUILD-ARCHITECTURE.md`** - Build architecture details (may need updating)

This CLAUDE.md serves as a quick reference and routing guide. For authoritative information, ALWAYS consult the above documents first.

## Repository Overview

This is a Flox-based build system for ComfyUI using Nix expressions. The repository builds ComfyUI packages that can be published to Flox catalogs and provides reproducible, versioned builds of ComfyUI with all dependencies.

**Key Context from ABOUT_THIS_REPO.md:**
- Default workspace: `$HOME/comfyui-work`
- Related repo: https://github.com/barstoolbluz/build-comfyui-extras.git (for custom nodes and extras - clone this when needed)
- Runtime: ComfyUI launches from a Flox environment with service management

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

### Documentation Structure

**Primary Sources (READ THESE):**
- `ABOUT_THIS_REPO.md` - Repository purpose, strategy, branching philosophy, runtime architecture
- `NIX_PYTHON_BUILD_GUIDE.md` - Python packaging patterns, vendoring, fixed-output derivations
- `FLOX-PYTHON.md` - Flox Python environment setup, venv management, runtime configuration
- `FLOX.md` - General Flox patterns and usage (if present)

**User Documentation:**
- `README.md` - End-user instructions and version tracking
- `USAGE.md` - Detailed usage examples
- `UPDATE.md` - Version update procedures

**Reference:**
- `REPRODUCIBLE-BUILD-ARCHITECTURE.md` - Build architecture details
- `KNOWN-ISSUES.md` - Platform-specific issues

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
1. **First read `NIX_PYTHON_BUILD_GUIDE.md`** for vendoring patterns
2. Add to `propagatedBuildInputs` in `comfyui.nix`
3. Check if custom build needed (see `spandrel.nix` for example)
4. Consider vendoring if network-dependent (see NIX_PYTHON_BUILD_GUIDE.md)
5. Clone https://github.com/barstoolbluz/build-comfyui-extras.git to check for related dependencies
6. Test on both Linux and Darwin

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
- Extras repo: https://github.com/barstoolbluz/build-comfyui-extras.git (clone when working with custom nodes)
- Upstream ComfyUI: https://github.com/Comfy-Org/ComfyUI
- Old upstream: https://github.com/comfyanonymous/ComfyUI

## When to Consult Which Document

### Use ABOUT_THIS_REPO.md for:
- Understanding the branching strategy and version rotation
- Learning about the runtime environment setup
- Understanding the relationship with build-comfyui-extras
- Getting the big picture of the project architecture

### Use NIX_PYTHON_BUILD_GUIDE.md for:
- Python packaging patterns and best practices
- Vendoring dependencies for reproducibility
- Fixed-output derivation patterns
- Handling problematic Python packages
- Understanding the three-tier Python packaging approach

### Use FLOX.md for:
- Understanding Flox fundamentals and philosophy
- General Flox environment management
- Service definitions and management
- Flox build patterns and best practices

### Use FLOX-PYTHON.md for:
- Setting up Flox Python environments
- Understanding venv bootstrapping in hooks
- Runtime environment configuration
- Python version management in Flox
- Python-specific Flox patterns

### Use REPRODUCIBLE-BUILD-ARCHITECTURE.md for:
- Understanding the three-tier packaging architecture
- Fixed-output derivation patterns
- Vendoring strategies and implementation
- Network isolation and sandbox requirements

### Use README.md for:
- Current version information
- User-facing build instructions
- Publishing workflows
- Version update procedures

## Important Notes

1. **Consult documentation** - Read ABOUT_THIS_REPO.md for strategy, NIX_PYTHON_BUILD_GUIDE.md for technical patterns
2. **Never skip testing** - Always run `flox build` before pushing
3. **Preserve reproducibility** - Use vendoring and fixed-output derivations (see NIX_PYTHON_BUILD_GUIDE.md)
4. **Document changes** - Update README.md when versions change
5. **Check dependencies** - Verify requirements.txt changes in upstream
6. **Test cross-platform** - Ensure builds work on Linux and Darwin when possible
7. **Check related repos** - Clone and examine https://github.com/barstoolbluz/build-comfyui-extras.git for custom nodes/extras integration

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