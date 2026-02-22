# comfyui-clip-interrogator: CLIP Interrogator for ComfyUI
# =========================================================
# This package is built WITHOUT torch/torchvision dependencies.
# The runtime environment (comfyui-repo) provides these, allowing
# the user to choose CUDA-enabled versions.
#
# Original deps: torch, torchvision, open_clip_torch, accelerate, transformers
# We remove all torch-dependent packages - runtime environment provides them.

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-clip-interrogator";
  version = "0.6.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pharmapsychotic";
    repo = "clip-interrogator";
    tag = "v${version}";
    hash = "sha256-cccVl689afyBf5EDrlGQAfjUJbxE3CoOqoWrHtPRhPM=";
  };

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python3.pkgs; [
    # Core dependencies only - torch ecosystem provided by runtime
    pillow
    requests
    safetensors
    tqdm
  ];

  # Remove torch-dependent packages from requirements
  # Runtime environment provides: torch, torchvision, open_clip_torch, accelerate, transformers
  pythonRemoveDeps = [
    "torch"
    "torchvision"
    "open_clip_torch"
    "accelerate"
    "transformers"
  ];

  # Disable tests - they require torch at build time
  doCheck = false;

  meta = with lib; {
    description = "CLIP Interrogator for ComfyUI (torch/torchvision provided by runtime)";
    homepage = "https://github.com/pharmapsychotic/clip-interrogator";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
