# Token Burn 🔥

**Feel the Token Burn.**

Your watch already knows when you have overdone it on the bike; now it knows when you have overdone it in Claude Code or Codex.
Plan limits drain like Body Battery, a reset is recovery time, and three back-to-back refactors before lunch earn you an **Overreaching** warning.
Beat your biggest day and it buzzes with a personal record, priced in dollars burned like calories.
Take a week off and it will tell you, gently, that you are **Detraining**.

It is [CodexBar](https://github.com/steipete/CodexBar) on a Garmin Forerunner 255, because why not...

> **Unofficial project.** Token Burn is not affiliated with or endorsed by CodexBar, Garmin, Anthropic, OpenAI or any other provider it shows.

https://github.com/user-attachments/assets/c0b03696-7d5f-4480-aae0-6bd983dadb8b

<p align="center">
  <img src="docs/media/screenshots/face.png" width="180" alt="Token Burn Face: the time with the date above and a flame at 12, framed by thin Claude and Codex gauges, with CC 92% in red and CX 64% below" />
  <img src="docs/media/screenshots/morning.png" width="180" alt="The Morning Report: yesterday Claude burned 2.4B tokens and $860, Overreaching with 8% left, and Codex 520M and $105, Maintaining with 36% left" />
  <img src="docs/media/screenshots/claude.png" width="180" alt="The Claude page: Overreaching, Max 20x, with Session at 92% and 1h 45m to recover, Weekly at 71% and Fable only at 30%, each with a pace tick" />
  <img src="docs/media/screenshots/history.png" width="180" alt="Burn History: Claude 42.8B tokens and $15300 over 30 days, Codex 9.6B and $1920, seven daily bars climbing to a PR, and Load High with a 47-day streak" />
</p>
<p align="center"><em>Claude is Overreaching again. Codex is Maintaining, for now.</em></p>

## How it's built

A script on your computer boils CodexBar's snapshot down to a small JSON file with [jq](https://jqlang.org/) and publishes it to a gist.
A [Connect IQ](https://developer.garmin.com/connect-iq/) app and watch face sync it through your phone every five minutes, like any other activity.

**Install: copy [`prebuilt/TokenBurn.prg`](prebuilt/TokenBurn.prg) and [`prebuilt/TokenBurnFace.prg`](prebuilt/TokenBurnFace.prg) to the watch's `GARMIN/APPS/` folder to see the demo; to see your own usage, publish to a gist and point the apps at it, as [Installing](docs/installing.md) explains.**

## Run locally

You need Java 11 or newer, curl, unzip, Python 3, OpenSSL, jq and ShellCheck.

```sh
make deps
make can-release
```

## Documentation

| Guide | What you'll find |
| --- | --- |
| [Using](docs/using.md) | The owner's manual: burn status, recovery time, personal records and alerts |
| [Installing](docs/installing.md) | Sideloading and pointing the watch at your snapshot |
| [Publisher](docs/publisher.md) | CodexBar, the config file and the snapshot format |
| [More guides](docs/README.md) | Providers, architecture, development, testing and screenshots |

## Credits and licence

Plan usage comes from [CodexBar](https://github.com/steipete/CodexBar) by Peter Steinberger.
Token Burn is released under the [MIT licence](LICENSE).
Film assets retain the licences and credits listed in [video/CREDITS.md](video/CREDITS.md).
It is not affiliated with or endorsed by CodexBar, Garmin or any provider it shows.
