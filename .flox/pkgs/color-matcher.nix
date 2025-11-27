{ lib
, python3Packages
, fetchFromGitHub
}:

python3Packages.buildPythonPackage rec {
  pname = "color-matcher";
  version = "0.6.0";
  format = "setuptools";

  # Fetch from GitHub instead of PyPI (more reliable)
  src = fetchFromGitHub {
    owner = "hahnec";
    repo = "color-matcher";
    rev = "v${version}";
    hash = "sha256-VNe0VBGCQ3w6Y/ky6mEmNBx4cJ8DnjHl1YoIj9LnInw=";
  };

  propagatedBuildInputs = with python3Packages; [
    numpy
    scipy
    scikit-image
    opencv4
  ];

  # Skip tests (no test suite in repo)
  doCheck = false;

  pythonImportsCheck = [ "color_matcher" ];

  meta = with lib; {
    description = "Color matcher for images";
    homepage = "https://github.com/hahnec/color-matcher";
    license = licenses.gpl3Only;
    platforms = platforms.all;
  };
}
