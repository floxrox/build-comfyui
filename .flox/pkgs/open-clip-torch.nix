# open-clip-torch: OpenAI CLIP implementation for ComfyUI
# =======================================================
# This package is built WITHOUT torch/torchvision dependencies.
# The runtime environment (comfyui-repo) provides these, allowing
# the user to choose CUDA-enabled versions.
#
# NOTE: This depends on timm, which will be pulled from nixpkgs
# for the build. At runtime, our custom comfyui-timm should be used.

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-open-clip-torch";
  version = "3.2.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "mlfoundations";
    repo = "open_clip";
    tag = "v${version}";
    hash = "sha256-k4/u0XtfBmPSVKfEK3wHqJXtKAuUNkUnk1TLG2S6PPs=";
  };

  build-system = with python3.pkgs; [
    pdm-backend
  ];

  dependencies = with python3.pkgs; [
    ftfy
    huggingface-hub
    protobuf
    regex
    safetensors
    sentencepiece
    tqdm
    # timm removed - will cause issues but runtime provides it
    # torch and torchvision removed - provided by runtime
  ];

  # Remove torch/torchvision AND timm from package requirements
  # timm is removed because nixpkgs timm has torch dep - runtime provides both
  pythonRemoveDeps = [
    "torch"
    "torchvision"
    "timm"
  ];

  # Disable tests - they require torch at build time
  doCheck = false;

  meta = with lib; {
    description = "OpenAI CLIP for ComfyUI (torch/torchvision provided by runtime)";
    homepage = "https://github.com/mlfoundations/open_clip";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
