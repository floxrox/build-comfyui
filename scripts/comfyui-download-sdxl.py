#!/usr/bin/env python3
"""Download Stable Diffusion XL 1.0 base model for ComfyUI."""
import argparse
import os
import shutil
import sys
from pathlib import Path, PurePosixPath

DESCRIPTION = """\
Download Stable Diffusion XL 1.0 base model for ComfyUI.

Downloads:
  sd_xl_base_1.0.safetensors  (~6.9 GB)  ->  checkpoints/

Source: stabilityai/stable-diffusion-xl-base-1.0 on HuggingFace
License: Stable Diffusion XL 1.0 License (free, no token required)

SDXL produces higher quality images than SD 1.5 at 1024x1024 resolution.
Requires more VRAM (~8 GB minimum). Single checkpoint includes the VAE.
"""

EPILOG = """\
environment variables:
  COMFYUI_MODELS_DIR   Override model download directory
  COMFYUI_WORK_DIR     Override work directory (models go in $COMFYUI_WORK_DIR/models)
  HF_TOKEN             HuggingFace token (not required for SDXL)

examples:
  comfyui-download-sdxl                       Download to default location
  comfyui-download-sdxl --dry-run             Show what would be downloaded
  comfyui-download-sdxl --models-dir /data    Download to /data/checkpoints/

after downloading:
  1. Start ComfyUI:  flox services start comfyui
  2. Open http://localhost:8188
  3. Load checkpoint: sd_xl_base_1.0.safetensors
  4. Use CheckpointLoaderSimple node
  5. Recommended resolution: 1024x1024
  6. Recommended CFG scale: 4-7
"""

MODEL_ID = "stabilityai/stable-diffusion-xl-base-1.0"

FILES = [
    # (remote_filename, subdirectory, local_filename, approx_size)
    ("sd_xl_base_1.0.safetensors", "checkpoints", "sd_xl_base_1.0.safetensors", "6.9 GB"),
]


def validate_remote_path(remote):
    """Reject path traversal or absolute paths in remote filenames."""
    p = PurePosixPath(remote)
    if p.is_absolute() or ".." in p.parts:
        raise ValueError(f"Unsafe remote path: {remote}")
    return remote


def safe_move(src, dst):
    """Move src to dst, handling cross-filesystem moves."""
    src, dst = Path(src), Path(dst)
    if src == dst:
        return
    if dst.exists():
        dst.unlink()
    try:
        src.rename(dst)
    except OSError:
        shutil.copy2(src, dst)
        src.unlink()


def cleanup_hf_cache(models_dir, files):
    """Remove .cache/ directories left by hf_hub_download. Best-effort, non-fatal."""
    cleaned = set()
    for entry in files:
        subdir = entry[1]
        cache_dir = models_dir / subdir / ".cache"
        cache_key = str(cache_dir)
        if cache_key in cleaned:
            continue
        cleaned.add(cache_key)
        if cache_dir.is_symlink():
            continue
        try:
            shutil.rmtree(cache_dir)
        except FileNotFoundError:
            pass
        except OSError:
            pass


def get_models_dir(override=None):
    if override:
        return Path(override)
    return Path(os.environ.get(
        "COMFYUI_MODELS_DIR",
        os.environ.get("COMFYUI_WORK_DIR", str(Path.home() / "comfyui-work")) + "/models"
    ))


def main():
    parser = argparse.ArgumentParser(
        prog="comfyui-download-sdxl",
        description=DESCRIPTION,
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="show what would be downloaded without downloading",
    )
    parser.add_argument(
        "--models-dir", type=str, default=None,
        help="override model download directory (default: ~/comfyui-work/models)",
    )
    args = parser.parse_args()

    models_dir = get_models_dir(args.models_dir)
    hf_token = os.environ.get("HF_TOKEN", "")

    for remote, subdir, local, size in FILES:
        validate_remote_path(remote)

    print()
    print("=" * 70)
    print("  Stable Diffusion XL 1.0 for ComfyUI")
    print("=" * 70)
    print()
    print(f"  Model:       {MODEL_ID}")
    print(f"  Destination: {models_dir}")
    print(f"  Token:       not required")
    print()
    print("  Files to download:")
    for remote, subdir, local, size in FILES:
        print(f"    {local:<45s} {size:>8s}  ->  {subdir}/")
    print()

    if args.dry_run:
        print("  [dry run] No files will be downloaded.")
        print()
        return

    try:
        from huggingface_hub import hf_hub_download
    except ImportError:
        print("ERROR: huggingface_hub is not installed.")
        print("  Install it with:  pip install huggingface-hub")
        sys.exit(1)

    for remote, subdir, local, size in FILES:
        target_dir = models_dir / subdir
        target_dir.mkdir(parents=True, exist_ok=True)

        print(f"  Downloading {remote} ({size})...")
        try:
            downloaded_path = hf_hub_download(
                repo_id=MODEL_ID,
                filename=remote,
                token=hf_token if hf_token else None,
                local_dir=target_dir,
                local_dir_use_symlinks=False,
                resume_download=True,
            )
            final_path = target_dir / local
            safe_move(downloaded_path, final_path)
            print(f"    -> {final_path}")
        except Exception as e:
            print(f"\n  ERROR: {e}")
            print(f"\n  Model page: https://huggingface.co/{MODEL_ID}")
            sys.exit(1)

    cleanup_hf_cache(models_dir, FILES)

    print()
    print("=" * 70)
    print("  Download complete!")
    print()
    print("  Next steps:")
    print("    1. Start ComfyUI:  flox services start comfyui")
    print("    2. Open http://localhost:8188")
    print("    3. Load checkpoint: sd_xl_base_1.0.safetensors")
    print("    4. Use 1024x1024 resolution, CFG 4-7")
    print("=" * 70)
    print()


if __name__ == "__main__":
    main()
