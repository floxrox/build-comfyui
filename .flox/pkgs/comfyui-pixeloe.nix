# comfyui-pixeloe: PixelOE for ComfyUI
# ====================================
# This package is built WITHOUT torch/torchvision dependencies.
# The runtime environment (comfyui-repo) provides these, allowing
# the user to choose CUDA-enabled versions.
#
# Note: Excluded on aarch64-linux due to kornia-rs build issues.
# Note: No version tags in repo, pinned to specific commit.

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-pixeloe";
  version = "0.1.5-unstable-2025-12-22";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "KohakuBlueleaf";
    repo = "PixelOE";
    rev = "802abe4e8fd887980d01082c98c64c91d0b6d754";
    hash = "sha256-OrivM2TF0HXJ4cDWkKsUxmzSMHxNCMocDdC3xIV/AnE=";
  };

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python3.pkgs; [
    # Core dependencies (excluding torch/torchvision/kornia - provided by runtime)
    opencv4
    numpy
    pillow
    scipy
  ];

  # Remove torch/torchvision/kornia from package requirements
  # These are provided by the runtime environment
  pythonRemoveDeps = [
    "torch"
    "torchvision"
    "kornia"
    "opencv-python"  # We provide opencv4 instead
  ];

  # Disable runtime deps check - opencv naming differences
  dontCheckRuntimeDeps = true;

  # Disable tests - they require torch at build time
  doCheck = false;

  meta = with lib; {
    description = "PixelOE for ComfyUI (torch/torchvision provided by runtime)";
    homepage = "https://github.com/KohakuBlueleaf/PixelOE";
    license = licenses.asl20;
    # Exclude on aarch64-linux due to kornia-rs build issues
    platforms = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
  };
}
