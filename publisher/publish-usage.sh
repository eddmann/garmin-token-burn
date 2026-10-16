#!/usr/bin/env bash
#
# publish-usage.sh: snapshot plan usage for up to three providers via the
# CodexBar CLI (https://github.com/steipete/CodexBar) and publish a compact
# JSON file for the Garmin "Token Burn" app and watch face to poll.
#
# CodexBar's dashboard snapshot gives the providers, in CodexBar's order, and
# their windows; `usage` adds each window's length, for the pace tick, and
# `cost` adds tokens and the last seven days. publisher/token-burn.json, when
# present, picks and relabels providers (see docs/publisher.md).
#
# Requires: codexbar 0.76 or later, jq. Repo mode also needs git; gist mode
# needs curl.
#
# Usage:
#   ./publish-usage.sh                     # snapshot + publish (repo mode)
#   PUBLISH_MODE=gist GIST_ID=... GITHUB_TOKEN=... ./publish-usage.sh
#   ./publish-usage.sh --dashboard-file f.json --usage-file f.json --cost-file f.json \
#     --config f.json --no-publish --out /tmp/out.json
#
# Configuration (environment variables):
#   CODEXBAR_BIN   codexbar binary (default: codexbar)
#   CONFIG         provider config (default: token-burn.json next to this script, if present)
#   ALERT_PCT      usedPercent threshold that sets alert=true (default: the config's alertPct, else 90)
#   PUBLISH_MODE   repo | gist | none (default: repo)
#   REPO_DIR       git repo to commit into (default: this script's parent dir)
#   DATA_FILE      path of the JSON within the repo (default: data/usage.json)
#   BRANCH         branch to push (default: main)
#   GIST_ID        gist to update (gist mode)
#   GIST_FILENAME  filename within the gist (default: usage.json)
#   GITHUB_TOKEN   token with gist scope (gist mode)
#   NOW            Unix time to snapshot at (default: the current time; set by the tests)
set -euo pipefail

CODEXBAR_BIN="${CODEXBAR_BIN:-codexbar}"
CONFIG="${CONFIG:-$(dirname "$0")/token-burn.json}"
ALERT_PCT="${ALERT_PCT:-}"
PUBLISH_MODE="${PUBLISH_MODE:-repo}"
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
DATA_FILE="${DATA_FILE:-data/usage.json}"
BRANCH="${BRANCH:-main}"
GIST_ID="${GIST_ID:-}"
GIST_FILENAME="${GIST_FILENAME:-usage.json}"
NOW="${NOW:-$(date +%s)}"

dashboard_file=""
usage_file=""
cost_file=""
out_file=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dashboard-file) dashboard_file="$2"; shift 2 ;;
    --usage-file) usage_file="$2"; shift 2 ;;
    --config)     CONFIG="$2";     shift 2 ;;
    --cost-file)  cost_file="$2";  shift 2 ;;
    --out)        out_file="$2";   shift 2 ;;
    --no-publish) PUBLISH_MODE="none"; shift ;;
    *) echo "unknown argument: $1" >&2; exit 64 ;;
  esac
done

# Each source is read from a file when one is given, as the tests do.
read_source() {
  if [[ -n "$1" ]]; then cat "$1"; else shift; "$CODEXBAR_BIN" "$@"; fi
}
dashboard_json="$(read_source "$dashboard_file" dashboard --identity redacted)"
usage_json="$(read_source "$usage_file" usage --format json)"
cost_json="$(read_source "$cost_file" cost --format json)"
config_json="{}"
if [[ -f "$CONFIG" ]]; then
  config_json="$(cat "$CONFIG")"
fi

snapshot="$(jq -n \
  --argjson dashboard "$dashboard_json" \
  --argjson usage "$usage_json" \
  --argjson cost "$cost_json" \
  --argjson config "$config_json" \
  --arg alertPct "$ALERT_PCT" \
  --argjson now "$NOW" \
  -f "$(dirname "$0")/snapshot.jq")"

if [[ -z "$out_file" ]]; then
  out_file="$REPO_DIR/$DATA_FILE"
fi
mkdir -p "$(dirname "$out_file")"
printf '%s\n' "$snapshot" > "$out_file"
echo "wrote $out_file"

case "$PUBLISH_MODE" in
  none)
    ;;
  repo)
    cd "$REPO_DIR"
    git pull --rebase -q origin "$BRANCH"
    git add "$DATA_FILE"
    if git diff --cached --quiet; then
      echo "no change; nothing to publish"
      exit 0
    fi
    git commit -q -m "chore: update token usage snapshot"
    # Retry a flaky network with backoff before giving up.
    for delay in 2 4 8 16 0; do
      if git push -q origin "$BRANCH"; then
        echo "pushed to $BRANCH"
        exit 0
      fi
      sleep "$delay"
    done
    echo "git push failed after retries" >&2
    exit 1
    ;;
  gist)
    if [[ -z "$GIST_ID" || -z "${GITHUB_TOKEN:-}" ]]; then
      echo "gist mode needs GIST_ID and GITHUB_TOKEN" >&2
      exit 64
    fi
    payload="$(jq -n --arg name "$GIST_FILENAME" --arg content "$snapshot" \
      '{files: {($name): {content: $content}}}')"
    curl -fsS -X PATCH \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      -d "$payload" \
      "https://api.github.com/gists/$GIST_ID" > /dev/null
    echo "updated gist $GIST_ID"
    ;;
  *)
    echo "unknown PUBLISH_MODE: $PUBLISH_MODE" >&2
    exit 64
    ;;
esac
