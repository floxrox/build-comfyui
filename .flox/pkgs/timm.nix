# timm: PyTorch Image Models for ComfyUI
# =======================================
# This package is built WITHOUT torch/torchvision dependencies.
# The runtime environment (comfyui-repo) provides these, allowing
# the user to choose CUDA-enabled versions.

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-timm";
  version = "1.0.22";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "huggingface";
    repo = "pytorch-image-models";
    tag = "v${version}";
    hash = "sha256-ilOnC1tqSb4TuSGRafMNl8hi9P2qdsBWbv3G9azy6Gs=";
  };

  build-system = with python3.pkgs; [
    pdm-backend
  ];

  dependencies = with python3.pkgs; [
    huggingface-hub
    pyyaml
    safetensors
    # torch and torchvision removed - provided by runtime
  ];

  # Remove torch/torchvision from package requirements
  pythonRemoveDeps = [
    "torch"
    "torchvision"
  ];

  # Disable tests - they require torch at build time
  doCheck = false;

  meta = with lib; {
    description = "PyTorch Image Models for ComfyUI (torch/torchvision provided by runtime)";
    homepage = "https://huggingface.co/docs/timm/index";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
