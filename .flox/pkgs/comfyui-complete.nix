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
  comfyuiVersion = "0.11.0";

  # Fix test failures on Darwin
  # - pyarrow: test_timezone_absent fails because macOS handles timezone lookups differently
  # - dask: test_series_aggregations_multilevel crashes workers on aarch64-darwin
  #         pythonImportsCheck also fails because dask.array requires numpy at import time
  # We override python3 so its .pkgs attribute has these packages with tests disabled
  python3Fixed = if stdenv.hostPlatform.isDarwin then
    python3.override {
      packageOverrides = pfinal: pprev: {
        pyarrow = pprev.pyarrow.overridePythonAttrs (old: {
          doCheck = false;
        });
        dask = pprev.dask.overridePythonAttrs (old: {
          doCheck = false;
          pythonImportsCheck = [];  # dask.array requires numpy which isn't available during check
        });
      };
    }
  else
    python3;

  # Import all the torch-agnostic packages
  # Pass python3 = python3Fixed to ensure pyarrow fix propagates
  comfyui-ultralytics = callPackage ./comfyui-ultralytics.nix { python3 = python3Fixed; };
  comfyui-timm = callPackage ./timm.nix { python3 = python3Fixed; };
  comfyui-open-clip-torch = callPackage ./open-clip-torch.nix { python3 = python3Fixed; };
  comfyui-accelerate = callPackage ./comfyui-accelerate.nix { python3 = python3Fixed; };
  comfyui-segment-anything = callPackage ./segment-anything.nix { python3 = python3Fixed; };
  comfyui-clip-interrogator = callPackage ./comfyui-clip-interrogator.nix { python3 = python3Fixed; };
  comfyui-transparent-background = callPackage ./comfyui-transparent-background.nix { python3 = python3Fixed; };
  comfyui-pixeloe = callPackage ./comfyui-pixeloe.nix { python3 = python3Fixed; };
  comfyui-spandrel = callPackage ./spandrel.nix { python3 = python3Fixed; };
  comfyui-peft = callPackage ./comfyui-peft.nix { python3 = python3Fixed; };
  comfyui-facexlib = callPackage ./comfyui-facexlib.nix { python3 = python3Fixed; };
  comfyui-sam2 = callPackage ./comfyui-sam2.nix { python3 = python3Fixed; };
  comfyui-thop = callPackage ./comfyui-thop.nix { python3 = python3Fixed; };
  onnxruntime-noexecstack = callPackage ./onnxruntime-noexecstack.nix { python3 = python3Fixed; };
  pyloudnorm = callPackage ./pyloudnorm.nix { python3 = python3Fixed; };
  colour-science = callPackage ./colour-science.nix { python3 = python3Fixed; };
  rembg = callPackage ./rembg.nix { python3 = python3Fixed; inherit onnxruntime-noexecstack; };
  ffmpy = callPackage ./ffmpy.nix { python3 = python3Fixed; };
  color-matcher = callPackage ./color-matcher.nix { python3 = python3Fixed; };
  img2texture = callPackage ./img2texture.nix { python3 = python3Fixed; };
  cstr = callPackage ./cstr.nix { python3 = python3Fixed; };
  comfy-aimdo = callPackage ./comfy-aimdo.nix { python3 = python3Fixed; };

  # Custom node packages
  # Note: comfyui-plugins, comfyui-custom-nodes, comfyui-videogen, comfyui-workflows
  # are source-only packages (stdenv.mkDerivation) that don't accept python3
  comfyui-plugins = callPackage ./comfyui-plugins.nix { };
  comfyui-impact-subpack = callPackage ./comfyui-impact-subpack.nix { python3 = python3Fixed; };
  comfyui-custom-nodes = callPackage ./comfyui-custom-nodes.nix { };
  comfyui-controlnet-aux = callPackage ./comfyui-controlnet-aux.nix { python3 = python3Fixed; };
  comfyui-videogen = callPackage ./comfyui-videogen.nix { };
  comfyui-workflows = callPackage ./comfyui-workflows.nix { };

  # Python with all dependencies
  pythonEnv = python3Fixed.withPackages (ps: with ps; [
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
    dill          # Required by Impact-Subpack
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
    hash = "sha256-CcA3xTVmBVLGMtM5F74R2LfwafFDxFHZ1uzx5MvrB/4=";
  };

in stdenv.mkDerivation rec {
  pname = "comfyui-complete";
  version = comfyuiVersion;

  src = comfyuiSrc;

  nativeBuildInputs = [ makeWrapper ];

  # Patch: Handle broken symlinks gracefully in custom_nodes loading
  # Without this fix, broken symlinks cause UnboundLocalError for sys_module_name
  # because the code only sets it for isfile() or isdir(), not for broken symlinks.
  postPatch = ''
    substituteInPlace nodes.py \
      --replace-fail \
'    elif os.path.isdir(module_path):
        sys_module_name = module_path.replace(".", "_x_")

    try:' \
'    elif os.path.isdir(module_path):
        sys_module_name = module_path.replace(".", "_x_")
    else:
        logging.warning(f"Skipping invalid module path (broken symlink?): {module_path}")
        return False

    try:'
  '';

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

    # FLOX_BUILD_RUNTIME_VERSION marker
    # This tracks iterations of the build recipe, not ComfyUI version.
    # Increment this when changing the build/setup logic.
    cat > $out/share/comfyui/.flox-build-v12 << 'FLOX_BUILD'
FLOX_BUILD_RUNTIME_VERSION=12
description: Add matrix-nio for ComfyUI-Manager matrix sharing
date: 2026-02-23
change:
  Add matrix-nio>=0.24 to pip dependencies. This enables the matrix
  sharing feature in ComfyUI-Manager which was previously disabled
  due to missing dependency.
FLOX_BUILD

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

    # Pre-copy JS extensions to web directory (prevents permission errors on startup)
    # Custom nodes like rgthree-comfy and ComfyUI-Custom-Scripts try to copy their JS
    # files to web/extensions at import time, which fails on read-only Nix store.
    echo "Pre-copying JS extensions to web/extensions..."
    mkdir -p $out/share/comfyui/web/extensions

    # rgthree-comfy: copies web/ to web/extensions/rgthree/
    # Newer versions use web/ directory structure with progress_bar.js and other components
    if [ -d "$out/share/comfyui/custom_nodes/rgthree-comfy/web" ]; then
      mkdir -p $out/share/comfyui/web/extensions/rgthree
      cp -r $out/share/comfyui/custom_nodes/rgthree-comfy/web/* $out/share/comfyui/web/extensions/rgthree/
      echo "  - Installed rgthree-comfy JS extensions (web/)"
    elif [ -d "$out/share/comfyui/custom_nodes/rgthree-comfy/js" ]; then
      # Fallback for older versions with js/ directory
      mkdir -p $out/share/comfyui/web/extensions/rgthree
      cp -r $out/share/comfyui/custom_nodes/rgthree-comfy/js/* $out/share/comfyui/web/extensions/rgthree/
      echo "  - Installed rgthree-comfy JS extensions (js/)"
    fi

    # ComfyUI-Custom-Scripts: copies web/ to web/extensions/pysssss/ComfyUI-Custom-Scripts/
    if [ -d "$out/share/comfyui/custom_nodes/ComfyUI-Custom-Scripts/web" ]; then
      mkdir -p "$out/share/comfyui/web/extensions/pysssss/ComfyUI-Custom-Scripts"
      cp -r $out/share/comfyui/custom_nodes/ComfyUI-Custom-Scripts/web/* "$out/share/comfyui/web/extensions/pysssss/ComfyUI-Custom-Scripts/"
      echo "  - Installed ComfyUI-Custom-Scripts JS extensions"
    fi

    # Create the setup script (run at activation to install pip packages)
    cat > $out/bin/comfyui-setup << 'SETUP'
#!/usr/bin/env bash
#
# ComfyUI Complete Setup
# ======================
# Sets up the venv and installs pip packages that can't be bundled in Nix.
# Called from the Flox manifest [hook] on-activate.

set -e

RUNTIME_VERSION="1.2.0"

# Allow user to force reset: COMFYUI_RESET=1 flox activate
if [ "''${COMFYUI_RESET:-0}" = "1" ]; then
  if [ -n "$FLOX_ENV_CACHE" ] && [ -d "$FLOX_ENV_CACHE" ]; then
    echo "COMFYUI_RESET=1 detected - clearing environment cache..."
    rm -rf "$FLOX_ENV_CACHE"
    echo "Cache cleared. Environment will be re-bootstrapped."
  fi
fi

setup_comfyui() {
  local venv="''${COMFYUI_VENV_DIR:-$FLOX_ENV_CACHE/venv}"
  local work_dir="''${COMFYUI_WORK_DIR:-$HOME/comfyui-work}"
  local comfyui_source

  # Find ComfyUI source relative to this script
  local script_dir="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"
  comfyui_source="$(dirname "$script_dir")/share/comfyui"

  # Helper: Get package requirement from ComfyUI's requirements.txt
  get_comfyui_requirement() {
    local package="$1"
    local req_file="$comfyui_source/requirements.txt"
    if [ -f "$req_file" ]; then
      grep "^''${package}[=><!]" "$req_file" 2>/dev/null | head -1
    fi
  }

  # Verify ComfyUI source is available
  if [ ! -d "$comfyui_source" ] || [ ! -f "$comfyui_source/main.py" ]; then
    echo "ERROR: ComfyUI source not found at $comfyui_source"
    return 1
  fi

  # Print FLOX_BUILD_RUNTIME_VERSION for debugging
  # This appears in: flox services logs comfyui --follow
  local flox_build_marker
  flox_build_marker=$(ls "$comfyui_source"/.flox-build-v* 2>/dev/null | head -1)
  if [ -n "$flox_build_marker" ]; then
    echo "=============================================="
    echo "FLOX_BUILD_RUNTIME_VERSION: $(basename "$flox_build_marker" | sed 's/.flox-build-v//')"
    echo "RUNTIME_VERSION: $RUNTIME_VERSION"
    echo "Source: $comfyui_source"
    echo "=============================================="
  fi

  # Create work directory structure
  mkdir -p "$work_dir"/{models,output,input,user,custom_nodes}
  mkdir -p "''${FLOX_ENV_CACHE:-$work_dir/.cache}"/{temp,uv,pip,logs}

  # ============================================================
  # RUNTIME DIRECTORY SETUP
  # ============================================================
  # Create runtime directory that mirrors store with writable parts.
  # This allows custom nodes to write configs, download models, etc.

  local comfyui_runtime="''${COMFYUI_RUNTIME:-$FLOX_ENV_CACHE/comfyui-runtime}"
  local version_file="$comfyui_runtime/.runtime_version"

  if [ ! -d "$comfyui_runtime" ] || [ ! -f "$version_file" ] || \
     [ "$(cat "$version_file" 2>/dev/null)" != "$RUNTIME_VERSION" ]; then
    echo "Setting up ComfyUI runtime directory..." >&2
    rm -rf "$comfyui_runtime"
    mkdir -p "$comfyui_runtime"

    # Symlink all files/dirs from store EXCEPT custom_nodes, models, and web
    # (custom_nodes needs to be writable for user nodes, models for downloads, web for extensions)
    for item in "$comfyui_source"/*; do
      item_name=$(basename "$item")
      if [ "$item_name" != "custom_nodes" ] && [ "$item_name" != "models" ] && [ "$item_name" != "web" ]; then
        ln -sfn "$item" "$comfyui_runtime/$item_name"
      fi
    done

    # Create writable custom_nodes directory
    mkdir -p "$comfyui_runtime/custom_nodes"

    # Symlink models to user's work directory (writable, for node downloads)
    ln -sfn "$work_dir/models" "$comfyui_runtime/models"

    # Copy web directory (some custom nodes need to write to web/extensions)
    # Use cp -R (works on both Linux and macOS)
    if [ -d "$comfyui_source/web" ]; then
      echo "Copying web directory for writable extensions..." >&2
      cp -RL "$comfyui_source/web" "$comfyui_runtime/"
      chmod -R u+w "$comfyui_runtime/web" 2>/dev/null || true
    fi

    # Mark version for cache invalidation
    echo "$RUNTIME_VERSION" > "$version_file"
  fi

  # ============================================================
  # CUSTOM NODES SETUP
  # ============================================================
  # Copy bundled custom nodes to user's work directory (if not already there).
  # This allows users to modify nodes while keeping upstream as reference.

  local custom_nodes_store="$comfyui_source/custom_nodes"
  local user_custom_nodes="$work_dir/custom_nodes"

  if [ -d "$custom_nodes_store" ]; then
    for node_dir in "$custom_nodes_store"/*; do
      if [ -d "$node_dir" ]; then
        local node_name=$(basename "$node_dir")
        local target="$user_custom_nodes/$node_name"

        # Remove broken symlinks (symlink exists but target doesn't)
        # These are useless and should be replaced with working versions
        if [ -L "$target" ] && [ ! -e "$target" ]; then
          echo "Removing broken symlink: $node_name" >&2
          rm -f "$target"
        fi

        # Copy node to user work directory if it doesn't exist
        if [ ! -e "$target" ]; then
          echo "Installing custom node: $node_name" >&2
          cp -RL "$node_dir" "$target"
          chmod -R u+w "$target" 2>/dev/null || true
        fi
      fi
    done
  fi

  # Link all user custom_nodes to runtime (including copied Flox nodes)
  if [ -d "$user_custom_nodes" ]; then
    for node_dir in "$user_custom_nodes"/*; do
      if [ -d "$node_dir" ] || [ -L "$node_dir" ]; then
        local node_name=$(basename "$node_dir")
        local target="$comfyui_runtime/custom_nodes/$node_name"

        # Skip backup directories
        if [[ "$node_name" == *.backup-* ]]; then
          continue
        fi

        # Skip if already exists in runtime
        if [ -e "$target" ]; then
          continue
        fi

        ln -sfn "$node_dir" "$target"
      fi
    done
  fi

  # ============================================================
  # WORKFLOWS SETUP
  # ============================================================
  # Copy bundled workflows to user's work directory (if not already there).
  # ComfyUI expects workflows in user/default/workflows/

  local workflows_store="$comfyui_source/workflows"
  local user_workflows="$work_dir/user/default/workflows"

  if [ -d "$workflows_store" ]; then
    mkdir -p "$user_workflows"
    for workflow_dir in "$workflows_store"/*; do
      if [ -d "$workflow_dir" ]; then
        local workflow_name=$(basename "$workflow_dir")
        local target="$user_workflows/$workflow_name"

        # Copy workflow to user work directory if it doesn't exist
        if [ ! -d "$target" ]; then
          echo "Installing workflow: $workflow_name" >&2
          cp -r "$workflow_dir" "$target"
          chmod -R u+w "$target" 2>/dev/null || true
        fi
      fi
    done
  fi

  # Create and activate virtual environment with system packages
  if [ ! -d "$venv" ]; then
    echo "Creating Python virtual environment with system packages..."
    if command -v uv &> /dev/null; then
      uv venv "$venv" --python python3 --system-site-packages
    else
      python3 -m venv --system-site-packages "$venv"
    fi
    # Invalidate deps marker since venv is fresh
    rm -f "''${FLOX_ENV_CACHE:-$work_dir/.cache}/.comfyui_deps_installed"
  fi

  # Add venv to PATH for this script
  if [ -d "$venv/bin" ]; then
    export PATH="$venv/bin:$PATH"
  fi

  # Install ComfyUI pip dependencies if not already done
  local deps_marker="''${FLOX_ENV_CACHE:-$work_dir/.cache}/.comfyui_deps_installed"
  if [ ! -f "$deps_marker" ]; then
    echo "Installing ComfyUI pip dependencies..."

    # Use uv if available, else pip
    local pip_cmd="pip install"
    if command -v uv &> /dev/null; then
      pip_cmd="uv pip install --python $venv/bin/python"
    fi

    # Install packages that need to be pip-installed
    $pip_cmd \
      comfyui-workflow-templates==0.8.15 \
      comfyui-embedded-docs==0.4.0 \
      "safetensors>=0.4.2" \
      "comfyui_manager>=4.0" \
      "matrix-nio>=0.24"  # ComfyUI-Manager matrix sharing feature

    # Install frontend package (version from ComfyUI's requirements.txt)
    frontend_req=$(get_comfyui_requirement "comfyui-frontend-package")
    if [ -n "$frontend_req" ]; then
      echo "Installing $frontend_req..."
      $pip_cmd "$frontend_req"
    else
      echo "Installing comfyui-frontend-package (fallback)..."
      $pip_cmd "comfyui-frontend-package>=1.37.11"
    fi

    # Install comfy-kitchen without deps to avoid pulling torch from PyPI
    if command -v uv &> /dev/null; then
      uv pip install --python "$venv/bin/python" --no-deps "comfy-kitchen>=0.2.7"
    else
      pip install --no-deps "comfy-kitchen>=0.2.7"
    fi

    # Install kornia only on non-x86_64-linux platforms (we have it from Flox on Linux)
    if [ "$(uname -m)" != "x86_64" ] || [ "$(uname -s)" != "Linux" ]; then
      echo "Installing kornia via pip (not available in Flox for this platform)..."
      if command -v uv &> /dev/null; then
        uv pip install --no-deps --python "$venv/bin/python" "kornia>=0.7.1"
        uv pip install --python "$venv/bin/python" kornia-rs
      else
        pip install --no-deps "kornia>=0.7.1"
        pip install kornia-rs
      fi
    fi

    touch "$deps_marker"
    echo "ComfyUI pip dependencies installed successfully"
  fi

  # Create extra_model_paths.yaml if it doesn't exist
  local extra_paths="''${COMFYUI_EXTRA_MODEL_PATHS:-$work_dir/extra_model_paths.yaml}"
  if [ ! -f "$extra_paths" ]; then
    cat > "$extra_paths" << 'YAML'
comfyui_work:
    base_path: ~/comfyui-work/models
    checkpoints: checkpoints/
    clip: clip/
    clip_vision: clip_vision/
    controlnet: controlnet/
    embeddings: embeddings/
    gligen: gligen/
    hypernetworks: hypernetworks/
    loras: loras/
    photomaker: photomaker/
    style_models: style_models/
    unet: unet/
    upscale_models: upscale_models/
    vae: vae/
    vae_approx: vae_approx/
    diffusion_models: diffusion_models/
    ultralytics: ultralytics/
    ultralytics_bbox: ultralytics/bbox/
    ultralytics_segm: ultralytics/segm/
    sams: sams/
    mmdets: mmdets/
    onnx: onnx/
    ipadapter: ipadapter/
    inpaint: inpaint/
YAML
    echo "Created $extra_paths"
  fi
}

setup_comfyui

echo ""
echo "ComfyUI Complete - Setup finished"
echo ""
SETUP

    chmod +x $out/bin/comfyui-setup

    # Wrap setup script with Python environment
    wrapProgram $out/bin/comfyui-setup \
      --prefix PATH : ${pythonEnv}/bin \
      --prefix PYTHONPATH : ${pythonEnv}/${python3Fixed.sitePackages}

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
      --prefix PYTHONPATH : ${pythonEnv}/${python3Fixed.sitePackages}

    # Create 'start' script - starts service and opens browser
    cat > $out/bin/start << 'START_SCRIPT'
#!/usr/bin/env bash
#
# ComfyUI Launcher
# ================
# Starts ComfyUI service and opens the web UI in a browser.
#
# Usage:
#   flox activate -s -- start
#
# Requires:
#   - flox services (for service management)
#   - curl (for health check)
#   - xdg-open or open (for browser, optional)

set -e

PORT="''${COMFYUI_PORT:-8188}"
URL="http://localhost:''${PORT}"

# Start service if not already running
if ! flox services status comfyui 2>/dev/null | grep -q "Running"; then
    echo "Starting ComfyUI service..."
    flox services start comfyui
fi

# Wait for server to be ready
echo "Waiting for ComfyUI to be ready..."
max_attempts=60
attempt=0
while ! curl -s "$URL" >/dev/null 2>&1; do
    sleep 0.5
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "Timeout waiting for ComfyUI to start"
        echo "Check logs with: flox services logs comfyui"
        exit 1
    fi
done

echo "ComfyUI is ready at $URL"

# Open browser
if grep -qi microsoft /proc/version 2>/dev/null; then
    # WSL - use Windows cmd.exe to open default browser
    /mnt/c/Windows/System32/cmd.exe /C start "" "$URL" >/dev/null 2>&1 || echo "Open $URL in your browser"
elif command -v xdg-open &>/dev/null; then
    xdg-open "$URL"
elif command -v open &>/dev/null; then
    open "$URL"
else
    echo "Open $URL in your browser"
fi
START_SCRIPT

    chmod +x $out/bin/start

    # Install model download scripts
    # These scripts help users download models for various workflows (FLUX, SD1.5, SD3.5, SDXL)
    echo "Installing model download scripts..."
    cp ${../../scripts}/comfyui-download-*.py $out/bin/
    chmod +x $out/bin/comfyui-download-*.py

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
        start                      # Start service and open browser
        comfyui-start              # Launch server directly
        comfyui-start --cpu        # Force CPU mode
        comfyui-start --help       # Show all options
    '';
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
    mainProgram = "comfyui-start";
  };
}
