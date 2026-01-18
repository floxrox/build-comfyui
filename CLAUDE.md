# CLAUDE.md

## Project Overview

ComfyUI build packages for Flox with custom node support and runtime package management.

## Key Packages

- **comfyui.nix**: Core application with Manager dependencies and uv in PATH
- **comfyui-manager.nix**: Runtime package manager with UV --system flag fix
- **comfyui-ultralytics.nix**: YOLO detection Python package
- **comfyui-impact-subpack.nix**: Impact Subpack with onnxruntime and ultralytics

## Critical Patterns

### OpenCV Standardization
All packages use `opencv4` to prevent "recursion detected" errors.

### Python Version Management
- **Current**: Python 3.13 (`python313Packages`)
- **Location**: Primary references in `comfyui.nix` and `comfyui-impact-subpack.nix`
- **Inheritance**: Most packages inherit Python from comfyui.nix
- **To change Python version**:
  1. Update `python3` and `python313Packages` in comfyui.nix
  2. Update `python313` references in comfyui-impact-subpack.nix
  3. Update pytorch package references (e.g., `pytorch-python313-cuda12_8`)
  4. Rebuild all packages to verify compatibility
  5. Test Manager and custom nodes still function
- **Note**: Some packages like pytorch have version-specific builds

### Activation Scripts Pattern
Packages provide their own activation scripts that symlink from nix store to user directory:
```bash
comfyui-activate-manager        # Links Manager to custom_nodes/
comfyui-activate-plugins        # Links Impact Pack to custom_nodes/
comfyui-activate-impact-subpack # Links Impact Subpack to custom_nodes/
```
Note: Python packages like ultralytics don't need activation scripts.

### Environment Integration Pattern
Manifest hooks should detect and prompt for activation, not reimplement:
```bash
if command -v comfyui-activate-impact-subpack >/dev/null 2>&1; then
  if [ ! -L "$WORK_DIR/custom_nodes/ComfyUI-Impact-Subpack" ]; then
    echo "Run: comfyui-activate-impact-subpack"
  fi
fi
```

### Manager Dependencies
Added to comfyui.nix: gitpython, pygithub, rich, typer, toml, chardet, uv

### Nixpkgs Pinning Strategy
- **Files with pinning**: comfyui.nix, manager, plugins, ultralytics, impact-subpack (5 total)
- **Keep synchronized**: All 5 files should use the same nixpkgs revision
- **When to update**:
  - Security fixes needed
  - New Python version required
  - Package build failures
  - Dependency version conflicts
- **Update process**:
  1. Update revision in all 5 files
  2. Test full rebuild
  3. Verify no regressions

## Branch Strategy

### Active Branches
- **main**: Current stable version (currently v0.6.0, core ComfyUI only)
- **nightly**: Latest upstream version (currently v0.9.1 with Manager, Ultralytics, Impact-Subpack)
- **historical**: Previous stable for compatibility (currently v0.6.0)

### Branch Rotation Strategy
When a new ComfyUI version is released (e.g., 0.9.2), branches rotate:

1. **Historical** → Becomes a version-specific branch (e.g., `v0.6.0`)
2. **Main** → Becomes the new `historical`
3. **Nightly** → Becomes the new `main`
4. **Nightly** → Gets updated to the latest version

```bash
# Example rotation when 0.9.2 releases:
historical (0.6.0) → git branch v0.6.0 (preserved)
main (0.6.0)       → historical (0.6.0)
nightly (0.9.1)    → main (0.9.1)
nightly (updated)  → nightly (0.9.2)
```

### Branch Rotation Process
```bash
# 1. Create version branch from historical
git checkout historical
git checkout -b v0.6.0
git push origin v0.6.0

# 2. Update historical from main
git checkout historical
git reset --hard main
git push --force-with-lease origin historical

# 3. Update main from nightly
git checkout main
git reset --hard nightly
git push --force-with-lease origin main

# 4. Update nightly with new version
git checkout nightly
# Update version in .flox/pkgs/comfyui.nix
# Update hash, test build
git commit -m "comfyui: update to v0.9.2"
git push origin nightly
```

### Version Preservation
- All versions preserved as branches: `v0.6.0`, `v0.9.1`, etc.
- Users can checkout specific versions: `git checkout v0.9.1`
- Three actively maintained versions at any time
- Version branches are frozen (no updates)

## Critical Fixes

### UV --system Flag Positioning
Manager requires UV's `--system` flag AFTER the subcommand:
- ✅ Correct: `uv pip install --system package`
- ❌ Wrong: `uv pip --system install package`

Fix applied in comfyui-manager.nix using sed patch that adds flag only for install/uninstall.

### Ultralytics Network Test Override
When building packages that depend on ultralytics, disable network tests:
```nix
ultralytics-no-tests = python313Packages.ultralytics.overridePythonAttrs (oldAttrs: {
  doCheck = false;
  pytestCheckPhase = "true";
});
```

## Common Issues

1. **"No module named 'rich'"**: Manager dependencies missing from comfyui.nix
2. **"Neither pip nor uv available"**: FIXED - uv added to PATH via makeWrapper
3. **UltralyticsDetectorProvider missing**: Install comfyui-impact-subpack package
4. **"No virtual environment found"**: FIXED - Manager patches uv with `--system` flag
5. **ModuleNotFoundError for Impact-Subpack**: Use Flox package, not git clone

## Testing Strategy

### Build Testing
```bash
# Core packages
flox build comfyui comfyui-manager comfyui-impact-subpack

# Supporting packages (spot check)
flox build spandrel segment-anything controlnet-aux

# Workflow templates (if updated)
flox build comfyui-workflow-templates
```

### Functional Testing
1. **Start service**: `cd /path/to/comfyui-env && flox activate --start-services`
2. **Check web UI**: http://localhost:8188
3. **Test workflows**:
   - Basic SD 1.5 text-to-image
   - SDXL with refiner (if models available)
   - ControlNet workflow (if controlnet-aux installed)
   - Impact Pack face detection (if activated)
4. **Verify Manager**:
   - Can list available nodes
   - UV commands work (`uv pip list --system`)
   - Can install a test package
5. **Check logs**: `flox services logs comfyui | grep -E "ERROR|FAILED"`

### Integration Testing
- Activation scripts create proper symlinks: `ls -la ~/comfyui-work/custom_nodes/`
- Manager can install packages: Test via web UI
- Impact Subpack nodes appear: Check node list for UltralyticsDetectorProvider

## Package Support Matrix

### v0.9.1+ (nightly branch)
All packages supported including:
- **Core**: comfyui, workflow-templates, frontend-package, embedded-docs
- **Custom Nodes**: comfyui-manager, comfyui-plugins (Impact Pack)
- **Detection**: comfyui-ultralytics, comfyui-impact-subpack
- **Tools**: comfy-kitchen
- **Supporting**: All Python packages (spandrel, segment-anything, etc.)

### v0.6.0 (main branch)
Limited package support:
- **Core**: comfyui, workflow-templates, frontend-package, embedded-docs
- **Custom Nodes**: comfyui-plugins (Impact Pack) - may have compatibility issues
- **Supporting**: Python packages (spandrel, segment-anything, etc.)
- **NOT AVAILABLE**: Manager, Ultralytics, Impact-Subpack, comfy-kitchen

## Compatibility Matrix

| ComfyUI | Manager | Impact Pack | Impact Subpack | Python | Branch |
|---------|---------|-------------|----------------|--------|--------|
| 0.9.1+  | latest  | 8.28        | 1.3.5          | 3.13   | nightly |
| 0.6.0   | N/A     | 8.28*       | N/A            | 3.13   | main |

*Impact Pack in v0.6.0 may have limited functionality without Manager

### Checking Compatibility
1. **Manager**: Check ltdrdata/ComfyUI-Manager releases for version requirements
2. **Impact Pack/Subpack**: Review requirements.txt in repositories
3. **Custom nodes**: Check `__init__.py` for ComfyUI version checks
4. **Python packages**: Verify no conflicting dependency versions

### Version Pinning
- Pin Manager to specific commit when ComfyUI has breaking API changes
- Pin custom nodes when node interface changes
- Document known working combinations in matrix above

### Version Support Policy
- **v0.9.1+**: Full support for Manager, Impact-Subpack, and new packages
- **v0.6.x**: Core ComfyUI only, custom nodes not guaranteed compatible
- **Migration**: When moving packages from nightly→main, only if v0.6.x can support them
- **New packages**: Add to nightly first, backport to main only if tested compatible

## Branch Migration Checklist

When nightly → main:
- [ ] Copy comfyui-manager.nix to main branch
- [ ] Copy comfyui-ultralytics.nix to main branch
- [ ] Copy comfyui-impact-subpack.nix to main branch
- [ ] Update package versions to match main's ComfyUI
- [ ] Update Python version if needed (see Python Version Management)
- [ ] Verify Manager dependencies in comfyui.nix
- [ ] Verify uv in PATH in comfyui.nix
- [ ] Update compatibility matrix
- [ ] Test all activation scripts work

## Maintenance Workflow

### Regular Updates (Weekly/As Needed)
1. Check ComfyUI releases: `curl -s https://api.github.com/repos/comfyanonymous/ComfyUI/releases/latest | jq -r '.tag_name'`
2. Check Manager updates: `curl -s https://api.github.com/repos/ltdrdata/ComfyUI-Manager/commits/main | head`
3. Review custom node compatibility in their repos
4. Update if stable release available

### Update Checklist
- [ ] Read ComfyUI changelog for breaking changes
- [ ] Update version and hash in comfyui.nix (see README.md for hash update)
- [ ] Update PyPI dependencies if requirements.txt changed
- [ ] Test Manager still works with UV flag fix
- [ ] Verify custom nodes load correctly
- [ ] Run test workflows (see Testing Strategy)
- [ ] Update compatibility matrix
- [ ] Commit with descriptive message: `comfyui: update to vX.Y.Z`
- [ ] Tag if stable release: `git tag comfyui-vX.Y.Z`
- [ ] Publish if tests pass (see Publishing Workflow)

### Dependency Updates
1. Check requirements.txt: `curl -s https://raw.githubusercontent.com/comfyanonymous/ComfyUI/vX.Y.Z/requirements.txt`
2. Update PyPI packages in comfyui.nix if versions changed
3. Test Manager dependencies are still included

### Troubleshooting Updates
- **Build failures**: Check nixpkgs updates, Python version compatibility
- **Import errors**: Verify Python dependencies, check `pip list` in environment
- **Node failures**: Check ComfyUI API changes, review changelog
- **Manager issues**: Verify UV --system flag patch still applies

## Publishing Workflow

### When to Publish
- After ComfyUI stable release (not pre-releases/RCs)
- After testing all core workflows
- When fixing critical bugs
- When adding new custom node packages

### Publishing Steps
1. **Ensure git is clean**: `git status`
2. **Push all changes**: `git push origin <branch>`
3. **Tag with version**: `git tag comfyui-v0.9.1 && git push --tags`
4. **Publish packages in order**:
   ```bash
   flox publish -o flox comfyui
   flox publish -o flox comfyui-manager
   flox publish -o flox comfyui-ultralytics
   flox publish -o flox comfyui-impact-subpack
   ```
5. **Document in commit**: Include breaking changes and migration steps

### Breaking Changes Protocol
- **Major ComfyUI version**: Consider creating new branch
- **API changes**: Update all dependent packages first
- **Python version change**: Test all custom nodes, update pytorch packages
- **Document migration**: Add notes to commit message or MIGRATION.md

### Version Tagging
- Git tags: `comfyui-vX.Y.Z` (matches ComfyUI version)
- Package version: In .nix file, no 'v' prefix (e.g., `version = "0.9.1"`)
- Catalog naming: `flox/comfyui` (organization namespace)