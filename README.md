# build-comfyui

ComfyUI 0.18.3 as a complete Nix package for Flox environments. Bundles ComfyUI core, 40+ Python dependencies (torch-agnostic builds), 24 custom nodes, launcher scripts, and model download tools into a single `stdenv.mkDerivation`.

This is the **build** repository. A separate runtime Flox environment consumes the output and provides GPU-specific PyTorch (CUDA, MPS, or CPU).

## Quick Start

```bash
# 1. Make code changes, commit them
git add -A && git commit -m "description of changes"

# 2. Update build metadata with current git state
./update-build-meta "changelog message"
git add build-meta/ && git commit -m "build-meta: update for build"

# 3. Build
flox build comfyui-complete

# 4. Verify
readlink -f result-comfyui-complete    # Nix store path
ls result-comfyui-complete/bin/        # Scripts
ls result-comfyui-complete/share/comfyui/custom_nodes/  # 24 nodes
```

## Build Output

```
result-comfyui-complete/
  bin/
    comfyui-setup              # Runtime setup (venv, pip deps, runtime dir)
    comfyui-start              # Service launcher (GPU detection, PYTHONPATH)
    start                      # Start service + open browser
    comfyui-download-flux.py       # FLUX.1-dev model downloader
    comfyui-download-sd15.py       # SD 1.5 model downloader
    comfyui-download-sd35.py       # SD 3.5 Large model downloader
    comfyui-download-sdxl.py       # SDXL 1.0 model downloader
    comfyui-download-wan22.py      # Wan 2.2 video model downloader
    comfyui-download-framepack.py  # FramePack video model downloader
    comfyui-download-hunyuan15.py  # HunyuanVideo 1.5 model downloader
  share/comfyui/
    main.py                    # ComfyUI entry point
    nodes.py                   # Node loader (patched for broken symlinks)
    comfy/                     # Core library
    comfy_extras/              # Built-in extra nodes
    web/                       # Frontend + pre-copied JS extensions
    custom_nodes/              # 24 bundled custom nodes
    workflows/                 # Bundled example workflows (FLUX, SD15, SD35, SDXL, WAN22, FRAMEPACK, HUNYUAN15, API)
  share/comfyui-complete/
    flox-build-version-*       # Build version marker
```

## Architecture

### comfyui-complete Overview

`comfyui-complete` is a single `stdenv.mkDerivation` that bundles:

- **ComfyUI 0.18.3 source** fetched from GitHub at a pinned tag
- **pythonEnv** with 40+ Python packages (torch, torchvision, numpy, scipy, transformers, diffusers, etc.)
- **24 custom nodes** from 5 sub-packages (Impact Pack, community nodes, ControlNet-Aux, video generation, Impact Subpack)
- **10 scripts** for setup, launching, and model downloads
- **Bundled workflows** for common model types

This is NOT a Python package — there is no `site-packages` in the output. The pythonEnv is used only to wrap `comfyui-setup` (via `wrapProgram --prefix PATH`). The main launcher (`comfyui-start`) is deliberately NOT wrapped — see [comfyui-start is NOT Wrapped](#comfyui-start-is-not-wrapped).

### Torch-Agnostic Build Pattern

**Problem:** Many Python ML packages (ultralytics, timm, open-clip-torch, accelerate, etc.) depend on PyTorch. When installed from standard channels, they pull in CPU-only torch, which conflicts with CUDA-enabled PyTorch in the runtime environment. GPU operations like NMS silently fall back to CPU.

**Solution:** 13 packages are rebuilt from source with `pythonRemoveDeps` to strip torch/torchvision from their dependency closures. At runtime, these packages use whatever PyTorch the Flox environment provides (CUDA, MPS, or CPU).

| Package | Description |
|---------|-------------|
| `comfyui-ultralytics` | YOLO object detection |
| `comfyui-timm` | PyTorch Image Models |
| `comfyui-open-clip-torch` | OpenAI CLIP implementation |
| `comfyui-accelerate` | HuggingFace distributed training |
| `comfyui-segment-anything` | Meta SAM segmentation |
| `comfyui-clip-interrogator` | Image-to-prompt |
| `comfyui-transparent-background` | ML-based background removal (x86_64-linux only) |
| `comfyui-pixeloe` | Pixel art conversion (x86_64-linux only) |
| `comfyui-spandrel` | Upscaler model architectures |
| `comfyui-peft` | Parameter-efficient fine-tuning |
| `comfyui-facexlib` | Face processing library |
| `comfyui-sam2` | Segment Anything Model 2 |
| `comfyui-thop` | PyTorch model profiler |

### Runtime Directory Pattern

The Nix store is read-only. ComfyUI expects to write to its application directory (custom node configs, web extensions, model downloads). The runtime directory pattern bridges this gap.

`comfyui-setup` creates `$FLOX_ENV_CACHE/comfyui-runtime` that mirrors the store layout with writable overlays:

```
Nix store (read-only)                    Runtime directory (writable)
result-comfyui-complete/                 $FLOX_ENV_CACHE/comfyui-runtime/
  share/comfyui/                           main.py          -> symlink to store
    main.py                                nodes.py         -> symlink to store
    nodes.py                               comfy/           -> symlink to store
    comfy/                                 comfy_extras/    -> symlink to store
    comfy_extras/                          web/             -> COPIED (writable, for JS extensions)
    web/                                   custom_nodes/    -> symlinks to ~/comfyui-work/custom_nodes/*
    custom_nodes/                          models/          -> symlink to ~/comfyui-work/models
                                           .runtime_version -> cache invalidation marker

                                         ~/comfyui-work/
                                           models/          -> writable, for model downloads
                                           custom_nodes/    -> writable copies of bundled nodes + user nodes
                                           user/            -> user preferences
                                           input/           -> input images
                                           output/          -> generated images
```

Bundled custom nodes are copied (not symlinked) to `~/comfyui-work/custom_nodes/` on first setup, so users can modify them. User-added nodes in that directory are symlinked into the runtime.

## Scripts

| Script | Description |
|--------|-------------|
| `comfyui-setup` | Creates venv, installs pip deps, builds runtime directory, copies custom nodes and workflows |
| `comfyui-start` | Builds selective PYTHONPATH, detects GPU, launches `main.py` |
| `start` | Runs `flox services start comfyui`, waits for health check, opens browser |
| `comfyui-download-flux.py` | Downloads FLUX.1-dev models (~22 GB, HF token required) |
| `comfyui-download-sd15.py` | Downloads Stable Diffusion 1.5 models (~4.3 GB) |
| `comfyui-download-sd35.py` | Downloads Stable Diffusion 3.5 Large models (~23 GB, HF token required) |
| `comfyui-download-sdxl.py` | Downloads Stable Diffusion XL 1.0 models (~6.9 GB) |
| `comfyui-download-wan22.py` | Downloads Wan 2.2 video models (~17-30 GB, variants: ti2v-5b, i2v-14b) |
| `comfyui-download-framepack.py` | Downloads FramePack I2V models (~24 GB) |
| `comfyui-download-hunyuan15.py` | Downloads HunyuanVideo 1.5 models (~18-26 GB, variants: i2v, t2v) |

### comfyui-setup

Called from the Flox manifest `[hook] on-activate`. Performs first-time environment bootstrap:

1. Creates a Python venv with `--system-site-packages` (uses uv if available)
2. Installs pip packages that can't be bundled in Nix: `comfyui-manager`, `comfyui-frontend-package`, `comfyui-workflow-templates`, `comfyui-embedded-docs`, `comfy-kitchen`, `matrix-nio`, `kornia` (non-x86_64-linux only)
3. Creates the runtime directory (symlinks store files, copies `web/` and `custom_nodes/`)
4. Copies bundled workflows to `~/comfyui-work/user/default/workflows/`
5. Creates `extra_model_paths.yaml` for model directory mapping

Wrapped with pythonEnv via `wrapProgram --prefix PATH` and `--prefix PYTHONPATH` so it has access to all bundled Python packages.

Supports `COMFYUI_RESET=1 flox activate` to force a full cache reset and re-bootstrap.

### comfyui-start

Used as the Flox service command. On each launch:

1. Builds a selective PYTHONPATH under `$FLOX_ENV_CACHE/.flox-pkgs` that combines:
   - CUDA/MPS torch, torchvision, and most packages from the Flox env's `site-packages`
   - scipy and numpy from the bundled pythonEnv (clean, single-version — see [Flox Profile Merge](#flox-profile-merge-scipy-frankenstein))
2. Detects GPU via `torch.accelerator.current_accelerator()` (falls back to individual CUDA/MPS checks for torch < 2.5)
3. Launches `main.py` with configured listen address, port, model paths, and optional flags

**NOT wrapped** with pythonEnv — see [comfyui-start is NOT Wrapped](#comfyui-start-is-not-wrapped).

### start

Convenience launcher for interactive use:

1. Starts the `comfyui` Flox service if not already running
2. Polls `http://localhost:$COMFYUI_PORT` until the server responds (60 attempts, 0.5s interval)
3. Opens the URL in a browser (handles WSL, xdg-open, macOS open)

### Environment Variables

| Variable | Used By | Default | Description |
|----------|---------|---------|-------------|
| `COMFYUI_WORK_DIR` | setup, start | `~/comfyui-work` | Base directory for mutable data |
| `COMFYUI_MODELS_DIR` | download scripts | `$COMFYUI_WORK_DIR/models` | Models directory |
| `COMFYUI_PORT` | start | `8188` | Server listen port |
| `COMFYUI_LISTEN` | start | `127.0.0.1` | Server listen address |
| `COMFYUI_DEVICE` | start | `auto` | Force device: `auto`, `cpu`, `gpu` |
| `COMFYUI_ENABLE_MANAGER` | start | `1` | Enable ComfyUI-Manager: `1` or `0` |
| `COMFYUI_BASE_DIR` | start | — | Runtime base directory (`--base-directory`) |
| `COMFYUI_OUTPUT_DIR` | start | — | Output directory (`--output-directory`) |
| `COMFYUI_INPUT_DIR` | start | — | Input directory (`--input-directory`) |
| `COMFYUI_USER_DIR` | start | — | User directory (`--user-directory`) |
| `COMFYUI_TEMP_DIR` | start | — | Temp directory (`--temp-directory`) |
| `COMFYUI_DATABASE_URL` | start | — | Database URL (`--database-url`) |
| `COMFYUI_EXTRA_MODEL_PATHS` | setup, start | `$COMFYUI_WORK_DIR/extra_model_paths.yaml` | Extra model paths config |
| `COMFYUI_RESET` | setup | `0` | Set to `1` to force full cache reset |
| `COMFYUI_VENV_DIR` | setup | `$FLOX_ENV_CACHE/venv` | Venv location override |
| `COMFYUI_RUNTIME` | setup | `$FLOX_ENV_CACHE/comfyui-runtime` | Runtime directory override |
| `HF_TOKEN` | download scripts | — | HuggingFace token (required for gated models) |

## Model Download Scripts

### Image Generation

| Command | Model | Size | HF Token |
|---------|-------|------|----------|
| `comfyui-download-sd15.py` | Stable Diffusion 1.5 | ~4.3 GB | Not required |
| `comfyui-download-sdxl.py` | Stable Diffusion XL 1.0 | ~6.9 GB | Not required |
| `comfyui-download-sd35.py` | Stable Diffusion 3.5 Large | ~23 GB | **Required** (gated) |
| `comfyui-download-flux.py` | FLUX.1-dev | ~22 GB | **Required** (gated) |

### Video Generation

| Command | Model | Size | HF Token | VRAM |
|---------|-------|------|----------|------|
| `comfyui-download-wan22.py` | Wan 2.2 TI2V-5B (default) | ~17 GB | Not required | 16+ GB |
| `comfyui-download-wan22.py --variant i2v-14b` | Wan 2.2 I2V-14B MoE (FP8, dual-model) | ~33 GB | Not required | 24+ GB |
| `comfyui-download-wan22.py --variant all` | Wan 2.2 All Variants | ~43 GB | Not required | 24+ GB |
| `comfyui-download-framepack.py` | FramePack I2V (HunyuanVideo, FP8) | ~24 GB | Not required | 24+ GB |
| `comfyui-download-hunyuan15.py` | HunyuanVideo 1.5 I2V (default) | ~18 GB | Not required | 24+ GB |
| `comfyui-download-hunyuan15.py --variant t2v` | HunyuanVideo 1.5 T2V | ~17 GB | Not required | 24+ GB |
| `comfyui-download-hunyuan15.py --variant all` | HunyuanVideo 1.5 All | ~26 GB | Not required | 24+ GB |

Each script supports `--help`, `--dry-run`, and `--models-dir` flags. Model files are placed in the correct subdirectories (checkpoints/, clip/, unet/, vae/, diffusion_models/, clip_vision/) automatically. Video scripts also support `--variant` for downloading specific model variants. Files shared between models (e.g., text encoders, VAE) are automatically skipped if already present.

```bash
export HF_TOKEN=hf_your_token_here
comfyui-download-sd35.py
```

## Known Issues & Workarounds

### Flox Profile Merge (scipy Frankenstein)

**What:** When two packages in a Flox environment propagate different scipy versions, the Flox profile merge combines files from both Nix store paths into a single `site-packages/scipy/` directory. This creates a broken "Frankenstein" scipy where `_propack/` (directory, from scipy 1.16.x) coexists with `_propack.cpython-313.so` (from scipy 1.17.0), causing `ImportError` at runtime.

**Root cause:** In the original dependency graph, `torchsde` propagated scipy 1.16.1 while `torchvision` propagated scipy 1.17.0. The Flox profile file-level merge mixed files from both versions.

**Fix 1 (upstream):** Removed scipy and numpy from torchsde's propagated dependencies in the `build-torchsde` repository. torchsde doesn't directly need scipy — it inherited it transitively.

**Fix 2 (defense-in-depth in comfyui-start):** The launcher script builds a selective PYTHONPATH that symlinks scipy and numpy from the bundled pythonEnv (which has a clean, single-version copy) while taking everything else from the Flox env (for CUDA torch). This guards against future version collisions from any source:

```bash
# From comfyui-start PYTHONPATH construction:
for item in "$sp_dir"/*; do
  case "$(basename "$item")" in
    scipy*|numpy*)
      # Use bundled pythonEnv version instead of Flox env's merged version
      bundled="$bundled_sp/$(basename "$item")"
      [ -e "$bundled" ] && ln -sfn "$bundled" "$flox_pkgs/"
      continue
      ;;
  esac
  ln -sfn "$item" "$flox_pkgs/"
done
export PYTHONPATH="$flox_pkgs${PYTHONPATH:+:$PYTHONPATH}"
```

Python searches: `PYTHONPATH` -> venv -> Flox env site-packages. The clean scipy/numpy in PYTHONPATH (via `.flox-pkgs`) is found before the potentially broken merged version.

### comfyui-start is NOT Wrapped

`comfyui-start` is deliberately NOT wrapped with `wrapProgram`. If it were, `wrapProgram --prefix PYTHONPATH` would prepend the bundled pythonEnv's `site-packages` to PYTHONPATH, putting CPU-only torch ahead of the Flox env's CUDA torch. GPU detection would fail, and all inference would silently run on CPU.

Instead, `comfyui-start` constructs PYTHONPATH at runtime, prioritizing the Flox env's packages (which include CUDA torch) and selectively pulling scipy/numpy from the bundled pythonEnv.

### Platform-Specific Limitations

| Package | Limitation | Reason |
|---------|-----------|--------|
| `comfyui-pixeloe` | x86_64-linux only | kornia-rs build issues on other platforms |
| `comfyui-transparent-background` | x86_64-linux only | kornia-rs dependency |
| `albumentations` | Not on Darwin | stringzilla compilation issues |
| `torchaudio` | Not bundled | nixpkgs 2.10.0 incompatible with torch 2.9.1 (missing `torch/csrc/stable/device.h`); runtime manifest provides it separately |

## Build Versioning

Version metadata is stored in `build-meta/comfyui-complete.json` and read by the Nix expression at eval time. The version scheme ensures successive builds produce distinct store paths in the Flox catalog.

### Schema

```json
{
  "build_version": 59,
  "force_increment": 0,
  "git_rev": "1e05b7a2c406f519e29a3394c1ce8d0ce76f5775",
  "git_rev_short": "1e05b7a",
  "changelog": "ComfyUI 0.18.3, video gen support (Wan 2.2, HunyuanVideo 1.5, FramePack), peft 0.18.1, comfy-aimdo 0.2.12"
}
```

### Version Format

The Nix `version` attribute is `0.18.3+<git_rev_short>` (e.g., `0.18.3+1e05b7a`). The `+` suffix ensures each code commit produces a distinct store path.

### Why Pre-Computed

`.git` is not available during `flox publish` (Nix evaluation happens in a sandbox without the git directory). Build metadata must be computed beforehand and committed to the repo as a JSON file that the Nix expression reads with `builtins.fromJSON`.

### Workflow

```bash
# 1. Commit code changes
git add -A && git commit -m "description"

# 2. Update metadata (captures current HEAD's rev + commit count)
./update-build-meta "what changed"

# 3. Commit metadata
git add build-meta/ && git commit -m "build-meta: update for build"

# 4. Build or publish
flox build comfyui-complete
flox publish comfyui-complete
```

### force_increment

For version bumps without code changes (e.g., upstream dependency updates), manually increment `force_increment` in the JSON. The build version is computed as `commit_count + force_increment`.

### Build Version Marker

The build output contains a marker file at `share/comfyui-complete/flox-build-version-<N>`:

```
build-version: 59
upstream-version: 0.18.3
package-version: 0.18.3+1e05b7a
git-rev: 1e05b7a2c406f519e29a3394c1ce8d0ce76f5775
git-rev-short: 1e05b7a
force-increment: 0
changelog: ComfyUI 0.18.3, video gen support (Wan 2.2, HunyuanVideo 1.5, FramePack), peft 0.18.1, comfy-aimdo 0.2.12
```

## Package Inventory

31 `.nix` files in `.flox/pkgs/`, grouped by function:

### Core (4)

| Package | File | Description |
|---------|------|-------------|
| `comfyui-complete` | `comfyui-complete.nix` | Complete bundled installation (main build target) |
| `comfyui` | `comfyui.nix` | Standalone source distribution (legacy, v0.14.2) |
| `comfyui-extras` | `comfyui-extras.nix` | Meta-package of torch-agnostic Python deps (legacy) |
| `comfyui-workflows` | `comfyui-workflows.nix` | Bundled example workflows (FLUX, SD15, SD35, SDXL, API) |

### Custom Nodes (5)

| Package | File | Description |
|---------|------|-------------|
| `comfyui-plugins` | `comfyui-plugins.nix` | Impact Pack (ltdrdata, v8.28) |
| `comfyui-impact-subpack` | `comfyui-impact-subpack.nix` | Impact Subpack (ltdrdata, v1.3.4) |
| `comfyui-custom-nodes` | `comfyui-custom-nodes.nix` | 14 community nodes + 1 vendored (SafeCLIP-SDXL) |
| `comfyui-controlnet-aux` | `comfyui-controlnet-aux.nix` | ControlNet preprocessors (Fannovel16) |
| `comfyui-videogen` | `comfyui-videogen.nix` | Video generation nodes (6 nodes) |

### Torch-Agnostic ML (13)

| Package | File | Description |
|---------|------|-------------|
| `comfyui-ultralytics` | `comfyui-ultralytics.nix` | YOLO object detection |
| `comfyui-timm` | `timm.nix` | PyTorch Image Models |
| `comfyui-open-clip-torch` | `open-clip-torch.nix` | OpenAI CLIP |
| `comfyui-accelerate` | `comfyui-accelerate.nix` | HuggingFace Accelerate |
| `comfyui-segment-anything` | `segment-anything.nix` | Meta SAM |
| `comfyui-clip-interrogator` | `comfyui-clip-interrogator.nix` | Image-to-prompt |
| `comfyui-transparent-background` | `comfyui-transparent-background.nix` | Background removal (x86_64-linux) |
| `comfyui-pixeloe` | `comfyui-pixeloe.nix` | Pixel art conversion (x86_64-linux) |
| `comfyui-spandrel` | `spandrel.nix` | Upscaler architectures |
| `comfyui-peft` | `comfyui-peft.nix` | Parameter-efficient fine-tuning |
| `comfyui-facexlib` | `comfyui-facexlib.nix` | Face processing |
| `comfyui-sam2` | `comfyui-sam2.nix` | Segment Anything Model 2 |
| `comfyui-thop` | `comfyui-thop.nix` | PyTorch model profiler |

### Supporting (9)

| Package | File | Description |
|---------|------|-------------|
| `onnxruntime-noexecstack` | `onnxruntime-noexecstack.nix` | ONNX inference (execstack fix) |
| `colour-science` | `colour-science.nix` | Color science library |
| `color-matcher` | `color-matcher.nix` | Color matching algorithms |
| `rembg` | `rembg.nix` | Background removal |
| `ffmpy` | `ffmpy.nix` | FFmpeg wrapper |
| `img2texture` | `img2texture.nix` | Seamless texture generation |
| `cstr` | `cstr.nix` | Colored terminal strings |
| `pyloudnorm` | `pyloudnorm.nix` | Audio loudness normalization |
| `comfy-aimdo` | `comfy-aimdo.nix` | Aimdo integration |

## Bundled Custom Nodes

24 custom nodes across 5 node packages:

### Impact Pack (`comfyui-plugins.nix`)

| Node | Owner/Repo | Description |
|------|-----------|-------------|
| ComfyUI-Impact-Pack | ltdrdata/ComfyUI-Impact-Pack | Face detection, segmentation, mask operations, batch processing |

### Impact Subpack (`comfyui-impact-subpack.nix`)

| Node | Owner/Repo | Description |
|------|-----------|-------------|
| ComfyUI-Impact-Subpack | ltdrdata/ComfyUI-Impact-Subpack | UltralyticsDetectorProvider, SAMLoader, SAM2 support |

### ControlNet-Aux (`comfyui-controlnet-aux.nix`)

| Node | Owner/Repo | Description |
|------|-----------|-------------|
| comfyui_controlnet_aux | Fannovel16/comfyui_controlnet_aux | ControlNet preprocessors (Canny, depth, pose, segmentation, etc.) |

### Community Nodes (`comfyui-custom-nodes.nix`)

| Node | Owner/Repo | Description |
|------|-----------|-------------|
| rgthree-comfy | rgthree/rgthree-comfy | Quality-of-life workflow improvements |
| images-grid-comfy-plugin | LEv145/images-grid-comfy-plugin | Image grid generation utilities |
| ComfyUI-Image-Saver | alexopus/ComfyUI-Image-Saver | Enhanced image saving with metadata |
| ComfyUI_UltimateSDUpscale | ssitu/ComfyUI_UltimateSDUpscale | Advanced SD upscaling |
| ComfyUI-KJNodes | kijai/ComfyUI-KJNodes | KJ's comprehensive node collection |
| ComfyUI_essentials | cubiq/ComfyUI_essentials | Essential utility nodes |
| ComfyUI-Custom-Scripts | pythongosssss/ComfyUI-Custom-Scripts | Custom script and widget nodes |
| ComfyUI_Comfyroll_CustomNodes | Suzie1/ComfyUI_Comfyroll_CustomNodes | Comfyroll node collection |
| efficiency-nodes-comfyui | jags111/efficiency-nodes-comfyui | Efficiency workflow nodes |
| was-node-suite-comfyui | WASasquatch/was-node-suite-comfyui | WAS comprehensive node suite |
| ComfyUI-mxToolkit | Smirnov75/ComfyUI-mxToolkit | MX toolkit nodes |
| ComfyUI_IPAdapter_plus | cubiq/ComfyUI_IPAdapter_plus | IPAdapter image-to-image conditioning |
| ComfyUI-IPAdapter-Flux | Shakker-Labs/ComfyUI-IPAdapter-Flux | IPAdapter for FLUX models |
| Comfyui-LayerForge | Azornes/Comfyui-LayerForge | Photoshop-like layer editor |
| ComfyUI-SafeCLIP-SDXL | — (vendored) | Safe CLIP encoding for SDXL |

### Video Generation (`comfyui-videogen.nix`)

| Node | Owner/Repo | Description |
|------|-----------|-------------|
| ComfyUI-AnimateDiff-Evolved | Kosinkadink/ComfyUI-AnimateDiff-Evolved | AnimateDiff video generation |
| ComfyUI-VideoHelperSuite | Kosinkadink/ComfyUI-VideoHelperSuite | Video loading, combining, previewing |
| ComfyUI-LTXVideo | Lightricks/ComfyUI-LTXVideo | Lightricks LTX-Video generation |
| ComfyUI-WanVideoWrapper | kijai/ComfyUI-WanVideoWrapper | Wan Video text/image-to-video |
| ComfyUI-FramePackWrapper | kijai/ComfyUI-FramePackWrapper | FramePack video generation (HunyuanVideo backbone) |
| ComfyUI-HunyuanVideoWrapper | kijai/ComfyUI-HunyuanVideoWrapper | HunyuanVideo text/image-to-video |

## Patches

### ComfyUI Core

- **Broken symlink handling (`nodes.py`)**: ComfyUI's `load_custom_node()` crashes with `UnboundLocalError` when it encounters a broken symlink in `custom_nodes/`. The code only sets `sys_module_name` for files or directories, not broken symlinks. Patch adds an `else` clause that logs a warning and returns `False`.

### Python Package Overrides

| Package | Fix | Platform |
|---------|-----|----------|
| `asyncer` | Add missing `sniffio` runtime dependency | All |
| `gguf` | Add missing `requests` runtime dependency | All |
| `pyarrow` | Disable tests (`test_timezone_absent` failure) | Darwin only |
| `dask` | Disable tests and `pythonImportsCheck` (crash on aarch64-darwin) | Darwin only |

### Custom Node Patches

| Node | Patch | Reason |
|------|-------|--------|
| ComfyUI_Comfyroll_CustomNodes | Fix `\W`, `\R` escape sequences | Python 3.12+ SyntaxWarning |
| ComfyUI_essentials | Fix `\.` escape sequences in docstrings | Python 3.12+ SyntaxWarning |
| ComfyUI-Custom-Scripts | Use `COMFYUI_BASE_DIR` env var for web directory; handle `PermissionError` on `makedirs` | Nix store is read-only |

### Pre-Created Configs

| File | Node | Reason |
|------|------|--------|
| `pysssss.json` | ComfyUI-Custom-Scripts | Normally created at runtime, fails on read-only store |
| `was_suite_config.json` | was-node-suite-comfyui | Normally created at runtime, fails on read-only store |
| `logs/` directory | Comfyui-LayerForge | Prevents `PermissionError` on first log write |

## Repository Structure

```
build-comfyui/
├── .flox/
│   ├── env/
│   │   └── manifest.toml          # Flox build environment
│   └── pkgs/
│       ├── comfyui-complete.nix   # Main build target (bundles everything)
│       ├── comfyui.nix            # Standalone source distribution (legacy)
│       ├── comfyui-extras.nix     # Torch-agnostic deps meta-package (legacy)
│       ├── comfyui-workflows.nix  # Bundled example workflows
│       ├── comfyui-plugins.nix    # Impact Pack
│       ├── comfyui-impact-subpack.nix
│       ├── comfyui-custom-nodes.nix   # 14 community nodes + 1 vendored
│       ├── comfyui-controlnet-aux.nix
│       ├── comfyui-videogen.nix       # 4 video generation nodes
│       ├── comfyui-ultralytics.nix    # ┐
│       ├── timm.nix                   # │
│       ├── open-clip-torch.nix        # │
│       ├── comfyui-accelerate.nix     # │
│       ├── segment-anything.nix       # │ 13 torch-agnostic
│       ├── comfyui-clip-interrogator.nix  # │ ML packages
│       ├── comfyui-transparent-background.nix # │
│       ├── comfyui-pixeloe.nix        # │
│       ├── spandrel.nix               # │
│       ├── comfyui-peft.nix           # │
│       ├── comfyui-facexlib.nix       # │
│       ├── comfyui-sam2.nix           # │
│       ├── comfyui-thop.nix           # ┘
│       ├── onnxruntime-noexecstack.nix # ┐
│       ├── colour-science.nix          # │
│       ├── color-matcher.nix           # │
│       ├── rembg.nix                   # │ 9 supporting
│       ├── ffmpy.nix                   # │ packages
│       ├── img2texture.nix             # │
│       ├── cstr.nix                    # │
│       ├── pyloudnorm.nix             # │
│       └── comfy-aimdo.nix            # ┘
├── build-meta/
│   └── comfyui-complete.json      # Build version metadata
├── scripts/
│   ├── comfyui-setup              # Reference setup script
│   ├── start                      # Reference start script
│   ├── comfyui-download-flux.py
│   ├── comfyui-download-sd15.py
│   ├── comfyui-download-sd35.py
│   ├── comfyui-download-sdxl.py
│   ├── comfyui-download-wan22.py
│   ├── comfyui-download-framepack.py
│   └── comfyui-download-hunyuan15.py
├── sources/
│   ├── ComfyUI-SafeCLIP-SDXL/     # Vendored custom node
│   ├── workflows/                  # Bundled workflow files
│   ├── color_matcher-*.whl         # Vendored wheel
│   ├── cstr-*.tar.gz               # Vendored source
│   └── img2texture-*.tar.gz        # Vendored source
├── update-build-meta              # Build metadata update script
├── flake.nix                      # Nix flake configuration
├── flake.lock
└── README.md
```

## Related Repositories

- **[build-torchsde](https://github.com/barstoolbluz/build-torchsde)** — torchsde rebuilt without torch/scipy/numpy propagated deps (fixes scipy Frankenstein)
- **[build-comfyui-packages](https://github.com/barstoolbluz/build-comfyui-packages)** — Torch-agnostic Python packages for ComfyUI
- **comfyui** — Runtime Flox environment that consumes this build output and provides GPU-specific PyTorch
- **[ComfyUI](https://github.com/comfyanonymous/ComfyUI)** — Upstream application

## License

ComfyUI is licensed under GPL-3.0. This packaging infrastructure is MIT licensed.
