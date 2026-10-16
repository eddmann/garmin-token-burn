[Back to Token Burn](../README.md)

# Development

## Layout

| Path | What it holds |
| --- | --- |
| `widget/` | The app: its `manifest.xml`, `monkey.jungle`, glance, pages, complication, alerts and strings |
| `face/` | The watch face, laid out the same way |
| `shared/` | Code and resources both apps compile in: storage, the background fetch, the gauges and burn status, settings and the icon |
| `prebuilt/` | The Forerunner 255 builds of both apps |
| `publisher/` | The snapshot script, its CodexBar fixtures and its tests |
| `data/usage.json` | The snapshot the app fetches by default; the committed one is the fixture output, and repo mode overwrites it |
| `scripts/` | SDK download and device file generation, used by `make deps` |
| `docker/` | A build image with the SDK baked in |

## Building

You need Java 11 or newer, curl, unzip, Python 3 and OpenSSL.

```sh
make deps
make build
```

`make deps` downloads the latest Connect IQ SDK for your OS into `.toolchain/sdk`, creates a signing key in `.keys/` and writes any Forerunner 255 device files that are missing.
`make build` writes `dist/TokenBurn-fr255.prg` and `dist/TokenBurnFace-fr255.prg`; set `DEVICE` for another model, or run `make build/all` for all four.
`make prebuilt` copies the Forerunner 255 builds into `prebuilt/`.

The compiler needs a folder of device files for each model, which normally come from Garmin's SDK Manager and need a Garmin login.
`scripts/gen-devices.py` writes them instead from the `devices.xml` that ships inside the SDK's own `monkeybrains.jar`.
They are enough to compile and sign, but not to run the simulator, which also needs the real fonts and bitmaps.
Files the SDK Manager has already installed are left alone.

| OS | Device files |
| --- | --- |
| macOS | `~/Library/Application Support/Garmin/ConnectIQ/Devices` |
| Linux | `~/.Garmin/ConnectIQ/Devices` |

To build with an SDK the SDK Manager installed, point `SDK_DIR` at it, for example `make build SDK_DIR="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/<sdk>"`.

`make build/docker` does the whole build in a container with the SDK and generated device files baked in, so only Docker is needed.

The project builds with `project.typecheck = 1`, Monkey C's gradual type checking, and the remaining warnings are untyped container accesses.

## The simulator

`make start` builds, opens the Connect IQ simulator and loads the app into it; `make start/face` loads the watch face instead.
It needs the real device files from the SDK Manager and a display.
In the simulator, the app fetches through your computer's network, so the snapshot URL has to be reachable from there, and the app settings editor under **File** can change the **Usage JSON URL** for a run.

## Conventions

The app draws everything with the `Dc` drawing calls and sizes it from the screen, so keep new screens the same way rather than adding layouts or bitmaps.
Keep the glance small: it shares a tight memory budget with the rest of the glance loop.
Publisher changes come with a fixture and an expected snapshot that `make test` checks.
