# FLUX.1 schnell for the IMS Living Lab, as a RunPod serverless worker (-> flux-worker).
#
# The ComfyUI worker the endpoint already ran (blib-la/runpod-worker-comfy 3.1.0, with
# FLUX.1 schnell, its text encoders and VAE baked in), plus two things for 360 images:
#
#   * the "360 Degree Flux - SCHNELL" LoRA by denrakeiw (civitai.com/models/682349, version
#     813766, trigger "360HDR seamless"). Its permissions allow selling images made with it
#     and running it as a generation service, with credit, but not re-hosting the file, so
#     it is not baked into this public image: start-flux.sh downloads it from Civitai when a
#     worker starts.
#   * spinagon/ComfyUI-seamless-tiling (GPL-3.0), for its "Circular VAE Decode": the decoder
#     treats the left and right edges as touching. FLUX's transformer has no conv layers for
#     the asymmetric-tiling trick to patch, so this smooths the join at decode time only.
#     Pinned to the last version that works with the older ComfyUI in the base image.
FROM timpietruskyblibla/runpod-worker-comfy:3.1.0-flux1-schnell

RUN git clone https://github.com/spinagon/ComfyUI-seamless-tiling.git /comfyui/custom_nodes/ComfyUI-seamless-tiling && \
    cd /comfyui/custom_nodes/ComfyUI-seamless-tiling && git checkout c907be28ab && rm -rf .git

COPY src/start-flux.sh /start-flux.sh
RUN chmod +x /start-flux.sh
CMD ["/start-flux.sh"]
