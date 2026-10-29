#!/usr/bin/env bash
#
# Runs publish-usage.sh against the CodexBar fixtures at a fixed time and
# compares the snapshot with the expected one.
set -euo pipefail

dir="$(cd "$(dirname "$0")/.." && pwd)"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT

# 2026-07-30T12:00:00Z, the time the fixtures describe.
export NOW=1785412800

snapshot() {
  "$dir/publish-usage.sh" \
    --dashboard-file "$dir/fixtures/dashboard.sample.json" \
    --usage-file "$dir/fixtures/usage.sample.json" \
    --cost-file "$dir/fixtures/cost.sample.json" \
    --config "$2" \
    --no-publish --out "$1" > /dev/null
}

check() {
  if [[ "$2" != "$3" ]]; then
    echo "FAIL: $1: expected $3, got $2" >&2
    exit 1
  fi
}

snapshot "$out/usage.json" /nonexistent
if ! diff -u "$dir/fixtures/usage.expected.json" "$out/usage.json"; then
  echo "FAIL: snapshot differs from fixtures/usage.expected.json" >&2
  exit 1
fi
echo "ok: snapshot matches fixtures/usage.expected.json"

check "personal records" "$(jq -c '[.providers[].pr]' "$out/usage.json")" "[true,false,false]"
check "streaks" "$(jq -c '[.providers[].streak]' "$out/usage.json")" "[2,1,0]"
check "yesterday" "$(jq -c '[.providers[] | [.yesterday_tokens, .yesterday_cost_usd]]' "$out/usage.json")" "[[3030000,27.8],[0,0],[null,null]]"
echo "ok: today's record, the burn streak and yesterday's burn"

ALERT_PCT=60 snapshot "$out/alert.json" /nonexistent
check "ALERT_PCT=60 alerts" "$(jq -c '[.providers[].alert]' "$out/alert.json")" "[true,false,false]"
echo "ok: ALERT_PCT raises the alert flag"

snapshot "$out/config.json" "$dir/fixtures/config.sample.json"
check "config order" "$(jq -c '[.providers[].id]' "$out/config.json")" '["codex","claude","gemini"]'
check "config face" "$(jq -c '.face' "$out/config.json")" "[1,0]"
check "config overrides" "$(jq -c '[.providers[0].name, .providers[0].color, .providers[1].short]' "$out/config.json")" '["OpenAI Codex",11141375,"CL"]'
check "config hidden window" "$(jq -c '[.providers[1].windows[].label]' "$out/config.json")" '["Session","Weekly"]'
check "config alertPct" "$(jq -c '[.providers[].alert]' "$out/config.json")" "[true,true,false]"
check "provider error" "$(jq -r '.providers[2].error' "$out/config.json")" "Not logged in to Gemini. Run 'gemini'..."
echo "ok: the config picks, orders and relabels providers"

before="$(shasum "$dir/../data/usage.json")"
if PUBLISH_MODE='' GIST_ID='' GITHUB_TOKEN='' "$dir/publish-usage.sh" \
    --dashboard-file "$dir/fixtures/dashboard.sample.json" \
    --usage-file "$dir/fixtures/usage.sample.json" \
    --cost-file "$dir/fixtures/cost.sample.json" > /dev/null 2>&1; then
  echo "FAIL: gist mode without GIST_ID and GITHUB_TOKEN should refuse" >&2
  exit 1
fi
check "demo snapshot untouched" "$(shasum "$dir/../data/usage.json")" "$before"
echo "ok: gist mode refuses without its settings and leaves data/usage.json alone"
