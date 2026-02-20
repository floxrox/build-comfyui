# ffmpy: Simple Python wrapper for FFmpeg
# ========================================
# Clean package - no torch dependencies.

{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonPackage rec {
  pname = "ffmpy";
  version = "0.5.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Ch00k";
    repo = "ffmpy";
    tag = "${version}";
    hash = "sha256-spbyz1EyMJRXJTm7TqN9XoqR9ztBKsNZx3NURwV7N2w=";
  };

  build-system = with python3.pkgs; [
    poetry-core
  ];

  # No Python dependencies - just requires ffmpeg at runtime
  dependencies = [ ];

  # Disable tests
  doCheck = false;

  pythonImportsCheck = [ "ffmpy" ];

  meta = with lib; {
    description = "A simple Python wrapper for FFmpeg";
    homepage = "https://github.com/Ch00k/ffmpy";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
