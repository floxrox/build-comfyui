# img2texture: Convert Images to Seamless Textures
# =================================================
# Clean package - no torch dependencies.
# Uses vendored tarball (no PyPI releases).

{ lib
, python3
}:

python3.pkgs.buildPythonPackage rec {
  pname = "img2texture";
  version = "unstable-2024-02-20";
  format = "setuptools";

  # Use vendored source for reproducibility
  src = ../../sources/img2texture-d6159abea44a0b2cf77454d3d46962c8b21eb9d3.tar.gz;

  propagatedBuildInputs = with python3.pkgs; [
    numpy
    pillow
  ];

  pythonImportsCheck = [ "img2texture" ];

  meta = with lib; {
    description = "Convert images to seamless textures";
    homepage = "https://github.com/WASasquatch/img2texture";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
