{ lib
, python3
}:

python3.pkgs.buildPythonPackage rec {
  pname = "nunchaku";
  version = "0.16.1";
  format = "wheel";

  # Use vendored source from repository
  src = ../../.flox/sources/nunchaku-${version}-py3-none-any.whl;

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
