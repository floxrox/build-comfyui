#!/usr/bin/env python3
"""Download Stable Diffusion 3.5 Large model and text encoders for ComfyUI."""
import argparse
import os
import shutil
import sys
from pathlib import Path, PurePosixPath

DESCRIPTION = """\
Download Stable Diffusion 3.5 Large model for ComfyUI.

Downloads:
  sd3.5_large.safetensors        (~11.7 GB)  ->  checkpoints/
  clip_l.safetensors             (~0.2 GB)   ->  clip/
  clip_g.safetensors             (~1.4 GB)   ->  clip/
  t5xxl_fp16.safetensors         (~9.5 GB)   ->  clip/
                                 -----------
                          Total: ~23 GB

Source: stabilityai/stable-diffusion-3.5-large on HuggingFace
License: Stability AI Community License (GATED - token required)

SD 3.5 Large uses a triple text encoder architecture (CLIP-L + CLIP-G +
T5-XXL) and produces high-quality images. Requires significant VRAM
(~12+ GB) and disk space for the text encoders.

IMPORTANT: This is a gated model. You must:
  1. Create a HuggingFace account at https://huggingface.co
  2. Accept the license at https://huggingface.co/stabilityai/stable-diffusion-3.5-large
  3. Create an access token at https://huggingface.co/settings/tokens
  4. Set HF_TOKEN before running this script
"""

EPILOG = """\
environment variables:
  HF_TOKEN             HuggingFace token (REQUIRED for SD 3.5)
  COMFYUI_MODELS_DIR   Override model download directory
  COMFYUI_WORK_DIR     Override work directory (models go in $COMFYUI_WORK_DIR/models)

examples:
  export HF_TOKEN=hf_your_token_here
  comfyui-download-sd35                       Download to default location
  comfyui-download-sd35 --dry-run             Show what would be downloaded
  comfyui-download-sd35 --models-dir /data    Download to custom location

after downloading:
  1. Start ComfyUI:  flox services start comfyui
  2. Open http://localhost:8188
  3. Use CheckpointLoaderSimple with sd3.5_large.safetensors
  4. Use TripleCLIPLoader with clip_l, clip_g, and t5xxl_fp16
  5. Recommended resolution: 1024x1024
"""

MODEL_ID = "stabilityai/stable-diffusion-3.5-large"

FILES = [
    # (remote_filename, subdirectory, local_filename, approx_size)
    ("sd3.5_large.safetensors", "checkpoints", "sd3.5_large.safetensors", "11.7 GB"),
    ("text_encoders/clip_l.safetensors", "clip", "clip_l.safetensors", "0.2 GB"),
    ("text_encoders/clip_g.safetensors", "clip", "clip_g.safetensors", "1.4 GB"),
    ("text_encoders/t5xxl_fp16.safetensors", "clip", "t5xxl_fp16.safetensors", "9.5 GB"),
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
    """Remove .cache/ dirs and empty nested dirs left by hf_hub_download.

    Best-effort and non-fatal: cleanup failure never blocks the download.
    Uses try/except instead of is_dir() checks to avoid TOCTOU races.
    Skips symlinks to avoid following links outside the model directory.
    Processes nested dirs deepest-first to handle multi-level paths.
    """
    cleaned_caches = set()
    nested_dirs = set()

    for entry in files:
        remote, subdir = entry[0], entry[1]
        target_dir = models_dir / subdir

        # Collect .cache/ dirs to remove
        cache_dir = target_dir / ".cache"
        cleaned_caches.add(cache_dir)

        # Collect nested parent dirs from remote paths (e.g., text_encoders/)
        if "/" in remote:
            nested = target_dir / PurePosixPath(remote).parent
            # Verify the resolved path stays inside target_dir
            try:
                nested.resolve().relative_to(target_dir.resolve())
                nested_dirs.add(nested)
            except ValueError:
                pass  # Path escapes target_dir, skip

    # Remove .cache/ directories
    for cache_dir in cleaned_caches:
        if cache_dir.is_symlink():
            continue
        try:
            shutil.rmtree(cache_dir)
        except (FileNotFoundError, OSError):
            pass

    # Remove empty nested dirs, deepest first
    for nested in sorted(nested_dirs, key=lambda p: len(p.parts), reverse=True):
        if nested.is_symlink():
            continue
        try:
            nested.rmdir()  # Only succeeds if empty
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
        prog="comfyui-download-sd35",
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

    # Validate all remote paths before doing anything
    for remote, subdir, local, size in FILES:
        validate_remote_path(remote)

    total_size = "~23 GB"

    print()
    print("=" * 70)
    print("  Stable Diffusion 3.5 Large for ComfyUI")
    print("=" * 70)
    print()
    print(f"  Model:       {MODEL_ID}")
    print(f"  Destination: {models_dir}")
    print(f"  Total size:  {total_size}")
    print(f"  Token:       {'set' if hf_token else 'NOT SET (required!)'}")
    print()
    print("  Files to download:")
    for remote, subdir, local, size in FILES:
        print(f"    {local:<45s} {size:>8s}  ->  {subdir}/")
    print()

    if not hf_token and not args.dry_run:
        print("  ERROR: HF_TOKEN is not set.")
        print()
        print("  SD 3.5 is a gated model. To download it:")
        print("    1. Accept the license at:")
        print(f"       https://huggingface.co/{MODEL_ID}")
        print("    2. Create a token at:")
        print("       https://huggingface.co/settings/tokens")
        print("    3. Run:")
        print("       export HF_TOKEN=hf_your_token_here")
        print("       comfyui-download-sd35")
        print()
        sys.exit(1)

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
            if "401" in str(e) or "403" in str(e) or "gated" in str(e).lower():
                print("  Make sure you have accepted the license and your token is valid.")
            sys.exit(1)

    cleanup_hf_artifacts(models_dir, FILES)

    print()
    print("=" * 70)
    print("  Download complete!")
    print()
    print("  Next steps:")
    print("    1. Start ComfyUI:  flox services start comfyui")
    print("    2. Open http://localhost:8188")
    print("    3. Use CheckpointLoaderSimple: sd3.5_large.safetensors")
    print("    4. Use TripleCLIPLoader: clip_l, clip_g, t5xxl_fp16")
    print("    5. Recommended resolution: 1024x1024")
    print("=" * 70)
    print()


if __name__ == "__main__":
    main()
