#!/usr/bin/env bash
set -Eeuo pipefail
# Installer for RunPod OFFICIAL ComfyUI pod template.
# Does not install, launch, stop or modify the template's ComfyUI process.
COMFY_DIR="${COMFY_DIR:-/workspace/runpod-slim/ComfyUI}"
HF_TOKEN="${HF_TOKEN:-}"
ARCHER2_URL="${ARCHER2_URL:-}"
LENOVO_QWEN21_URL="${LENOVO_QWEN21_URL:-}"
WORKFLOW_URL="${WORKFLOW_URL:-}"
log(){ printf '[qwen21] %s\n' "$*"; }
[[ -f "$COMFY_DIR/main.py" ]] || { log "ComfyUI not ready at $COMFY_DIR. Wait for the official template to finish initialization."; exit 1; }
CUSTOM="$COMFY_DIR/custom_nodes"; MODELS="$COMFY_DIR/models"
mkdir -p "$CUSTOM" "$MODELS/diffusion_models" "$MODELS/text_encoders" "$MODELS/vae" "$MODELS/loras/Qwen21" "$COMFY_DIR/user/default/workflows"
if [[ -x /workspace/runpod-slim/venv/bin/python ]]; then
  PYTHON="/workspace/runpod-slim/venv/bin/python"
elif [[ -x "$COMFY_DIR/venv/bin/python" ]]; then
  PYTHON="$COMFY_DIR/venv/bin/python"
else
  # Determine the running ComfyUI interpreter if possible; never silently install into the wrong environment.
  PID="$(pgrep -f '[p]ython.*main.py.*8188' | head -1 || true)"
  if [[ -n "$PID" && -x "/proc/$PID/exe" ]]; then PYTHON="$(readlink -f "/proc/$PID/exe")"; else
    log 'Could not identify ComfyUI virtualenv. Specify PYTHON=/absolute/path/to/venv/bin/python'; exit 1
  fi
fi
PYTHON="${PYTHON_OVERRIDE:-$PYTHON}"
log "Python executable: $PYTHON"
install_node(){
  local repo="$1" name="$2" dest="$CUSTOM/$2"
  if [[ ! -f "$dest/__init__.py" ]]; then
    if [[ -e "$dest" ]]; then log "Existing incomplete directory at $dest. Resolve it before retrying."; exit 1; fi
    log "Cloning $name"
    git clone --depth 1 "$repo" "$dest"
  else log "Already installed: $name"; fi
  if [[ -f "$dest/requirements.txt" ]]; then "$PYTHON" -m pip install -r "$dest/requirements.txt"; fi
}
install_node https://github.com/ausboss/ComfyUI-AusBoss.git ComfyUI-AusBoss
install_node https://github.com/willmiao/ComfyUI-Lora-Manager.git ComfyUI-Lora-Manager
fetch(){
  local url="$1" dest="$2" tmp="${2}.partial"
  if [[ -s "$dest" ]]; then log "Already downloaded: $(basename "$dest")"; return; fi
  mkdir -p "$(dirname "$dest")"
  local args=(--fail --location --retry 8 --retry-delay 5 --connect-timeout 30 --continue-at -)
  if [[ -n "$HF_TOKEN" && "$url" == *huggingface.co* ]]; then args+=(--header "Authorization: Bearer $HF_TOKEN"); fi
  log "Downloading $(basename "$dest")"
  curl "${args[@]}" --output "$tmp" "$url"
  [[ -s "$tmp" ]] || { log "Empty download: $url"; exit 1; }
  mv -f "$tmp" "$dest"
}
BASE=https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main
fetch "$BASE/diffusion_models/qwen_image_2.1_turbo_int8_convrot.safetensors" "$MODELS/diffusion_models/qwen_image_2.1_turbo_int8_convrot.safetensors"
fetch "$BASE/text_encoders/qwen3vl_8b_int8_convrot.safetensors" "$MODELS/text_encoders/qwen3vl_8b_int8_convrot.safetensors"
fetch "$BASE/vae/qwen_image_2.1_vae_bf16.safetensors" "$MODELS/vae/qwen_image_2.1_vae_bf16.safetensors"
fetch https://huggingface.co/ausboss/Qwen-Image-2.1-Consistency-LoRA/resolve/main/qwen-image-2.1-consistency.safetensors "$MODELS/loras/qwen-image-2.1-consistency.safetensors"
fetch https://huggingface.co/ausboss/Qwen-Image-2.1-Restore-LoRA/resolve/main/qwen-image-2.1-restore.safetensors "$MODELS/loras/qwen-image-2.1-restore.safetensors"
if [[ -n "$ARCHER2_URL" ]]; then fetch "$ARCHER2_URL" "$MODELS/loras/Qwen21/ARCHER2.safetensors"; else log 'ARCHER2_URL not set; custom ARCHER2 LoRA must be supplied separately'; fi
if [[ -n "$LENOVO_QWEN21_URL" ]]; then fetch "$LENOVO_QWEN21_URL" "$MODELS/loras/Qwen21/lenovo_qwen21.safetensors"; else log 'LENOVO_QWEN21_URL not set; custom lenovo_qwen21 LoRA must be supplied separately'; fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$COMFY_DIR/user/default/workflows/qwenImage21TurboGenerate_v12.json"
if [[ -f "$SCRIPT_DIR/qwenImage21TurboGenerate_v12.json" ]]; then cp "$SCRIPT_DIR/qwenImage21TurboGenerate_v12.json" "$DEST"; log 'Copied workflow JSON';
elif [[ -n "$WORKFLOW_URL" ]]; then fetch "$WORKFLOW_URL" "$DEST";
else log 'Workflow JSON not found alongside installer; copy/import it manually or set WORKFLOW_URL'; fi
log 'Setup complete. Official ComfyUI already running? Restart the POD once to register newly installed custom nodes. Do not run a second server.'
