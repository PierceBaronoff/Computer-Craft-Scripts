--[[ AIRSHIP POCKET REMOTE v1  (wireless or ender pocket computer, advanced recommended)

  summon                       come to where I am now, hover 10 above
  summon -here -land           come to where I am now and land
  summon -here -hover 20       come here, hover 20 above (never under sea level + 20)
  summon -follow [-hover N]    follow me (position sent every second)
  goto x y z [-land|-hover N|-exact]
  goto <name> [-land|-hover N|-exact]
  waypoint <name> -here        save my position as a waypoint
  waypoint <name> x y z        save coordinates as a waypoint
  waypoints                    list waypoints     delwp <name>   delete one
  refuel                       fly to the dock and refuel
  land | takeoff [m] | stop | status | clear | help
]]

local SHIP_ID  = 0                -- PLACEHOLDER: main computer ID
local SECRET   = "CHANGE-ME"      -- PLACEHOLDER: must match the main computer
local PROTO    = "airship"
local FOLLOW_EVERY = 1            -- seconds between position updates in follow mode

------------------------------------------------------------------------ SETUP
local modem = peripheral.find("modem", function(_, m) return m.isWireless() end)
assert(modem, "Needs a wireless or ender modem upgrade")
rednet.open(peripheral.getName(modem))

local W, H = term.getSize()
local root = term.current()
local bar  = window.create(root, 1, 1, W, 3)
local main = window.create(root, 1, 4, W, H - 3)
term.redirect(main)

local state = { following = false, line1 = "Ship: ?", line2 = "" }

local function drawBar()
  bar.setBackgroundColor(root.isColour() and colours.blue or colours.grey)
  bar.setTextColor(colours.white)
  bar.clear()
  bar.setCursorPos(1, 1); bar.write(state.line1:sub(1, W))
  bar.setCursorPos(1, 2); bar.write(state.line2:sub(1, W))
  bar.setCursorPos(1, 3); bar.write((state.following and "[FOLLOWING]" or ""):sub(1, W))
  main.restoreCursor()
end

------------------------------------------------------------------------ HELPERS
local function myPos()
  local x, y, z = gps.locate(2)
  if not x then return nil end
  return { x = x, y = y, z = z }
end

local function send(msg, wait)
  msg.secret = SECRET
  rednet.send(SHIP_ID, msg, PROTO)
  if not wait then return true end
  local timer = os.startTimer(3)
  while true do
    local ev, a, b, c = os.pullEvent()
    if ev == "rednet_message" and a == SHIP_ID and c == PROTO and type(b) == "table" and b.type == "reply" then
      return b
    elseif ev == "timer" and a == timer then
      return nil
    end
  end
end

local function show(r)
  if not r then printError("No reply (range? ID? secret?)") return end
  if r.ok then print(r.text) else printError(r.text) end
end

-- Flags: -here -follow -land -exact -hover N. Other words go into args (leading '-' stripped).
local function parse(words)
  local o = { args = {} }
  local i = 1
  while i <= #words do
    local w = words[i]
    if w == "-here" then o.here = true
    elseif w == "-follow" then o.follow = true
    elseif w == "-land" then o.land = true
    elseif w == "-exact" then o.exact = true
    elseif w == "-hover" then
      o.hover = tonumber(words[i + 1]); i = i + 1
      if not o.hover then return nil, "-hover needs a number" end
    elseif w ~= "-" then
      -- keep negative numbers, strip the dash from names like "-home"
      o.args[#o.args + 1] = tonumber(w) and w or (w:gsub("^%-", ""))
    end
    i = i + 1
  end
  return o
end

local function coords(a, from)
  local x, y, z = tonumber(a[from]), tonumber(a[from + 1]), tonumber(a[from + 2])
  if x and y and z then return { x = x, y = y, z = z } end
end

------------------------------------------------------------------------ COMMANDS
local HELP = {
  "summon [-here|-follow]", "  [-land|-hover N]",
  "goto x y z|name", "  [-land|-hover N|-exact]",
  "waypoint name -here", "waypoint name x y z",
  "waypoints  delwp name",
  "refuel land takeoff [m]", "stop status clear",
}

local function run(line)
  local words = {}
  for t in line:gmatch("%S+") do words[#words + 1] = t end
  local cmd = table.remove(words, 1)
  if not cmd then return end
  local o, err = parse(words)
  if not o then printError(err) return end
  local a = o.args

  if cmd == "help" then for _, l in ipairs(HELP) do print(l) end return end
  if cmd == "clear" then term.clear(); term.setCursorPos(1, 1) return end

  -- Any flight command other than status/waypoint stuff stops follow updates
  local passive = { status = true, waypoint = true, waypoints = true, delwp = true }
  if not passive[cmd] then state.following = false; drawBar() end

  if cmd == "summon" then
    local p = myPos()
    if not p then printError("No GPS fix here") return end
    local r = send({ cmd = "summon", pos = p, follow = o.follow, land = o.land,
                     hover = o.hover, exact = o.exact }, true)
    show(r)
    if r and r.ok and o.follow then state.following = true; drawBar() end

  elseif cmd == "goto" then
    local p = coords(a, 1)
    local msg = { cmd = "goto", land = o.land, hover = o.hover, exact = o.exact }
    if p then msg.pos = p
    elseif a[1] then msg.name = a[1]
    else printError("goto x y z  or  goto name") return end
    show(send(msg, true))

  elseif cmd == "waypoint" then
    local name = a[1]
    if not name then printError("waypoint name -here|x y z") return end
    local p = o.here and myPos() or coords(a, 2)
    if not p then printError(o.here and "No GPS fix here" or "Need -here or x y z") return end
    show(send({ cmd = "wp_set", name = name, pos = p }, true))

  elseif cmd == "waypoints" then show(send({ cmd = "wp_list" }, true))
  elseif cmd == "delwp" then
    if not a[1] then printError("delwp name") return end
    show(send({ cmd = "wp_del", name = a[1] }, true))
  elseif cmd == "refuel" then show(send({ cmd = "refuel" }, true))
  elseif cmd == "land" then show(send({ cmd = "land" }, true))
  elseif cmd == "takeoff" then show(send({ cmd = "takeoff", height = tonumber(a[1]) }, true))
  elseif cmd == "stop" or cmd == "unfollow" then show(send({ cmd = "stop" }, true))
  elseif cmd == "status" then
    local r = send({ cmd = "status" }, true)
    show(r)
    if r and r.ok then state.line1 = r.text; drawBar() end
  else
    printError("Unknown: " .. cmd .. " (try help)")
  end
end

------------------------------------------------------------------------ TASKS
local function inputTask()
  local history = {}
  print("Airship remote. 'help' for commands.")
  while true do
    write("> ")
    local line = read(nil, history)
    if line ~= "" then history[#history + 1] = line end
    local ok, e = pcall(run, line)
    if not ok then printError(e) end
  end
end

local function listenTask()
  while true do
    local id, m = rednet.receive(PROTO)
    if id == SHIP_ID and type(m) == "table" then
      if m.type == "note" then
        state.line2 = m.text
        if m.text:find("Arrived") or m.text:find("Landed") or m.text:find("docked") then
          state.line2 = "** " .. m.text .. " **"
        end
        if m.text:find("Lost contact") or m.text:find("Pilot has control") then state.following = false end
        drawBar()
      elseif m.type == "eta" then
        state.line1 = ("%s %dm ETA %s"):format(m.mode, m.dist, m.eta)
        drawBar()
      end
    end
  end
end

local function followTask()
  while true do
    if state.following then
      local p = myPos()
      if p then send({ cmd = "follow_pos", pos = p }, false) end
    end
    sleep(FOLLOW_EVERY)
  end
end

drawBar()
parallel.waitForAny(inputTask, listenTask, followTask)