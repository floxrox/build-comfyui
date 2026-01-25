# comfyui: ComfyUI Source Distribution
# =====================================
# This package provides the ComfyUI application source code as a
# read-only distribution for use in Flox runtime environments.
#
# ComfyUI is a powerful and modular stable diffusion GUI and backend.
# This package includes:
#   - Core ComfyUI application (main.py, server.py, execution.py, etc.)
#   - Built-in nodes (comfy_extras/)
#   - API server and client libraries
#   - Web frontend
#
# At runtime, this source distribution is combined with:
#   - Python environment (PyTorch, transformers, etc.)
#   - comfyui-extras (torch-agnostic ML dependencies)
#   - comfyui-plugins (custom node packages)
#
# Mutable directories (user/, input/, output/, custom_nodes/)
# are managed separately by the runtime environment.

{ lib
, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation rec {
  pname = "comfyui";
  version = "0.9.2";

  src = fetchFromGitHub {
    owner = "comfyanonymous";
    repo = "ComfyUI";
    rev = "v${version}";
    hash = "sha256-/QuoChUV6dsTeOcxCRfZ4e20H55LlY7bxd4PkpOElAM=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    # Create destination directory
    mkdir -p $out/share/comfyui

    # Copy core application files
    cp -r . $out/share/comfyui/

    # Remove git metadata and CI files from the installed copy
    rm -rf $out/share/comfyui/.git
    rm -rf $out/share/comfyui/.github
    rm -rf $out/share/comfyui/.ci

    # Remove directories that should be managed by runtime
    # (these will be symlinked or overlaid at runtime)
    rm -rf $out/share/comfyui/custom_nodes
    rm -rf $out/share/comfyui/input
    rm -rf $out/share/comfyui/output
    rm -rf $out/share/comfyui/user
    rm -rf $out/share/comfyui/models

    # Create placeholder directories (helps with runtime setup)
    mkdir -p $out/share/comfyui/custom_nodes
    mkdir -p $out/share/comfyui/input
    mkdir -p $out/share/comfyui/output
    mkdir -p $out/share/comfyui/user
    mkdir -p $out/share/comfyui/models

    runHook postInstall
  '';

  meta = with lib; {
    description = "ComfyUI source distribution for Flox runtime environments";
    longDescription = ''
      ComfyUI is a powerful and modular stable diffusion GUI and backend.

      This package provides the core application as a read-only source
      distribution. At runtime, it is combined with:
      - Python environment with PyTorch and ML dependencies
      - comfyui-extras (torch-agnostic ML packages)
      - comfyui-plugins (custom node packages)

      Mutable directories (models/, custom_nodes/, user/, input/, output/)
      are managed separately by the runtime environment.

      Version: ${version}
    '';
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    license = licenses.gpl3Only;
    platforms = platforms.all;
  };
}
