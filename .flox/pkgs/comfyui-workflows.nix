{ lib, stdenv }:

stdenv.mkDerivation {
  pname = "comfyui-workflows";
  version = "1.0.2";

  src = ../../sources/workflows;

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    # Install workflows (proper Web UI format for browser rendering)
    mkdir -p $out/share/comfyui/workflows
    for dir in */; do
      cp -r "$dir" $out/share/comfyui/workflows/
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "Bundled example workflows for ComfyUI";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
