# Computer-Craft-Scripts

Hub for my ComputerCraft (CC: Tweaked) scripts.

## How it works

1. **`setup.lua`** – run once on a new computer. It asks GitHub what's in `scripts/`, shows an
   arrow-key menu, saves your choice to `/.hub/config`, downloads `update.lua` and runs it.
2. **`update.lua`** – reads `/.hub/config`, downloads the newest copy of the chosen script from
   `scripts/` and runs it (falls back to the local copy if GitHub can't be reached).
3. **`scripts/`** – every `<name>.lua` in here shows up in the setup menu as `<name>`.

## Installing on a computer

```
pastebin run <code>
```

or, without Pastebin (always pulls the latest `setup.lua`):

```
wget run https://raw.githubusercontent.com/PierceBaronoff/Computer-Craft-Scripts/main/setup.lua
```

The HTTP API must be enabled in the ComputerCraft server config.

## Adding a script

Drop `myscript.lua` into `scripts/` and push to `main`. It'll appear in the menu on the next setup.

## Notes

- Files are read from the `main` branch (`BRANCH` at the top of `setup.lua`).
- The script list uses the unauthenticated GitHub API (60 requests/hour per IP).
- `raw.githubusercontent.com` caches for ~5 minutes, so fresh pushes can take a moment to appear.
