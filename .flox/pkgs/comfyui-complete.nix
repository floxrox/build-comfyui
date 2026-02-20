# comfyui-complete: Complete ComfyUI Installation
# =================================================
# A comprehensive, self-contained ComfyUI package that bundles:
#   - ComfyUI core application
#   - All Python dependencies (torch-agnostic builds)
#   - All custom nodes (Impact Pack, community nodes, etc.)
#   - Setup and launcher scripts
#
# This package avoids venv isolation issues by providing a complete
# Python environment with all dependencies properly configured.
#
# Usage:
#   comfyui-start                    # Launch ComfyUI server
#   comfyui-start --help             # Show all options
#
# Environment Variables:
#   COMFYUI_WORK_DIR    - Base directory for mutable data (default: ~/comfyui-work)
#   COMFYUI_MODELS_DIR  - Models directory (default: $COMFYUI_WORK_DIR/models)
#   COMFYUI_PORT        - Server port (default: 8188)
#   COMFYUI_LISTEN      - Listen address (default: 127.0.0.1)

{ lib
, stdenv
, fetchFromGitHub
, python3
, makeWrapper
, callPackage
, symlinkJoin
}:

let
  # ComfyUI version
  comfyuiVersion = "0.14.2";

  # Import all the torch-agnostic packages
  comfyui-ultralytics = callPackage ./comfyui-ultralytics.nix { };
  comfyui-timm = callPackage ./timm.nix { };
  comfyui-open-clip-torch = callPackage ./open-clip-torch.nix { };
  comfyui-accelerate = callPackage ./comfyui-accelerate.nix { };
  comfyui-segment-anything = callPackage ./segment-anything.nix { };
  comfyui-clip-interrogator = callPackage ./comfyui-clip-interrogator.nix { };
  comfyui-transparent-background = callPackage ./comfyui-transparent-background.nix { };
  comfyui-pixeloe = callPackage ./comfyui-pixeloe.nix { };
  comfyui-spandrel = callPackage ./spandrel.nix { };
  comfyui-peft = callPackage ./comfyui-peft.nix { };
  comfyui-facexlib = callPackage ./comfyui-facexlib.nix { };
  comfyui-sam2 = callPackage ./comfyui-sam2.nix { };
  comfyui-thop = callPackage ./comfyui-thop.nix { };
  onnxruntime-noexecstack = callPackage ./onnxruntime-noexecstack.nix { };
  pyloudnorm = callPackage ./pyloudnorm.nix { };
  colour-science = callPackage ./colour-science.nix { };
  rembg = callPackage ./rembg.nix { inherit onnxruntime-noexecstack; };
  ffmpy = callPackage ./ffmpy.nix { };
  color-matcher = callPackage ./color-matcher.nix { };
  img2texture = callPackage ./img2texture.nix { };
  cstr = callPackage ./cstr.nix { };
  comfy-aimdo = callPackage ./comfy-aimdo.nix { };

  # Custom node packages
  comfyui-plugins = callPackage ./comfyui-plugins.nix { };
  comfyui-impact-subpack = callPackage ./comfyui-impact-subpack.nix { };
  comfyui-custom-nodes = callPackage ./comfyui-custom-nodes.nix { };
  comfyui-controlnet-aux = callPackage ./comfyui-controlnet-aux.nix { };
  comfyui-videogen = callPackage ./comfyui-videogen.nix { };
  comfyui-workflows = callPackage ./comfyui-workflows.nix { };

  # Python with all dependencies
  pythonEnv = python3.withPackages (ps: with ps; [
    # Core ComfyUI dependencies
    torch
    torchvision
    torchaudio
    numpy
    scipy
    pillow
    psutil
    tqdm
    einops
    pyyaml
    aiohttp
    yarl
    transformers
    tokenizers
    sentencepiece
    safetensors
    filelock
    fsspec
    markupsafe
    typing-extensions
    regex
    packaging
    sqlalchemy
    alembic
    pydantic
    pydantic-settings
    diffusers
    av
    huggingface-hub

    # From nixpkgs - standard packages
    piexif
    simpleeval
    numba
    gitpython
    easydict
    pymatting
    pillow-heif
    rich
    imageio-ffmpeg
    gguf
    onnx
    hydra-core    # Required by sam2
    iopath        # Required by sam2
  ] ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    albumentations
  ] ++ [
    # Torch-agnostic ML packages (our custom builds)
    comfyui-ultralytics
    comfyui-timm
    comfyui-open-clip-torch
    comfyui-accelerate
    comfyui-segment-anything
    comfyui-clip-interrogator
    comfyui-spandrel
    colour-science
    rembg
    ffmpy
    color-matcher
    img2texture
    cstr
    comfyui-peft
    comfyui-facexlib
    comfyui-sam2
    comfyui-thop
    pyloudnorm
    onnxruntime-noexecstack
    comfy-aimdo
  ] ++ lib.optionals (stdenv.hostPlatform.system == "x86_64-linux") [
    comfyui-pixeloe
    comfyui-transparent-background
  ]);

  # ComfyUI source
  comfyuiSrc = fetchFromGitHub {
    owner = "comfyanonymous";
    repo = "ComfyUI";
    rev = "v${comfyuiVersion}";
    hash = "sha256-rrkVEnoWp0BBFZS4fMHo72aYZSxy0I3O8C9DMKXsr88=";
  };

in stdenv.mkDerivation rec {
  pname = "comfyui-complete";
  version = comfyuiVersion;

  src = comfyuiSrc;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    # Create directory structure
    mkdir -p $out/share/comfyui
    mkdir -p $out/bin

    # Copy ComfyUI source
    cp -r . $out/share/comfyui/

    # Remove git/CI files
    rm -rf $out/share/comfyui/.git
    rm -rf $out/share/comfyui/.github
    rm -rf $out/share/comfyui/.ci

    # Remove mutable directories (will be created at runtime)
    rm -rf $out/share/comfyui/custom_nodes
    rm -rf $out/share/comfyui/input
    rm -rf $out/share/comfyui/output
    rm -rf $out/share/comfyui/user
    rm -rf $out/share/comfyui/models

    # Create custom_nodes directory and install all custom nodes
    mkdir -p $out/share/comfyui/custom_nodes

    # Impact Pack
    cp -r ${comfyui-plugins}/share/comfyui/custom_nodes/* $out/share/comfyui/custom_nodes/ || true

    # Impact Subpack
    cp -r ${comfyui-impact-subpack}/share/comfyui/custom_nodes/* $out/share/comfyui/custom_nodes/ || true

    # Community custom nodes
    cp -r ${comfyui-custom-nodes}/share/comfyui/custom_nodes/* $out/share/comfyui/custom_nodes/ || true

    # ControlNet-Aux
    cp -r ${comfyui-controlnet-aux}/share/comfyui/custom_nodes/* $out/share/comfyui/custom_nodes/ || true

    # Videogen nodes
    cp -r ${comfyui-videogen}/share/comfyui/custom_nodes/* $out/share/comfyui/custom_nodes/ || true

    # Install workflows
    mkdir -p $out/share/comfyui/workflows
    cp -r ${comfyui-workflows}/share/comfyui/workflows/* $out/share/comfyui/workflows/ || true

    # Create the main launcher script
    cat > $out/bin/comfyui-start << 'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail

# Configuration with defaults
WORK_DIR="''${COMFYUI_WORK_DIR:-$HOME/comfyui-work}"
MODELS_DIR="''${COMFYUI_MODELS_DIR:-$WORK_DIR/models}"
OUTPUT_DIR="''${COMFYUI_OUTPUT_DIR:-$WORK_DIR/output}"
INPUT_DIR="''${COMFYUI_INPUT_DIR:-$WORK_DIR/input}"
USER_DIR="''${COMFYUI_USER_DIR:-$WORK_DIR/user}"
TEMP_DIR="''${COMFYUI_TEMP_DIR:-$WORK_DIR/temp}"
VENV_DIR="''${COMFYUI_VENV_DIR:-$WORK_DIR/venv}"
LISTEN="''${COMFYUI_LISTEN:-127.0.0.1}"
PORT="''${COMFYUI_PORT:-8188}"

# Get script directory to find ComfyUI source
SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"
COMFYUI_SOURCE="$(dirname "$SCRIPT_DIR")/share/comfyui"

echo "ComfyUI Complete Launcher"
echo "========================="
echo ""
echo "Source:    $COMFYUI_SOURCE"
echo "Work dir:  $WORK_DIR"
echo "Models:    $MODELS_DIR"
echo "Venv:      $VENV_DIR"
echo "Listen:    $LISTEN:$PORT"
echo ""

# Create required directories
mkdir -p "$MODELS_DIR"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$INPUT_DIR"
mkdir -p "$USER_DIR"
mkdir -p "$TEMP_DIR"

# Create venv with system site-packages if it doesn't exist
# This allows ComfyUI Manager to pip install additional packages
# while inheriting all packages from the Nix Python environment
if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "Creating venv with system site-packages..."
    python3 -m venv --system-site-packages "$VENV_DIR"
    echo "Venv created at $VENV_DIR"
fi

# Activate the venv
source "$VENV_DIR/bin/activate"

# Create extra_model_paths.yaml if it doesn't exist
EXTRA_PATHS="$WORK_DIR/extra_model_paths.yaml"
if [ ! -f "$EXTRA_PATHS" ]; then
    cat > "$EXTRA_PATHS" << YAML
comfyui:
    base_path: $MODELS_DIR
    checkpoints: checkpoints
    clip: clip
    clip_vision: clip_vision
    configs: configs
    controlnet: controlnet
    diffusion_models: diffusion_models
    diffusers: diffusers
    embeddings: embeddings
    gligen: gligen
    hypernetworks: hypernetworks
    loras: loras
    photomaker: photomaker
    style_models: style_models
    text_encoders: text_encoders
    unet: unet
    upscale_models: upscale_models
    vae: vae
    vae_approx: vae_approx
    ultralytics: ultralytics
    ultralytics_bbox: ultralytics/bbox
    ultralytics_segm: ultralytics/segm
    sams: sams
    mmdets: mmdets
    onnx: onnx
    ipadapter: ipadapter
    inpaint: inpaint
YAML
    echo "Created $EXTRA_PATHS"
fi

# Detect GPU mode
GPU_MODE=""
if python3 -c "
import torch
if torch.cuda.is_available():
    exit(0)
if hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
    exit(0)
exit(1)
" 2>/dev/null; then
    echo "GPU detected"
else
    echo "No GPU detected, using CPU mode"
    GPU_MODE="--cpu"
fi

echo ""
echo "Starting ComfyUI..."
echo ""

# Set COMFYUI_BASE_DIR for custom nodes that need write access
export COMFYUI_BASE_DIR="$COMFYUI_SOURCE"

exec python3 "$COMFYUI_SOURCE/main.py" $GPU_MODE \
    --listen "$LISTEN" \
    --port "$PORT" \
    --output-directory "$OUTPUT_DIR" \
    --input-directory "$INPUT_DIR" \
    --user-directory "$USER_DIR" \
    --temp-directory "$TEMP_DIR" \
    --extra-model-paths-config "$EXTRA_PATHS" \
    "$@"
LAUNCHER

    chmod +x $out/bin/comfyui-start

    # Wrap the launcher with Python environment
    wrapProgram $out/bin/comfyui-start \
      --prefix PATH : ${pythonEnv}/bin \
      --prefix PYTHONPATH : ${pythonEnv}/${python3.sitePackages}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Complete ComfyUI installation with all dependencies and custom nodes";
    longDescription = ''
      A comprehensive, self-contained ComfyUI package that includes:

      - ComfyUI ${comfyuiVersion} core application
      - All Python dependencies (torch-agnostic builds)
      - Impact Pack and Impact Subpack
      - Community custom nodes (rgthree, WAS, efficiency, essentials, etc.)
      - ControlNet-Aux preprocessors
      - Video generation nodes (AnimateDiff, VideoHelperSuite, LTXVideo)
      - Default workflows

      This package avoids venv isolation issues by bundling everything
      into a single derivation with proper Python path configuration.

      Usage:
        comfyui-start              # Launch server
        comfyui-start --cpu        # Force CPU mode
        comfyui-start --help       # Show all options
    '';
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
    mainProgram = "comfyui-start";
  };
}
