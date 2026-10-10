-- update.lua
-- Keeps this computer in sync with the repo:
--   1. Updates itself (update.lua) and setup.lua if the repo copies differ
--      from what's on disk.
--   2. Downloads the script chosen in setup.lua as /startup.lua,
--      replacing any existing startup.lua.
--   3. Runs the new startup.lua.
--
-- Scripts call this at the top with --check (see README). In that mode
-- step 3 is skipped: if startup.lua changed the computer reboots into the
-- new version, otherwise control returns to the calling script.

local CONFIG_PATH = "/.hub/config"
local UPDATE_PATH = "/update.lua"
local SETUP_PATH = "/setup.lua"
local STARTUP_PATH = "/startup.lua"

-- --updated: passed to the fresh copy of itself after a self-update, so
--            the new copy doesn't try to update itself again.
-- --check:   called from a script; don't launch startup.lua (see above).
local flags = {}
for _, arg in ipairs({ ... }) do flags[arg] = true end
local justUpdated = flags["--updated"]
local checkOnly = flags["--check"]

local function readFile(path)
  if not fs.exists(path) then return nil end
  local f = fs.open(path, "rb")
  local data = f.readAll()
  f.close()
  return data
end

local function writeFile(path, data)
  local f = fs.open(path, "wb")
  f.write(data)
  f.close()
end

local function fetch(url)
  local res, err = http.get(url, { ["User-Agent"] = "cc-script-hub" }, true)
  if not res then return nil, err end
  local body = res.readAll()
  res.close()
  return body
end

if not http then
  error("HTTP API is disabled. Enable it in the ComputerCraft config.", 0)
end

local config = textutils.unserialise(readFile(CONFIG_PATH) or "")
if type(config) ~= "table" or not config.file then
  error("No script chosen yet - run setup.lua first.", 0)
end

local RAW_URL = ("https://raw.githubusercontent.com/%s/%s/"):format(config.repo, config.branch)

-- Download repoPath and write it to localPath if it differs from what's on disk.
-- Returns true if the file changed, false if already current, nil + err on failure.
local function sync(repoPath, localPath)
  local remote, err = fetch(RAW_URL .. repoPath)
  if not remote then return nil, err end
  if remote == readFile(localPath) then return false end
  writeFile(localPath, remote)
  return true
end

-- 1. Self-update, then hand over to the new copy.
if not justUpdated then
  local changed, err = sync("update.lua", UPDATE_PATH)
  if changed then
    print("update.lua changed, restarting...")
    shell.run(UPDATE_PATH, "--updated", checkOnly and "--check" or nil)
    return
  elseif changed == nil then
    print("Couldn't check update.lua: " .. tostring(err))
  end
end

local changed, err = sync("setup.lua", SETUP_PATH)
if changed then
  print("setup.lua updated.")
elseif changed == nil then
  print("Couldn't check setup.lua: " .. tostring(err))
end

-- 2. Pull the chosen script down as startup.lua.
print("Updating " .. config.script .. "...")
changed, err = sync("scripts/" .. config.file, STARTUP_PATH)
if changed then
  print(config.script .. " installed as startup.lua.")
elseif changed == false then
  print(config.script .. " is up to date.")
elseif fs.exists(STARTUP_PATH) then
  print("Update failed (" .. tostring(err) .. "), keeping existing startup.lua.")
else
  error("Could not download " .. config.file .. ": " .. tostring(err), 0)
end

-- 3. Launch it. A calling script just carries on unless it was replaced.
if not checkOnly then
  shell.run(STARTUP_PATH)
elseif changed then
  print("Rebooting into new version...")
  sleep(1)
  os.reboot()
end
