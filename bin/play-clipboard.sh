#!/usr/bin/env bash
# momovox helper: narrate the clipboard, detached (returns instantly).
# Args: [voice] [speed] — empty means "use saved default".
set -uo pipefail
MOMOVOX="$(command -v momovox 2>/dev/null || echo "$HOME/.local/bin/momovox")"
LOG="$HOME/.cache/momovox/widget.log"
mkdir -p "$HOME/.cache/momovox"
args=(--clipboard)
[ -n "${1:-}" ] && args+=(--voice "$1")
[ -n "${2:-}" ] && args+=(--speed "$2")
setsid "$MOMOVOX" "${args[@]}" >>"$LOG" 2>&1 < /dev/null &
