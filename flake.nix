{
  description = "ComfyUI complete build environment with all dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Overlay to fix test failures on Darwin
        # - pyarrow: test_timezone_absent fails because macOS handles timezone lookups differently
        # - dask: test_series_aggregations_multilevel crashes workers on aarch64-darwin
        #         pythonImportsCheck also fails because dask.array requires numpy at import time
        # We override the python interpreters so their .pkgs attribute has the fix
        pythonDarwinFix = pfinal: pprev: {
          pyarrow = pprev.pyarrow.overridePythonAttrs (old: {
            doCheck = false;
          });
          dask = pprev.dask.overridePythonAttrs (old: {
            doCheck = false;
            pythonImportsCheck = [];  # dask.array requires numpy which isn't available during check
          });
        };

        darwinOverlay = final: prev:
          if prev.stdenv.hostPlatform.isDarwin then {
            # Override python interpreters so python.pkgs has the fix
            python3 = prev.python3.override {
              packageOverrides = pythonDarwinFix;
            };
            python313 = prev.python313.override {
              packageOverrides = pythonDarwinFix;
            };
            python312 = prev.python312.override {
              packageOverrides = pythonDarwinFix;
            };
            python311 = prev.python311.override {
              packageOverrides = pythonDarwinFix;
            };
          } else {};

        pkgs = import nixpkgs {
          inherit system;
          overlays = [ darwinOverlay ];
          config = {
            allowUnfree = true;
          };
        };

        # Helper to call packages from .flox/pkgs/
        callPkg = name: pkgs.callPackage ./.flox/pkgs/${name}.nix {};

      in {
        # Re-export pkgs with the overlay applied
        legacyPackages = pkgs;

        # Build packages using pkgs with Darwin test fix overlay applied
        packages = {
          # Main package
          comfyui-complete = callPkg "comfyui-complete";
          default = self.packages.${system}.comfyui-complete;

          # Core packages
          comfyui = callPkg "comfyui";
          comfyui-extras = callPkg "comfyui-extras";
          comfyui-workflows = callPkg "comfyui-workflows";

          # Custom node packages
          comfyui-plugins = callPkg "comfyui-plugins";
          comfyui-impact-subpack = callPkg "comfyui-impact-subpack";
          comfyui-custom-nodes = callPkg "comfyui-custom-nodes";
          comfyui-controlnet-aux = callPkg "comfyui-controlnet-aux";
          comfyui-videogen = callPkg "comfyui-videogen";

          # ML packages (torch-agnostic builds)
          comfyui-ultralytics = callPkg "comfyui-ultralytics";
          comfyui-accelerate = callPkg "comfyui-accelerate";
          comfyui-clip-interrogator = callPkg "comfyui-clip-interrogator";
          comfyui-facexlib = callPkg "comfyui-facexlib";
          comfyui-peft = callPkg "comfyui-peft";
          comfyui-pixeloe = callPkg "comfyui-pixeloe";
          comfyui-sam2 = callPkg "comfyui-sam2";
          comfyui-thop = callPkg "comfyui-thop";
          comfyui-transparent-background = callPkg "comfyui-transparent-background";

          # Supporting packages
          color-matcher = callPkg "color-matcher";
          colour-science = callPkg "colour-science";
          comfy-aimdo = callPkg "comfy-aimdo";
          cstr = callPkg "cstr";
          ffmpy = callPkg "ffmpy";
          img2texture = callPkg "img2texture";
          onnxruntime-noexecstack = callPkg "onnxruntime-noexecstack";
          open-clip-torch = callPkg "open-clip-torch";
          pyloudnorm = callPkg "pyloudnorm";
          rembg = callPkg "rembg";
          segment-anything = callPkg "segment-anything";
          spandrel = callPkg "spandrel";
          timm = callPkg "timm";
        };

        # Development shell with build tools
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            python3
            nix-prefetch-git
            nix-prefetch-github
          ];
        };
      }
    );
}
