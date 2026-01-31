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
- Installs model download scripts to `$out/bin/` (see [Model Download Scripts](#model-download-scripts) below)

At runtime, the Flox environment symlinks mutable directories to user-writable locations.

## Repository Structure

```
build-comfyui/
├── .flox/
│   ├── env/
│   │   └── manifest.toml      # Flox build environment
│   └── pkgs/
│       └── comfyui.nix        # Main package definition
├── scripts/
│   ├── comfyui-download-sd15.py   # SD 1.5 downloader
│   ├── comfyui-download-sdxl.py   # SDXL 1.0 downloader
│   ├── comfyui-download-sd35.py   # SD 3.5 Large downloader
│   └── comfyui-download-flux.py   # FLUX.1-dev downloader
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

## Model Download Scripts

The `scripts/` directory contains Python scripts for downloading popular models from HuggingFace. These are installed to `$out/bin/` and available as CLI commands in the runtime environment.

| Command | Model | Size | HF Token |
|---------|-------|------|----------|
| `comfyui-download-sd15` | Stable Diffusion 1.5 | ~4.3 GB | Not required |
| `comfyui-download-sdxl` | Stable Diffusion XL 1.0 | ~6.9 GB | Not required |
| `comfyui-download-sd35` | Stable Diffusion 3.5 Large | ~23 GB | **Required** (gated) |
| `comfyui-download-flux` | FLUX.1-dev | ~22 GB | **Required** (gated) |

Each script supports `--help`, `--dry-run`, and `--models-dir` flags. Model files are placed in the correct subdirectories (checkpoints/, clip/, unet/, vae/) automatically.

For gated models, set `HF_TOKEN` before running:

```bash
export HF_TOKEN=hf_your_token_here
comfyui-download-sd35
```

Environment variables:

| Variable | Purpose |
|----------|---------|
| `HF_TOKEN` | HuggingFace access token (required for gated models) |
| `COMFYUI_MODELS_DIR` | Override model download directory directly |
| `COMFYUI_WORK_DIR` | Override work directory (models go in `$COMFYUI_WORK_DIR/models`) |

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
| `main` | 0.9.2 | Stable track |
| `latest` | 0.10.0 | Cutting-edge track |
| `v0.9.1` | 0.9.1 | Historical snapshot |

## Related Repositories

- **[build-comfyui-packages](https://github.com/barstoolbluz/build-comfyui-packages)**: Torch-agnostic Python packages and custom nodes
- **comfyui**: Runtime environment that combines this package with dependencies
- **[ComfyUI](https://github.com/comfyanonymous/ComfyUI)**: Upstream application

## License

ComfyUI is licensed under GPL-3.0. This packaging infrastructure is MIT licensed.
