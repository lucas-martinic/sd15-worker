# sd15-worker

Stable Diffusion 1.5 for the Inter(mediate) Spaces Living Lab, as a RunPod serverless worker.
A1111 1.10.1, the SD 1.5 checkpoint (`v1-5-pruned-emaonly`), the
[LatentLabs360](https://huggingface.co/AlanB/LatentLabs360) LoRA (`<lora:LatentLabs360:1>`) and
the [asymmetric tiling](https://github.com/tjm35/asymmetric-tiling-sd-webui) extension, all baked
into the image. No network volume, so the endpoint can run in any data centre with stock.

Input, same shape as the worker it replaced:

```json
{"input": {"api": {"method": "POST", "endpoint": "/sdapi/v1/txt2img"}, "payload": {"prompt": "..."}}}
```

Output: A1111's JSON (`images` are base64 PNGs).

GitHub Actions builds `ghcr.io/lucas-martinic/sd15-worker:<commit>` on every push to main.
