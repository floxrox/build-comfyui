# comfyui-transparent-background: Background Removal for ComfyUI
# ===============================================================
# This package is built WITHOUT torch/torchvision dependencies.
# The runtime environment (comfyui-repo) provides these, allowing
# the user to choose CUDA-enabled versions.
#
# Note: Excluded on aarch64-linux due to kornia-rs build issues.

{ lib
, python3
, fetchFromGitHub
, stdenv
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-transparent-background";
  version = "1.3.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "plemeri";
    repo = "transparent-background";
    tag = "${version}";
    hash = "sha256-jQMz5KMGyE69uAyMKhn27qM5BYtBmi5VgxlHAw39FM8=";
  };

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  # Patch setup.py to remove directory creation that fails in sandbox
  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail 'os.makedirs(os.path.join(cfg_path, ".transparent-background"), exist_ok=True)' 'pass'
  '';

  dependencies = with python3.pkgs; [
    # Core dependencies (excluding torch/torchvision/timm/kornia - provided by runtime)
    opencv4
    tqdm
    gdown
    wget
    easydict
    pyyaml
    pymatting
  ] ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    # albumentations has issues on Darwin
    albumentations
  ];

  # Remove torch/torchvision/timm/kornia from package requirements
  # These are provided by the runtime environment
  pythonRemoveDeps = [
    "torch"
    "torchvision"
    "timm"
    "kornia"
    "opencv-python"  # We provide opencv4 instead
    "albucore"  # Comes with albumentations
  ];

  # Disable runtime deps check - opencv naming differences
  dontCheckRuntimeDeps = true;

  # Disable tests - they require torch at build time
  doCheck = false;

  meta = with lib; {
    description = "Transparent Background for ComfyUI (torch/torchvision provided by runtime)";
    homepage = "https://github.com/plemeri/transparent-background";
    license = licenses.mit;
    # Exclude on aarch64-linux due to kornia-rs build issues
    platforms = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
  };
}
