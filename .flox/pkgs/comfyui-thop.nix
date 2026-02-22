# comfyui-thop: Ultralytics THOP for ComfyUI
# ==========================================
# This package is built WITHOUT torch dependency.
# The runtime environment (comfyui-repo) provides PyTorch, allowing
# the user to choose CUDA-enabled versions.
#
# THOP (Torch-OpCounter) profiles PyTorch models by computing
# MACs (Multiply-Accumulate Operations) and parameters.

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-thop";
  version = "2.0.18";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ultralytics";
    repo = "thop";
    tag = "v${version}";
    hash = "sha256-Vi3QURIEZaOk/PJFRB+GEFmksvo2ZSkhXe+HQE6yWcU=";
  };

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python3.pkgs; [
    numpy
  ];

  # Remove torch - provided by runtime's CUDA PyTorch
  pythonRemoveDeps = [
    "torch"
  ];

  # Disable tests - they require torch at build time
  doCheck = false;

  meta = with lib; {
    description = "THOP (Torch-OpCounter) for ComfyUI (torch provided by runtime)";
    homepage = "https://github.com/ultralytics/thop";
    license = licenses.agpl3Only;
    platforms = platforms.unix;
  };
}
