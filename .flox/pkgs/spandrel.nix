# spandrel: Neural Network Architecture Library for ComfyUI
# =========================================================
# This package is built WITHOUT torch/torchvision dependencies.
# The runtime environment (comfyui-repo) provides these, allowing
# the user to choose CUDA-enabled versions.
#
# Spandrel is used for loading and running various upscaler models.

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-spandrel";
  version = "0.4.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "chaiNNer-org";
    repo = "spandrel";
    tag = "v${version}";
    hash = "sha256-BiC4gmRsNkRAUonKHV7U/hvOP00pIPtm40ydmSlNDCI=";
  };

  # The actual package is in libs/spandrel subdirectory
  sourceRoot = "${src.name}/libs/spandrel";

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python3.pkgs; [
    safetensors
    numpy
    einops
    typing-extensions
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
    description = "Neural Network Architecture Library for ComfyUI (torch/torchvision provided by runtime)";
    homepage = "https://github.com/chaiNNer-org/spandrel";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
