{ lib
, python3
, comfyui-workflow-templates-core
, comfyui-workflow-templates-media-api
, comfyui-workflow-templates-media-video
, comfyui-workflow-templates-media-image
, comfyui-workflow-templates-media-other
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-workflow-templates";
  version = "0.7.63";
  format = "wheel";

  # Use vendored source from repository
  src = ../../.flox/sources/comfyui_workflow_templates-${version}-py3-none-any.whl;

  propagatedBuildInputs = [
    comfyui-workflow-templates-core
    comfyui-workflow-templates-media-api
    comfyui-workflow-templates-media-video
    comfyui-workflow-templates-media-image
    comfyui-workflow-templates-media-other
  ];

  dontBuild = true;
  doCheck = false;

  meta = with lib; {
    description = "ComfyUI workflow templates";
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    license = licenses.gpl3Only;
  };
}
