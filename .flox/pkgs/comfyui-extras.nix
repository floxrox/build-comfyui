# comfyui-extras: Torch-Agnostic Dependencies for ComfyUI Custom Nodes
# =====================================================================
#
# This meta-package provides all Python dependencies needed by popular
# ComfyUI custom nodes (Impact Pack, WAS Node Suite, Efficiency Nodes, etc.)
# built WITHOUT torch/torchvision in their closures.
#
# WHY TORCH-AGNOSTIC?
# -------------------
# Many Python ML packages (ultralytics, timm, open-clip, accelerate, etc.)
# depend on PyTorch. When installed from standard channels, they pull in
# CPU-only torch/torchvision, which conflicts with CUDA-enabled PyTorch
# and causes GPU operations (like NMS) to fail silently on CPU.
#
# This package rebuilds all torch-dependent packages from source using
# pythonRemoveDeps to strip torch requirements. At runtime, these packages
# use whatever PyTorch the environment provides (CUDA, MPS, or CPU).
#
# INCLUDED PACKAGES:
# ------------------
# ML/Vision (torch-agnostic builds):
#   - ultralytics (YOLO object detection)
#   - timm (PyTorch Image Models)
#   - open-clip-torch (OpenAI CLIP)
#   - accelerate (HuggingFace distributed training)
#   - segment-anything (Meta SAM)
#   - clip-interrogator (image-to-prompt)
#   - transparent-background (background removal)
#   - pixeloe (pixel art conversion)
#   - rembg (background removal)
#   - peft (parameter-efficient fine-tuning)
#   - facexlib (face processing)
#
# Image Processing:
#   - colour-science, color-matcher, albumentations, pymatting
#   - pillow-heif (HEIF/HEIC support)
#
# Audio/Video:
#   - pyloudnorm (audio loudness normalization)
#   - imageio-ffmpeg (FFmpeg wrapper for video I/O)
#
# Utilities:
#   - ffmpy (FFmpeg wrapper), img2texture, cstr
#   - piexif, simpleeval, numba, gitpython, easydict, onnxruntime
#
# PLATFORM FIXES:
# ---------------
# When building via flake.nix, the pyarrow darwin fix overlay is applied
# through the flake's pkgs. This file uses standard callPackage arguments.

{ lib
, python3
, callPackage
, stdenv
}:

let
  # Torch-agnostic ML packages (rebuilt from source without torch deps)
  # Pass python3 through to ensure pyarrow fix propagates on Darwin
  comfyui-ultralytics = callPackage ./comfyui-ultralytics.nix { inherit python3; };
  comfyui-timm = callPackage ./timm.nix { inherit python3; };
  comfyui-open-clip-torch = callPackage ./open-clip-torch.nix { inherit python3; };
  comfyui-accelerate = callPackage ./comfyui-accelerate.nix { inherit python3; };
  comfyui-segment-anything = callPackage ./segment-anything.nix { inherit python3; };
  comfyui-clip-interrogator = callPackage ./comfyui-clip-interrogator.nix { inherit python3; };
  comfyui-transparent-background = callPackage ./comfyui-transparent-background.nix { inherit python3; };
  comfyui-pixeloe = callPackage ./comfyui-pixeloe.nix { inherit python3; };
  comfyui-spandrel = callPackage ./spandrel.nix { inherit python3; };
  comfyui-peft = callPackage ./comfyui-peft.nix { inherit python3; };
  comfyui-facexlib = callPackage ./comfyui-facexlib.nix { inherit python3; };

  # Patched packages
  onnxruntime-noexecstack = callPackage ./onnxruntime-noexecstack.nix { inherit python3; };

  # Clean packages (no torch dependencies)
  pyloudnorm = callPackage ./pyloudnorm.nix { inherit python3; };
  colour-science = callPackage ./colour-science.nix { inherit python3; };
  rembg = callPackage ./rembg.nix { inherit python3; inherit onnxruntime-noexecstack; };
  ffmpy = callPackage ./ffmpy.nix { inherit python3; };
  color-matcher = callPackage ./color-matcher.nix { inherit python3; };
  img2texture = callPackage ./img2texture.nix { inherit python3; };
  cstr = callPackage ./cstr.nix { inherit python3; };
in

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-extras";
  version = "0.10.0";
  format = "other";

  # No source - this is a meta-package
  dontUnpack = true;
  dontBuild = true;
  doCheck = false;

  propagatedBuildInputs = (with python3.pkgs; [
    # From nixpkgs - standard packages (no torch contamination)
    piexif          # EXIF metadata handling
    simpleeval      # Safe expression evaluation
    numba           # JIT compilation for numerical code
    gitpython       # Git repository access
    easydict        # Dict with attribute access
    pymatting       # Image matting algorithms
    pillow-heif     # HEIF/HEIC image support
    rich            # Terminal formatting (needed by ComfyUI-Manager)
    imageio-ffmpeg  # FFmpeg wrapper for video I/O
    gguf            # GGUF model format support
    onnx            # ONNX model format library
  ]) ++ lib.optionals (!stdenv.hostPlatform.isDarwin) (with python3.pkgs; [
    # Broken on Darwin due to stringzilla compilation issues
    albumentations  # Image augmentation library
  ]) ++ [
    # Torch-agnostic ML packages (always included)
    comfyui-ultralytics       # YOLO object detection
    comfyui-timm              # PyTorch Image Models
    comfyui-open-clip-torch   # OpenAI CLIP implementation
    comfyui-accelerate        # HuggingFace Accelerate
    comfyui-segment-anything  # Meta SAM segmentation
    comfyui-clip-interrogator # Image to prompt
    comfyui-spandrel          # Upscaler model architectures
    colour-science            # Color science library
    rembg                     # Background removal
    ffmpy                     # FFmpeg wrapper
    color-matcher             # Color matching algorithms
    img2texture               # Seamless texture generation
    cstr                      # Colored terminal strings
    comfyui-peft              # Parameter-efficient fine-tuning
    comfyui-facexlib          # Face processing library
    pyloudnorm                # Audio loudness normalization
    onnxruntime-noexecstack   # ONNX inference (execstack fix for hardened kernels)
  ] ++ lib.optionals (stdenv.hostPlatform.system == "x86_64-linux") [
    # x86_64-linux only (kornia-rs build issues on other platforms)
    comfyui-pixeloe               # Pixel art conversion
    comfyui-transparent-background # Background removal (ML-based)
  ];

  installPhase = ''
    mkdir -p $out
    echo "${version}" > $out/version
  '';

  meta = with lib; {
    description = "Torch-agnostic Python dependencies for ComfyUI custom nodes";
    longDescription = ''
      A comprehensive collection of Python packages required by popular ComfyUI
      custom nodes including Impact Pack, WAS Node Suite, and Efficiency Nodes.

      All ML packages that normally depend on PyTorch (ultralytics, timm,
      open-clip, accelerate, segment-anything, clip-interrogator, etc.) have
      been rebuilt WITHOUT torch/torchvision in their closures. This ensures
      they use the CUDA-enabled PyTorch provided by the runtime environment,
      avoiding conflicts with CPU-only torch that can cause GPU operations
      to silently fall back to CPU.

      Includes: ultralytics, timm, open-clip-torch, accelerate, segment-anything,
      clip-interrogator, transparent-background, pixeloe, rembg, colour-science,
      color-matcher, albumentations, pymatting, pillow-heif, ffmpy, and more.
    '';
    homepage = "https://github.com/barstoolbluz/build-comfyui-packages";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
