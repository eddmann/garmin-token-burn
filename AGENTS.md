- `widget/`: the Connect IQ app (glance, pages, complication and alerts) in Monkey C, for the four Forerunner 255 models.
- `face/`: the watch face.
- `shared/`: storage, background fetch, gauges, burn status, settings and icon, compiled into both apps.
- `publisher/`: `publish-usage.sh` and `snapshot.jq`, which turn CodexBar's dashboard, usage and cost output into `data/usage.json`, the `token-burn.json` config, and fixtures and tests.
- `scripts/`: SDK download and device file generation for `make deps`.
- `video/`: the parody advert as a Remotion project, rendered into `docs/media/video` by `make video`.
- `docs/`: guides, indexed in `docs/README.md`.

Keep changes focused and as simple as possible: no gold plating, over-architecting, over-engineering or over-testing.

Prefer `make` targets over direct commands - run `make help` for targets.
Run `make can-release` after any changes to validate.
The simulator needs SDK Manager device files and a display; generated device files only compile.

Follow `docs/architecture.md` for how the snapshot reaches the watch and what is stored.
The glance has a tight memory budget: keep it to reading storage and drawing two lines.
Publisher changes need a fixture and expected snapshot that `make test` checks; keep `NOW` pinned.
Rebuild `prebuilt/` with `make prebuilt` when either app changes.
