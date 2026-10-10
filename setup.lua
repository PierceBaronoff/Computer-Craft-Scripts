-- setup.lua
-- First-run installer for the Computer-Craft-Scripts hub.
--
-- Lists the scripts in the repo's scripts/ folder, lets you pick one,
-- saves that choice to disk, then downloads and runs update.lua, which
-- handles fetching and launching the chosen script.
--
-- Install with:  pastebin run <code>
--           or:  wget run https://raw.githubusercontent.com/PierceBaronoff/Computer-Craft-Scripts/main/setup.lua

local REPO = "PierceBaronoff/Computer-Craft-Scripts"
local BRANCH = "main"
local SCRIPTS_DIR = "scripts"

local CONFIG_PATH = "/.hub/config"
local UPDATE_PATH = "/update.lua"

local API_URL = ("https://api.github.com/repos/%s/contents/%s?ref=%s"):format(REPO, SCRIPTS_DIR, BRANCH)
local RAW_URL = ("https://raw.githubusercontent.com/%s/%s/"):format(REPO, BRANCH)

local function fail(msg)
  if term.isColour() then term.setTextColour(colours.red) end
  print(msg)
  term.setTextColour(colours.white)
  error("setup aborted", 0)
end

local function fetch(url)
  local res, err = http.get(url, { ["User-Agent"] = "cc-script-hub" })
  if not res then return nil, err end
  local body = res.readAll()
  res.close()
  return body
end

-- Ask GitHub which .lua files live in scripts/.
local function listScripts()
  local body, err = fetch(API_URL)
  if not body then fail("Could not reach GitHub: " .. tostring(err)) end

  local entries = textutils.unserialiseJSON(body)
  if type(entries) ~= "table" then fail("Unexpected response from GitHub API.") end

  local scripts = {}
  for _, entry in ipairs(entries) do
    if entry.type == "file" and entry.name:match("%.lua$") then
      scripts[#scripts + 1] = { name = entry.name:gsub("%.lua$", ""), file = entry.name }
    end
  end
  table.sort(scripts, function(a, b) return a.name < b.name end)
  return scripts
end

-- Arrow-key menu (number keys 1-9 jump straight to an entry).
local function choose(scripts)
  local selected, scroll = 1, 0
  local colour = term.isColour()

  while true do
    local w, h = term.getSize()
    local rows = h - 3

    if selected <= scroll then scroll = selected - 1 end
    if selected > scroll + rows then scroll = selected - rows end

    term.setBackgroundColour(colours.black)
    term.clear()
    term.setCursorPos(1, 1)
    if colour then term.setTextColour(colours.yellow) end
    print("Script Hub - choose a script to install")
    term.setTextColour(colours.lightGrey or colours.white)
    print(("Up/Down + Enter  (%d found)"):format(#scripts))

    for i = scroll + 1, math.min(#scripts, scroll + rows) do
      term.setCursorPos(1, 3 + i - scroll)
      if i == selected then
        if colour then
          term.setBackgroundColour(colours.blue)
          term.setTextColour(colours.white)
        end
        term.write(("> %d. %s"):format(i, scripts[i].name):sub(1, w))
        term.setBackgroundColour(colours.black)
      else
        term.setTextColour(colours.white)
        term.write(("  %d. %s"):format(i, scripts[i].name):sub(1, w))
      end
    end
    term.setTextColour(colours.white)

    local event, key = os.pullEvent()
    if event == "key" and key == keys.up then
      selected = selected == 1 and #scripts or selected - 1
    elseif event == "key" and key == keys.down then
      selected = selected == #scripts and 1 or selected + 1
    elseif event == "key" and (key == keys.enter or key == keys.numPadEnter) then
      term.clear()
      term.setCursorPos(1, 1)
      return scripts[selected]
    elseif event == "char" then
      local n = tonumber(key)
      if n and n >= 1 and n <= #scripts then selected = n end
    end
  end
end

local function saveConfig(script)
  fs.makeDir(fs.getDir(CONFIG_PATH))
  local f = fs.open(CONFIG_PATH, "w")
  f.write(textutils.serialise({
    script = script.name,
    file = script.file,
    repo = REPO,
    branch = BRANCH,
  }))
  f.close()
end

local function downloadUpdater()
  local body, err = fetch(RAW_URL .. "update.lua")
  if not body then fail("Could not download update.lua: " .. tostring(err)) end
  local f = fs.open(UPDATE_PATH, "w")
  f.write(body)
  f.close()
end

if not http then
  fail("HTTP API is disabled. Enable it in the ComputerCraft config.")
end

print("Fetching script list...")
local scripts = listScripts()
if #scripts == 0 then fail("No scripts found in " .. SCRIPTS_DIR .. "/ on " .. BRANCH .. ".") end

local choice = choose(scripts)
saveConfig(choice)
print("Selected: " .. choice.name)

print("Downloading update.lua...")
downloadUpdater()

print("Starting update.lua...")
shell.run(UPDATE_PATH)
