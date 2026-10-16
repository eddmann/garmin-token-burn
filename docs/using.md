[Back to Token Burn](../README.md)

# Using Token Burn

Token Burn records your AI coding the way your watch records training.
It tracks up to three providers, such as Claude, Codex and Cursor, in the order the publisher lists them, and reports their limits, burn status, recovery time and burn history.
Each provider has its own colour, and is labelled with its name in the app and with a short label, such as `CC` or `CX`, on the glance, the watch face and the complication.

A provider's limits are its **windows**, such as a five-hour session, a week or a month.
Its **headline** is the window closest to its limit, and is the figure the glance, the watch face, the complication and Burn Status show.

## Viewing the Token Burn Glance

1. From the watch face, press **Up** or **Down** to scroll through the glances.
2. Stop on **TOKEN BURN** to see the headline of your two face providers, such as `CC 62%  CX 55%`, with a bar under each in its zone colour.

`TOKEN BURN !` in red means a provider has reached its alert threshold.
The glance shows the last data the watch received, so it appears even when your phone is out of range.

NOTE: If Token Burn is not in the glance list, add it from the glance list's edit menu.

## Viewing the Morning Report

The Morning Report is the first page you see when you open Token Burn.

1. From the Token Burn glance, press **Start**.
2. For each provider, the report shows yesterday's tokens and dollars burned, such as `Claude 3.0M · $27.80`, then its burn status and how much of its headline window is left, such as `Overreaching · 38% left`.

Providers without token logs show only their burn status and what is left.

## Moving Between Pages

Press **Up** or **Down**, or **Start**, to move between pages.
The dots on the left edge show which page you are on, and the line at the bottom shows how long ago the watch received the data.

| Page | What it shows |
| --- | --- |
| Morning Report | Yesterday's burn, burn status and what is left, for each provider |
| Burn Status | A gauge for each provider's headline window |
| One page per provider | Its burn status, plan and credits, and every window |
| Today's Burn | Tokens torched and dollars burned today |
| Burn History | The last 30 days, the last seven days as bars, burn load and burn streak |

## Burn Status

Burn status works like training status: it tells you whether your current burn is sustainable.

### Viewing Burn Status

The Burn Status page shows a gauge for each provider, outermost first.
Each gauge is open at the bottom and fills clockwise with the share of the headline window used.
The white tick marks where an even pace through the window would be; if the fill is past the tick, you are using that window faster than it recovers.

With two providers, the page also shows each one's burn status and recovery time, such as `Overreaching · 4h 29m`.
With three, it shows the percentages only; each provider's page shows its status.

### Burn Status Levels

| Status | What it means |
| --- | --- |
| Productive | Your burn load is high: you have used more tokens in the last seven days than in an average week |
| Maintaining | Your burn is steady and within your limits |
| Recovering | Your burn load is low, or, for a provider without token logs, every window is more than 25 points behind an even pace |
| Overreaching | At least one window is more than 10 points ahead of an even pace, so you are on course to run out before it recovers |
| Detraining | The provider has token logs but no tokens in the last seven days |

Overreaching and Detraining take priority over the others.

### Usage Zones

Gauges, bars and percentages are coloured by zone.
Provider names keep their own colours.

| Zone | Share of the window used |
| --- | --- |
| Green | Under 50% |
| Yellow | 50% to 74% |
| Orange | 75% to 89% |
| Red | 90% or more, or the provider's alert flag is set |

## About Recovery Time

Recovery time is the time until a window resets.
It appears next to each window on a provider's page, such as `Session  4h 29m`, and next to the burn status on Burn Status.
When a window recovers, its share used returns to 0%.

## Viewing a Provider

Each provider has its own page.

- The burn status appears under the provider's name.
- The plan and any credits appear next, such as `Pro 20x · 62.5K credits`. During a service incident, the incident replaces this line in orange.
- Each window has a row with its name, recovery time and share used, and a bar with the even-pace tick.

## Today's Burn

Today's Burn shows the tokens each provider has torched today, such as `Claude 4.2M`, with the dollars burned, and the total for all providers.
It includes only providers with local token logs, such as Claude and Codex.

On a subscription plan, dollars burned are what the same tokens would have cost on the API.
Like calories, they keep score rather than show a bill.

## Burn History

Burn History shows each provider's tokens and dollars burned over the last 30 days, and a bar for each of the last seven days, stacked in provider order.
The dotted line marks your daily average.

### Burn Load

Burn load compares your last seven days with an average week from the last 30.

| Burn load | Last seven days compared with an average week |
| --- | --- |
| High | More than 1.3 times |
| Optimal | Between 0.8 and 1.3 times |
| Low | Less than 0.8 times |

Burn load appears under the bars, such as `Load Low · 2-day streak`.
Only providers with token logs have a burn load.

### Personal Records

A personal record is a day with more tokens than any of the 29 days before it.
On a record day, Today's Burn shows a `PR` badge next to that provider's dollars burned, and Burn History shows `PR` beside today's bar.

### Burn Streak

Your burn streak is the number of days in a row with tokens, up to today.
If you have not used any tokens yet today, the streak counts up to yesterday.
Burn History shows the longest streak of your providers.

## Using Token Burn Face

Token Burn Face shows your two face providers on the main screen.

1. Hold **Up**, then select **Watch Face**.
2. Select **Token Burn Face**.

The time appears in the middle, with the date above it and the flame at 12 o'clock.
Two thin gauges, one for each face provider in its own colour, show their headline windows, and the percentages appear below the time, such as `CC 62%  CX 55%`.

## Adding the Limit Used Complication

Token Burn provides a complication, **Limit used**, that shows the busiest headline among your providers, such as `CC 62%`.
You can add it to any watch face with a slot that accepts Connect IQ complications.

1. Edit the watch face, and select the slot you want to change.
2. Select **Token Burn**.

NOTE: Not every Garmin watch face offers a slot that accepts Connect IQ complications.

## Alerts

Token Burn notifies you with a vibration and a message.

| Alert | When it appears |
| --- | --- |
| `Overreaching: Claude session 92%` | A window first reaches the alert threshold, 90% unless your config sets another |
| `New PR! Claude 4.2M tokens torched` | A provider first sets a personal record today |

Each alert appears once.
An Overreaching alert can appear again only after that provider drops back under the threshold, and a personal record alert only on another record day.

## Troubleshooting

### My watch shows No data yet

The watch has not received any data.

- Check that your phone is connected to the watch and the Garmin Connect app is running.
- Check that the data URL opens in a browser over HTTPS.
- Check that the publisher has run since you installed Token Burn.

### The footer says stale

The data is more than 20 minutes old, and the footer and the watch face show `stale` in orange.
Your phone may have been out of Bluetooth range, or the publisher may not have run recently.

### A provider shows --%

CodexBar could not read that provider when the publisher last ran.
The provider's page shows the start of the error, such as `Not logged in to Gemini. Run 'gemini'...`.
See [Providers](providers.md) for how to fix it.
