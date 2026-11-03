# Lab image workers

The image models of the Inter(mediate) Spaces Living Lab, as RunPod serverless workers. No
network volumes, so each endpoint can run in any data centre with stock. GitHub Actions
builds all three on every push to main, tagged with the commit:

| Image | What is in it | Lab "Seamless edges" | Lab "360 LoRA" |
|---|---|---|---|
| `ghcr.io/lucas-martinic/sd15-worker` | A1111 1.10.1, SD 1.5 (`v1-5-pruned-emaonly`) | [asymmetric tiling](https://github.com/tjm35/asymmetric-tiling-sd-webui), X only | [LatentLabs360](https://huggingface.co/AlanB/LatentLabs360), `<lora:LatentLabs360:1>` |
| `ghcr.io/lucas-martinic/sdxl-worker` | A1111 1.10.1, SDXL base 1.0 | the same extension | [360Redmond](https://huggingface.co/artificialguybr/360Redmond), `<lora:360Redmond:1>`, prompt "360 view" |
| `ghcr.io/lucas-martinic/flux-worker` | ComfyUI ([runpod-worker-comfy](https://github.com/blib-la/runpod-worker-comfy) 3.1.0) with FLUX.1 schnell | `CircularVAEDecode` from [ComfyUI-seamless-tiling](https://github.com/spinagon/ComfyUI-seamless-tiling): smooths the join at decode only | [360 Degree Flux - SCHNELL](https://civitai.com/models/682349) by denrakeiw, `360HDR_SCHNELL.safetensors`, trigger "360HDR seamless"; downloaded from Civitai at worker start, not re-hosted |

The two A1111 images share `Dockerfile` (`--build-arg MODEL=sd15|sdxl`) and take:

```json
{"input": {"api": {"method": "POST", "endpoint": "/sdapi/v1/txt2img"}, "payload": {"prompt": "..."}}}
```

Output: A1111's JSON (`images` are base64 PNGs). The FLUX image (`Dockerfile.flux`) takes a
ComfyUI workflow, `{"input": {"workflow": {...}}}`, as the base worker documents.
