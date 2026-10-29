[Back to Token Burn](../README.md)

# Providers

Token Burn shows whatever CodexBar can read, so adding a provider is mostly a CodexBar job.
There is no per-provider code in the publisher or on the watch.

## Adding one

1. Sign in to the provider the way CodexBar expects; `codexbar usage --provider <id>` says what is missing if it cannot read it.
2. Switch it on in CodexBar's settings, or with `codexbar config enable --provider <id>`.
3. Check that it shows up with its windows:

   ```sh
   codexbar dashboard --identity redacted --pretty
   ```

4. If you keep a `show` list in `publisher/token-burn.json`, add its id there; otherwise it appears after the providers before it, up to three.
5. Give it a `short` label if its first two letters are unclear, and a `color` if CodexBar's accent is close to another provider's.
6. Run `make publish`. The watch picks it up on its next fetch, with no new build.

## How its windows reach the watch

Each window in `dashboard` becomes one in the snapshot, with its label, the share used and the minutes until it resets.
The publisher matches it to the same window in `codexbar usage` to learn its length, falling back to the kind (`session` is five hours, anything weekly is a week, anything monthly is 30 days), and from that works out where an even pace would be.

On the watch:

- the provider's page shows a bar for each of its first three windows;
- its headline, the window closest to its limit, drives the overview gauge, and on the face pair the face, glance and complication;
- any window at or above the alert threshold sets its alert flag, turns it red and posts one notification.

Credits, a plan name and a service incident show under the provider's name on its page, and the burn pages include it when CodexBar has local token logs for it, as it does for Claude and Codex.

## When a provider fails

If CodexBar cannot read a provider, `dashboard` keeps it with an error, and so does the snapshot.
Its page shows the start of the message, such as `Not logged in to Gemini. Run 'gemini'...`, and its overview line reads `--%` until the next good publish.
Hide it from `show`, or sign in again, to clear it.
