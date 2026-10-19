# RunPod official ComfyUI template: Qwen Image 2.1 Turbo

Use RunPod's official **ComfyUI - CUDA 12.8** (4090/L40/etc.) or **ComfyUI - CUDA 13** (RTX 5090) GPU Pod template. It launches ComfyUI automatically on port 8188. The install lives at `/workspace/runpod-slim/ComfyUI`. Use a persistent `/workspace` volume with enough space for model downloads and working files (50 GB minimum is sensible; more if using other models).

## Install (first boot)

After the official pod has finished initializing, put `install.sh` and `qwenImage21TurboGenerate_v12.json` together in `/workspace/qwen21-deploy/`. Via RunPod's web terminal or Jupyter terminal, run:

```bash
bash /workspace/qwen21-deploy/install.sh
```

Then **restart the pod once** so its already-running ComfyUI process picks up the newly installed custom nodes. Do not change the official template's start command to `python main.py` or to the installer. On future boots, the official template will automatically start ComfyUI and all files will remain on persistent storage. No need to rerun the installer unless you rebuild your `/workspace` volume.

## GitHub-based initial installation

Push `install.sh` and the workflow JSON into your GitHub repository. On a **public** GitHub repo, after the pod has initialized, use:

```bash
mkdir -p /workspace/qwen21-deploy
curl -fL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install.sh -o /workspace/qwen21-deploy/install.sh
curl -fL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/qwenImage21TurboGenerate_v12.json -o /workspace/qwen21-deploy/qwenImage21TurboGenerate_v12.json
bash /workspace/qwen21-deploy/install.sh
```

For a private repo, the above raw links won't work without authentication. Clone with a properly scoped credential or transfer the two files into the pod. Never hardcode tokens in GitHub.

## Optional environment variables

- `ARCHER2_URL`: Direct authorized download URL for `ARCHER2.safetensors` (will save to `models/loras/Qwen21/`).
- `LENOVO_QWEN21_URL`: Direct authorized download URL for `lenovo_qwen21.safetensors`.
- `HF_TOKEN`: Only necessary for restricted Hugging Face downloads.
- `PYTHON_OVERRIDE`: If the official image uses a different virtual environment, set the path to its `python` executable.
- `WORKFLOW_URL`: Raw JSON URL if `qwenImage21TurboGenerate_v12.json` is not alongside the installer.

The uploaded workflow references `WhitneyUpscaler.png`, an input reference image not embedded in the JSON, so supply it inside ComfyUI. Missing custom LoRAs will trigger an error in the workflow because the loader is set to fail if LoRAs are absent.

You can access LoRA Manager at `<your-ComfyUI-URL>/loras` after restarting. Its CivitAI features may require a CivitAI API key set in its UI.

**Note:** This deliberately does not promise that setup occurs before the official template's *first* ComfyUI start. The official template autostarts its own server. Installing after initial boot followed by one restart is the supported non-invasive method; integrating true pre-start installation would require a template-specific startup hook or a custom image. This package has been syntax checked, not live-tested on a RunPod pod.
