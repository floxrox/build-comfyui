# comfyui-facexlib: Face Processing Library for ComfyUI
# ======================================================
# Face detection, alignment, parsing, and restoration utilities.
# Built WITHOUT torch/torchvision dependencies.
# Runtime environment provides these, allowing CUDA-enabled versions.
#
# Used by: ComfyUI-nunchaku (face restoration)
# Version: 0.3.0

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-facexlib";
  version = "0.3.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "xinntao";
    repo = "facexlib";
    tag = "v${version}";
    hash = "sha256-ic3hXKJZFOkj30ZjCOfjXHnFRuAZ9ASnj/+pe79vacg=";
  };

  build-system = with python3.pkgs; [
    setuptools
    cython
    numpy
  ];

  dependencies = with python3.pkgs; [
    # Core dependencies (excluding torch/torchvision - provided by runtime)
    filterpy
    numba
    numpy
    opencv4
    pillow
    scipy
    tqdm
  ];

  # Fix Python 3.13 compatibility and version detection
  # setup.py uses exec()+locals() pattern that broke in Python 3.13
  postPatch = ''
    echo "__version__ = '${version}'" > facexlib/version.py

    substituteInPlace setup.py \
      --replace-fail "version=get_version()" "version='${version}'"
  '';

  # Remove torch-contaminated deps - provided by runtime environment
  pythonRemoveDeps = [
    "torch"
    "torchvision"
    "opencv-python"  # Provided as opencv4 in nixpkgs
  ];

  # Disable tests - they require torch at build time
  doCheck = false;

  meta = with lib; {
    description = "Face processing library for ComfyUI (torch provided by runtime)";
    homepage = "https://github.com/xinntao/facexlib";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
