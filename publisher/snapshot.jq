# Reduces CodexBar's dashboard, usage and cost output to the snapshot the
# watch reads. Inputs: $dashboard, $usage, $cost, $config, $alertPct, $now.

def to_epoch:
  if type == "string" then (sub("\\.[0-9]+"; "") | try fromdateiso8601 catch null) else null end;

def mins_left:
  to_epoch | if . == null then null
  else (((. - $now) / 60) | floor | if . < 0 then 0 else . end) end;

def pct: if . == null then null else (. + 0.5 | floor) end;

def by_provider: map(select(type == "object" and .provider != null) | {key: .provider, value: .}) | from_entries;

def day_on($date): (.daily // []) | map(select(.date == $date)) | last;

# A window's length in minutes: from the matching `usage` window, else from
# its kind.
def window_minutes($u):
  .kind as $kind | (.resetAt | to_epoch) as $reset
  | ([($u.usage.extraRateWindows // [])[] | select(.id == $kind) | .window.windowMinutes]
     + [($u.usage.primary, $u.usage.secondary, $u.usage.tertiary)
        | select(. != null and $reset != null and ((.resetsAt | to_epoch) // 0 | . - $reset | fabs) <= 120)
        | .windowMinutes]
     + [if $kind == "session" then 300 elif ($kind | test("week")) then 10080
        elif ($kind | test("month")) then 43200 else null end])
  | map(select(. != null)) | first;

# An accent colour snapped by hue to one of the vivid colours the Forerunner
# 255's 64-colour screen shows well; grey when it has little colour.
def watch_color:
  ltrimstr("#") | ascii_downcase | explode
  | map(if . >= 97 then . - 87 else . - 48 end)
  | [(.[0] * 16 + .[1]), (.[2] * 16 + .[3]), (.[4] * 16 + .[5])] | map(. / 255)
  | (max) as $max | (min) as $min | ($max - $min) as $d
  | if $d < 0.15 then 11184810
    else (if $max == .[0] then 60 * (((.[1] - .[2]) / $d) % 6)
          elif $max == .[1] then 60 * ((.[2] - .[0]) / $d + 2)
          else 60 * ((.[0] - .[1]) / $d + 4) end | if . < 0 then . + 360 else . end) as $hue
      | [[20, 16733440], [200, 43775], [228, 22015], [275, 11141375], [320, 16711850], [380, 16733440]]
      | min_by(.[0] - $hue | fabs) | .[1]
    end;

def short_default:
  if .id == "claude" then "CC" elif .id == "codex" then "CX"
  else (.name // .id | ascii_upcase | .[0:2]) end;

def message: if type == "object" then (.message // .description // "error") else tostring end;

($config.providers // {}) as $overrides
| (if $alertPct != "" then ($alertPct | tonumber) else ($config.alertPct // 90) end) as $alert
| ($usage | by_provider) as $usageBy
| ($cost | by_provider) as $costBy
| ($now | strftime("%Y-%m-%d")) as $today
| ($dashboard.providers // [] | map(select(.enabled != false))) as $all
| (if $config.show then [$config.show[] as $id | $all[] | select(.id == $id)] else $all end) as $shown
| ($shown[0:3] | map(
    . as $d
    | ($overrides[$d.id] // {}) as $o
    | ($usageBy[$d.id] // {}) as $u
    | ($costBy[$d.id] // {}) as $c
    | ($c | day_on($today) // {}) as $day
    # Tokens for each of the last 30 days, oldest first and today last.
    | [range(29; -1; -1) as $ago
        | ($c | day_on(($now - $ago * 86400) | strftime("%Y-%m-%d")))
        | .totalTokens // 0] as $month
    | {
        id: $d.id,
        name: ($o.name // $d.name // $d.id),
        short: ($o.short // ($d | short_default)),
        color: (($o.color // $d.display.accentColor // "#AAAAAA") | watch_color),
        plan: ($d.identity.plan // null),
        windows: [($d.windows // [])[] | select(.kind as $k | ($o.hide // []) | index($k) | not)
          | window_minutes($u) as $length
          | (.resetAt | mins_left) as $left
          | {
              label: (.label // .kind),
              pct: (.usedPercent | pct),
              resets_min: $left,
              pace_pct: (if $length == null or $left == null then null
                         else (($length - $left) * 100 / $length | pct | if . < 0 then 0 else . end) end)
            }],
        credits: (if $d.credits.remaining == null then null
                  else ($d.credits.remaining | if . >= 1000 then (. / 100 | floor | . / 10 | tostring) + "K" else tostring end)
                       + " " + ($d.credits.unit // "credits") end),
        status: (if $d.status == null then null
                 elif ($d.status | type) == "object" then (if ($d.status.indicator // "none") == "none" then null else ($d.status.description // $d.status.indicator) end)
                 else ($d.status | tostring) end),
        error: (if $d.error == null then null
                else ($d.error | message | if length > 40 then (.[0:40] | sub(" [^ ]*$"; "")) + "..." else . end) end),
        today_tokens: ($day.totalTokens // null),
        today_cost_usd: ($day.totalCost // null),
        yesterday_tokens: (if $c.daily then $month[28] else null end),
        yesterday_cost_usd: (if $c.daily
          then ($c | day_on(($now - 86400) | strftime("%Y-%m-%d")) | .totalCost // 0)
          else null end),
        last30_tokens: ($c.last30DaysTokens // null),
        last30_cost_usd: ($c.last30DaysCostUSD // $d.cost.last30DaysUSD // null),
        week_tokens: $month[23:]
      }
    | .pr = (($month[0:29] | max) as $best | $best > 0 and $month[29] > $best)
    | .streak = ($month | reverse | (if .[0] == 0 then .[1:] else . end)
                 | (map(. > 0) | index(false)) // length)
    | .alert = ([.windows[].pct // 0] | any(. >= $alert))
  )) as $providers
| {
    version: 2,
    updated: $now,
    face: ([($config.face // [])[] as $id | $providers | map(.id) | index($id) | select(. != null)]
           | if length == 0 then [range(0; [2, ($providers | length)] | min)] else .[0:2] end),
    providers: $providers
  }
