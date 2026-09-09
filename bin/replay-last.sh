#!/usr/bin/env bash
# momovox helper: replay the latest narration (last.mp3), detached.
set -uo pipefail
LAST="$HOME/.cache/momovox/last.mp3"
LOG="$HOME/.cache/momovox/widget.log"
[ -f "$LAST" ] || { echo "Nothing to replay yet." >&2; exit 1; }
mkdir -p "$HOME/.cache/momovox"
# --title=momovox keeps it visible to `momovox --status/--stop`.
setsid mpv --no-video --title=momovox "$LAST" >>"$LOG" 2>&1 < /dev/null &
