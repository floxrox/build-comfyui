# ComfyUI Packages

## Core Packages

### comfyui.nix
Main ComfyUI application with Python dependencies.
- **Added dependencies**: gitpython, pygithub, rich, typer, toml, chardet (for Manager)
- **Added tools**: uv package manager in PATH via makeWrapper for runtime installations
- **OpenCV**: Standardized to opencv4
- **Path wrapping**: `--prefix PATH : "${uv}/bin"` enables Manager package installs

### comfyui-manager.nix
Runtime package manager for custom nodes.
- **Activation**: `comfyui-activate-manager` symlinks to userland
- **Features**: Web UI for node installation, doesn't write to nix store
- **Dependencies**: Requires uv/pip for runtime package operations
- **Critical Fix**: Sed patch adds `--system` flag AFTER uv subcommand (install/uninstall only)
- **Pattern**: `uv pip install --system` (correct) vs `uv pip --system install` (wrong)

### comfyui-ultralytics.nix
YOLO detection support for UltralyticsDetectorProvider node.
- **Type**: Python package (no activation script needed)
- **Note**: Base ultralytics package, Impact-Subpack provides the nodes
- **OpenCV**: Uses opencv4

### comfyui-impact-subpack.nix
Impact Subpack with YOLO detection nodes and onnxruntime.
- **Activation**: `comfyui-activate-impact-subpack` symlinks to custom_nodes/
- **Dependencies**: matplotlib, numpy, opencv4, dill, ultralytics with onnxruntime
- **Build Fix**: Overrides ultralytics to disable network tests (`doCheck = false`)
- **Provides**: UltralyticsDetectorProvider and additional Impact nodes

## Supporting Packages

### comfyui-plugins.nix
Impact Pack and other custom nodes.
- **Impact-Pack**: Face enhancement, detection nodes
- **Impact-Subpack**: Contains UltralyticsDetectorProvider

### Other Dependencies
- spandrel.nix - Model loading library
- nunchaku.nix - FLUX optimization
- controlnet-aux.nix - Advanced preprocessors
- gguf.nix - Quantized model support
- accelerate.nix - Model loading optimization

## Package Patterns

### Activation Scripts
Custom node packages provide their own activation scripts:
1. Package installs to nix store with activation script in `$out/bin/`
2. Activation script creates symlink from store → userland
3. ComfyUI loads from userland directory

Examples:
```bash
comfyui-activate-manager        # Links Manager to custom_nodes/
comfyui-activate-plugins        # Links Impact Pack to custom_nodes/
comfyui-activate-impact-subpack # Links Impact Subpack to custom_nodes/
```

### Environment Integration
Environments should detect and prompt for activation, not reimplement:
```bash
# In manifest.toml [hook] section
if command -v comfyui-activate-impact-subpack >/dev/null 2>&1; then
  if [ ! -L "$WORK_DIR/custom_nodes/ComfyUI-Impact-Subpack" ]; then
    echo "Run: comfyui-activate-impact-subpack"
  fi
fi
```

### Build Overrides for Network Tests
When packages fail due to network tests in sandbox:
```nix
package-no-tests = pythonPackages.package.overridePythonAttrs (oldAttrs: {
  doCheck = false;
  pytestCheckPhase = "true";
});
```

## Branch Availability

- **main** (0.6.0): Core ComfyUI only
- **nightly** (0.9.1): All packages including Manager, Ultralytics, and Impact-Subpack
- **historical** (0.6.0): Core ComfyUI only

## Branch Migration

When nightly becomes main:
1. Copy comfyui-manager.nix, comfyui-ultralytics.nix, and comfyui-impact-subpack.nix to main branch
2. Update versions in these packages to match main's ComfyUI version
3. Verify uv is in PATH in comfyui.nix
4. Test all activation scripts still work with older ComfyUI

## Build & Integration

### How they're built
- Manager: stdenv.mkDerivation (pure file copy with activation script and sed patch)
- Ultralytics: buildPythonPackage (wraps ultralytics Python package)
- Impact-Subpack: stdenv.mkDerivation with Python dependencies and activation script
- All are separate Flox packages (`flox build <package-name>`)
- They don't depend on comfyui.nix but require it at runtime

### Integration with comfyui
- comfyui.nix has Manager's Python dependencies (rich, gitpython, etc.)
- comfyui.nix adds uv to PATH for Manager's runtime installs
- Activation scripts symlink from nix store to ComfyUI's custom_nodes/

### Maintenance
- Update Manager: Change rev/hash in comfyui-manager.nix
- Update Ultralytics: Change version/hash in comfyui-ultralytics.nix
- Update Impact-Subpack: Change rev/hash in comfyui-impact-subpack.nix
- If network tests fail: Add override pattern to disable tests
- Keep versions aligned with ComfyUI version on each branch