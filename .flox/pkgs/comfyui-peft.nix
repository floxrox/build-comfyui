# comfyui-peft: HuggingFace PEFT for ComfyUI
# =============================================
# Parameter-Efficient Fine-Tuning (PEFT) library.
# Built WITHOUT torch/transformers/accelerate dependencies.
# Runtime environment provides these, allowing CUDA-enabled versions.
#
# Used by: WanVideoWrapper, ComfyUI-nunchaku
# Version: 0.17.1 (matches nixpkgs)

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-peft";
  version = "0.17.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "huggingface";
    repo = "peft";
    tag = "v${version}";
    hash = "sha256-xtpxwbKf7ZaUYblGdwtPZE09qrlBQTMm5oryUJwa6AA=";
  };

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python3.pkgs; [
    # Core dependencies (excluding torch ecosystem - provided by runtime)
    numpy
    packaging
    psutil
    pyyaml
    tqdm
    safetensors
    huggingface-hub
  ];

  # Remove torch-contaminated deps - provided by runtime environment
  pythonRemoveDeps = [
    "torch"          # Runtime's CUDA PyTorch
    "transformers"   # Runtime environment (nixpkgs)
    "accelerate"     # comfyui-accelerate (in comfyui-extras)
  ];

  # Disable tests - they require torch at build time
  doCheck = false;

  meta = with lib; {
    description = "PEFT for ComfyUI (torch provided by runtime)";
    homepage = "https://github.com/huggingface/peft";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
