#!/usr/bin/env python3
"""Download LTX-2 video generation models for ComfyUI."""
import argparse
import os
import shutil
import sys
from pathlib import Path, PurePosixPath

DESCRIPTION = """\
Download LTX-2 (19B) video generation models for ComfyUI.

Variants:
  default (no flag)  Distilled FP8 + Gemma FP8 + upscaler    ~41 GB
  bf16               Distilled BF16 + Gemma FP8 + upscaler   ~57 GB
  all                Both checkpoint variants                 ~68 GB

Default downloads:
  ltx-2-19b-distilled-fp8.safetensors      (~27 GB)  ->  checkpoints/
  gemma_3_12B_it_fp8_scaled.safetensors    (~13 GB)  ->  text_encoders/gemma_3_12B_it_fp8_scaled/
  tokenizer files (tokenizer.model, etc.)  (~38 MB)  ->  text_encoders/gemma_3_12B_it_fp8_scaled/
  ltx-2-spatial-upscaler-x2-1.0.safetensors (~1 GB)  ->  latent_upscale_models/

BF16 additional/alternative downloads:
  ltx-2-19b-distilled.safetensors          (~43 GB)  ->  checkpoints/

Source: Lightricks/LTX-2 + Comfy-Org/ltx-2 on HuggingFace
License: LTXV Research License (no HuggingFace token required)

LTX-2 is a 19B parameter audio+video generation model from Lightricks.
Generates high-quality video with audio from text or image prompts.
The distilled variant uses fewer sampling steps for faster generation.
Requires 24+ GB VRAM (FP8) or 32+ GB VRAM with offloading (BF16).
"""

EPILOG = """\
environment variables:
  COMFYUI_MODELS_DIR   Override model download directory
  COMFYUI_WORK_DIR     Override work directory (models go in $COMFYUI_WORK_DIR/models)

examples:
  comfyui-download-ltx2.py                      Download FP8 distilled (default)
  comfyui-download-ltx2.py --variant bf16        Download BF16 distilled
  comfyui-download-ltx2.py --variant all         Download all variants
  comfyui-download-ltx2.py --dry-run             Show what would be downloaded
  comfyui-download-ltx2.py --models-dir /data    Download to custom location

after downloading:
  1. Start ComfyUI:  flox services start comfyui
  2. Open http://localhost:8188
  3. Load the ltx2-t2v-distilled or ltx2-i2v-distilled workflow
  4. Enter your prompt (and reference image for I2V)
  5. Generate video (121 frames at 24fps = ~5 seconds)
"""

LTX2_REPO = "Lightricks/LTX-2"
COMFY_REPO = "Comfy-Org/ltx-2"

# Gemma text encoder subdirectory name
# The LTXVGemmaCLIPModelLoader node expects the model file alongside tokenizer
# files in a subdirectory (it uses path.parents[1] to find tokenizer.model).
GEMMA_DIR = "gemma_3_12B_it_fp8_scaled"

# (repo_id, remote_filename, subdirectory, local_filename, approx_size)
FILES_COMMON = [
    (COMFY_REPO, "split_files/text_encoders/gemma_3_12B_it_fp8_scaled.safetensors", f"text_encoders/{GEMMA_DIR}", "gemma_3_12B_it_fp8_scaled.safetensors", "13 GB"),
    (LTX2_REPO, "ltx-2-spatial-upscaler-x2-1.0.safetensors", "latent_upscale_models", "ltx-2-spatial-upscaler-x2-1.0.safetensors", "1 GB"),
]

# Tokenizer files required by LTXVGemmaCLIPModelLoader
# These must be in the same directory as the Gemma model weights
# Tokenizer + config files required by LTXVGemmaCLIPModelLoader
# from_pretrained needs config.json for model architecture, tokenizer files for
# text encoding, and chat_template.jinja for LTXVGemmaEnhancePrompt node.
FILES_TOKENIZER = [
    (LTX2_REPO, "text_encoder/config.json", f"text_encoders/{GEMMA_DIR}", "config.json", "<1 KB"),
    (LTX2_REPO, "text_encoder/generation_config.json", f"text_encoders/{GEMMA_DIR}", "generation_config.json", "<1 KB"),
    (LTX2_REPO, "tokenizer/tokenizer.model", f"text_encoders/{GEMMA_DIR}", "tokenizer.model", "4.5 MB"),
    (LTX2_REPO, "tokenizer/tokenizer.json", f"text_encoders/{GEMMA_DIR}", "tokenizer.json", "32 MB"),
    (LTX2_REPO, "tokenizer/tokenizer_config.json", f"text_encoders/{GEMMA_DIR}", "tokenizer_config.json", "1.2 MB"),
    (LTX2_REPO, "tokenizer/chat_template.jinja", f"text_encoders/{GEMMA_DIR}", "chat_template.jinja", "1.5 KB"),
    (LTX2_REPO, "tokenizer/special_tokens_map.json", f"text_encoders/{GEMMA_DIR}", "special_tokens_map.json", "<1 KB"),
    (LTX2_REPO, "tokenizer/added_tokens.json", f"text_encoders/{GEMMA_DIR}", "added_tokens.json", "<1 KB"),
    (LTX2_REPO, "tokenizer/preprocessor_config.json", f"text_encoders/{GEMMA_DIR}", "preprocessor_config.json", "<1 KB"),
    (LTX2_REPO, "tokenizer/processor_config.json", f"text_encoders/{GEMMA_DIR}", "processor_config.json", "<1 KB"),
]

# Symlink needed for from_pretrained (expects model*.safetensors naming)
GEMMA_MODEL_SYMLINK = ("model.safetensors", "gemma_3_12B_it_fp8_scaled.safetensors")

FILES_FP8 = [
    (LTX2_REPO, "ltx-2-19b-distilled-fp8.safetensors", "checkpoints", "ltx-2-19b-distilled-fp8.safetensors", "27 GB"),
]

FILES_BF16 = [
    (LTX2_REPO, "ltx-2-19b-distilled.safetensors", "checkpoints", "ltx-2-19b-distilled.safetensors", "43 GB"),
]

VARIANT_SIZES = {
    "fp8": "~41 GB",
    "bf16": "~57 GB",
    "all": "~68 GB",
}

VARIANT_LABELS = {
    "fp8": "LTX-2 19B Distilled FP8 (recommended)",
    "bf16": "LTX-2 19B Distilled BF16 (full precision)",
    "all": "LTX-2 All Variants",
}


def get_files(variant):
    if variant == "fp8":
        return FILES_FP8 + FILES_COMMON + FILES_TOKENIZER
    elif variant == "bf16":
        return FILES_BF16 + FILES_COMMON + FILES_TOKENIZER
    elif variant == "all":
        seen = set()
        files = []
        for f in FILES_FP8 + FILES_BF16 + FILES_COMMON + FILES_TOKENIZER:
            key = (f[2], f[3])  # (subdir, local_name)
            if key not in seen:
                seen.add(key)
                files.append(f)
        return files
    return FILES_FP8 + FILES_COMMON + FILES_TOKENIZER


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
        prog="comfyui-download-ltx2",
        description=DESCRIPTION,
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--variant", choices=["fp8", "bf16", "all"], default="fp8",
        help="model variant to download (default: fp8)",
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
    print(f"  License:     LTXV Research License (no token required)")
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

    # Patch tokenizer_config.json with chat_template from chat_template.jinja
    # The LTX-2 repo ships these as separate files but transformers expects
    # chat_template embedded in tokenizer_config.json for apply_chat_template()
    import json as _json
    gemma_dir = models_dir / f"text_encoders/{GEMMA_DIR}"
    tc_path = gemma_dir / "tokenizer_config.json"
    jinja_path = gemma_dir / "chat_template.jinja"
    if tc_path.exists() and jinja_path.exists():
        with open(tc_path) as f:
            tc = _json.load(f)
        if "chat_template" not in tc:
            with open(jinja_path) as f:
                tc["chat_template"] = f.read()
            with open(tc_path, "w") as f:
                _json.dump(tc, f, indent=2, ensure_ascii=False)
            print("  Patched tokenizer_config.json with chat_template")

    # Create model.safetensors symlink for from_pretrained compatibility
    # LTXVGemmaCLIPModelLoader uses Gemma3ForConditionalGeneration.from_pretrained()
    # which expects files named model*.safetensors
    gemma_dir = models_dir / f"text_encoders/{GEMMA_DIR}"
    symlink_name, symlink_target = GEMMA_MODEL_SYMLINK
    symlink_path = gemma_dir / symlink_name
    if gemma_dir.exists() and not symlink_path.exists():
        symlink_path.symlink_to(symlink_target)
        print(f"  Created symlink: {symlink_name} -> {symlink_target}")

    print()
    print("=" * 70)
    print("  Download complete!")
    print()
    print("  Next steps:")
    print("    1. Start ComfyUI:  flox services start comfyui")
    print("    2. Open http://localhost:8188")
    print("    3. Load 'ltx2-t2v-distilled' or 'ltx2-i2v-distilled' workflow")
    print("    4. Enter your prompt (and reference image for I2V)")
    print("    5. Generate video")
    print("=" * 70)
    print()


if __name__ == "__main__":
    main()
