{ lib
, python3
}:

python3.pkgs.buildPythonPackage rec {
  pname = "spandrel";
  version = "0.4.0";
  pyproject = true;

  # Use vendored source from repository
  src = ../../.flox/sources/spandrel-${version}.tar.gz;

  build-system = with python3.pkgs; [
    setuptools
  ];

  propagatedBuildInputs = with python3.pkgs; [
    torch
    torchvision
    numpy
    einops
    pillow
    safetensors
  ];

  doCheck = false;

  meta = with lib; {
    description = "Spandrel is a library for loading and running pre-trained PyTorch models";
    homepage = "https://github.com/chaiNNer-org/spandrel";
    license = licenses.mit;
  };
}
