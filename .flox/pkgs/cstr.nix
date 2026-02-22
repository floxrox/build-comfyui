# cstr: Colored Terminal String Formatting
# =========================================
# Clean package - no torch dependencies.
# Uses vendored tarball (no PyPI releases).

{ lib
, python3
}:

python3.pkgs.buildPythonPackage rec {
  pname = "cstr";
  version = "unstable-2023-05-28";
  format = "setuptools";

  # Use vendored source for reproducibility
  src = ../../sources/cstr-0520c29a18a7a869a6e5983861d6f7a4c86f8e9b.tar.gz;

  pythonImportsCheck = [ "cstr" ];

  meta = with lib; {
    description = "A Python library for colored terminal string formatting";
    homepage = "https://github.com/WASasquatch/cstr";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
