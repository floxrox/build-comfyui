# comfyui-controlnet-aux: ControlNet Preprocessors for ComfyUI
# =============================================================
# This package provides ComfyUI-ControlNet-Aux (Fannovel16), which adds
# ControlNet preprocessor nodes for image conditioning workflows.
#
# Preprocessors included:
#   - Canny edge detection
#   - Depth estimation (MiDaS, LeReS, Zoe)
#   - Normal map generation
#   - Pose estimation (OpenPose)
#   - Segmentation (Semantic, OneFormer)
#   - Line detection (MLSD, HED, PiDiNet)
#   - Shuffle, Color, Tile, and more
#
# Note: MediaPipe is NOT included (not in nixpkgs, known upstream issues).
# Nodes requiring mediapipe (DWPose, some face detection) won't work.
# Users can install mediapipe manually if needed.
#
# This package bundles Python dependencies and installs to custom_nodes.
# Built WITHOUT torch/torchvision - runtime environment provides these.
#
# Version: 1.1.3 (pinned to commit 136f125c for reproducibility)

{ lib
, python3
, fetchFromGitHub
, callPackage
, stdenv
}:

let
  # Torch-agnostic timm (provides image model architectures)
  comfyui-timm = callPackage ./timm.nix { };
in

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-controlnet-aux";
  version = "1.1.3";
  format = "other";  # Not a Python package, just source files with deps

  src = fetchFromGitHub {
    owner = "Fannovel16";
    repo = "comfyui_controlnet_aux";
    rev = "136f125c89aed92ced1b6fbb491e13719b72fcc0";  # Dec 10, 2025
    hash = "sha256-DlspkqzN7Ls8kXWQMtVQygzsgu/z6FtjMqDthuza/Kc=";
  };

  # Python dependencies from requirements.txt (excluding torch, torchvision, mediapipe)
  propagatedBuildInputs = with python3.pkgs; [
    # Core ML/Vision dependencies
    einops              # Einstein notation for tensor operations
    fvcore              # Facebook Vision Core (model utilities)
    scikit-image        # Image processing algorithms
    scikit-learn        # Machine learning algorithms

    # Data structures and config
    omegaconf           # Hierarchical configuration
    addict              # Dict with attribute access
    yacs                # Yet Another Configuration System
    ftfy                # Text encoding fixes

    # Geometry and visualization
    trimesh             # 3D mesh processing
    matplotlib          # Plotting library
    scipy               # Scientific computing

    # Utilities
    filelock            # File locking
    huggingface-hub     # Model downloading
    importlib-metadata  # Package metadata
    python-dateutil     # Date utilities
    pyyaml              # YAML parsing
    yapf                # Python formatter (used by some preprocessors)

    # Image processing (from nixpkgs)
    opencv4             # OpenCV
    pillow              # PIL
    numpy               # NumPy
  ] ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    # Broken on Darwin due to test failures
    albumentations      # Image augmentation library
  ] ++ [
    # Torch-agnostic dependencies (rebuilt without torch)
    comfyui-timm        # PyTorch Image Models
  ];

  dontBuild = true;
  dontConfigure = true;
  doCheck = false;

  installPhase = ''
    runHook preInstall

    # Create directory structure
    mkdir -p $out/share/comfyui/custom_nodes

    # Install ControlNet-Aux
    cp -r . $out/share/comfyui/custom_nodes/comfyui_controlnet_aux

    # Clean up unnecessary files
    rm -rf $out/share/comfyui/custom_nodes/comfyui_controlnet_aux/.git
    rm -rf $out/share/comfyui/custom_nodes/comfyui_controlnet_aux/.github

    runHook postInstall
  '';

  meta = with lib; {
    description = "ControlNet preprocessors for ComfyUI";
    longDescription = ''
      ComfyUI-ControlNet-Aux provides comprehensive ControlNet preprocessor nodes:

      - Edge detection: Canny, HED, PiDiNet, MLSD, Lineart
      - Depth estimation: MiDaS, LeReS, Zoe Depth
      - Normal maps: BAE Normal
      - Pose estimation: OpenPose (body, face, hands)
      - Segmentation: Semantic, OneFormer, SAM
      - Utility: Shuffle, Color, Tile

      Note: MediaPipe is NOT included due to nixpkgs availability issues.
      DWPose and some face detection nodes won't work without manual
      mediapipe installation.

      Built without torch/torchvision - runtime environment provides these.
    '';
    homepage = "https://github.com/Fannovel16/comfyui_controlnet_aux";
    license = licenses.asl20;  # Apache-2.0
    platforms = platforms.unix;
  };
}
