# comfyui-custom-nodes: Community Custom Nodes for ComfyUI
# =========================================================
# This package bundles essential community custom nodes for ComfyUI.
# Nodes are fetched from GitHub at pinned versions for reproducibility.
#
# Included nodes:
#   - rgthree-comfy: Quality-of-life improvements
#   - images-grid-comfy-plugin: Image grid utilities
#   - ComfyUI-Image-Saver: Enhanced image saving
#   - ComfyUI_UltimateSDUpscale: Ultimate SD upscaling
#   - ComfyUI-KJNodes: KJ's node collection
#   - ComfyUI_essentials: Essential utilities
#   - ComfyUI-Custom-Scripts: Custom script nodes
#   - ComfyUI_Comfyroll_CustomNodes: Comfyroll collection
#   - efficiency-nodes-comfyui: Efficiency workflow nodes
#   - was-node-suite-comfyui: WAS node suite
#   - ComfyUI-mxToolkit: MX toolkit nodes
#   - ComfyUI_IPAdapter_plus: IPAdapter image-to-image conditioning
#   - ComfyUI-IPAdapter-Flux: IPAdapter for FLUX models
#   - ComfyUI-SafeCLIP-SDXL: Safe CLIP encoding for SDXL (vendored)
#   - Comfyui-LayerForge: Photoshop-like layer editor for ComfyUI
#
# Note: ComfyUI-Manager is excluded (ships with ComfyUI now).
# Note: ComfyUI-Impact-Pack and Subpack are separate packages.
#
# Build-time patches applied:
#   - ComfyUI_Comfyroll_CustomNodes: Fix Python 3.12+ SyntaxWarnings
#     (invalid escape sequences \W and \R in string literals)
#   - rgthree-comfy: Fix Python 3.12+ SyntaxWarning
#     (invalid escape sequence \d in regex pattern - add raw string prefix)
#   - ComfyUI_essentials: Fix Python 3.12+ SyntaxWarnings
#     (invalid escape sequences \. in docstring regex examples)
#   - ComfyUI-Custom-Scripts: Use COMFYUI_BASE_DIR env var for web directory
#     (allows writing to runtime dir instead of read-only Nix store)
#
# Version tracks ComfyUI release for compatibility.

{ lib
, stdenv
, fetchFromGitHub
}:

let
  # Define all custom node sources
  nodeSources = {
    rgthree-comfy = fetchFromGitHub {
      owner = "rgthree";
      repo = "rgthree-comfy";
      rev = "v.1.0.0";
      hash = "sha256-bzQcQ37v7ZrHDitZV6z3h/kdNbWxpLxNSvh0rSxnLss=";
    };

    images-grid-comfy-plugin = fetchFromGitHub {
      owner = "LEv145";
      repo = "images-grid-comfy-plugin";
      rev = "2.6";
      hash = "sha256-YG08pF6Z44y/gcS9MrCD/X6KqG99ig+VKLfZOd49w9s=";
    };

    ComfyUI-Image-Saver = fetchFromGitHub {
      owner = "alexopus";
      repo = "ComfyUI-Image-Saver";
      rev = "v1.21.0";
      hash = "sha256-W0w3+T6Ui2yDDXfJojYS79q+xRhTRvQEjiL1V3QQ/B4=";
    };

    ComfyUI_UltimateSDUpscale = fetchFromGitHub {
      owner = "ssitu";
      repo = "ComfyUI_UltimateSDUpscale";
      rev = "177019948d900fcd97e5b4167ceae259dd9dd312";
      hash = "sha256-bw1hcRAhNV1dzSZv2IpblBIu4pR6H8KatF0tLLAmnW4=";
    };

    ComfyUI-KJNodes = fetchFromGitHub {
      owner = "kijai";
      repo = "ComfyUI-KJNodes";
      rev = "4d68afac6b7079c3980c8b4845b4a47eb5c6660d";
      hash = "sha256-vRUCrWdaRNLz4ETrJNSxGLTncq2MJzSk6wTitkBDaig=";
    };

    ComfyUI_essentials = fetchFromGitHub {
      owner = "cubiq";
      repo = "ComfyUI_essentials";
      rev = "9d9f4bedfc9f0321c19faf71855e228c93bd0dc9";
      hash = "sha256-wkwkZVZYqPgbk2G4DFguZ1absVUFRJXYDRqgFrcLrfU=";
    };

    ComfyUI-Custom-Scripts = fetchFromGitHub {
      owner = "pythongosssss";
      repo = "ComfyUI-Custom-Scripts";
      rev = "f2838ed5e59de4d73cde5c98354b87a8d3200190";
      hash = "sha256-0DgPrOFXOjQ4K1RKxLQdtGfJHbopP8iovoJqna8d+Gg=";
    };

    ComfyUI_Comfyroll_CustomNodes = fetchFromGitHub {
      owner = "Suzie1";
      repo = "ComfyUI_Comfyroll_CustomNodes";
      rev = "d78b780ae43fcf8c6b7c6505e6ffb4584281ceca";
      hash = "sha256-+qhDJ9hawSEg9AGBz8w+UzohMFhgZDOzvenw8xVVyPc=";
    };

    efficiency-nodes-comfyui = fetchFromGitHub {
      owner = "jags111";
      repo = "efficiency-nodes-comfyui";
      rev = "f0971b5553ead8f6e66bb99564431e2590cd3981";
      hash = "sha256-F/n/aDjM/EtOLvnBE1SLJtg+8RSrfZ5yXumyuLetaXQ=";
    };

    was-node-suite-comfyui = fetchFromGitHub {
      owner = "WASasquatch";
      repo = "was-node-suite-comfyui";
      rev = "ea935d1044ae5a26efa54ebeb18fe9020af49a45";
      hash = "sha256-/qaoURMMkhb789FOpL2PujL2vdROnGkrAjvVBZV5D5c=";
    };

    ComfyUI-mxToolkit = fetchFromGitHub {
      owner = "Smirnov75";
      repo = "ComfyUI-mxToolkit";
      rev = "7f7a0e584f12078a1c589645d866ae96bad0cc35";
      hash = "sha256-0vf6rkDzUvsQwhmOHEigq1yUd/VQGFNLwjp9/P9wJ10=";
    };

    ComfyUI_IPAdapter_plus = fetchFromGitHub {
      owner = "cubiq";
      repo = "ComfyUI_IPAdapter_plus";
      rev = "a0f451a5113cf9becb0847b92884cb10cbdec0ef";
      hash = "sha256-Ft9WJcmjzon2tAMJq5na24iqYTnQWEQFSKUElSVwYgw=";
    };

    ComfyUI-IPAdapter-Flux = fetchFromGitHub {
      owner = "Shakker-Labs";
      repo = "ComfyUI-IPAdapter-Flux";
      rev = "eef22b6875ddaf10f13657248b8123d6bdec2014";
      hash = "sha256-sd/krgeQAw19nz6oYUrjXq1KiXMnJ2jV7LjL++AiaA0=";
    };

    Comfyui-LayerForge = fetchFromGitHub {
      owner = "Azornes";
      repo = "Comfyui-LayerForge";
      rev = "v1.5.11";
      hash = "sha256-NdZuh7mDTZPk+iyQITo4qVg/c1qxgKAFZB3wLAHCWvE=";
    };
  };

  nodeNames = builtins.attrNames nodeSources;

in stdenv.mkDerivation rec {
  pname = "comfyui-custom-nodes";
  version = "0.14.2";  # Tracks ComfyUI version

  # We don't have a single src - we use multiple fetchFromGitHub sources
  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    # Create directory structure
    mkdir -p $out/share/comfyui/custom_nodes

    # Install each node from GitHub
    ${lib.concatStringsSep "\n" (map (name: ''
      echo "Installing ${name}..."
      cp -r ${nodeSources.${name}} $out/share/comfyui/custom_nodes/${name}
      chmod -R u+w $out/share/comfyui/custom_nodes/${name}
      rm -rf $out/share/comfyui/custom_nodes/${name}/.git
      rm -rf $out/share/comfyui/custom_nodes/${name}/.github
    '') nodeNames)}

    # Install vendored SafeCLIP-SDXL
    echo "Installing ComfyUI-SafeCLIP-SDXL (vendored)..."
    mkdir -p $out/share/comfyui/custom_nodes/ComfyUI-SafeCLIP-SDXL
    cp ${../../sources/ComfyUI-SafeCLIP-SDXL/__init__.py} $out/share/comfyui/custom_nodes/ComfyUI-SafeCLIP-SDXL/__init__.py

    # Patch ComfyUI_Comfyroll_CustomNodes for Python 3.12+ compatibility
    # Fixes invalid escape sequences (\W, \R) that cause SyntaxWarnings
    echo "Patching ComfyUI_Comfyroll_CustomNodes for Python 3.12+ compatibility..."
    comfyroll_dir="$out/share/comfyui/custom_nodes/ComfyUI_Comfyroll_CustomNodes"

    substituteInPlace "$comfyroll_dir/nodes/nodes_list.py" \
      --replace-fail 'C:\Windows\Fonts' 'C:/Windows/Fonts'

    substituteInPlace "$comfyroll_dir/nodes/nodes_xygrid.py" \
      --replace-fail 'fonts\Roboto-Regular.ttf' 'fonts/Roboto-Regular.ttf'

    # Patch rgthree-comfy for Python 3.12+ compatibility
    # Fixes invalid escape sequence \d in regex pattern
    echo "Patching rgthree-comfy for Python 3.12+ compatibility..."
    rgthree_dir="$out/share/comfyui/custom_nodes/rgthree-comfy"

    substituteInPlace "$rgthree_dir/py/power_prompt.py" \
      --replace-fail "pattern='<lora:" "pattern=r'<lora:"

    # Patch ComfyUI_essentials for Python 3.12+ compatibility
    # Fixes invalid escape sequences in docstring regex examples
    echo "Patching ComfyUI_essentials for Python 3.12+ compatibility..."
    essentials_dir="$out/share/comfyui/custom_nodes/ComfyUI_essentials"

    substituteInPlace "$essentials_dir/conditioning.py" \
      --replace-fail 'double_blocks\.0\.' 'double_blocks\\.0\\.' \
      --replace-fail 'single_blocks\.0\.' 'single_blocks\\.0\\.' \
      --replace-fail '(img|txt)_(mod|attn|mlp)\.' '(img|txt)_(mod|attn|mlp)\\.' \
      --replace-fail '(lin|qkv|proj|0|2)\.' '(lin|qkv|proj|0|2)\\.' \
      --replace-fail '(linear[12]|modulation\.lin)\.' '(linear[12]|modulation\\.lin)\\.'

    # Patch ComfyUI-Custom-Scripts to use COMFYUI_BASE_DIR env var
    # This allows the node to write to runtime web directory instead of read-only store
    echo "Patching ComfyUI-Custom-Scripts for Flox/Nix compatibility..."
    customscripts_dir="$out/share/comfyui/custom_nodes/ComfyUI-Custom-Scripts"

    substituteInPlace "$customscripts_dir/pysssss.py" \
      --replace-fail 'dir = os.path.dirname(inspect.getfile(PromptServer))' 'dir = os.environ.get("COMFYUI_BASE_DIR", os.path.dirname(inspect.getfile(PromptServer)))'

    runHook postInstall
  '';

  meta = with lib; {
    description = "Community custom nodes for ComfyUI";
    longDescription = ''
      A curated collection of essential community custom nodes for ComfyUI:

      - rgthree-comfy: Quality-of-life workflow improvements
      - images-grid-comfy-plugin: Image grid generation utilities
      - ComfyUI-Image-Saver: Enhanced image saving with metadata
      - ComfyUI_UltimateSDUpscale: Advanced SD upscaling
      - ComfyUI-KJNodes: KJ's comprehensive node collection
      - ComfyUI_essentials: Essential utility nodes
      - ComfyUI-Custom-Scripts: Custom script and widget nodes
      - ComfyUI_Comfyroll_CustomNodes: Comfyroll node collection
      - efficiency-nodes-comfyui: Efficiency workflow nodes
      - was-node-suite-comfyui: WAS comprehensive node suite
      - ComfyUI-mxToolkit: MX toolkit nodes
      - ComfyUI_IPAdapter_plus: IPAdapter image-to-image conditioning
      - ComfyUI-IPAdapter-Flux: IPAdapter for FLUX models
      - ComfyUI-SafeCLIP-SDXL: Safe CLIP encoding for SDXL
      - Comfyui-LayerForge: Photoshop-like layer editor for ComfyUI

      Note: ComfyUI-Manager is excluded (now ships with ComfyUI).
      Note: Impact Pack and Subpack are provided by separate packages.

      Version: ${version} (tracks ComfyUI release)
    '';
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    license = licenses.gpl3Only;
    platforms = platforms.all;
  };
}
