{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision for compatibility
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/fe5e41d7ffc0421f0913e8472ce6238ed0daf8e3.tar.gz";
  }) {
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
  };

  inherit (nixpkgs_pinned) lib stdenv fetchFromGitHub python3 makeWrapper bash;
in

stdenv.mkDerivation rec {
  pname = "comfyui-plugins";
  version = "0.6.0";  # Match ComfyUI version

  # Start with just Impact Pack for now
  src = fetchFromGitHub {
    owner = "ltdrdata";
    repo = "ComfyUI-Impact-Pack";
    rev = "8.28";  # Latest version
    hash = "sha256-V/gMPqo9Xx21+KpG5LPzP5bML9nGlHHMyVGoV+YgFWE=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    # Create directory structure
    mkdir -p $out/share/comfyui/custom_nodes
    mkdir -p $out/bin

    # Install Impact Pack
    cp -r . $out/share/comfyui/custom_nodes/ComfyUI-Impact-Pack

    # Create activation script that links plugins into ComfyUI
    cat > $out/bin/comfyui-activate-plugins << 'EOF'
    #!${bash}/bin/bash
    set -e

    # Determine ComfyUI directory
    if [ -n "$1" ]; then
      COMFYUI_DIR="$1"
    else
      COMFYUI_DIR="''${COMFYUI_WORK_DIR:-$HOME/comfyui-work}/default"
    fi

    if [ ! -d "$COMFYUI_DIR" ]; then
      echo "Error: ComfyUI directory not found: $COMFYUI_DIR"
      echo "Please run ComfyUI at least once or specify the directory:"
      echo "  comfyui-activate-plugins /path/to/comfyui"
      exit 1
    fi

    echo "Activating ComfyUI plugins in: $COMFYUI_DIR"

    # Create custom_nodes directory if it doesn't exist
    mkdir -p "$COMFYUI_DIR/custom_nodes"

    # Link each plugin
    for plugin in ${placeholder "out"}/share/comfyui/custom_nodes/*; do
      plugin_name=$(basename "$plugin")
      target="$COMFYUI_DIR/custom_nodes/$plugin_name"

      if [ -e "$target" ]; then
        echo "  ⚠️  $plugin_name already exists, skipping"
      else
        ln -sf "$plugin" "$target"
        echo "  ✅ Activated $plugin_name"
      fi
    done

    echo ""
    echo "Plugins activated! Restart ComfyUI to use them."
    echo ""
    echo "Installed plugins:"
    echo "  • Impact Pack - Face detection & enhancement"
    echo ""
    echo "To download required models, run:"
    echo "  comfyui-download-impact-models"
    EOF
    chmod +x $out/bin/comfyui-activate-plugins

    # Create model download script for Impact Pack
    cat > $out/bin/comfyui-download-impact-models << 'EOF'
    #!${bash}/bin/bash
    set -e

    COMFYUI_DIR="''${COMFYUI_WORK_DIR:-$HOME/comfyui-work}/default"
    MODELS_DIR="$COMFYUI_DIR/models"

    echo "Downloading Impact Pack models to: $MODELS_DIR"

    # Create directories
    mkdir -p "$MODELS_DIR/ultralytics/bbox"

    # Download face detection model (essential)
    if [ ! -f "$MODELS_DIR/ultralytics/bbox/face_yolov8m.pt" ]; then
      echo "Downloading face detection model..."
      wget -q --show-progress -O "$MODELS_DIR/ultralytics/bbox/face_yolov8m.pt" \
        "https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt"
      echo "  ✅ face_yolov8m.pt downloaded"
    else
      echo "  ⚠️  face_yolov8m.pt already exists"
    fi

    echo ""
    echo "Model download complete! Impact Pack is ready to use."
    EOF
    chmod +x $out/bin/comfyui-download-impact-models

    runHook postInstall
  '';

  meta = with lib; {
    description = "Essential custom node plugins for ComfyUI";
    longDescription = ''
      Collection of essential ComfyUI custom nodes:
      - Impact Pack: Face detection and enhancement

      After installation, run:
      1. comfyui-activate-plugins  # Link plugins to ComfyUI
      2. comfyui-download-impact-models  # Download required models
    '';
    license = licenses.gpl3Only;
    platforms = platforms.all;
  };
}