#!/usr/bin/env python3
"""Download FLUX.1-dev UNET, VAE, and text encoders for ComfyUI."""
import argparse
import os
import shutil
import sys
from pathlib import Path, PurePosixPath

DESCRIPTION = """\
Download FLUX.1-dev model for ComfyUI.

Downloads:
  flux1-dev.safetensors          (~12.0 GB)  ->  unet/
  ae.safetensors                 (~0.3 GB)   ->  vae/
  clip_l.safetensors             (~0.2 GB)   ->  clip/       (from FLUX repo)
  t5xxl_fp16.safetensors         (~9.5 GB)   ->  clip/       (from comfyanonymous)
                                 -----------
                          Total: ~22 GB

Source: black-forest-labs/FLUX.1-dev on HuggingFace
        comfyanonymous/flux_text_encoders (T5-XXL encoder)
License: FLUX.1-dev Non-Commercial License (GATED - token required)

FLUX.1-dev is a rectified flow transformer model that produces excellent
images with strong prompt adherence. Unlike checkpoint-based models, FLUX
uses a separate UNET loader. Requires significant VRAM (~12+ GB).

IMPORTANT: This is a gated model. You must:
  1. Create a HuggingFace account at https://huggingface.co
  2. Accept the license at https://huggingface.co/black-forest-labs/FLUX.1-dev
  3. Create an access token at https://huggingface.co/settings/tokens
  4. Set HF_TOKEN before running this script
"""

EPILOG = """\
environment variables:
  HF_TOKEN             HuggingFace token (REQUIRED for FLUX)
  COMFYUI_MODELS_DIR   Override model download directory
  COMFYUI_WORK_DIR     Override work directory (models go in $COMFYUI_WORK_DIR/models)

examples:
  export HF_TOKEN=hf_your_token_here
  comfyui-download-flux                       Download to default location
  comfyui-download-flux --dry-run             Show what would be downloaded
  comfyui-download-flux --models-dir /data    Download to custom location

after downloading:
  1. Start ComfyUI:  flox services start comfyui
  2. Open http://localhost:8188
  3. Use UNETLoader (not CheckpointLoader) with flux1-dev.safetensors
  4. Use DualCLIPLoader with clip_l and t5xxl_fp16 (select flux type)
  5. Use VAELoader with ae.safetensors
  6. Recommended resolution: 1024x1024
  7. Use low CFG (1-2) — FLUX uses guidance embedding instead
"""

MODEL_ID = "black-forest-labs/FLUX.1-dev"
TEXT_ENCODER_REPO = "comfyanonymous/flux_text_encoders"

# (repo_id, remote_filename, subdirectory, local_filename, approx_size)
FILES = [
    (MODEL_ID, "flux1-dev.safetensors", "unet", "flux1-dev.safetensors", "12.0 GB"),
    (MODEL_ID, "ae.safetensors", "vae", "ae.safetensors", "0.3 GB"),
    (MODEL_ID, "text_encoder/model.safetensors", "clip", "clip_l.safetensors", "0.2 GB"),
    (TEXT_ENCODER_REPO, "t5xxl_fp16.safetensors", "clip", "t5xxl_fp16.safetensors", "9.5 GB"),
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
        remote, subdir = entry[1], entry[2]
        target_dir = models_dir / subdir

        # Collect .cache/ dirs to remove
        cache_dir = target_dir / ".cache"
        cleaned_caches.add(cache_dir)

        # Collect nested parent dirs from remote paths (e.g., text_encoder/)
        if "/" in remote:
            nested = target_dir / PurePosixPath(remote).parent
            try:
                nested.resolve().relative_to(target_dir.resolve())
                nested_dirs.add(nested)
            except ValueError:
                pass

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
        prog="comfyui-download-flux",
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
    for repo, remote, subdir, local, size in FILES:
        validate_remote_path(remote)

    total_size = "~22 GB"

    print()
    print("=" * 70)
    print("  FLUX.1-dev for ComfyUI")
    print("=" * 70)
    print()
    print(f"  Model:       {MODEL_ID}")
    print(f"  Destination: {models_dir}")
    print(f"  Total size:  {total_size}")
    print(f"  Token:       {'set' if hf_token else 'NOT SET (required!)'}")
    print()
    print("  Files to download:")
    for repo, remote, subdir, local, size in FILES:
        src = f"({repo.split('/')[-1]})" if repo != MODEL_ID else ""
        print(f"    {local:<40s} {size:>8s}  ->  {subdir}/  {src}")
    print()

    if not hf_token and not args.dry_run:
        print("  ERROR: HF_TOKEN is not set.")
        print()
        print("  FLUX.1-dev is a gated model. To download it:")
        print("    1. Accept the license at:")
        print(f"       https://huggingface.co/{MODEL_ID}")
        print("    2. Create a token at:")
        print("       https://huggingface.co/settings/tokens")
        print("    3. Run:")
        print("       export HF_TOKEN=hf_your_token_here")
        print("       comfyui-download-flux")
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

    for repo, remote, subdir, local, size in FILES:
        target_dir = models_dir / subdir
        target_dir.mkdir(parents=True, exist_ok=True)

        print(f"  Downloading {remote} ({size})...")
        try:
            downloaded_path = hf_hub_download(
                repo_id=repo,
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
            print(f"\n  Model page: https://huggingface.co/{repo}")
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
    print("    3. Use UNETLoader (not CheckpointLoader): flux1-dev.safetensors")
    print("    4. Use DualCLIPLoader: clip_l + t5xxl_fp16 (select 'flux' type)")
    print("    5. Use VAELoader: ae.safetensors")
    print("    6. Use low CFG (1-2) - FLUX uses guidance embedding instead")
    print("=" * 70)
    print()


if __name__ == "__main__":
    main()
