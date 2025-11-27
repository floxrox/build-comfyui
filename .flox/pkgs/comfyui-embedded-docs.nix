{ lib
, python3
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-embedded-docs";
  version = "0.3.1";
  format = "wheel";

  # Use vendored source from repository
  src = ../../.flox/sources/comfyui_embedded_docs-${version}-py3-none-any.whl;

  propagatedBuildInputs = [ ];

  doCheck = false;

  meta = with lib; {
    description = "ComfyUI embedded documentation";
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    license = licenses.gpl3Only;
  };
}
