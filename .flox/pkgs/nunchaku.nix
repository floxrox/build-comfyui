{ lib
, python3
, fetchurl
}:

python3.pkgs.buildPythonPackage rec {
  pname = "nunchaku";
  version = "0.16.1";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/py3/n/nunchaku/nunchaku-${version}-py3-none-any.whl";
    hash = "sha256-qP1b+b+a3MWYcdXNj5AiZfOlX5AKxByvG9KUESDn6Ks=";
  };

  propagatedBuildInputs = with python3.pkgs; [
    numpy
    scipy
    matplotlib
    pandas
    tqdm
  ];

  # Skip build and tests
  dontBuild = true;
  doCheck = false;

  meta = with lib; {
    description = "FLUX model optimization library";
    homepage = "https://github.com/mit-han-lab/nunchaku";
    license = licenses.mit;
  };
}
