[Back to Token Burn](../README.md)

# Installing

Token Burn is installed by sideloading, so it never goes through the Connect IQ Store.
It supports the four Forerunner 255 models: the 255, 255 Music, 255S and 255S Music.

## Sideloading

1. Connect the watch to a computer with its USB cable. On a Mac the watch shows up over MTP, so open it with an MTP client such as [OpenMTP](https://openmtp.ganeshrvel.com/).
2. Copy [`prebuilt/TokenBurn.prg`](../prebuilt/TokenBurn.prg) for the app and [`prebuilt/TokenBurnFace.prg`](../prebuilt/TokenBurnFace.prg) for the watch face, or your own builds from `dist/`, into the watch's `GARMIN/APPS/` folder. Either works on its own.
3. Eject the watch. Token Burn appears in the glance list (if it isn't shown, add it from the glance list's edit menu), and Token Burn Face in the list of watch faces.

The app's builds for the four models come out byte for byte the same, so the one prebuilt file runs on all of them; both apps size everything from the screen they are drawn on.
A build is signed with the key in `.keys/`, which `make deps` creates once; rebuilding with a different key installs as a different app, so its stored snapshot starts empty.

## Pointing it at your snapshot

The app and the face each fetch the URL in their **Usage JSON URL** setting.
The default is `https://raw.githubusercontent.com/eddmann/garmin-token-burn/main/data/usage.json`, which the publisher's repo mode updates.
Raw URLs on a private repository need a token the watch cannot send, so while this repository is private, use the publisher's gist mode instead; a secret gist works, since its raw URL needs no login.

For a sideloaded build, the setting's default is the place to change it: set your URL in `shared/resources/settings/properties.xml`, which both apps use, then run `make build` and copy the new files across.
The URL must be HTTPS with a valid certificate, because the phone makes the request on the watch's behalf.
