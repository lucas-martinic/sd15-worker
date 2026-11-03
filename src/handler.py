"""RunPod handler: forwards {"api": {"method", "endpoint"}, "payload"} to the local A1111 API.

The same input shape as the worker it replaced (weihzh/runpod-worker-a1111). Used by both
images: sd15-worker (lab page MODELS.sd15) and sdxl-worker (MODELS.sdxl, since 3 Nov 2026).
Only /sdapi/v1/ endpoints are forwarded.
"""
import time

import requests
import runpod

API = 'http://127.0.0.1:3000'


def wait_for_a1111():
    for _ in range(900):
        try:
            if requests.get(API + '/sdapi/v1/sd-models', timeout=5).ok:
                return
        except requests.RequestException:
            pass
        time.sleep(1)
    raise RuntimeError('A1111 did not start within 15 minutes')


def handler(job):
    inp = job.get('input') or {}
    api = inp.get('api') or {}
    method = str(api.get('method') or 'POST').upper()
    endpoint = str(api.get('endpoint') or '/sdapi/v1/txt2img')
    if not endpoint.startswith('/sdapi/v1/') or method not in ('GET', 'POST'):
        return {'error': f'not allowed: {method} {endpoint}'}
    payload = inp.get('payload') or {}
    r = requests.request(method, API + endpoint, json=None if method == 'GET' else payload, timeout=900)
    try:
        out = r.json()
    except ValueError:
        return {'error': f'A1111 answered {r.status_code}', 'body': r.text[:500]}
    if not r.ok:
        return {'error': f'A1111 answered {r.status_code}', 'detail': out}
    return out


wait_for_a1111()
runpod.serverless.start({'handler': handler})
