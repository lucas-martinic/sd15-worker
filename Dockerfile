# Stable Diffusion 1.5 or SDXL for the IMS Living Lab, as a RunPod serverless worker.
#
#   docker build --build-arg MODEL=sd15 .   SD 1.5 + LatentLabs360          -> sd15-worker
#   docker build --build-arg MODEL=sdxl .   SDXL base 1.0 + 360Redmond      -> sdxl-worker
#
# Everything is baked in: A1111, the checkpoint, the 360 LoRA and the asymmetric tiling
# extension ("Seamless edges" on the lab page; it patches the conv layers, so it works on
# both). No network volume, on purpose: a volume pins the endpoint to one data centre, and
# the old one (EU-SE-1) was closed by RunPod in Oct/Nov 2026, taking the previous setup
# (everything on volume fa477vsdos) with it.
#
# Licences: SD 1.5 CreativeML Open RAIL-M; SDXL base CreativeML Open RAIL++-M; LatentLabs360
# and 360Redmond (artificialguybr) BigScience OpenRAIL-M. All allow redistribution and
# commercial use of the output, with the RAIL use restrictions attached.

# ---------------------------------------------------------------- models
FROM alpine:3.20 AS download
ARG MODEL=sd15
RUN apk add --no-cache wget && mkdir -p /out/Lora && \
    if [ "$MODEL" = sdxl ]; then \
      wget -q -O /out/model.safetensors \
        https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors && \
      wget -q -O /out/Lora/360Redmond.safetensors \
        https://huggingface.co/artificialguybr/360Redmond/resolve/main/View360.safetensors; \
    else \
      wget -q -O /out/model.safetensors \
        https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors && \
      wget -q -O /out/Lora/LatentLabs360.safetensors \
        https://huggingface.co/AlanB/LatentLabs360/resolve/main/latentlabs360_v01.safetensors; \
    fi

# ---------------------------------------------------------------- A1111
FROM python:3.10.14-slim

ARG A1111_RELEASE=v1.10.1
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    TORCH_COMMAND="pip install torch==2.1.2 torchvision==0.16.2 --extra-index-url https://download.pytorch.org/whl/cu121" \
    STABLE_DIFFUSION_REPO=https://github.com/w-e-w/stablediffusion.git
# STABLE_DIFFUSION_REPO: Stability-AI/stablediffusion, which A1111 1.10 clones on setup,
# was taken down; this is the mirror the A1111 maintainers point to.

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && \
    apt-get install -y --no-install-recommends fonts-dejavu-core git wget procps \
      libgoogle-perftools-dev libtcmalloc-minimal4 libgl1 libglib2.0-0 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git && \
    cd stable-diffusion-webui && git reset --hard ${A1111_RELEASE} && \
    pip install -r requirements_versions.txt && \
    python -c "from launch import prepare_environment; prepare_environment()" --skip-torch-cuda-test && \
    git clone --depth 1 https://github.com/tjm35/asymmetric-tiling-sd-webui.git extensions/asymmetric-tiling-sd-webui && \
    python -c "from transformers import CLIPTokenizer, CLIPTextConfig; \
CLIPTokenizer.from_pretrained('openai/clip-vit-large-patch14'); CLIPTextConfig.from_pretrained('openai/clip-vit-large-patch14')"

COPY --from=download /out/model.safetensors /model.safetensors
COPY --from=download /out/Lora/ /stable-diffusion-webui/models/Lora/

RUN pip install runpod==1.7.* requests
COPY src/start.sh src/handler.py /
RUN chmod +x /start.sh
CMD ["/start.sh"]
