# comfyui-sam2: Meta's Segment Anything Model 2 for ComfyUI
# =========================================================
# This package is built WITHOUT torch/torchvision dependencies.
# The runtime environment (comfyui-repo) provides these, allowing
# the user to choose CUDA-enabled versions.
#
# SAM2 is the successor to Segment Anything, with improved
# performance and video segmentation capabilities.
#
# Note: SAM2's setup.py normally requires torch at build time.
# We patch it to remove this requirement and disable CUDA extension building.

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-sam2";
  version = "1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "facebookresearch";
    repo = "sam2";
    rev = "main";
    hash = "sha256-pUPaUD/5wOhdJcNYPH9LV5oA1noDeWKconfpIFOyYBQ=";
  };

  # Patch setup.py to remove torch build requirement and disable CUDA extensions
  postPatch = ''
    # Remove torch/torchvision from REQUIRED_PACKAGES in setup.py
    substituteInPlace setup.py \
      --replace-fail '"torch>=2.5.1",' "" \
      --replace-fail '"torchvision>=0.20.1",' ""

    # Disable CUDA extension building (requires torch at build time)
    substituteInPlace setup.py \
      --replace-fail 'BUILD_CUDA = os.getenv("SAM2_BUILD_CUDA", "1") == "1"' 'BUILD_CUDA = False'

    # Remove torch requirement from pyproject.toml build-system
    substituteInPlace pyproject.toml \
      --replace-fail '"torch>=2.5.1",' ""
  '';

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python3.pkgs; [
    # Bundled: standard Python packages (no torch contamination)
    numpy
    tqdm
    hydra-core
    iopath
    pillow
  ];

  # Remove torch/torchvision from package requirements
  # These are provided by the runtime environment
  pythonRemoveDeps = [
    "torch"
    "torchvision"
  ];

  # Disable tests - they require torch and models
  doCheck = false;

  # Skip runtime dependency check since torch isn't available at build time
  dontCheckRuntimeDeps = true;

  meta = with lib; {
    description = "Meta's Segment Anything Model 2 for ComfyUI (torch/torchvision provided by runtime)";
    homepage = "https://github.com/facebookresearch/sam2";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
