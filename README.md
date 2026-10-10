# Computer-Craft-Scripts

Hub for my ComputerCraft (CC: Tweaked) scripts.

## How it works

1. **`setup.lua`** – run once on a new computer. It asks GitHub what's in `scripts/`, shows an
   arrow-key menu, saves your choice to `/.hub/config`, downloads `update.lua` and runs it.
2. **`update.lua`** – reads `/.hub/config`, then:
   - re-downloads itself and `setup.lua` if the repo copies differ from what's on disk
     (after a self-update it restarts using the new copy);
   - downloads the chosen script from `scripts/` as `/startup.lua`, replacing any existing one
     (keeps the old `startup.lua` if GitHub can't be reached);
   - runs `startup.lua`.
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

Every script should start with this line so it updates itself each time it boots:

```lua
if fs.exists("/update.lua") then shell.run("/update.lua", "--check") end
```

With `--check`, `update.lua` syncs everything as usual but doesn't launch `startup.lua`. If the
script itself changed it reboots into the new version; otherwise the script just carries on.

## Notes

- Run `update` on a computer at any time to pull the latest scripts.
- To switch a computer to a different script, run `setup` again.

- Files are read from the `main` branch (`BRANCH` at the top of `setup.lua`).
- The script list uses the unauthenticated GitHub API (60 requests/hour per IP).
- `raw.githubusercontent.com` caches for ~5 minutes, so fresh pushes can take a moment to appear.
