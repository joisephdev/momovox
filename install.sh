#!/usr/bin/env bash
# momovox core installer: venv + deps + symlinks. Harness-agnostic (no pi here).
# Agent adapters live in sibling package momovox-pi.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== momovox: installing =="

if ! command -v uv >/dev/null 2>&1; then
  echo "❌ Missing 'uv'. Install it: curl -LsSf astral.sh/uv/install.sh | sh"
  exit 1
fi

cd "$ROOT"
uv sync --quiet
echo "✅ deps (edge-tts) installed in .venv"

chmod +x bin/momovox hooks/play-reply.sh
mkdir -p "$HOME/.local/bin"
ln -sf "$ROOT/bin/momovox" "$HOME/.local/bin/momovox"
echo "✅ symlink: ~/.local/bin/momovox -> $ROOT/bin/momovox"
ln -sf "$ROOT/hooks/play-reply.sh" "$HOME/.local/bin/momovox-play-reply"
echo "✅ symlink: ~/.local/bin/momovox-play-reply (notification click handler)"

for dep in mpv ffmpeg wl-paste; do
  command -v "$dep" >/dev/null 2>&1 && echo "✅ $dep ok" || echo "⚠️  missing $dep (sudo pacman -S ${dep/wl-paste/wl-clipboard})"
done

# Agent harness adapters (pi skill/extension, …) live in momovox-pi
# and are installed from that package, never from here.

# Legacy cleanup (previous names: lee, narrate, omarchutter-pi)
rm -f "$HOME/.local/bin/lee" "$HOME/.local/bin/narrate" "$HOME/.local/bin/narrator-play-reply"
for legacy in lee narrate; do
  if [ -L "$HOME/.agents/skills/$legacy" ] || [ -d "$HOME/.agents/skills/$legacy" ]; then
    rm -rf "$HOME/.agents/skills/$legacy"
    echo "🧹 legacy ~/.agents/skills/$legacy removed"
  fi
done
if [ -L "$HOME/.pi/agent/extensions/narrator" ]; then
  rm -f "$HOME/.pi/agent/extensions/narrator"
  echo "🧹 legacy ~/.pi/agent/extensions/narrator removed"
fi
# NOTE: omarchutter-pi links/extension are left intact on purpose: that install
# keeps working until Phase 2 moves the adapter to momovox-pi.

echo ""
echo "Try:  momovox \"hello, I'm Dalia and I can read your giant tasks aloud\""
echo "      momovox --clipboard --voice jorge --speed +15%"
echo "      momovox --stop"
echo ""
echo "== Voice catalog (Spanish + English) =="
"$ROOT/bin/momovox" --list-voices
echo ""
echo "Change the default voice per run with -v/--voice, or per session with:"
echo "  MOMOVOX_VOICE=ava momovox \"hello in English\""
