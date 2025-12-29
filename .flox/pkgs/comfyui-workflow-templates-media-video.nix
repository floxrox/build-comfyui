{ lib
, python3
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-workflow-templates-media-video";
  version = "0.3.22";
  format = "wheel";

  # Use vendored source from repository
  src = ../../.flox/sources/comfyui_workflow_templates_media_video-${version}-py3-none-any.whl;

  propagatedBuildInputs = [ ];

  dontBuild = true;
  doCheck = false;

  meta = with lib; {
    description = "ComfyUI workflow templates media video";
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    license = licenses.gpl3Only;
  };
}
