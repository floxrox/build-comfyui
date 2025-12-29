{ lib
, python3
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-frontend-package";
  version = "1.34.9";
  format = "wheel";

  # Use vendored source from repository
  src = ../../.flox/sources/comfyui_frontend_package-${version}-py3-none-any.whl;

  # No dependencies - this is a frontend package
  propagatedBuildInputs = [ ];

  # Skip tests
  doCheck = false;

  meta = with lib; {
    description = "ComfyUI frontend package";
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    license = licenses.gpl3Only;
  };
}
