# rembg: Remove Background from Images
# =====================================
# Clean package - no torch dependencies.

{ lib
, python3
, fetchFromGitHub
, onnxruntime-noexecstack ? null
}:

python3.pkgs.buildPythonPackage rec {
  pname = "rembg";
  version = "2.0.68";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "danielgatis";
    repo = "rembg";
    tag = "v${version}";
    hash = "sha256-uaZgikCpyO1noGg5P5tsdk24pzQofE5l4n7B9QcGHm4=";
  };

  build-system = with python3.pkgs; [
    setuptools
    wheel
  ];

  dependencies = with python3.pkgs; [
    # Core dependencies
    jsonschema
    numpy
    opencv4
    pillow
    pooch
    pymatting
    scikit-image
    scipy
    tqdm
    # CLI/Web dependencies (commonly used)
    aiohttp
    asyncer
    click
    filetype
    imagehash
    # CPU runtime (use patched version if available)
    (if onnxruntime-noexecstack != null then onnxruntime-noexecstack else onnxruntime)
  ];

  # Remove opencv-python-headless (we provide opencv4 instead)
  pythonRemoveDeps = [
    "opencv-python-headless"
  ];

  # Disable runtime deps check - opencv naming differences
  dontCheckRuntimeDeps = true;

  # Disable tests
  doCheck = false;

  meta = with lib; {
    description = "Remove image backgrounds using machine learning";
    homepage = "https://github.com/danielgatis/rembg";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
