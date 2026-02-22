# comfyui-videogen: Video Generation Custom Nodes for ComfyUI
# ===========================================================
# Bundles popular video generation/processing custom nodes.
# These are source-only packages (no Python build needed).
# Python dependencies are provided by comfyui-extras and the runtime manifest.
#
# Included nodes:
#   - ComfyUI-AnimateDiff-Evolved: AnimateDiff video generation
#   - ComfyUI-VideoHelperSuite: Video loading, combining, previewing
#   - ComfyUI-LTXVideo: Lightricks LTX-Video generation
#   - ComfyUI-WanVideoWrapper: Wan Video (text/image-to-video)
#
# Dependencies provided by:
#   - comfyui-extras: peft, facexlib, pyloudnorm, imageio-ffmpeg, etc.
#   - Runtime manifest: diffusers, transformers, av (PyAV), ffmpeg

{ lib
, stdenv
, fetchFromGitHub
}:

let
  nodeSources = {
    ComfyUI-AnimateDiff-Evolved = fetchFromGitHub {
      owner = "Kosinkadink";
      repo = "ComfyUI-AnimateDiff-Evolved";
      rev = "90fb1331201a4b29488089e4fbffc0d82cc6d0a9";
      hash = "sha256-HiaT0u8lGX3sUMluh/WtKOwGS9IaGE+y3nxeClh20ds=";
    };

    ComfyUI-VideoHelperSuite = fetchFromGitHub {
      owner = "Kosinkadink";
      repo = "ComfyUI-VideoHelperSuite";
      rev = "993082e4f2473bf4acaf06f51e33877a7eb38960";
      hash = "sha256-oII4aAK8O44MBaxOATG7tAXmF1ESRm7nacNmj1E3pE8=";
    };

    ComfyUI-LTXVideo = fetchFromGitHub {
      owner = "Lightricks";
      repo = "ComfyUI-LTXVideo";
      rev = "d153ca3f7839759baa7c58c331277451ba760bbb";
      hash = "sha256-LQhw/YNViZcUiX8S4OeBUdiW0SE4ppV6m7gnJkoxf0I=";
    };

    ComfyUI-WanVideoWrapper = fetchFromGitHub {
      owner = "kijai";
      repo = "ComfyUI-WanVideoWrapper";
      rev = "d00abe52d720a5845343ad0dd2927275bad399e7";
      hash = "sha256-JFQlebtw9dVFmWdiFbiDVbWhPdXkXymcicVn4/kUxrA=";
    };
  };

  nodeNames = builtins.attrNames nodeSources;

in stdenv.mkDerivation rec {
  pname = "comfyui-videogen";
  version = "0.9.1";

  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/comfyui/custom_nodes

    ${lib.concatStringsSep "\n" (map (name: ''
      echo "Installing ${name}..."
      cp -r ${nodeSources.${name}} $out/share/comfyui/custom_nodes/${name}
      chmod -R u+w $out/share/comfyui/custom_nodes/${name}
      rm -rf $out/share/comfyui/custom_nodes/${name}/.git
      rm -rf $out/share/comfyui/custom_nodes/${name}/.github
    '') nodeNames)}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Video generation custom nodes for ComfyUI";
    longDescription = ''
      A collection of video generation and processing custom nodes for ComfyUI:

      - ComfyUI-AnimateDiff-Evolved: AnimateDiff video generation workflows
      - ComfyUI-VideoHelperSuite: Video loading, combining, and previewing
      - ComfyUI-LTXVideo: Lightricks LTX-Video generation
      - ComfyUI-WanVideoWrapper: Wan Video text/image-to-video generation

      Python dependencies (peft, facexlib, pyloudnorm, imageio-ffmpeg, diffusers,
      transformers, av) are provided by comfyui-extras and the runtime manifest.
    '';
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    license = licenses.gpl3Only;
    platforms = platforms.all;
  };
}
