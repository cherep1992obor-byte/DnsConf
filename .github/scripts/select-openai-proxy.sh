#!/usr/bin/env bash
set -euo pipefail

config_path="${1:-config/openai.hosts}"

# The first three addresses are advertised by dns.mafioznik.xyz and Comss DNS.
# The remaining addresses are GeoHide fallbacks from different regions.
candidates=(
  103.137.248.145
  95.81.98.64
  89.150.59.128
  143.20.64.192
  31.25.239.132
  107.175.76.134
  192.3.233.253
)

request_code() {
  local ip="$1"
  local host="$2"
  local path="$3"
  local method="$4"

  curl --silent --show-error --insecure \
    --connect-timeout 4 --max-time 12 \
    --resolve "${host}:443:${ip}" \
    --request "$method" \
    --output /dev/null --write-out '%{http_code}' \
    "https://${host}${path}" 2>/dev/null || true
}

is_healthy() {
  local ip="$1"
  local codex tasks flags cloud static websocket

  codex="$(request_code "$ip" chatgpt.com /backend-api/codex/responses POST)"
  tasks="$(request_code "$ip" chatgpt.com '/backend-api/wham/tasks/list?limit=1&task_filter=current' GET)"
  flags="$(request_code "$ip" ab.chatgpt.com /v1 GET)"
  cloud="$(request_code "$ip" codex-cloud-backend.chatgpt.com / GET)"
  static="$(request_code "$ip" persistent.oaistatic.com / GET)"
  websocket="$(request_code "$ip" ws.chatgpt.com / GET)"

  [[ "$codex" == 401 ]] &&
    [[ "$tasks" == 401 ]] &&
    [[ "$flags" == 401 || "$flags" == 403 ]] &&
    [[ "$cloud" == 401 || "$cloud" == 403 ]] &&
    [[ "$static" == 403 || "$static" == 404 ]] &&
    [[ "$websocket" == 400 || "$websocket" == 401 || "$websocket" == 403 || "$websocket" == 404 ]]
}

selected_ip=""
for candidate in "${candidates[@]}"; do
  echo "Checking OpenAI proxy ${candidate}..."
  if is_healthy "$candidate"; then
    selected_ip="$candidate"
    break
  fi
done

if [[ -z "$selected_ip" ]]; then
  echo "No OpenAI proxy passed all health checks." >&2
  exit 1
fi

temporary_path="${config_path}.tmp"
awk -v ip="$selected_ip" '
  /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]/ {
    sub(/^[^[:space:]]+/, ip)
  }
  { print }
' "$config_path" > "$temporary_path"
mv "$temporary_path" "$config_path"

echo "Selected OpenAI proxy: ${selected_ip}"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "selected_ip=${selected_ip}" >> "$GITHUB_OUTPUT"
fi
