# color-matcher: Color Matching Algorithms for Images
# ===================================================
# Clean package - no torch dependencies.
# Uses vendored wheel (0.6.0 not available on GitHub releases).

{ lib
, python3
}:

python3.pkgs.buildPythonPackage rec {
  pname = "color-matcher";
  version = "0.6.0";
  format = "wheel";

  # Use vendored source for reproducibility
  src = ../../sources/color_matcher-0.6.0-py3-none-any.whl;

  dontBuild = true;

  propagatedBuildInputs = with python3.pkgs; [
    numpy
    opencv4
    scikit-image
  ];

  # Skip imports check - opencv dependency issues
  # pythonImportsCheck = [ "color_matcher" ];

  meta = with lib; {
    description = "Color matching algorithms for images";
    homepage = "https://github.com/hahnec/color-matcher";
    license = licenses.gpl3;
    platforms = platforms.unix;
  };
}
