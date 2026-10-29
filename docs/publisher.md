[Back to Token Burn](../README.md)

# Publisher

`publisher/publish-usage.sh` takes a snapshot of your plan usage with the [CodexBar](https://github.com/steipete/CodexBar) CLI and publishes a compact `data/usage.json` for the app and the face to fetch.
The reduction itself lives in `publisher/snapshot.jq`.

## Prerequisites

```sh
brew install --cask steipete/tap/codexbar
brew install jq
```

Token Burn needs CodexBar 0.76 or later, for `codexbar dashboard`.
CodexBar reads the sign-ins your tools already keep, such as `~/.claude` and `~/.codex`, or a browser session for web dashboards, so there is nothing else to log in to.
Switch on the providers you want in CodexBar's settings, or with `codexbar config enable --provider <id>`, then check what it sees:

```sh
codexbar dashboard --identity redacted --pretty
```

## What it reads

| Command | What it gives the snapshot |
| --- | --- |
| `codexbar dashboard --identity redacted` | The enabled providers in CodexBar's order, with each one's name, plan, accent colour, credits, status, error and windows |
| `codexbar usage --format json` | Each window's length in minutes, so the watch can draw where an even pace would be |
| `codexbar cost --format json` | Today's and the last 30 days' tokens and API price, and the last seven days, for the providers with local logs |

A provider that CodexBar cannot read stays in the snapshot with its error, rather than breaking it.

## Configuration

`publisher/token-burn.json` is optional; without it the watch shows the first three providers CodexBar has switched on, in CodexBar's order.

```json
{
  "alertPct": 90,
  "show": ["claude", "codex", "cursor"],
  "face": ["claude", "codex"],
  "providers": {
    "claude": {"short": "CC", "hide": ["claude-weekly-scoped-fable"]},
    "codex": {"short": "CX"},
    "cursor": {"name": "Cursor", "short": "CU", "color": "#8C6CF0"}
  }
}
```

| Key | Meaning |
| --- | --- |
| `alertPct` | The share of any window at which a provider's alert flag is set (90 by default); `ALERT_PCT` in the environment overrides it |
| `show` | Provider ids to show, in order, at most three; CodexBar's enabled providers when left out |
| `face` | The two providers the face, the glance and the complication show; the first two shown when left out |
| `providers.<id>.name` | The name on the app's pages; CodexBar's display name by default |
| `providers.<id>.short` | The short label on the face, glance and complication; `CC` and `CX` for Claude and Codex, otherwise the name's first two letters |
| `providers.<id>.color` | An identity colour as `#RRGGBB`; CodexBar's accent colour by default |
| `providers.<id>.hide` | Window kinds to leave out, as `dashboard` names them |

Provider ids and window kinds are the ones `codexbar dashboard` prints.
Colours are snapped to the nearest of the few vivid colours the Forerunner 255's 64-colour screen shows well; green, yellow and red are kept for the usage zones.

## The snapshot

```json
{
  "version": 2,
  "updated": 1785412800,
  "face": [0, 1],
  "providers": [
    {
      "id": "claude",
      "name": "Claude",
      "short": "CC",
      "color": 16733440,
      "plan": "Max 20x",
      "windows": [
        {"label": "Session", "pct": 62, "resets_min": 269, "pace_pct": 10},
        {"label": "Weekly", "pct": 41, "resets_min": 3599, "pace_pct": 64}
      ],
      "credits": null,
      "status": null,
      "error": null,
      "today_tokens": 4200000,
      "today_cost_usd": 38.2,
      "yesterday_tokens": 3030000,
      "yesterday_cost_usd": 27.8,
      "last30_tokens": 96500000,
      "last30_cost_usd": 823.1,
      "week_tokens": [0, 0, 0, 0, 0, 3030000, 4200000],
      "alert": false,
      "pr": true,
      "streak": 2
    }
  ]
}
```

| Field | Meaning |
| --- | --- |
| `version` | 2, the snapshot format |
| `updated` | When the snapshot was taken, in Unix seconds |
| `face` | Indexes into `providers` of the two the face, glance and complication show |
| `color` | The identity colour as a 24-bit RGB number |
| `plan`, `credits` | The plan name and any credit balance, such as `62.5K credits`, or `null` |
| `windows` | Every window CodexBar reports, in its order: the label, the share used, minutes until it resets, and the share of the window already elapsed, which is where an even pace would be (`null` when its length is unknown) |
| `status`, `error` | A service incident or why CodexBar could not read the provider, each `null` when there is none; errors are cut to 40 characters |
| `today_tokens`, `today_cost_usd` | Today's tokens (UTC day) and their API price, from the local logs; on a subscription plan the cost is notional |
| `yesterday_tokens`, `yesterday_cost_usd` | The same for yesterday, for the Morning Report: 0 for a provider with logs but no usage, `null` for one without logs |
| `last30_tokens`, `last30_cost_usd` | Tokens and API price over the last 30 days |
| `week_tokens` | Tokens for each of the last seven UTC days, oldest first and today last, with 0 for a day with no usage |
| `alert` | `true` when any window is at or above the alert threshold |
| `pr` | `true` when today's tokens beat every one of the 29 days before, with at least one of them above 0 |
| `streak` | Days in a row with tokens, ending today, or yesterday if there are none yet today |

Three providers come to about 2 KB, well inside the roughly 8 KB a Connect IQ background fetch can hand to the app.

## Publish modes

| `PUBLISH_MODE` | What happens |
| --- | --- |
| `gist` (default) | Updates a gist, which works for a secret gist too; needs `GIST_ID` and a `GITHUB_TOKEN` with the `gist` scope |
| `repo` | Commits `data/usage.json` and pushes `main`; the watch fetches it from `raw.githubusercontent.com`, which works only while the repository is public |
| `none` | Only writes the file, as `--no-publish` does |

Use repo mode only from your own fork, since it commits to whichever repository you run it in.
For gist mode, point the app at `https://gist.githubusercontent.com/<user>/<gist-id>/raw/usage.json`; leaving out the revision always serves the latest.
The other settings, such as `CONFIG`, `REPO_DIR`, `DATA_FILE`, `BRANCH` and `GIST_FILENAME`, are listed at the top of the script.

## Running it

`make publish` runs the script once with whatever is set in the environment; run it whenever you want the watch to catch up.
To keep the watch current without thinking about it, run it every five minutes, the watch's fetch interval, from cron or a `launchd` agent with `StartInterval` set to 300.

## Trying it without CodexBar

```sh
publisher/publish-usage.sh \
  --dashboard-file publisher/fixtures/dashboard.sample.json \
  --usage-file publisher/fixtures/usage.sample.json \
  --cost-file publisher/fixtures/cost.sample.json \
  --no-publish --out /tmp/usage.json
```

The fixtures describe Claude, Codex, Cursor and a signed-out Gemini, and `data/usage.json` in this repository is the snapshot they make.
