# segment-anything: Meta's Segment Anything Model for ComfyUI
# ===========================================================
# This package is built WITHOUT torch/torchvision dependencies.
# The runtime environment (comfyui-repo) provides these, allowing
# the user to choose CUDA-enabled versions.

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-segment-anything";
  version = "1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "facebookresearch";
    repo = "segment-anything";
    rev = "main";  # v1.0 is just the main branch
    hash = "sha256-28XHhv/hffVIpbxJKU8wfPvDB63l93Z6r9j1vBOz/P0=";
  };

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  # segment-anything has no mandatory dependencies
  # Optional deps (matplotlib, pycocotools, opencv-python, onnx, onnxruntime)
  # can be installed separately if needed
  dependencies = [ ];

  # Remove any torch references from requirements
  pythonRemoveDeps = [
    "torch"
    "torchvision"
  ];

  # Disable tests - they may require torch
  doCheck = false;

  meta = with lib; {
    description = "Meta's Segment Anything Model for ComfyUI (torch provided by runtime)";
    homepage = "https://github.com/facebookresearch/segment-anything";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
