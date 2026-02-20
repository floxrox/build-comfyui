# comfyui-impact-subpack: Additional Nodes for ComfyUI Impact Pack
# ==================================================================
# This package provides ComfyUI-Impact-Subpack, which extends
# Impact Pack with additional detection and segmentation nodes.
#
# Impact Subpack provides:
#   - UltralyticsDetectorProvider (YOLO-based detection)
#   - SAMLoader (Segment Anything Model loader)
#   - SAM2 support (Segment Anything Model 2)
#   - Additional segmentation utilities
#
# This package bundles its Python dependencies:
#   - comfyui-thop (PyTorch model profiler, required by ultralytics)
#   - comfyui-ultralytics (YOLO object detection)
#   - comfyui-segment-anything (SAM)
#   - comfyui-sam2 (SAM2)
#
# Note: Also requires ComfyUI-Impact-Pack (provided by comfyui-plugins)
#
# Version: 1.3.5_flox_build (based on upstream 1.3.4 + bundled Python deps)

{ lib
, python3
, fetchFromGitHub
, callPackage
}:

let
  comfyui-thop = callPackage ./comfyui-thop.nix { };
  comfyui-ultralytics = callPackage ./comfyui-ultralytics.nix { };
  comfyui-segment-anything = callPackage ./segment-anything.nix { };
  comfyui-sam2 = callPackage ./comfyui-sam2.nix { };
in

python3.pkgs.buildPythonPackage rec {
  pname = "comfyui-impact-subpack";
  version = "1.3.5_flox_build";  # Based on upstream 1.3.4 + bundled Python deps
  format = "other";  # No Python build system, just source files

  # Impact Subpack v1.3.4
  src = fetchFromGitHub {
    owner = "ltdrdata";
    repo = "ComfyUI-Impact-Subpack";
    rev = "1.3.4";
    hash = "sha256-BHtfkaqCPf/YXfGbF/xyryjt+M8izkdoUAKNJLfyvqI=";
  };

  # Bundle Python dependencies required by Impact Subpack
  propagatedBuildInputs = [
    comfyui-thop              # PyTorch model profiler (required by ultralytics)
    comfyui-ultralytics       # UltralyticsDetectorProvider
    comfyui-segment-anything  # SAMLoader
    comfyui-sam2              # SAM2 support
  ];

  dontBuild = true;
  dontConfigure = true;
  doCheck = false;

  installPhase = ''
    runHook preInstall

    # Create directory structure
    mkdir -p $out/share/comfyui/custom_nodes

    # Install Impact Subpack
    cp -r . $out/share/comfyui/custom_nodes/ComfyUI-Impact-Subpack

    # Remove unnecessary files from the installed copy
    rm -rf $out/share/comfyui/custom_nodes/ComfyUI-Impact-Subpack/.git
    rm -rf $out/share/comfyui/custom_nodes/ComfyUI-Impact-Subpack/.github

    runHook postInstall
  '';

  meta = with lib; {
    description = "Additional nodes for ComfyUI Impact Pack (Subpack)";
    longDescription = ''
      ComfyUI-Impact-Subpack extends Impact Pack with additional nodes:
      - UltralyticsDetectorProvider: YOLO-based object detection
      - SAMLoader: Segment Anything Model loader
      - SAM2: Segment Anything Model 2 support
      - Additional segmentation and detection utilities

      This package bundles its Python dependencies:
      - comfyui-ultralytics
      - comfyui-segment-anything
      - comfyui-sam2

      Also requires comfyui-plugins (Impact Pack source).

      Based on upstream version 1.3.4 with bundled Python dependencies.
    '';
    homepage = "https://github.com/ltdrdata/ComfyUI-Impact-Subpack";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
}
