# comfyui-plugins: Essential Custom Node Plugins for ComfyUI
# ==========================================================
# This package provides ComfyUI-Impact-Pack, the most essential
# custom node collection for ComfyUI workflows.
#
# Impact Pack provides:
#   - Face detection and enhancement (FaceDetailer)
#   - Object detection and segmentation
#   - Mask operations and refinement
#   - Batch processing utilities
#
# Note: Impact Pack requires Python dependencies from comfyui-extras
# (ultralytics, segment-anything, etc.) which are provided separately.
#
# Version tracks ComfyUI release for compatibility.
# Impact Pack source version noted in comments.

{ lib
, stdenv
, fetchFromGitHub
, bash
}:

stdenv.mkDerivation rec {
  pname = "comfyui-plugins";
  version = "0.9.2";  # Tracks ComfyUI version

  # Impact Pack v8.28
  src = fetchFromGitHub {
    owner = "ltdrdata";
    repo = "ComfyUI-Impact-Pack";
    rev = "8.28";
    hash = "sha256-V/gMPqo9Xx21+KpG5LPzP5bML9nGlHHMyVGoV+YgFWE=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    # Create directory structure
    mkdir -p $out/share/comfyui/custom_nodes

    # Install Impact Pack
    cp -r . $out/share/comfyui/custom_nodes/ComfyUI-Impact-Pack

    # Remove unnecessary files from the installed copy
    rm -rf $out/share/comfyui/custom_nodes/ComfyUI-Impact-Pack/.git
    rm -rf $out/share/comfyui/custom_nodes/ComfyUI-Impact-Pack/.github

    runHook postInstall
  '';

  meta = with lib; {
    description = "Essential custom node plugins for ComfyUI (Impact Pack)";
    longDescription = ''
      ComfyUI-Impact-Pack provides essential custom nodes for ComfyUI:
      - FaceDetailer: Automatic face detection and enhancement
      - Object detection and segmentation nodes
      - Mask manipulation and refinement tools
      - Batch processing utilities

      Requires comfyui-extras for Python dependencies (ultralytics,
      segment-anything, etc.).

      Impact Pack source version: 8.28
    '';
    homepage = "https://github.com/ltdrdata/ComfyUI-Impact-Pack";
    license = licenses.gpl3Only;
    platforms = platforms.all;
  };
}
