#!/usr/bin/env bash
# Fetch the 360HDR schnell LoRA (see Dockerfile.flux for why it is not in the image), then
# hand over to the base image's start script. If Civitai is down the worker still starts:
# plain FLUX keeps working and only requests that ask for the LoRA fail.
LORA=/comfyui/models/loras/360HDR_SCHNELL.safetensors
URL='https://civitai.com/api/download/models/813766?fileId=727360'
if [ ! -s "$LORA" ]; then
  mkdir -p "$(dirname "$LORA")"
  for i in 1 2 3; do
    if wget -q -O "$LORA.part" "$URL" && head -c 8 "$LORA.part" | od -An -tu8 | awk '$1 > 0 && $1 < 100000000 {ok=1} END {exit !ok}'; then
      mv "$LORA.part" "$LORA"; echo "start-flux: 360HDR LoRA ready ($(du -h "$LORA" | cut -f1))"; break
    fi
    echo "start-flux: LoRA download failed (try $i)"; rm -f "$LORA.part"; sleep 5
  done
fi
exec /start.sh
