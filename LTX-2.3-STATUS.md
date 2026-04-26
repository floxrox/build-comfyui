# LTX-2.3 Support Status

**Status:** Blocked — upstream ComfyUI bug
**Last checked:** 2026-03-29
**ComfyUI version tested:** 0.18.3 (tag) + master (fc1fdf3389aa, 2026-03-28)

## The Problem

LTX-2.3 (22B audio-video model by Lightricks) cannot generate video locally via `CLIPTextEncode` in ComfyUI. The only working text encoding path is `GemmaAPITextEncode`, which requires a paid Lightricks API key.

## Root Cause

The LTX-2.3 checkpoint (`ltx-2.3-22b-dev.safetensors`, 43 GB) contains `text_embedding_projection` weights at the top level:

```
text_embedding_projection.video_aggregate_embed.weight  [4096, 188160]
text_embedding_projection.video_aggregate_embed.bias    [4096]
text_embedding_projection.audio_aggregate_embed.weight  [2048, 188160]
text_embedding_projection.audio_aggregate_embed.bias    [2048]
```

ComfyUI's checkpoint loader splits state dict keys between the diffusion model and text encoder using `text_encoder_key_prefix` (for LTXAV: `["text_encoders."]`). Since `text_embedding_projection.*` keys don't start with `text_encoders.`, they get routed to the **diffusion model**, not the text encoder.

The text encoder (`LTXAVTEModel`) creates a `DualLinearProjection` module for the text projection but its weights are never loaded. When `CLIPTextEncode` calls `encode_token_weights()`, it tries to run the uninitialized projection (`self.text_embedding_projection(out)`), which crashes:

```
AttributeError: 'Linear' object has no attribute 'weight'
```

at `comfy/ops.py:230` in `cast_bias_weight()`.

## Why Adding the Prefix Doesn't Work

Adding `"text_embedding_projection."` to `text_encoder_key_prefix` causes the checkpoint loader to **strip** that prefix before passing keys to the text encoder. So `text_embedding_projection.video_aggregate_embed.weight` becomes `video_aggregate_embed.weight`. But `load_sd()` in `lt.py` expects keys starting with `text_embedding_projection.` — creating a double-stripping mismatch.

## What Needs to Happen

One of:

1. **ComfyUI upstream fix**: Route `text_embedding_projection.*` keys to the text encoder WITHOUT prefix stripping. This likely requires a custom `process_clip_state_dict` override in the LTXAV supported model class that handles these keys specially.

2. **Alternative**: Have the diffusion model's `preprocess_text_embeds` apply the text projection (it already has the weights), and make the text encoder skip projection entirely when it detects dual_linear with unloaded weights. This would require changes to both `model_base.py` and `text_encoders/lt.py`.

3. **ComfyUI-LTXVideo custom node fix**: The `GemmaAPITextEncode` node in ComfyUI-LTXVideo handles text projection correctly using its own `gemma_encoder.py`. A local equivalent (without the API call) could load the Gemma model + text projection from the checkpoint and do the encoding+projection in one step.

## How to Check if Fixed

```bash
# 1. Update ComfyUI version in comfyui-complete.nix
# 2. Build: flox build comfyui-complete
# 3. Load the LTX-2.3 two-stage workflow
# 4. Queue with CLIPTextEncode connected to LTXVConditioning
# 5. If no "'Linear' object has no attribute 'weight'" error → fixed
```

The test workflow is at:
`~/comfyui-work/user/default/workflows/LTX23-I2V-Two-Stage-Official.json`

## Models Already Downloaded

All LTX-2.3 model files are on disk at `~/comfyui-work/models/`:

| File | Location | Size |
|------|----------|------|
| `ltx-2.3-22b-dev.safetensors` | `checkpoints/` | 43 GB |
| `ltx-2.3-22b-dev_transformer_only_fp8_scaled.safetensors` | `diffusion_models/` | 22 GB |
| `gemma_3_12B_it_fp4_mixed.safetensors` | `clip/` | 9.4 GB |
| `gemma_3_12B_it_fp8_scaled.safetensors` | `clip/` | 13.2 GB |
| `ltx-2.3_text_projection_bf16.safetensors` | `clip/` | 2.2 GB |
| `LTX23_video_vae_bf16.safetensors` | `vae/` | 1.4 GB |
| `LTX23_audio_vae_bf16.safetensors` | `vae/` + `checkpoints/` (symlink) | 348 MB |
| `ltx-2.3-spatial-upscaler-x2-1.1.safetensors` | `latent_upscale_models/` | 950 MB |
| `ltx-2.3-temporal-upscaler-x2-1.0.safetensors` | `latent_upscale_models/` | 250 MB |
| `ltx-2.3-22b-distilled-lora-384.safetensors` | `loras/` | 7.1 GB |

## Additional Dependencies

- **ComfyMath** custom node (for `CM_FloatToInt`): cloned to `~/comfyui-work/custom_nodes/ComfyMath/`
- **ComfyUI-LTXVideo** node: already bundled (pinned March 6, 2026)

## Related Issues

- [ComfyUI #12592](https://github.com/Comfy-Org/ComfyUI/issues/12592): Linear no attribute weight with LTXAV MixedPrecisionOps
- [ComfyUI #11920](https://github.com/Comfy-Org/ComfyUI/issues/11920): Gemma-3 breaks LTX-2 on Blackwell/RTX 5090
