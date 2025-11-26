{ lib
, python3
, fetchurl
}:

python3.pkgs.buildPythonPackage rec {
  pname = "controlnet-aux";
  version = "0.0.10";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/py3/c/controlnet_aux/controlnet_aux-${version}-py3-none-any.whl";
    hash = "sha256-ytNIDWLH3xrlaSWKZZyI1zCHMyPSrbufb3rr2HkX3zs=";
  };

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
