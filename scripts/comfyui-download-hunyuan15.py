#!/usr/bin/env python3
"""Download HunyuanVideo 1.5 I2V/T2V models for ComfyUI."""
import argparse
import os
import shutil
import sys
from pathlib import Path, PurePosixPath

DESCRIPTION = """\
Download HunyuanVideo 1.5 models for ComfyUI.

Variants:
  i2v (default)  Image-to-Video (480p, FP8, cfg-distilled)  ~21 GB
  t2v            Text-to-Video (480p, FP8, cfg-distilled)    ~19 GB
  all            Both variants                               ~29 GB

I2V downloads:
  hunyuanvideo1.5_480p_i2v_cfg_distilled_fp8_scaled.safetensors (~7.8 GB)  ->  diffusion_models/
  qwen_2.5_vl_7b_fp8_scaled.safetensors   (~8.7 GB)   ->  clip/
  byt5_small_glyphxl_fp16.safetensors      (~0.4 GB)   ->  clip/
  hunyuanvideo15_vae_fp16.safetensors      (~2.3 GB)   ->  vae/
  sigclip_vision_patch14_384.safetensors   (~0.8 GB)   ->  clip_vision/

T2V additional downloads:
  hunyuanvideo1.5_480p_t2v_cfg_distilled_fp8_scaled.safetensors (~7.8 GB)  ->  diffusion_models/

Source: Comfy-Org/HunyuanVideo_1.5_repackaged (all files)
License: Tencent Hunyuan Community License (no HuggingFace token required)

HunyuanVideo 1.5 offers high-quality text-to-video and image-to-video
generation. The cfg-distilled FP8 variants are optimized for consumer GPUs.
Requires 24+ GB VRAM.
"""

EPILOG = """\
environment variables:
  COMFYUI_MODELS_DIR   Override model download directory
  COMFYUI_WORK_DIR     Override work directory (models go in $COMFYUI_WORK_DIR/models)

examples:
  comfyui-download-hunyuan15                         Download I2V (default)
  comfyui-download-hunyuan15 --variant t2v           Download T2V
  comfyui-download-hunyuan15 --variant all           Download all variants
  comfyui-download-hunyuan15 --dry-run               Show what would be downloaded
  comfyui-download-hunyuan15 --models-dir /data      Download to custom location

after downloading:
  1. Start ComfyUI:  flox services start comfyui
  2. Open http://localhost:8188
  3. Load the hunyuan15-i2v or hunyuan15-t2v workflow
  4. Set your input image/prompt, then generate
"""

HV15_REPO = "Comfy-Org/HunyuanVideo_1.5_repackaged"

# (repo_id, remote_filename, subdirectory, local_filename, approx_size)
FILES_I2V = [
    (HV15_REPO, "split_files/diffusion_models/hunyuanvideo1.5_480p_i2v_cfg_distilled_fp8_scaled.safetensors", "diffusion_models", "hunyuanvideo1.5_480p_i2v_cfg_distilled_fp8_scaled.safetensors", "7.8 GB"),
    (HV15_REPO, "split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors", "clip", "qwen_2.5_vl_7b_fp8_scaled.safetensors", "8.7 GB"),
    (HV15_REPO, "split_files/text_encoders/byt5_small_glyphxl_fp16.safetensors", "clip", "byt5_small_glyphxl_fp16.safetensors", "0.4 GB"),
    (HV15_REPO, "split_files/vae/hunyuanvideo15_vae_fp16.safetensors", "vae", "hunyuanvideo15_vae_fp16.safetensors", "2.3 GB"),
    (HV15_REPO, "split_files/clip_vision/sigclip_vision_patch14_384.safetensors", "clip_vision", "sigclip_vision_patch14_384.safetensors", "0.8 GB"),
]

FILES_T2V = [
    (HV15_REPO, "split_files/diffusion_models/hunyuanvideo1.5_480p_t2v_cfg_distilled_fp8_scaled.safetensors", "diffusion_models", "hunyuanvideo1.5_480p_t2v_cfg_distilled_fp8_scaled.safetensors", "7.8 GB"),
    (HV15_REPO, "split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors", "clip", "qwen_2.5_vl_7b_fp8_scaled.safetensors", "8.7 GB"),
    (HV15_REPO, "split_files/text_encoders/byt5_small_glyphxl_fp16.safetensors", "clip", "byt5_small_glyphxl_fp16.safetensors", "0.4 GB"),
    (HV15_REPO, "split_files/vae/hunyuanvideo15_vae_fp16.safetensors", "vae", "hunyuanvideo15_vae_fp16.safetensors", "2.3 GB"),
]

VARIANT_SIZES = {
    "i2v": "~21 GB",
    "t2v": "~19 GB",
    "all": "~29 GB",
}

VARIANT_LABELS = {
    "i2v": "HunyuanVideo 1.5 I2V (Image-to-Video, 480p, FP8)",
    "t2v": "HunyuanVideo 1.5 T2V (Text-to-Video, 480p, FP8)",
    "all": "HunyuanVideo 1.5 All Variants",
}


def get_files(variant):
    if variant == "i2v":
        return FILES_I2V
    elif variant == "t2v":
        return FILES_T2V
    elif variant == "all":
        seen = set()
        files = []
        for f in FILES_I2V + FILES_T2V:
            key = (f[2], f[3])  # (subdir, local_name)
            if key not in seen:
                seen.add(key)
                files.append(f)
        return files
    return FILES_I2V


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
        prog="comfyui-download-hunyuan15",
        description=DESCRIPTION,
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--variant", choices=["i2v", "t2v", "all"], default="i2v",
        help="model variant to download (default: i2v)",
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
    files = get_files(args.variant)

    # Validate all remote paths before doing anything
    for repo, remote, subdir, local, size in files:
        validate_remote_path(remote)

    total_size = VARIANT_SIZES[args.variant]
    label = VARIANT_LABELS[args.variant]

    print()
    print("=" * 70)
    print(f"  {label}")
    print("=" * 70)
    print()
    print(f"  Destination: {models_dir}")
    print(f"  Total size:  {total_size}")
    print(f"  License:     Tencent Hunyuan Community License (no token required)")
    print()
    print("  Files to download:")
    for repo, remote, subdir, local, size in files:
        src = f"({repo.split('/')[-1]})"
        print(f"    {local:<55s} {size:>8s}  ->  {subdir}/  {src}")
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

    for repo, remote, subdir, local, size in files:
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

    cleanup_hf_artifacts(models_dir, files)

    print()
    print("=" * 70)
    print("  Download complete!")
    print()
    print("  Next steps:")
    print("    1. Start ComfyUI:  flox services start comfyui")
    print("    2. Open http://localhost:8188")
    if args.variant in ("i2v", "all"):
        print("    3. Load 'hunyuan15-i2v' workflow from the workflow browser")
        print("    4. Set your input image and prompt, then generate")
    if args.variant in ("t2v", "all"):
        print("    3. Load 'hunyuan15-t2v' workflow from the workflow browser")
        print("    4. Set your prompt and generate")
    print("=" * 70)
    print()


if __name__ == "__main__":
    main()
