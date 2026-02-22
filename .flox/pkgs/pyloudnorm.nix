# pyloudnorm: Audio Loudness Normalization
# ==========================================
# ITU-R BS.1770-4 compliant audio loudness measurement and normalization.
# Pure Python package with only scipy/numpy dependencies.
#
# Used by: WanVideoWrapper (audio processing in video generation)
# Version: 0.2.0

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "pyloudnorm";
  version = "0.2.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "csteinmetz1";
    repo = "pyloudnorm";
    tag = "v${version}";
    hash = "sha256-47CU/veoOQYv5G1QBm3F+j7ltmVvcWSY4hQWtaC6WEI=";
  };

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python3.pkgs; [
    scipy
    numpy
  ];

  doCheck = false;

  meta = with lib; {
    description = "Audio loudness normalization (ITU-R BS.1770-4)";
    homepage = "https://github.com/csteinmetz1/pyloudnorm";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
