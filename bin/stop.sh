#!/usr/bin/env bash
# momovox helper: stop any narration in progress.
set -uo pipefail
MOMOVOX="$(command -v momovox 2>/dev/null || echo "$HOME/.local/bin/momovox")"
exec "$MOMOVOX" --stop
