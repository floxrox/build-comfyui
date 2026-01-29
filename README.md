# build-comfyui

ComfyUI source distribution package for Flox environments.

## Purpose

This repository packages the [ComfyUI](https://github.com/comfyanonymous/ComfyUI) application as a Nix derivation for use in Flox runtime environments. The package provides ComfyUI's core application code as a read-only distribution, with mutable directories (models, custom_nodes, user data) managed separately by the runtime.

## Why This Exists

ComfyUI is typically installed via `git clone` with mutable state mixed into the application directory. This approach doesn't work well with Nix's immutable store model. This package:

1. **Separates code from data**: Application code lives in the Nix store; user data lives in writable locations
2. **Enables reproducible deployments**: Pin to specific ComfyUI versions with cryptographic hashes
3. **Supports Flox environments**: Integrates with the `comfyui` runtime environment for a complete setup

## What It Does

The package:

- Fetches ComfyUI source from GitHub at a pinned version
- Removes directories that should be mutable (models/, custom_nodes/, user/, input/, output/)
- Applies patches for compatibility (see [Patches](#patches) below)
- Installs to `$out/share/comfyui/`

At runtime, the Flox environment symlinks mutable directories to user-writable locations.

## Repository Structure

```
build-comfyui/
├── .flox/
│   ├── env/
│   │   └── manifest.toml      # Flox build environment
│   └── pkgs/
│       └── comfyui.nix        # Main package definition
├── README.md                  # This file
└── result-comfyui             # Build output symlink (gitignored)
```

## Building

```bash
# Enter the build environment
cd /path/to/build-comfyui
flox activate

# Build the package
flox build comfyui

# Output appears at ./result-comfyui
ls result-comfyui/share/comfyui/
```

## Patches

### Broken Symlink Handling (nodes.py)

**Problem**: ComfyUI's `load_custom_node()` function crashes with `UnboundLocalError` when it encounters a broken symlink in `custom_nodes/`. The code only sets `sys_module_name` for files (`isfile()`) or directories (`isdir()`), but broken symlinks are neither.

**Fix**: Added an `else` clause that logs a warning and returns `False`:

```python
elif os.path.isdir(module_path):
    sys_module_name = module_path.replace(".", "_x_")
else:
    logging.warning(f"Skipping invalid module path (broken symlink?): {module_path}")
    return False
```

**Status**: Applied via `postPatch` in comfyui.nix. Remove when fixed upstream.

## Mutable Directories

The following directories are **not** included in the package (runtime creates them):

| Directory | Purpose | Runtime Location |
|-----------|---------|------------------|
| `models/` | Model files (checkpoints, LoRAs, etc.) | `$HOME/comfyui-work/models` |
| `custom_nodes/` | User-installed custom nodes | `$HOME/comfyui-work/custom_nodes` |
| `user/` | User preferences and settings | `$HOME/comfyui-work/user` |
| `input/` | Input images for workflows | `$HOME/comfyui-work/input` |
| `output/` | Generated images | `$HOME/comfyui-work/output` |

## Versioning

Package versions track upstream ComfyUI releases:

| Branch | ComfyUI Version | Notes |
|--------|-----------------|-------|
| `main` | 0.10.0 | Stable track |
| `latest` | 0.11.0 | Cutting-edge track |
| `v0.9.2` | 0.9.2 | Historical snapshot |
| `v0.9.1` | 0.9.1 | Historical snapshot |

## Related Repositories

- **[build-comfyui-packages](https://github.com/barstoolbluz/build-comfyui-packages)**: Torch-agnostic Python packages and custom nodes
- **comfyui**: Runtime environment that combines this package with dependencies
- **[ComfyUI](https://github.com/comfyanonymous/ComfyUI)**: Upstream application

## License

ComfyUI is licensed under GPL-3.0. This packaging infrastructure is MIT licensed.
