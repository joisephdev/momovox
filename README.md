# momovox 🎙

Hear long texts instead of reading them. Harness-agnostic neural
text-to-speech: plain CLI + Omarchy desktop integration. No agent harness
required (pi / Claude / Codex adapters live in sibling packages such as
`momovox-pi` and only shell out to this binary).

- **Engine:** Edge-TTS (free, online, no API key) · default voice
  `es-MX-DaliaNeural`, full ES+EN catalog (`momovox --list-voices`)
- **Streaming playback:** first audio in ~3s via pipelined sentence chunks
- **Click-to-listen:** Omarchy notifications with `--exec` run
  `momovox-play-reply` (stop-previous + narrate saved answer)
- **Hygiene:** cache retention (newest 20), rotating log, no secrets anywhere

## Install

```bash
git clone https://github.com/joisephdev/momovox.git && cd momovox && ./install.sh
# Try it:
momovox "hello, I can read your long texts aloud"
```

Requires: `uv`, `mpv`, `ffmpeg`, `wl-clipboard` (Wayland), internet.

## Usage

```bash
momovox "long text..."                  # direct
echo "..." | momovox                    # pipe (how agents feed it)
momovox answer.md                       # .md/.txt (markdown cleaned automatically)
momovox --clipboard                     # narrate your Ctrl+C
momovox --paste                         # paste manually, Ctrl+D to narrate
momovox answer.md -v ava --speed +15% -o summary.mp3
momovox --select-voice                  # interactive picker, saves your default
momovox --stop                          # stop playback (+ background workers)
momovox --version                       # semver gate for adapters (>=0.3.0)
```

Precedence: `--voice/--speed` flag > `MOMOVOX_VOICE`/`MOMOVOX_SPEED` env >
`~/.config/momovox/config.json` > default (dalia/+0%).

Audio goes to `~/.cache/momovox/` (`last.mp3` = latest; pruned to newest 20).

## For adapter authors

This binary is the whole API. Gate on `momovox --version >= 0.3.0`, share
`~/.config/momovox/config.json` + `~/.cache/momovox/`, never vendor synthesis.
See the contract in [../SPLIT_PLAN.md](../SPLIT_PLAN.md).

## Security (for marketplace review)

Outbound HTTPS only (Microsoft Edge TTS endpoint), no API keys, no inbound
ports, no credentials. Disk state: disposable mp3 cache + voice/speed prefs.
