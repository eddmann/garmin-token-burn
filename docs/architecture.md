[Back to Token Burn](../README.md)

# Architecture

Token Burn is a pipeline with three hops: the publisher on your computer, a static JSON file on the web, and the app on the watch.

| Step | Where | What happens |
| --- | --- | --- |
| Snapshot | Your computer | `publish-usage.sh` runs CodexBar's `dashboard`, `usage` and `cost` commands and `snapshot.jq` reduces them to one entry per provider, applying `token-burn.json` |
| Publish | GitHub | The snapshot is pushed to `data/usage.json` in this repository or to a gist, and served over HTTPS |
| Fetch | Phone, then watch | Every five minutes a background event on the watch asks the Garmin Connect app to fetch the URL over Bluetooth |
| Draw | Watch | The glance, the pages and the face read the stored snapshot |

## On the watch

| File | Role |
| --- | --- |
| `widget/source/TokenBurnApp.mc`, `face/source/TokenBurnFaceApp.mc` | Register the five-minute background event and redraw when it returns |
| `shared/source/TokenBurnServiceDelegate.mc` | The background service that makes the web request and stores the snapshot |
| `widget/source/UsageEvents.mc` | Publishes the complication and posts the alert notification after each fetch; the face's copy does nothing |
| `shared/source/UsageStore.mc` | Storage, the snapshot URL, the face pair, each provider's headline window, and the number formatting |
| `shared/source/UsageRing.mc` | The gauges and bars, pace ticks, zone and provider colours, and the flame |
| `widget/source/TokenBurnGlanceView.mc` | The glance: two lines and a usage bar per tool |
| `widget/source/TokenBurnView.mc`, `TokenBurnDelegate.mc` | The overview, a page per provider, the burn pages, and the buttons that move between them |
| `face/source/TokenBurnFaceView.mc` | The watch face |

The app is declared as a `watch-app`: the Forerunner 255 has no separate widget type, runs apps with a glance in the glance list, and only lets that type publish complications and post notifications.
The app and the face are separate Connect IQ apps, each with its own storage and its own background fetch, built from `shared/` plus their own folder through `monkey.jungle`.

Five minutes is the shortest interval Connect IQ allows for a background event.
The background service saves a successful fetch itself, so the glance and the face have it even when the app is not running; it is kept in `Application.Storage` under `usage`, with the time it arrived under `fetchedAt`; the footer's age and the stale warning come from `fetchedAt`, not from the snapshot's own `updated` time.
Opening the full app also fetches in the foreground when the stored snapshot is older than five minutes.

The watch knows nothing about particular providers: everything it draws comes from the snapshot's list of providers and windows, and the headline is worked out on the watch as the window with the highest share used.
Burn status and load are worked out on the watch too, in `UsageRing.burnStatus` and `UsageStore.loadRatio`, from the windows, `week_tokens` and `last30_tokens`; the publisher adds only `pr`, `streak` and yesterday's burn, which need the daily history.
The pages follow the number of providers, up to three, and the burn pages leave out providers with no token logs.

The glance runs under a tight memory limit, which is why it only reads a few numbers from storage and draws two lines of text and two bars.
`UsageStore` is annotated for the background and glance contexts so the same helpers are available to all three.
