#!/usr/bin/env python3
"""Download Wan 2.2 video generation models for ComfyUI."""
import argparse
import os
import shutil
import sys
from pathlib import Path, PurePosixPath

DESCRIPTION = """\
Download Wan 2.2 video generation models for ComfyUI.

Variants:
  ti2v-5b (default)  Text+Image-to-Video 5B (FP16)     ~17 GB
  i2v-14b            Image-to-Video 14B MoE (FP8)       ~20 GB
  all                Both variants                       ~30 GB

TI2V-5B downloads:
  wan2.2_ti2v_5B_fp16.safetensors         (~9.3 GB)   ->  diffusion_models/
  umt5_xxl_fp8_e4m3fn_scaled.safetensors  (~6.3 GB)   ->  clip/
  wan2.2_vae.safetensors                  (~1.3 GB)   ->  vae/

I2V-14B additional downloads:
  wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors (~13.3 GB)  ->  diffusion_models/
  wan_2.1_vae.safetensors                          (~0.2 GB)   ->  vae/

Source: Comfy-Org/Wan_2.2_ComfyUI_Repackaged on HuggingFace
License: Apache 2.0 (no HuggingFace token required)

Wan 2.2 is an open-source video generation model with excellent quality.
The TI2V-5B model generates short videos from text + optional reference image.
The I2V-14B MoE model produces higher quality image-to-video results.
Requires 16+ GB VRAM for 5B, 24+ GB VRAM for 14B.
"""

EPILOG = """\
environment variables:
  COMFYUI_MODELS_DIR   Override model download directory
  COMFYUI_WORK_DIR     Override work directory (models go in $COMFYUI_WORK_DIR/models)

examples:
  comfyui-download-wan22                         Download TI2V-5B (default)
  comfyui-download-wan22 --variant i2v-14b       Download I2V-14B
  comfyui-download-wan22 --variant all           Download all variants
  comfyui-download-wan22 --dry-run               Show what would be downloaded
  comfyui-download-wan22 --models-dir /data      Download to custom location

after downloading:
  1. Start ComfyUI:  flox services start comfyui
  2. Open http://localhost:8188
  3. Load the wan22-ti2v workflow from the workflow browser
  4. Set your input image and prompt
  5. Generate video (81 frames at 24fps = ~3.4 seconds)
"""

WAN_REPO = "Comfy-Org/Wan_2.2_ComfyUI_Repackaged"

# (repo_id, remote_filename, subdirectory, local_filename, approx_size)
FILES_TI2V_5B = [
    (WAN_REPO, "split_files/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors", "diffusion_models", "wan2.2_ti2v_5B_fp16.safetensors", "9.3 GB"),
    (WAN_REPO, "split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors", "clip", "umt5_xxl_fp8_e4m3fn_scaled.safetensors", "6.3 GB"),
    (WAN_REPO, "split_files/vae/wan2.2_vae.safetensors", "vae", "wan2.2_vae.safetensors", "1.3 GB"),
]

FILES_I2V_14B = [
    (WAN_REPO, "split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors", "diffusion_models", "wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors", "13.3 GB"),
    (WAN_REPO, "split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors", "clip", "umt5_xxl_fp8_e4m3fn_scaled.safetensors", "6.3 GB"),
    (WAN_REPO, "split_files/vae/wan_2.1_vae.safetensors", "vae", "wan_2.1_vae.safetensors", "0.2 GB"),
]

VARIANT_SIZES = {
    "ti2v-5b": "~17 GB",
    "i2v-14b": "~20 GB",
    "all": "~30 GB",
}

VARIANT_LABELS = {
    "ti2v-5b": "Wan 2.2 TI2V-5B (Text+Image-to-Video, FP16)",
    "i2v-14b": "Wan 2.2 I2V-14B MoE (Image-to-Video, FP8)",
    "all": "Wan 2.2 All Variants",
}


def get_files(variant):
    if variant == "ti2v-5b":
        return FILES_TI2V_5B
    elif variant == "i2v-14b":
        return FILES_I2V_14B
    elif variant == "all":
        seen = set()
        files = []
        for f in FILES_TI2V_5B + FILES_I2V_14B:
            key = (f[2], f[3])  # (subdir, local_name)
            if key not in seen:
                seen.add(key)
                files.append(f)
        return files
    return FILES_TI2V_5B


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
        prog="comfyui-download-wan22",
        description=DESCRIPTION,
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--variant", choices=["ti2v-5b", "i2v-14b", "all"], default="ti2v-5b",
        help="model variant to download (default: ti2v-5b)",
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
    print(f"  Source:      {WAN_REPO}")
    print(f"  Destination: {models_dir}")
    print(f"  Total size:  {total_size}")
    print(f"  License:     Apache 2.0 (no token required)")
    print()
    print("  Files to download:")
    for repo, remote, subdir, local, size in files:
        print(f"    {local:<50s} {size:>8s}  ->  {subdir}/")
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
    if args.variant in ("ti2v-5b", "all"):
        print("    3. Load 'wan22-ti2v' workflow from the workflow browser")
        print("    4. Set your input image and prompt, then generate")
    if args.variant in ("i2v-14b", "all"):
        print("    3. Load 'wan22-i2v-14b' workflow from the workflow browser")
        print("    4. Set your input image and prompt, then generate")
    print("=" * 70)
    print()


if __name__ == "__main__":
    main()
