#!/usr/bin/env bash
# momovox-play-reply — click handler for momovox reply notifications.
# Stops any narration in progress, then narrates the saved answer file.
# Runs detached from the notification click; returns immediately.
set -uo pipefail

FILE="${1:-$HOME/.cache/momovox/hook-last.md}"
# Precedence mirrors the CLI: explicit arg > env > config file > default.
VOICE="${2:-${MOMOVOX_VOICE:-}}"
SPEED="${3:-${MOMOVOX_SPEED:-}}"
if [ -z "$VOICE" ] || [ -z "$SPEED" ]; then
  CFG_VOICE="$(python3 -c 'import json,os;print(json.load(open(os.path.expanduser("~/.config/momovox/config.json"))).get("voice",""))' 2>/dev/null)"
  CFG_SPEED="$(python3 -c 'import json,os;print(json.load(open(os.path.expanduser("~/.config/momovox/config.json"))).get("speed",""))' 2>/dev/null)"
  VOICE="${VOICE:-$CFG_VOICE}"
  SPEED="${SPEED:-$CFG_SPEED}"
fi
VOICE="${VOICE:-dalia}"
SPEED="${SPEED:-+0%}"
NARRATE="$(command -v momovox 2>/dev/null || echo "$HOME/.local/bin/momovox")"
LOG="$HOME/.cache/momovox/hook-play.log"

mkdir -p "$HOME/.cache/momovox"
[ -f "$FILE" ] || exit 0
OMACHY="$(command -v omarchy 2>/dev/null || echo /usr/share/omarchy/bin/omarchy)"
# Instant ack: synthesis takes ~1s per 45 chars, so confirm the click now.
"$OMACHY" notification send --app-name momovox "⏳ Preparando audio…" \
  "Convirtiendo tu respuesta a voz, sonará en segundos." >/dev/null 2>&1 || true
"$NARRATE" --stop >/dev/null 2>&1 || true
setsid "$NARRATE" --file "$FILE" --voice "$VOICE" --speed "$SPEED" >>"$LOG" 2>&1 < /dev/null &
