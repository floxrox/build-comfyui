from typing_extensions import override

import nodes
from comfy_api.latest import ComfyExtension, io


class SafeCLIPTextEncodeSDXL(io.ComfyNode):
    @classmethod
    def define_schema(cls):
        return io.Schema(
            node_id="SafeCLIPTextEncodeSDXL",
            category="advanced/conditioning",
            inputs=[
                io.Clip.Input("clip"),
                io.Int.Input("width", default=1024, min=0, max=nodes.MAX_RESOLUTION),
                io.Int.Input("height", default=1024, min=0, max=nodes.MAX_RESOLUTION),
                io.Int.Input("crop_w", default=0, min=0, max=nodes.MAX_RESOLUTION),
                io.Int.Input("crop_h", default=0, min=0, max=nodes.MAX_RESOLUTION),
                io.Int.Input("target_width", default=1024, min=0, max=nodes.MAX_RESOLUTION),
                io.Int.Input("target_height", default=1024, min=0, max=nodes.MAX_RESOLUTION),
                io.String.Input("text_g", multiline=True, dynamic_prompts=True),
                io.String.Input("text_l", multiline=True, dynamic_prompts=True),
            ],
            outputs=[io.Conditioning.Output()],
        )

    @classmethod
    def execute(cls, clip, width, height, crop_w, crop_h, target_width, target_height, text_g, text_l) -> io.NodeOutput:
        # Tokenize global and local text
        tokens_g = clip.tokenize(text_g)
        tokens_l = clip.tokenize(text_l)

        # Some CLIP implementations only produce "l"
        # Ensure we always have a "g" key
        if "g" not in tokens_g:
            tokens_g["g"] = tokens_g.get("l", [])

        tokens = tokens_g
        tokens["l"] = tokens_l.get("l", tokens_l.get("g", []))

        # Match lengths like the original SDXL node does
        if len(tokens["l"]) != len(tokens["g"]):
            empty = clip.tokenize("")
            while len(tokens["l"]) < len(tokens["g"]):
                tokens["l"] += empty["l"]
            while len(tokens["l"]) > len(tokens["g"]):
                tokens["g"] += empty["g"]

        return io.NodeOutput(clip.encode_from_tokens_scheduled(tokens, add_dict={"width": width, "height": height, "crop_w": crop_w, "crop_h": crop_h, "target_width": target_width, "target_height": target_height}))


class SafeClipSdxlExtension(ComfyExtension):
    @override
    async def get_node_list(self) -> list[type[io.ComfyNode]]:
        return [
            SafeCLIPTextEncodeSDXL,
        ]


async def comfy_entrypoint() -> SafeClipSdxlExtension:
    return SafeClipSdxlExtension()
