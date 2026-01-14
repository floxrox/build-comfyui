{ lib
, python3
, fetchPypi
}:

python3.pkgs.buildPythonPackage rec {
  pname = "segment-anything";
  version = "1.0";
  format = "setuptools";

  src = fetchPypi {
    pname = "segment_anything";
    inherit version;
    hash = "";  # Will get from build error
  };

  propagatedBuildInputs = with python3.pkgs; [
    numpy
    torch
    torchvision
    opencv4
    matplotlib
    onnxruntime
  ];

  # Skip tests as they require model files
  doCheck = false;

  pythonImportsCheck = [ "segment_anything" ];

  meta = with lib; {
    description = "The Segment Anything Model (SAM) from Meta AI";
    homepage = "https://github.com/facebookresearch/segment-anything";
    license = licenses.asl20;
  };
}