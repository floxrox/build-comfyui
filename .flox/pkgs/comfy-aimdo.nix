# comfy-aimdo: AI Model Demand Offloading Allocator
# ==================================================
# Required by ComfyUI v0.14+ for dynamic VRAM management.
# Handles per-node mempool chunking for multi-model workflows.

{ lib
, python3
, fetchPypi
}:

python3.pkgs.buildPythonPackage rec {
  pname = "comfy-aimdo";
  version = "0.1.8";
  format = "wheel";

  src = fetchPypi {
    pname = "comfy_aimdo";
    inherit version;
    format = "wheel";
    dist = "py3";
    python = "py3";
    hash = "sha256-BVs3sDetESkbqH2knvJ4weuw4ix0IRH6+a4xWzru3Zk=";
  };

  # No dependencies beyond Python itself
  dependencies = [];

  # Disable tests
  doCheck = false;

  pythonImportsCheck = [ "comfy_aimdo" ];

  meta = with lib; {
    description = "AI Model Demand Offloading Allocator for ComfyUI";
    homepage = "https://github.com/Comfy-Org/comfy-aimdo";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
}
