#!/usr/bin/env bash
# A1111 as a local API on port 3000, then the RunPod handler that forwards to it.
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"
python /stable-diffusion-webui/webui.py \
  --skip-python-version-check --skip-torch-cuda-test --skip-install --skip-version-check \
  --ckpt /model.safetensors --no-half-vae --opt-sdp-attention --disable-safe-unpickle \
  --no-hashing --no-download-sd-model --api --nowebui --port 3000 &
exec python -u /handler.py
