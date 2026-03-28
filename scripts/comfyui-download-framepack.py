#!/usr/bin/env python3
"""Download FramePack I2V model (HunyuanVideo backbone) for ComfyUI."""
import argparse
import os
import shutil
import sys
from pathlib import Path, PurePosixPath

DESCRIPTION = """\
Download FramePack I2V model for ComfyUI.

Downloads:
  FramePackI2V_HY_fp8_e4m3fn.safetensors  (~15.2 GB)  ->  diffusion_models/
  clip_l.safetensors                       (~0.2 GB)   ->  clip/
  llava_llama3_fp8_scaled.safetensors      (~8.5 GB)   ->  clip/
  hunyuan_video_vae_bf16.safetensors       (~0.5 GB)   ->  vae/
                                           -----------
                                    Total: ~24 GB

Source: Kijai/HunyuanVideo_comfy (diffusion model)
        Comfy-Org/HunyuanVideo_repackaged (text encoders, VAE)
License: Tencent Hunyuan Community License (no HuggingFace token required)

FramePack uses the HunyuanVideo backbone for high-quality image-to-video
generation with temporal packing for efficient inference. The FP8 variant
runs on 24+ GB VRAM GPUs.
"""

EPILOG = """\
environment variables:
  COMFYUI_MODELS_DIR   Override model download directory
  COMFYUI_WORK_DIR     Override work directory (models go in $COMFYUI_WORK_DIR/models)

examples:
  comfyui-download-framepack                     Download all files
  comfyui-download-framepack --dry-run           Show what would be downloaded
  comfyui-download-framepack --models-dir /data  Download to custom location

after downloading:
  1. Start ComfyUI:  flox services start comfyui
  2. Open http://localhost:8188
  3. Load the framepack-i2v workflow from the workflow browser
  4. Set your input image and prompt, then generate
"""

FRAMEPACK_REPO = "Kijai/HunyuanVideo_comfy"
HUNYUAN_REPO = "Comfy-Org/HunyuanVideo_repackaged"

# (repo_id, remote_filename, subdirectory, local_filename, approx_size)
FILES = [
    (FRAMEPACK_REPO, "FramePackI2V_HY_fp8_e4m3fn.safetensors", "diffusion_models", "FramePackI2V_HY_fp8_e4m3fn.safetensors", "15.2 GB"),
    (HUNYUAN_REPO, "split_files/text_encoders/clip_l.safetensors", "clip", "clip_l_hunyuan.safetensors", "0.2 GB"),
    (HUNYUAN_REPO, "split_files/text_encoders/llava_llama3_fp8_scaled.safetensors", "clip", "llava_llama3_fp8_scaled.safetensors", "8.5 GB"),
    (HUNYUAN_REPO, "split_files/vae/hunyuan_video_vae_bf16.safetensors", "vae", "hunyuan_video_vae_bf16.safetensors", "0.5 GB"),
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


def cleanup_hf_artifacts(models_dir, files):
    """Remove .cache/ dirs and empty nested dirs left by hf_hub_download."""
    cleaned_caches = set()
    nested_dirs = set()

    for entry in files:
        remote, subdir = entry[1], entry[2]
        target_dir = models_dir / subdir

        cache_dir = target_dir / ".cache"
        cleaned_caches.add(cache_dir)

        if "/" in remote:
            nested = target_dir / PurePosixPath(remote).parent
            try:
                nested.resolve().relative_to(target_dir.resolve())
                nested_dirs.add(nested)
            except ValueError:
                pass

    for cache_dir in cleaned_caches:
        if cache_dir.is_symlink():
            continue
        try:
            shutil.rmtree(cache_dir)
        except (FileNotFoundError, OSError):
            pass

    for nested in sorted(nested_dirs, key=lambda p: len(p.parts), reverse=True):
        if nested.is_symlink():
            continue
        try:
            nested.rmdir()
        except (FileNotFoundError, OSError):
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
        prog="comfyui-download-framepack",
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

    # Validate all remote paths before doing anything
    for repo, remote, subdir, local, size in FILES:
        validate_remote_path(remote)

    total_size = "~24 GB"

    print()
    print("=" * 70)
    print("  FramePack I2V (HunyuanVideo Backbone, FP8)")
    print("=" * 70)
    print()
    print(f"  Destination: {models_dir}")
    print(f"  Total size:  {total_size}")
    print(f"  License:     Tencent Hunyuan Community License (no token required)")
    print()
    print("  Files to download:")
    for repo, remote, subdir, local, size in FILES:
        src = f"({repo.split('/')[-1]})"
        print(f"    {local:<45s} {size:>8s}  ->  {subdir}/  {src}")
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

    for repo, remote, subdir, local, size in FILES:
        target_dir = models_dir / subdir
        target_dir.mkdir(parents=True, exist_ok=True)

        final_path = target_dir / local
        if final_path.exists():
            print(f"  Skipping {local} (already exists)")
            continue

        print(f"  Downloading {local} ({size})...")
        try:
            downloaded_path = hf_hub_download(
                repo_id=repo,
                filename=remote,
                local_dir=target_dir,
            )
            safe_move(downloaded_path, final_path)
            print(f"    -> {final_path}")
        except Exception as e:
            print(f"\n  ERROR: {e}")
            print(f"\n  Model page: https://huggingface.co/{repo}")
            sys.exit(1)

    cleanup_hf_artifacts(models_dir, FILES)

    print()
    print("=" * 70)
    print("  Download complete!")
    print()
    print("  Next steps:")
    print("    1. Start ComfyUI:  flox services start comfyui")
    print("    2. Open http://localhost:8188")
    print("    3. Load 'framepack-i2v' workflow from the workflow browser")
    print("    4. Set your input image and prompt, then generate")
    print("=" * 70)
    print()


if __name__ == "__main__":
    main()
