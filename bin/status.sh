#!/usr/bin/env bash
# momovox helper: print playing|idle (polled by the bar widget).
set -uo pipefail
MOMOVOX="$(command -v momovox 2>/dev/null || echo "$HOME/.local/bin/momovox")"
exec "$MOMOVOX" --status
