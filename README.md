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

## Uninstall

```bash
omarchy plugin disable joisephdev.momovox   # if enabled as widget
omarchy plugin remove joisephdev.momovox    # removes ~/.config/omarchy/plugins/joisephdev.momovox
rm -f ~/.local/bin/momovox ~/.local/bin/momovox-play-reply
rm -rf ~/.local/share/momovox/.venv        # deps (edge-tts)
rm -rf ~/.cache/momovox ~/.config/momovox  # audio cache + voice prefs (optional)
```

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

## Omarchy bar widget 🔊

This repo doubles as the Omarchy plugin (`manifest.json`, kind
`bar-widget`, id `joisephdev.momovox`). After `./install.sh`:

```bash
rsync -av --exclude='.git' --exclude='.venv' --exclude='__pycache__' \
  ./ ~/.config/omarchy/plugins/joisephdev.momovox/
omarchy plugin enable joisephdev.momovox right && omarchy restart shell
```

Bar shows **Vox** (▶ while speaking): left-click opens Play clipboard /
Stop / Replay last, right-click plays the clipboard instantly. Voice/speed
come from the plugin settings (empty = saved `momovox --select-voice`
default). State is polled via `momovox --status`.

## For adapter authors

This binary is the whole API. Gate on `momovox --version >= 0.3.0`, share
`~/.config/momovox/config.json` + `~/.cache/momovox/`, never vendor synthesis.
See the contract in [../SPLIT_PLAN.md](../SPLIT_PLAN.md).

## Security (for marketplace review)

Outbound HTTPS only (Microsoft Edge TTS endpoint), no API keys, no inbound
ports, no credentials. Disk state: disposable mp3 cache + voice/speed prefs.
