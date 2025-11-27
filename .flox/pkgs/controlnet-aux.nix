{ lib
, python3
}:

python3.pkgs.buildPythonPackage rec {
  pname = "controlnet-aux";
  version = "0.0.10";
  format = "wheel";

  # Use vendored source from repository
  src = ../../.flox/sources/controlnet_aux-${version}-py3-none-any.whl;

  propagatedBuildInputs = with python3.pkgs; [
    torch
    importlib-metadata
    huggingface-hub
    scipy
    opencv-python
    filelock
    numpy
    pillow
    einops
    torchvision
    timm
    scikit-image
  ];

  # Skip build and tests
  dontBuild = true;
  doCheck = false;

  meta = with lib; {
    description = "ControlNet preprocessor library for ComfyUI";
    homepage = "https://github.com/Mikubill/controlnet-aux";
    license = licenses.asl20;
  };
}
