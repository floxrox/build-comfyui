{ lib
, python3
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-workflow-templates-media-image";
  version = "0.3.43";
  format = "wheel";

  # Use vendored source from repository
  src = ../../.flox/sources/comfyui_workflow_templates_media_image-${version}-py3-none-any.whl;

  propagatedBuildInputs = [ ];

  dontBuild = true;
  doCheck = false;

  meta = with lib; {
    description = "ComfyUI workflow templates media image";
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    license = licenses.gpl3Only;
  };
}
