# colour-science: Colour Science for Python
# ==========================================
# Clean package - no torch dependencies.

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "colour-science";
  version = "0.4.6";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "colour-science";
    repo = "colour";
    tag = "v${version}";
    hash = "sha256-kjJc6D4jhvAJh6rIVvKO2bw++K3XlfjD4Djav6778lk=";
  };

  build-system = with python3.pkgs; [
    hatchling
    hatch-vcs
  ];

  dependencies = with python3.pkgs; [
    # Core dependencies
    imageio
    numpy
    scipy
    typing-extensions
  ];

  # Disable tests - they require many optional dependencies
  doCheck = false;

  meta = with lib; {
    description = "Colour Science for Python";
    homepage = "https://www.colour-science.org/";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
