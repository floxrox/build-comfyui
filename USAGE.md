# ComfyUI Flox Package

A rock-solid, publishable ComfyUI package for Flox with comprehensive dependency management and workflow support.

## Features

- ✅ **Self-contained** - Works out of the box with generic PyTorch
- ✅ **Optimizable** - Override with CUDA-optimized packages in your environment
- ✅ **Complete dependencies** - All Python packages needed for common workflows
- ✅ **Workflow-ready** - Supports GGUF, ControlNet, upscaling, and more
- ✅ **Interactive model downloads** - Smart token handling with multiple fallbacks
- ✅ **Cross-platform** - Works on Linux and macOS (CPU mode)

## Quick Start

### 1. Install the Package

```bash
flox install yourname/comfyui
```

### 2. Download Models

```bash
# Stable Diffusion 1.5 (4.3GB, no token required)
comfyui-download sd15

# Stable Diffusion XL (6.9GB, no token required)
comfyui-download sdxl

# Stable Diffusion 3.5 Large (27GB, requires HF token)
comfyui-download sd35

# FLUX.1 Dev (23GB FP8, requires HF token)
comfyui-download flux
```

### 3. Run ComfyUI

```bash
comfyui --listen 0.0.0.0 --port 8188
# Open http://localhost:8188 in your browser
```

---

## PyTorch Optimization Guide

The base package includes generic PyTorch from nixpkgs. For CUDA acceleration, override with optimized versions.

### Recommended Optimization Hierarchy

#### Option 1: Pre-built Optimized Packages (Best)

Use published, architecture-specific builds from FloxHub:

```toml
[install]
comfyui.pkg-path = "yourname/comfyui"

# Override with pre-built CUDA-optimized packages
pytorch.pkg-path = "flox/pytorch-python313-cuda12_8-sm86-avx2"
torchvision.pkg-path = "flox/torchvision-python313-cuda12_8-sm86-avx2"
# Note: Bundled numpy/scipy work fine for most users
# Build and publish custom versions if you need CUDA-specific optimizations
```

**Pros:**
- ✅ Latest PyTorch versions
- ✅ Architecture-specific optimizations (SM 8.6, AVX2, etc.)
- ✅ No compile time, instant installation
- ✅ Pre-tested and published

**Available optimized packages:**
- `flox/pytorch-python313-cuda12_8-sm86-avx2` - RTX 3090/A40 (Ampere)
- `flox/pytorch-python313-cuda12_8-sm89-avx512` - RTX 4090 (Ada)
- `flox/pytorch-python313-cuda12_8-sm120-avx512` - RTX 5090 (Blackwell)
- Custom builds (build and publish your own)

#### Option 2: nixpkgs CUDA Version (Good)

Use official nixpkgs CUDA-enabled builds:

```toml
[install]
comfyui.pkg-path = "yourname/comfyui"

# Override with nixpkgs CUDA versions
pytorch.pkg-path = "python313Packages.pytorchWithCuda"
torchvision.pkg-path = "python313Packages.torchvisionWithCuda"
```

**Pros:**
- ✅ Official nixpkgs packages
- ✅ Up-to-date versions
- ✅ Well-maintained

**Cons:**
- ⚠️ May require compile + patch on first installation
- ⚠️ Not architecture-specific (generic CUDA)

#### Option 3: Generic (Default)

The bundled versions work for CPU and basic CUDA:

```toml
[install]
comfyui.pkg-path = "yourname/comfyui"
# No overrides - uses bundled pytorch
```

**Pros:**
- ✅ Works immediately
- ✅ No configuration needed

**Cons:**
- ❌ Not optimized for specific GPUs
- ❌ Slower inference

---

## Building Your Own Optimized PyTorch

For maximum performance on specific hardware:

1. **Clone this repository**
2. **Create custom PyTorch build** (see Flox docs on building packages)
3. **Publish to your catalog**:
   ```bash
   flox publish -o yourcatalog pytorch-custom
   ```
4. **Use in environments**:
   ```toml
   [install]
   pytorch.pkg-path = "yourcatalog/pytorch-custom"
   ```

---

## Model Downloads with Interactive Token Handling

The package includes smart model downloaders with automatic token discovery:

### Token Priority (Automatic)

1. `HF_TOKEN` environment variable
2. `HUGGING_FACE_HUB_TOKEN` environment variable
3. HuggingFace CLI cache (`~/.cache/huggingface/token`)
4. Interactive prompt (with instructions)

### Usage Examples

**With environment variable:**
```bash
export HF_TOKEN=hf_your_token_here
comfyui-download sd35
```

**Runtime override:**
```bash
HF_TOKEN=hf_xxx comfyui-download flux
```

**Interactive (prompts if no token found):**
```bash
comfyui-download sd35
# Script will guide you through getting a token
```

### Available Models

| Model | Size | Token Required | Best For |
|-------|------|----------------|----------|
| `sd15` | 4.3GB | No | Fast iterations, 512x512 |
| `sdxl` | 6.9GB | No | High quality, 1024x1024 |
| `sd35` | 27GB | Yes | Highest quality, flexible |
| `flux` | 23GB | Yes | State-of-the-art, FP8 optimized |

---

## Workflow Support

This package includes dependencies for common ComfyUI workflows:

### Built-in Support

- ✅ **GGUF quantized models** - Reduced VRAM usage (critical for FLUX)
- ✅ **ControlNet preprocessing** - opencv-python + controlnet-aux for advanced preprocessors
- ✅ **FLUX optimization** - nunchaku for faster FLUX inference
- ✅ **Model optimization** - accelerate + spandrel for faster loading
- ✅ **HuggingFace integration** - huggingface-hub for downloads
- ✅ **Image processing** - timm + scikit-image for advanced workflows

### Custom Nodes (User Installation)

The package does NOT bundle custom nodes. Install them separately based on your needs:

#### Essential Custom Nodes

```bash
cd ~/comfyui-work/default/custom_nodes

# Ultimate SD Upscale (tiled upscaling)
git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale

# rgthree (LoRA tools, image comparison)
git clone https://github.com/rgthree/rgthree-comfy

# KJNodes (utilities, torch compile)
git clone https://github.com/kijai/ComfyUI-KJNodes

# Image Saver (advanced metadata)
git clone https://github.com/alexopus/ComfyUI-Image-Saver

# GGUF support (quantized models)
git clone https://github.com/city96/ComfyUI-GGUF
```

#### Optional Custom Nodes

```bash
# Florence-2 (image captioning, VLM)
git clone https://github.com/kijai/ComfyUI-Florence2

# WAS Node Suite (text processing)
git clone https://github.com/WASasquatch/was-node-suite-comfyui

# ControlNet Aux (preprocessors)
git clone https://github.com/Fannovel16/comfyui_controlnet_aux

# mxToolkit (interactive sliders)
git clone https://github.com/Smirnov75/ComfyUI-mxToolkit

# Custom Scripts (debugging)
git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts
```

See [CUSTOM-NODES.md](./CUSTOM-NODES.md) for detailed installation and dependency notes.

---

## Directory Structure

The package uses environment variables for customization:

```bash
# Default directory structure
~/comfyui-work/
├── models/
│   ├── checkpoints/     # SD checkpoints
│   ├── clip/            # CLIP & text encoders
│   ├── unet/            # FLUX UNet models
│   ├── vae/             # VAE models
│   ├── loras/           # LoRA weights
│   ├── upscale_models/  # Upscaler models
│   ├── controlnet/      # ControlNet models
│   └── embeddings/      # Textual inversions
├── output/              # Generated images
├── input/               # Input images
└── temp/                # Temporary files
```

### Customizing Paths

Override with environment variables:

```bash
export COMFYUI_MODELS_DIR=/custom/models
export COMFYUI_OUTPUT_DIR=/custom/output
export COMFYUI_INPUT_DIR=/custom/input
export COMFYUI_TEMP_DIR=/custom/temp

comfyui --listen 0.0.0.0
```

Or in your Flox manifest:

```toml
[vars]
COMFYUI_MODELS_DIR = "/mnt/storage/models"
COMFYUI_OUTPUT_DIR = "/mnt/storage/output"
```

---

## Python Dependencies

### Core Dependencies (Bundled)

From ComfyUI upstream requirements:
- torch, torchvision, torchaudio, torchsde
- transformers, tokenizers, sentencepiece
- numpy, scipy, pillow, einops
- safetensors, kornia
- aiohttp, yarl
- pyyaml, pydantic, pydantic-settings
- alembic, sqlalchemy
- av, tqdm, psutil

### Workflow Support (Bundled)

Additional packages for common workflows:
- `opencv-python` - ControlNet preprocessors
- `gguf` - Quantized model support
- `accelerate` - Model loading optimization
- `huggingface-hub` - Model downloads
- `spandrel` - PyTorch model loading

### NOT Included

These require custom installation (not in nixpkgs):
- `controlnet_aux` - Install manually if needed for advanced ControlNet preprocessing

---

## Platform Support

- **Linux (x86_64, aarch64)** - Full support with CUDA optimization
- **macOS (x86_64, aarch64)** - CPU mode only, Metal acceleration via custom builds

---

## Troubleshooting

### ComfyUI won't start

```bash
# Check Python environment
comfyui --help

# Verify models directory
ls -la ~/comfyui-work/models/checkpoints/
```

### Model download fails

```bash
# Check token
echo $HF_TOKEN

# Test HuggingFace connection
python3 -c "from huggingface_hub import HfApi; print(HfApi().whoami())"

# Accept model license at https://huggingface.co/<model-repo>
```

### CUDA not detected

```bash
# Verify CUDA-enabled PyTorch
python3 -c "import torch; print(torch.cuda.is_available())"

# Check you're using pytorchWithCuda or optimized build
flox list
```

### Custom node missing dependencies

```bash
# Install per custom node requirements
cd ~/comfyui-work/default/custom_nodes/ComfyUI-Florence2
pip install -r requirements.txt
```

---

## Publishing This Package

```bash
# 1. Ensure clean git state
git add .flox/
git commit -m "Add ComfyUI base package"
git push

# 2. Build and test
flox build comfyui-base

# 3. Publish to your catalog
flox auth login
flox publish -o yourcatalog comfyui-base

# 4. Others can now install
flox install yourcatalog/comfyui
```

---

## Contributing

Workflow support improvements welcome! If you find missing dependencies for specific workflows, please open an issue.

## License

ComfyUI is GPL-3.0. This packaging follows the same license.

## Resources

- [ComfyUI Documentation](https://docs.comfy.org/)
- [Flox Documentation](https://flox.dev/docs)
- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [HuggingFace Models](https://huggingface.co/models?pipeline_tag=text-to-image)
