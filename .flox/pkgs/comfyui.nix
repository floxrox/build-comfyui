{ lib
, python3
, fetchFromGitHub
, makeWrapper
, comfyui-frontend-package
, comfyui-workflow-templates
, comfyui-workflow-templates-core
, comfyui-workflow-templates-media-api
, comfyui-workflow-templates-media-video
, comfyui-workflow-templates-media-image
, comfyui-workflow-templates-media-other
, comfyui-embedded-docs
, spandrel
, nunchaku
, controlnet-aux
}:

python3.pkgs.buildPythonApplication rec {
  pname = "comfyui";
  version = "0.6.0";
  format = "other";

  src = fetchFromGitHub {
    owner = "comfyanonymous";
    repo = "ComfyUI";
    rev = "v${version}";
    hash = "sha256-gd02tXWjFJ7kTGF8GT1RfVdzhXu4mM2EoQnAVt83qjQ=";
  };

  # Python dependencies for ComfyUI
  # PyTorch, numpy, scipy can be overridden in Flox environments with optimized versions:
  #   - python313Packages.pytorchWithCuda (nixpkgs CUDA version)
  #   - flox/pytorch-python313-cuda12_8-sm86-avx2 (pre-built optimized)
  #   - Custom builds published to your catalog
  propagatedBuildInputs = [
    # ComfyUI-specific packages
    comfyui-frontend-package
    comfyui-workflow-templates
    comfyui-embedded-docs
    spandrel

    # Workflow optimization packages
    nunchaku          # FLUX inference optimization
    controlnet-aux    # Advanced ControlNet preprocessors
  ] ++ (with python3.pkgs; [
    # PyTorch stack - Override with CUDA-optimized if needed
    torch
    torchvision
    torchaudio
    torchsde

    # Scientific computing - Override with CUDA-optimized if needed
    numpy
    scipy
    pillow
    einops

    # ML/AI libraries
    transformers
    tokenizers
    sentencepiece
    safetensors
  ]) ++ lib.optionals (!lib.elem python3.stdenv.hostPlatform.system ["aarch64-linux" "aarch64-darwin"]) (with python3.pkgs; [
    # kornia - excluded on ARM64 due to kornia-rs build crashes
    kornia
  ]) ++ (with python3.pkgs; [
    # Web and async
    aiohttp
    yarl

    # Data and config
    pyyaml
    pydantic
    pydantic-settings

    # Database
    alembic
    sqlalchemy

    # Media
    av

    # Utilities
    tqdm
    psutil
    huggingface-hub   # Model downloads

    # Workflow support dependencies
    opencv-python     # ControlNet preprocessors (Canny, HED, etc.)
    gguf              # GGUF quantized model support (critical for FLUX)
    accelerate        # Model loading optimization

    # Additional dependencies for workflow optimization
    timm              # PyTorch Image Models (for controlnet-aux)
    scikit-image      # Image processing (for controlnet-aux)
    matplotlib        # Plotting library (for nunchaku)
    pandas            # Data analysis (for nunchaku)
  ]);

  nativeBuildInputs = [ makeWrapper ];

  # Skip build phase - ComfyUI runs from source
  dontBuild = true;

  # Don't run tests
  doCheck = false;

  # Disable automatic Python wrapping - we'll do it ourselves
  dontWrapPythonPrograms = true;

  installPhase = ''
    runHook preInstall

    # Create directory structure
    mkdir -p $out/share/comfyui
    mkdir -p $out/share/comfyui-tools
    mkdir -p $out/bin

    # Copy all ComfyUI files to share directory
    cp -r . $out/share/comfyui/

    # Build Python environment with all dependencies
    pythonEnv="${python3.withPackages (ps: propagatedBuildInputs)}"

    # Install enhanced model download tools (as library scripts)
    cp ${../../assets/download-sd15-enhanced.py} $out/share/comfyui-tools/download-sd15.py
    cp ${../../assets/download-sdxl-enhanced.py} $out/share/comfyui-tools/download-sdxl.py
    cp ${../../assets/download-sd35-enhanced.py} $out/share/comfyui-tools/download-sd35.py
    cp ${../../assets/download-flux-enhanced.py} $out/share/comfyui-tools/download-flux.py

    # Create wrapped Python executables for download scripts
    for script in download-sd15 download-sdxl download-sd35 download-flux; do
      makeWrapper $pythonEnv/bin/python3 $out/share/comfyui-tools/''${script}-wrapped \
        --add-flags "$out/share/comfyui-tools/''${script}.py"
      chmod +x $out/share/comfyui-tools/''${script}-wrapped
    done

    # Install comfyui-download CLI tool (wrapper script)
    cp ${../../assets/comfyui-download-enhanced} $out/bin/comfyui-download
    chmod +x $out/bin/comfyui-download

    # Create wrapper script for comfyui
    # Use --suffix so environment packages can override bundled versions
    makeWrapper ${python3}/bin/python3 $out/bin/comfyui \
      --add-flags "$out/share/comfyui/main.py" \
      --suffix PYTHONPATH : "$out/share/comfyui" \
      --suffix PYTHONPATH : "$pythonEnv/${python3.sitePackages}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "The most powerful and modular diffusion model GUI and backend";
    homepage = "https://github.com/comfyanonymous/ComfyUI";
    license = licenses.gpl3Only;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "comfyui";
  };
}
