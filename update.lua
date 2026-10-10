-- update.lua
-- Reads the script choice saved by setup.lua, downloads the latest copy
-- of that script from the repo, then runs it.
--
-- Minimal first version: grab the newest copy and launch it.

local CONFIG_PATH = "/.hub/config"

if not fs.exists(CONFIG_PATH) then
  error("No script chosen yet - run setup.lua first.", 0)
end

local f = fs.open(CONFIG_PATH, "r")
local config = textutils.unserialise(f.readAll())
f.close()
if type(config) ~= "table" or not config.file then
  error("Config at " .. CONFIG_PATH .. " is corrupt - run setup.lua again.", 0)
end

local url = ("https://raw.githubusercontent.com/%s/%s/scripts/%s"):format(config.repo, config.branch, config.file)
local target = "/" .. config.file

print("Updating " .. config.script .. "...")
local res, err = http.get(url, { ["User-Agent"] = "cc-script-hub" })
if res then
  local body = res.readAll()
  res.close()
  local out = fs.open(target, "w")
  out.write(body)
  out.close()
  print("Up to date.")
elseif fs.exists(target) then
  print("Update failed (" .. tostring(err) .. "), running existing copy.")
else
  error("Could not download " .. config.file .. ": " .. tostring(err), 0)
end

shell.run(target)
