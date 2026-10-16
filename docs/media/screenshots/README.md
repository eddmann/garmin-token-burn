[Back to Token Burn](../../../README.md)

# Screenshots

These are captured in the Connect IQ simulator (SDK 9.2.0) on the Forerunner 255 profile, from the SDK Manager's device files.
They show `data/usage.json`, the demo snapshot the publisher makes from its fixtures (Claude, Codex and Cursor), so the numbers match `publisher/fixtures/usage.expected.json`.

| File | Screen |
| --- | --- |
| `face.png` | The watch face |
| `glance.png` | The glance |
| `morning.png` | The Morning Report |
| `overview.png` | Burn Status |
| `claude.png`, `codex.png`, `cursor.png` | A page per provider |
| `today.png` | Today's Burn |
| `history.png` | Burn History |

## How they were made

Each screen comes from a throwaway build, never committed, made from a copy of `widget/`, `face/` and `shared/`:

1. `onStart` saves `data/usage.json` straight into storage and the background fetch is stubbed out, so the footer reads `0m ago` and nothing overwrites the sample data.
2. For the pages, `mPage` starts on the page wanted (0 for the Morning Report, 1 for Burn Status, then one per provider, then Today's Burn and Burn History) and `getGlanceView` is removed, so the simulator opens the full app instead of the glance; the glance and the face are the apps as they are.
3. Each build runs with `monkeydo <prg> fr255`, and the simulator window is captured with `screencapture -l <window id>`.
4. The watch screen is cropped from the Retina capture at the display position in the device's `simulator.json`, halved with nearest-neighbour sampling to the native 260 × 260, and masked to the round screen.

The face, glance and pages were also checked the same way on the 218 × 218 Forerunner 255S.
