# comfyui-accelerate: Hugging Face Accelerate for ComfyUI
# ========================================================
# This package is built WITHOUT torch dependencies.
# The runtime environment (comfyui-repo) provides these, allowing
# the user to choose CUDA-enabled versions.

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-accelerate";
  version = "1.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "huggingface";
    repo = "accelerate";
    tag = "v${version}";
    hash = "sha256-XVJqyhDSUPQDHdaB6GDxHhuC6EWCSZNArjzyLpvhQHI=";
  };

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python3.pkgs; [
    # Core dependencies (excluding torch - provided by runtime)
    numpy
    packaging
    psutil
    pyyaml
    huggingface-hub
    safetensors
  ];

  # Remove torch from package requirements
  pythonRemoveDeps = [
    "torch"
  ];

  # Disable tests - they require torch at build time
  doCheck = false;

  meta = with lib; {
    description = "Accelerate for ComfyUI (torch provided by runtime)";
    homepage = "https://github.com/huggingface/accelerate";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
