[Back to Token Burn](../README.md)

# Testing

`make can-release` runs every check CI runs, in this order.

| Check | Command | What it covers |
| --- | --- | --- |
| Lint | `make lint` | ShellCheck over the publisher, its tests and the SDK script |
| Publisher | `make test` | The snapshot built from the CodexBar fixtures, compared field by field with `publisher/fixtures/usage.expected.json`; today's personal record, the burn streak and yesterday's burn; `ALERT_PCT` raising the alert flag; and `fixtures/config.sample.json` choosing, ordering, relabelling and hiding, with a failing provider's error kept |
| Build | `make build/all` | The app and the watch face compiling, type-checking and signing for all four Forerunner 255 models |

The publisher test pins the clock to 2026-07-30 12:00 UTC with `NOW`, so the reset countdowns and today's totals come out the same every run.
After changing the transform on purpose, regenerate the expected snapshot with the same `NOW` and no config, check the diff, and copy it to `data/usage.json`, the snapshot the app fetches by default.

CI runs `make deps can-release` on Ubuntu for every push to `main` and every pull request, using the generated device files.
There are no automated tests on the watch itself; changes are checked by eye in the simulator with `make start` and `make start/face`.
