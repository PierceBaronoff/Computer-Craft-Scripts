--[[ AIRSHIP FLIGHT COMPUTER v1  (front / main computer)
  CC:Tweaked + Create + Create Aeronautics, redstone relays only, GPS + rear heading node.

  Run modes (type at the computer's shell):
    startup          normal flight program (auto-runs on boot, restarts itself on errors)
    startup scan     list redstone relays and show live inputs on every side (map your controls)
    startup test     cycle every configured output so you can check wiring (SHIP MUST BE MOORED)

  Search "PLACEHOLDER" for everything you need to fill in.
]]

------------------------------------------------------------------------ CONFIG
local CFG = {
  SECRET  = "CHANGE-ME",          -- PLACEHOLDER: must match the pocket remote
  ALLOWED = {},                   -- pocket computer IDs allowed to command, e.g. {7}. {} = any with secret
  PROTO   = "airship",
  HPROTO  = "airship-hdg",
  DT      = 0.1,                  -- control loop period (s)
  NAV_DT  = 0.25,                 -- GPS / heading update period (s)

  -- Rear heading node
  REAR_ID   = 0,                  -- PLACEHOLDER: rear computer ID
  REAR_BACK = 14,                 -- blocks behind the front computer
  REAR_UP   = 1,                  -- blocks above the front computer
  REAR_TOL  = 1.5,                -- reject fixes whose spacing is off by more than this (m)
  HDG_OFFSET = 0,                 -- calibration trim (deg)

  -- Linked controller inputs: { relay, side } per key, so they can be split across relays.
  -- Relays sit on a surface (bottom) with a modem on top, so only front/back/left/right are usable.
  -- Analog 0..15 accepted.
  INPUT = {
    forward = { "redstone_relay_0", "front" },   -- PLACEHOLDER  W
    back    = { "redstone_relay_0", "back" },    -- PLACEHOLDER  S
    left    = { "redstone_relay_0", "left" },    -- PLACEHOLDER  A
    right   = { "redstone_relay_0", "right" },   -- PLACEHOLDER  D
    up      = { "redstone_relay_12", "front" },  -- PLACEHOLDER  Space
    down    = { "redstone_relay_12", "back" },   -- PLACEHOLDER  Shift
    coarse  = { "redstone_relay_12", "left" },   -- PLACEHOLDER  analog lever: coarse height
    fine    = { "redstone_relay_12", "right" },  -- PLACEHOLDER  analog lever: fine height
  },
  -- Height levers (manual mode): coarse splits LEVER_MIN..LEVER_MAX into 16 bands,
  -- fine splits each band into 16 more = 256 heights, about 0.93 m apart.
  -- Moving either lever sets a new altitude target. Space/Shift still work and win until the levers move again.
  ALT_LEVERS = true,
  LEVER_MIN = 64, LEVER_MAX = 300,
  DEADBAND = 0.05,                -- input fraction treated as zero

  -- Propellers. speed = analog transmission (0 = full, 15 = stop). fwd/rev = directional gearshift relays.
  PROP = {
    left  = { speed = { "redstone_relay_1", "back" },    -- PLACEHOLDER
              fwd   = { "redstone_relay_1", "front" },   -- PLACEHOLDER
              rev   = { "redstone_relay_2", "front" },   -- PLACEHOLDER
              invert = false },
    right = { speed = { "redstone_relay_3", "back" },    -- PLACEHOLDER
              fwd   = { "redstone_relay_3", "front" },   -- PLACEHOLDER
              rev   = { "redstone_relay_4", "front" },   -- PLACEHOLDER
              invert = false },
  },
  YAW_SIGN = 1,                   -- flip to -1 if D turns the ship left

  -- Engine sleep relay: output ON = engine OFF
  ENGINE     = { "redstone_relay_11", "front" },         -- PLACEHOLDER (nil to disable sleep)
  IDLE_SLEEP = 30,                -- s with no input / no thrust demand before the engine sleeps
  WAKE_DELAY = 1.5,               -- s to let the engine spin up before thrust is applied

  -- Burners in fill order. 20 x 15 = 300 lift steps.
  BURNERS = {                                            -- PLACEHOLDER names/sides
    -- 4 direction relays, 1 burner each
    { "redstone_relay_1", "left" }, { "redstone_relay_2", "left" },
    { "redstone_relay_3", "left" }, { "redstone_relay_4", "left" },
    -- 4 relays with 3 burners
    { "redstone_relay_5", "left" }, { "redstone_relay_5", "right" }, { "redstone_relay_5", "front" },
    { "redstone_relay_6", "left" }, { "redstone_relay_6", "right" }, { "redstone_relay_6", "front" },
    { "redstone_relay_7", "left" }, { "redstone_relay_7", "right" }, { "redstone_relay_7", "front" },
    { "redstone_relay_8", "left" }, { "redstone_relay_8", "right" }, { "redstone_relay_8", "front" },
    -- 2 relays with 2 burners
    { "redstone_relay_9", "left" },  { "redstone_relay_9", "right" },
    { "redstone_relay_10", "left" }, { "redstone_relay_10", "right" },
  },
  FILL_MODE = "sequential",       -- "sequential" = burner 1 to 15, then burner 2...  "even" = spread across all

  -- Manual flying
  THROTTLE_MODE = "spring",       -- "spring": hold W/S, ramps back to 0 on release. "cruise": W/S nudge a setpoint that stays
  RAMP_UP   = 0.25,               -- throttle change per second when speeding up (0.25 = 4 s to full)
  RAMP_DOWN = 0.5,                -- per second when slowing / braking
  MANUAL_YAW = 0.6,               -- differential strength for A/D
  HEADING_HOLD = true,            -- hold heading when A/D released

  -- Altitude (cascade: altitude error -> wanted vertical speed -> lift)
  ALT = { CLIMB_RATE = 2.0, DESC_RATE = 2.0, LAND_RATE = 0.8,  -- m/s
          KP = 0.5,               -- m/s wanted per m of altitude error
          KV = 40,                -- lift steps per m/s of vertical speed error
          KI = 4,                 -- trim learning rate
          LEAD = 1.0,             -- s of momentum allowed for when you let go of Space/Shift
          TRIM_START = 150,       -- first guess at hover lift (learned and saved after)
          MAX_Y = 310 },

  -- Navigation
  NAV = { CRUISE_Y = 120,         -- PLACEHOLDER: safe transit altitude above your terrain
          SEA_LEVEL = 64, DEFAULT_HOVER = 10,
          LAND_HEIGHT = 3,        -- PLACEHOLDER: blocks from the bottom of the ship up to the front computer
          LONG_DIST = 48,         -- trips longer than this climb to cruise altitude first
          AUTO_SPEED = 1.0, MIN_SPEED = 0.15, SLOW_DIST = 40,
          ARRIVE = 4, DOCK_ARRIVE = 1.5, FOLLOW_RADIUS = 6, FOLLOW_TIMEOUT = 6,
          HDG_KP = 0.02, HDG_KD = 0.02, MAX_YAW = 0.6, MAX_TURN_ERR = 50,
          BRAKE_K = 0.3, ETA_EVERY = 3 },

  -- Docking / refuel. All PLACEHOLDERS until measured in-game.
  DOCK = { x = nil, y = nil, z = nil,  -- PLACEHOLDER: front computer GPS position when docked
           heading = nil,              -- PLACEHOLDER: compass heading when docked
           approachHeight = 15,        -- hover this far above the dock before descending
           signal = nil,               -- PLACEHOLDER optional { "relay", "side" } held ON while fuelling
           fuelTime = 30 },            -- PLACEHOLDER seconds to stay for fuelling
}

------------------------------------------------------------------------ HELPERS
local atan2 = math.atan2 or math.atan
local function clamp(x, a, b) return math.max(a, math.min(b, x)) end
local function round(x) return math.floor(x + 0.5) end
local function hdiff(t, c) return (t - c + 180) % 360 - 180 end
local function hdist(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2) end
local function compassTo(a, b) return math.deg(atan2(b.x - a.x, -(b.z - a.z))) % 360 end
local LMAX = #CFG.BURNERS * 15

local function loadT(path, default)
  if not fs.exists(path) then return default end
  local f = fs.open(path, "r"); local t = textutils.unserialize(f.readAll()); f.close()
  return t or default
end
local function saveT(path, t)
  local f = fs.open(path, "w"); f.write(textutils.serialize(t)); f.close()
end

------------------------------------------------------------------------ STATE
local S = {
  mode = "MANUAL",           -- MANUAL | AUTO | LANDED
  pos = nil, alt = nil, vs = 0, vel = { x = 0, z = 0 }, speed = 0, fwd = 0,
  hdg = nil, pitch = 0, turnRate = 0, gpsOK = false, hdgOK = false, gpsFails = 0, hdgFails = 0,
  thr = 0, lift = 0, trim = CFG.ALT.TRIM_START, landBias = 0,
  altT = nil, cruise = 0,
  mission = nil, owner = nil, msg = "starting",
  lastActive = 0, sleeping = false, wakeAt = 0,
  propL = 0, propR = 0,
}
local saved = loadT("trim.db", nil)
if saved and saved.trim then S.trim = saved.trim end
S.lift = S.trim
local WP = loadT("waypoints.db", {})

------------------------------------------------------------------------ OUTPUTS
local relays, outCache = {}, {}
local function R(name)
  relays[name] = relays[name] or peripheral.wrap(name)
  if not relays[name] then error("Redstone relay not found: " .. tostring(name), 0) end
  return relays[name]
end
local function setOut(o, v)
  if not o then return end
  local key = o[1] .. ":" .. o[2]
  if outCache[key] ~= v then outCache[key] = v; R(o[1]).setAnalogOutput(o[2], v) end
end

local function setProp(p, cmd)
  if p.invert then cmd = -cmd end
  local mag = math.abs(cmd)
  if mag < 0.03 then
    setOut(p.fwd, 0); setOut(p.rev, 0); setOut(p.speed, 15)
  else
    setOut(p.speed, clamp(round(15 * (1 - mag)), 0, 14))
    if cmd > 0 then setOut(p.rev, 0); setOut(p.fwd, 15)
    else setOut(p.fwd, 0); setOut(p.rev, 15) end
  end
end

local function setLift(L)
  L = clamp(round(L), 0, LMAX)
  local n = #CFG.BURNERS
  for i, b in ipairs(CFG.BURNERS) do
    local v
    if CFG.FILL_MODE == "even" then
      v = math.floor(L / n) + ((i <= L % n) and 1 or 0)
    else
      v = clamp(L - 15 * (i - 1), 0, 15)
    end
    setOut(b, v)
  end
end

local function propsOff()
  setProp(CFG.PROP.left, 0); setProp(CFG.PROP.right, 0)
  S.thr, S.propL, S.propR = 0, 0, 0
end

local function engineSleep(on)
  if not CFG.ENGINE or S.sleeping == on then return end
  S.sleeping = on
  setOut(CFG.ENGINE, on and 15 or 0)
  if not on then S.wakeAt = os.clock() + CFG.WAKE_DELAY end
end

------------------------------------------------------------------------ COMMS
local function notify(text)
  S.msg = text
  if S.owner then rednet.send(S.owner, { type = "note", text = text }, CFG.PROTO) end
end

------------------------------------------------------------------------ INPUTS
local function readInputs()
  local I = CFG.INPUT
  local function g(o)
    local v = R(o[1]).getAnalogInput(o[2]) / 15
    return v >= CFG.DEADBAND and v or 0
  end
  local t = { fwd = g(I.forward), back = g(I.back), left = g(I.left), right = g(I.right),
              up = g(I.up), down = g(I.down) }
  if CFG.ALT_LEVERS then
    t.coarse = R(I.coarse[1]).getAnalogInput(I.coarse[2])
    t.fine   = R(I.fine[1]).getAnalogInput(I.fine[2])
  end
  return t
end

-- coarse 0..15 and fine 0..15 -> one of 256 heights between LEVER_MIN and LEVER_MAX
local function leverAlt(coarse, fine)
  local idx = coarse * 16 + fine                 -- 0..255
  return CFG.LEVER_MIN + idx * (CFG.LEVER_MAX - CFG.LEVER_MIN) / 255
end

------------------------------------------------------------------------ NAV (GPS + heading)
local navPrev = nil
local function navProcess(front, rear, now)
  if front then
    S.gpsFails = 0
    if navPrev then
      local dt = now - navPrev.t
      if dt > 0.05 then
        local a = 0.5
        local vx, vz = (front.x - navPrev.x) / dt, (front.z - navPrev.z) / dt
        S.vel.x = S.vel.x + a * (vx - S.vel.x)
        S.vel.z = S.vel.z + a * (vz - S.vel.z)
        S.vs = S.vs + a * ((front.y - navPrev.y) / dt - S.vs)
      end
    end
    navPrev = { x = front.x, y = front.y, z = front.z, t = now }
    S.pos = { x = front.x, y = front.y, z = front.z }
    S.alt = front.y
    S.speed = math.sqrt(S.vel.x ^ 2 + S.vel.z ^ 2)
    S.gpsOK = true
  else
    S.gpsFails = S.gpsFails + 1
    if S.gpsFails >= 3 then S.gpsOK = false end
  end

  local ok = false
  if front and type(rear) == "table" then
    local dx, dy, dz = front.x - rear.x, front.y - rear.y, front.z - rear.z
    local h = math.sqrt(dx * dx + dz * dz)
    local len = math.sqrt(h * h + dy * dy)
    local want = math.sqrt(CFG.REAR_BACK ^ 2 + CFG.REAR_UP ^ 2)
    if math.abs(len - want) <= CFG.REAR_TOL then
      local hdg = (math.deg(atan2(dx, -dz)) + CFG.HDG_OFFSET) % 360
      if S.hdg and S.hdgT then
        local dt = now - S.hdgT
        if dt > 0.05 then S.turnRate = S.turnRate + 0.5 * (hdiff(hdg, S.hdg) / dt - S.turnRate) end
      end
      S.hdg, S.hdgT = hdg, now
      S.pitch = math.deg(atan2(dy, h)) - math.deg(atan2(-CFG.REAR_UP, CFG.REAR_BACK))
      ok = true
    end
  end
  if ok then S.hdgFails, S.hdgOK = 0, true
  else
    S.hdgFails = S.hdgFails + 1
    if S.hdgFails >= 3 then S.hdgOK = false end
  end
  if S.hdg then
    local r = math.rad(S.hdg)
    S.fwd = S.vel.x * math.sin(r) - S.vel.z * math.cos(r)
  end
end

local function navTask()
  while true do
    local front, rear
    rednet.send(CFG.REAR_ID, "fix", CFG.HPROTO)
    parallel.waitForAll(
      function()
        local x, y, z = gps.locate(0.5)
        if x then front = { x = x, y = y, z = z } end
      end,
      function()
        local id, m
        repeat id, m = rednet.receive(CFG.HPROTO, 0.6) until id == nil or id == CFG.REAR_ID
        rear = m
      end)
    navProcess(front, rear, os.clock())
    sleep(CFG.NAV_DT)
  end
end

------------------------------------------------------------------------ CONTROL PIECES
local function headingPD(target)
  local err = hdiff(target, S.hdg)
  return clamp(CFG.NAV.HDG_KP * err - CFG.NAV.HDG_KD * S.turnRate, -CFG.NAV.MAX_YAW, CFG.NAV.MAX_YAW)
end

local function rampTo(cur, target, dt)
  local slowing = math.abs(target) < math.abs(cur) or target * cur < 0
  local step = (slowing and CFG.RAMP_DOWN or CFG.RAMP_UP) * dt
  if target > cur then return math.min(target, cur + step) end
  return math.max(target, cur - step)
end

local function altitudeLoop(vsDes, dt, landing)
  if vsDes == nil then
    if not S.altT then S.altT = S.alt end
    vsDes = clamp(CFG.ALT.KP * (S.altT - S.alt), -CFG.ALT.DESC_RATE, CFG.ALT.CLIMB_RATE)
  end
  if vsDes > 0 and S.alt >= CFG.ALT.MAX_Y then vsDes = 0 end
  local e = vsDes - S.vs
  if landing then
    S.landBias = clamp(S.landBias - CFG.ALT.KI * e * dt, 0, S.trim)
  else
    S.landBias = 0
    -- learn hover trim only while roughly holding height, so climbs don't wind it up
    if math.abs(vsDes) <= 0.5 then S.trim = clamp(S.trim + CFG.ALT.KI * e * dt, 0, LMAX) end
  end
  return clamp(S.trim - S.landBias + CFG.ALT.KV * e, 0, LMAX)
end

-- Fly to target x/z. Returns thr, yaw, settled, dist
local function navTo(t, arrive, finalHdg)
  local dist = hdist(S.pos, t)
  if S.navInside then
    if dist > arrive * 2 then S.navInside = false end
  elseif dist < arrive then
    S.navInside = true
  end
  if S.navInside then
    S.navHoldHdg = S.navHoldHdg or S.hdg
    local yaw = headingPD(finalHdg or S.navHoldHdg)
    local thr = clamp(-S.fwd * CFG.NAV.BRAKE_K, -0.4, 0.4)
    return thr, yaw, S.speed < 0.4, dist
  end
  S.navHoldHdg = nil
  local brg = compassTo(S.pos, t)
  local err = hdiff(brg, S.hdg)
  local thr = 0
  if math.abs(err) < CFG.NAV.MAX_TURN_ERR then
    thr = CFG.NAV.AUTO_SPEED * clamp(dist / CFG.NAV.SLOW_DIST, CFG.NAV.MIN_SPEED, 1) * math.cos(math.rad(err))
  end
  return thr, headingPD(brg), false, dist
end

------------------------------------------------------------------------ MISSIONS
local function newMission(kind, target, opts)
  opts = opts or {}
  local M = { kind = kind, target = target, phase = "transit", opts = opts,
              lastUpdate = os.clock(), arrive = CFG.NAV.ARRIVE, name = opts.name }
  local ty = target.y or S.alt
  if opts.dock then
    M.final, M.arrive = "dock", CFG.NAV.ARRIVE
    M.finalAlt = CFG.DOCK.y + CFG.DOCK.approachHeight
  elseif opts.land then
    M.final = "land"
    M.landAlt = target.y and (target.y + CFG.NAV.LAND_HEIGHT) or nil
    M.finalAlt = target.y and (math.max(ty, CFG.NAV.SEA_LEVEL) + CFG.NAV.DEFAULT_HOVER) or S.alt
  else
    M.final = "hover"
    M.finalAlt = opts.exact and ty or (math.max(ty, CFG.NAV.SEA_LEVEL) + (opts.hover or CFG.NAV.DEFAULT_HOVER))
  end
  M.finalAlt = clamp(M.finalAlt, 0, CFG.ALT.MAX_Y)
  if kind == "follow" then M.arrive = CFG.NAV.FOLLOW_RADIUS end
  local far = hdist(S.pos, target) > CFG.NAV.LONG_DIST
  M.transitAlt = clamp(math.max(far and CFG.NAV.CRUISE_Y or 0, M.finalAlt, S.alt), 0, CFG.ALT.MAX_Y)
  return M
end

local function start(M)
  S.mode, S.mission = "AUTO", M
  S.navInside, S.navHoldHdg, S.contactT = false, nil, nil
  S.etaSpeed, S.etaLast, S.etaSent = 0, nil, 0
  S.lastActive = os.clock()
  engineSleep(false)
end

local function startHold(msg)
  if not S.gpsOK then S.mode, S.mission = "MANUAL", nil; return end
  local M = { kind = "hold", target = S.pos, phase = "hold", finalAlt = S.alt, holdHdg = S.hdg, announced = true }
  start(M)
  S.navInside = true
  if msg then notify(msg) end
end

local function touchdown(text)
  S.mode, S.mission = "LANDED", nil
  S.altT = nil
  propsOff()
  notify(text or "Landed")
end

local function enterManual()
  S.mode, S.mission = "MANUAL", nil
  S.altT, S.cruise = nil, 0
  S.manualHdg, S.steerReleased = nil, nil
end

local function sendEta(dist)
  local now = os.clock()
  if S.etaLast then
    local dt = now - S.etaLast.t
    if dt > 0 then S.etaSpeed = S.etaSpeed + 0.3 * ((S.etaLast.d - dist) / dt - S.etaSpeed) end
  end
  S.etaLast = { d = dist, t = now }
  if S.owner and now - S.etaSent >= CFG.NAV.ETA_EVERY then
    S.etaSent = now
    local eta = "--:--"
    if S.etaSpeed > 0.3 then
      local sec = dist / S.etaSpeed
      eta = ("%d:%02d"):format(math.floor(sec / 60), math.floor(sec % 60))
    end
    rednet.send(S.owner, { type = "eta", dist = math.floor(dist), eta = eta,
                           mode = S.mission and S.mission.kind or S.mode }, CFG.PROTO)
  end
end

local function contactCheck(landAlt)
  if landAlt and S.alt > landAlt + 4 then S.contactT = nil return false end
  if S.vs > -0.15 and S.lift < S.trim * 0.6 then
    S.contactT = S.contactT or os.clock()
    return os.clock() - S.contactT > 3
  end
  S.contactT = nil
  return false
end

-- returns thr, yaw, vsDes, liftOverride, landing
local function autopilot(dt)
  local M = S.mission
  if M.kind == "follow" and os.clock() - M.lastUpdate > CFG.NAV.FOLLOW_TIMEOUT then
    startHold("Lost contact with pocket - holding here")
    M = S.mission
  end
  local ph = M.phase

  if ph == "transit" then
    local dist = hdist(S.pos, M.target)
    if M.kind == "follow" then
      S.altT = dist > CFG.NAV.LONG_DIST and math.max(M.finalAlt, CFG.NAV.CRUISE_Y) or M.finalAlt
    else
      S.altT = M.transitAlt
      sendEta(dist)
    end
    if S.alt < S.altT - 8 and dist > CFG.NAV.LONG_DIST then
      S.navHoldHdg = S.navHoldHdg or S.hdg
      return 0, headingPD(S.navHoldHdg)            -- climb before setting off
    end
    local thr, yaw, settled = navTo(M.target, M.arrive)
    if S.navInside and settled and M.kind ~= "follow" then
      M.holdHdg = S.hdg
      if M.final == "hover" then
        M.phase = "hold"
      elseif M.final == "land" then
        M.phase = "descend"; notify("Over target, landing")
      elseif M.final == "dock" then
        M.phase = "approach"; notify("At dock, lining up")
      end
    end
    return thr, yaw

  elseif ph == "hold" then
    S.altT = M.finalAlt
    local thr, yaw = navTo(M.target, CFG.NAV.ARRIVE, M.holdHdg)
    if not M.announced and math.abs(S.alt - M.finalAlt) < 2 then
      M.announced = true
      notify("Arrived" .. (M.name and (" at " .. M.name) or ""))
    end
    return thr, yaw

  elseif ph == "descend" then
    local thr, yaw = navTo(M.target, CFG.NAV.ARRIVE, M.holdHdg)
    local vsDes = (M.landAlt and S.alt > M.landAlt + 6) and -CFG.ALT.DESC_RATE or -CFG.ALT.LAND_RATE
    if contactCheck(M.landAlt) then touchdown("Landed") return 0, 0, nil, 0 end
    return thr, yaw, vsDes, nil, true

  elseif ph == "approach" then
    S.altT = M.finalAlt
    local thr, yaw = navTo(M.target, CFG.NAV.DOCK_ARRIVE, CFG.DOCK.heading)
    local steady = S.navInside and math.abs(S.alt - S.altT) < 1.5 and S.speed < 0.3
                   and math.abs(hdiff(CFG.DOCK.heading, S.hdg)) < 3
    if steady then
      M.steadyT = M.steadyT or os.clock()
      if os.clock() - M.steadyT > 2 then M.phase = "dockdesc"; notify("Docking") end
    else
      M.steadyT = nil
    end
    return thr, yaw

  elseif ph == "dockdesc" then
    local thr, yaw = navTo(M.target, CFG.NAV.DOCK_ARRIVE, CFG.DOCK.heading)
    if S.alt <= CFG.DOCK.y + 0.3 or contactCheck(CFG.DOCK.y + CFG.NAV.LAND_HEIGHT) then
      M.phase, M.fuelStart = "fuel", os.clock()
      propsOff()
      setOut(CFG.DOCK.signal, 15)
      notify("Docked, refuelling")
      return 0, 0, nil, 0
    end
    return thr, yaw, -CFG.ALT.LAND_RATE * 0.6, nil, true

  elseif ph == "fuel" then
    if os.clock() - M.fuelStart >= CFG.DOCK.fuelTime then
      setOut(CFG.DOCK.signal, 0)
      touchdown("Refuelled, docked")
    end
    return 0, 0, nil, 0
  end
  return 0, 0
end

-- returns thr, yaw, vsDes
local function manual(inp, dt)
  local want = inp.fwd - inp.back
  local thr
  if CFG.THROTTLE_MODE == "cruise" then
    S.cruise = clamp(S.cruise + want * CFG.RAMP_UP * dt, -1, 1)
    thr = S.cruise
  else
    thr = want
  end

  local steer = inp.right - inp.left
  local yaw = 0
  if steer ~= 0 or not S.hdgOK or not CFG.HEADING_HOLD then
    yaw = steer * CFG.MANUAL_YAW
    S.steerReleased, S.manualHdg = nil, nil
  else
    S.steerReleased = S.steerReleased or os.clock()
    if os.clock() - S.steerReleased > 0.6 then
      S.manualHdg = S.manualHdg or S.hdg
      yaw = headingPD(S.manualHdg)
    end
  end

  local vsDes
  local climb = inp.up - inp.down
  if climb > 0 then vsDes = climb * CFG.ALT.CLIMB_RATE; S.altT = nil
  elseif climb < 0 then vsDes = climb * CFG.ALT.DESC_RATE; S.altT = nil
  elseif not S.altT and S.alt then S.altT = S.alt + S.vs * CFG.ALT.LEAD end  -- allow for momentum
  return thr, yaw, vsDes
end

------------------------------------------------------------------------ MAIN CONTROL STEP
local lastTrimSave = 0
local function controlStep(dt)
  local now = os.clock()
  local inp = readInputs()
  local anyInput = (inp.fwd + inp.back + inp.left + inp.right + inp.up + inp.down) > 0

  -- Height levers: only a CHANGE counts as a command (so they don't fight the autopilot)
  local leverMoved = false
  if CFG.ALT_LEVERS then
    local key = inp.coarse * 16 + inp.fine
    if S.leverKey == nil then
      S.leverKey = key                              -- first read after boot: no sudden jump
    elseif key ~= S.leverKey then
      S.leverKey, leverMoved = key, true
      S.leverSettle = now                           -- wait for the pilot to finish moving them
    end
    S.leverAlt = leverAlt(inp.coarse, inp.fine)
    if leverMoved then anyInput = true end
  end

  if anyInput then
    S.lastActive = now
    if S.mode ~= "MANUAL" then
      local was = S.mode
      enterManual()
      notify(was == "LANDED" and "Taking off - manual" or "Pilot has control")
    end
  end
  if S.leverSettle and now - S.leverSettle > 0.3 and inp.up == 0 and inp.down == 0 then
    S.leverSettle = nil
    S.altT = clamp(S.leverAlt, 0, CFG.ALT.MAX_Y)
    S.msg = ("Lever height %.0f"):format(S.altT)
  end

  local thr, yaw, vsDes, liftOverride, landing = 0, 0, nil, nil, false
  if S.mode == "MANUAL" then
    thr, yaw, vsDes = manual(inp, dt)
  elseif S.mode == "AUTO" then
    if S.gpsOK and S.hdgOK then
      thr, yaw, vsDes, liftOverride, landing = autopilot(dt)
    elseif not S.navWarned then
      S.navWarned = true
      notify(S.gpsOK and "Heading lost (rear node) - autopilot paused" or "GPS lost - autopilot paused")
    end
    if S.gpsOK and S.hdgOK then S.navWarned = false end
  elseif S.mode == "LANDED" then
    liftOverride = 0
    -- Safety net: if we are actually falling, we weren't on the ground
    if S.gpsOK and S.vs < -1.0 then
      S.fallT = S.fallT or now
      if now - S.fallT > 2 then
        S.fallT = nil
        S.lift = S.trim
        startHold("Not on the ground! Holding altitude")
        liftOverride = nil
      end
    else
      S.fallT = nil
    end
  end

  -- Engine sleep: idle long enough and nothing asking for thrust
  local demand = math.abs(thr) > 0.05 or math.abs(yaw) > 0.15
  if demand then S.lastActive = now end
  if CFG.ENGINE then
    if S.sleeping and (anyInput or demand) then
      engineSleep(false)
      if S.owner then notify("Engine waking") end
    elseif not S.sleeping and now - S.lastActive > CFG.IDLE_SLEEP then
      local phase = S.mission and S.mission.phase
      if S.mode ~= "AUTO" or phase == "hold" or phase == "fuel" then
        propsOff(); engineSleep(true); S.msg = "Engine asleep"
      end
    end
  end
  if S.sleeping or now < S.wakeAt then thr, yaw = 0, 0 end

  -- Propellers (ramped throttle, differential steering)
  S.thr = rampTo(S.thr, thr, dt)
  yaw = yaw * CFG.YAW_SIGN
  local l, r = S.thr + yaw, S.thr - yaw
  local m = math.max(1, math.abs(l), math.abs(r))
  S.propL, S.propR = l / m, r / m
  if not S.sleeping then
    setProp(CFG.PROP.left, S.propL)
    setProp(CFG.PROP.right, S.propR)
  end

  -- Lift
  if liftOverride then
    S.lift = liftOverride
  elseif S.gpsOK and S.alt then
    S.lift = altitudeLoop(vsDes, dt, landing)
  elseif S.mode == "MANUAL" then
    S.lift = clamp(S.lift + (inp.up - inp.down) * LMAX * 0.1 * dt, 0, LMAX)  -- no GPS: direct lift
  end
  setLift(S.lift)

  if now - lastTrimSave > 30 then lastTrimSave = now; saveT("trim.db", { trim = S.trim }) end
end

------------------------------------------------------------------------ COMMAND HANDLER
local function status()
  local M = S.mission
  return ("%s%s alt %s hdg %s spd %.1f %s"):format(
    S.mode, M and ("/" .. M.kind .. ":" .. M.phase) or "",
    S.alt and ("%.0f"):format(S.alt) or "?", S.hdg and ("%.0f"):format(S.hdg) or "?",
    S.speed, S.sleeping and "ENGINE OFF" or "")
end

local function handle(m)
  local c = m.cmd
  if c ~= "follow_pos" and c ~= "status" and c ~= "wp_list" then S.lastActive = os.clock() end

  if c == "status" then return { text = status() } end
  if c == "wp_list" then
    local names = {}
    for k, p in pairs(WP) do names[#names + 1] = ("%s %d %d %d"):format(k, p.x, p.y, p.z) end
    table.sort(names)
    return { text = #names == 0 and "No waypoints" or table.concat(names, "\n") }
  end
  if c == "wp_set" then
    if not (m.name and m.pos) then return { ok = false, text = "Need a name and position" } end
    WP[m.name] = { x = round(m.pos.x), y = round(m.pos.y), z = round(m.pos.z) }
    saveT("waypoints.db", WP)
    local p = WP[m.name]
    return { text = ("Saved %s %d %d %d"):format(m.name, p.x, p.y, p.z) }
  end
  if c == "wp_del" then
    if not WP[m.name] then return { ok = false, text = "No waypoint " .. tostring(m.name) } end
    WP[m.name] = nil; saveT("waypoints.db", WP)
    return { text = "Deleted " .. m.name }
  end

  if c == "follow_pos" and not S.gpsOK then return nil end
  if not S.gpsOK then return { ok = false, text = "Ship has no GPS fix" } end

  if c == "follow_pos" then
    local M = S.mission
    if S.mode == "AUTO" and M and M.kind == "follow" and m.pos then
      M.target, M.lastUpdate = m.pos, os.clock()
      M.finalAlt = clamp(math.max(m.pos.y, CFG.NAV.SEA_LEVEL) + (M.opts.hover or CFG.NAV.DEFAULT_HOVER), 0, CFG.ALT.MAX_Y)
    end
    return nil
  elseif c == "summon" then
    if not m.pos then return { ok = false, text = "No position sent" } end
    if m.follow then
      start(newMission("follow", m.pos, { hover = m.hover }))
      return { text = "Following you" }
    end
    start(newMission("goto", m.pos, { land = m.land, hover = m.hover, exact = m.exact, name = "you" }))
    return { text = ("On my way, %.0f m"):format(hdist(S.pos, m.pos)) }
  elseif c == "goto" then
    local p, name = m.pos, nil
    if m.name then
      p, name = WP[m.name], m.name
      if not p then return { ok = false, text = "No waypoint " .. m.name } end
    end
    if not p then return { ok = false, text = "No destination" } end
    start(newMission("goto", p, { land = m.land, hover = m.hover, exact = m.exact, name = name }))
    return { text = ("Heading to %s, %.0f m"):format(name or "target", hdist(S.pos, p)) }
  elseif c == "refuel" then
    local D = CFG.DOCK
    if not (D.x and D.y and D.z and D.heading) then return { ok = false, text = "Dock not set up yet (CFG.DOCK)" } end
    start(newMission("refuel", { x = D.x, y = D.y, z = D.z }, { dock = true, name = "dock" }))
    return { text = "Heading to dock" }
  elseif c == "land" then
    start(newMission("land", { x = S.pos.x, z = S.pos.z }, { land = true }))
    return { text = "Landing here" }
  elseif c == "takeoff" then
    startHold()
    S.mission.finalAlt = clamp(S.alt + (tonumber(m.height) or 15), 0, CFG.ALT.MAX_Y)
    S.mission.announced = false
    return { text = "Taking off" }
  elseif c == "stop" then
    startHold()
    return { text = "Stopped, holding position" }
  end
  return { ok = false, text = "Unknown command " .. tostring(c) }
end

local function allowed(id)
  if #CFG.ALLOWED == 0 then return true end
  for _, v in ipairs(CFG.ALLOWED) do if v == id then return true end end
  return false
end

local function commsTask()
  while true do
    local id, m = rednet.receive(CFG.PROTO)
    if type(m) == "table" and m.secret == CFG.SECRET and allowed(id) and m.cmd then
      S.owner = id
      local ok, res = pcall(handle, m)
      if not ok then res = { ok = false, text = "Error: " .. tostring(res) } end
      if res then
        rednet.send(id, { type = "reply", ok = res.ok ~= false, text = res.text }, CFG.PROTO)
      end
    end
  end
end

------------------------------------------------------------------------ TASKS
local function controlTask()
  local last = os.clock()
  while true do
    sleep(CFG.DT)
    local now = os.clock()
    controlStep(math.max(0.05, now - last))
    last = now
  end
end

local function screenTask()
  while true do
    term.clear(); term.setCursorPos(1, 1)
    local M = S.mission
    print(("AIRSHIP v1   computer #%d"):format(os.getComputerID()))
    print(("Mode  %s%s"):format(S.mode, M and (" " .. M.kind .. "/" .. M.phase) or ""))
    if S.pos then print(("Pos   %.0f %.0f %.0f"):format(S.pos.x, S.pos.y, S.pos.z)) else print("Pos   NO GPS") end
    print(("Hdg   %s  pitch %.1f  turn %.1f/s"):format(S.hdgOK and ("%.0f"):format(S.hdg) or "LOST", S.pitch, S.turnRate))
    print(("Speed %.1f m/s  fwd %.1f  VS %.2f"):format(S.speed, S.fwd, S.vs))
    print(("Alt target %s  levers %s"):format(S.altT and ("%.0f"):format(S.altT) or "-",
      S.leverAlt and ("%.0f"):format(S.leverAlt) or "-"))
    print(("Lift %d/%d  trim %.0f"):format(round(S.lift), LMAX, S.trim))
    print(("Props L %.2f  R %.2f  thr %.2f"):format(S.propL, S.propR, S.thr))
    print(("Engine %s"):format(S.sleeping and "ASLEEP" or "running"))
    if M and M.target then print(("Target %.0f m away"):format(hdist(S.pos or M.target, M.target))) end
    print("> " .. S.msg)
    sleep(0.5)
  end
end

------------------------------------------------------------------------ SCAN / TEST MODES
local function scanMode()
  local names = {}
  for _, n in ipairs(peripheral.getNames()) do
    if peripheral.getType(n) == "redstone_relay" then names[#names + 1] = n end
  end
  table.sort(names)
  local sides = { "front", "back", "left", "right", "top", "bottom" }
  print(#names .. " redstone relays found. Showing live inputs, Ctrl+T to stop.")
  sleep(2)
  while true do
    term.clear(); term.setCursorPos(1, 1)
    print("Press keys on the controller and watch:")
    for _, n in ipairs(names) do
      local parts = {}
      for _, s in ipairs(sides) do
        local v = peripheral.call(n, "getAnalogInput", s)
        if v > 0 then parts[#parts + 1] = s .. "=" .. v end
      end
      print(n .. ": " .. (#parts > 0 and table.concat(parts, " ") or "-"))
    end
    sleep(0.2)
  end
end

local function testMode()
  print("OUTPUT TEST - ship must be moored/landed.")
  print("Press Enter to start, Ctrl+T to abort.")
  read()
  local function step(label, o, v)
    print(label .. "  (" .. o[1] .. " " .. o[2] .. ")")
    setOut(o, v); sleep(2); setOut(o, v == 15 and 0 or 15)
  end
  if CFG.ENGINE then step("ENGINE SLEEP relay ON (engine should stop)", CFG.ENGINE, 15) end
  for i, b in ipairs(CFG.BURNERS) do step("Burner " .. i .. " full", b, 15) end
  for name, p in pairs(CFG.PROP) do
    print(name .. " prop FORWARD slow"); setProp(p, 0.3); sleep(3); setProp(p, 0)
    print(name .. " prop REVERSE slow"); setProp(p, -0.3); sleep(3); setProp(p, 0)
  end
  print("Test done.")
end

------------------------------------------------------------------------ RUN
local args = { ... }
if _G.__AIRSHIP_TEST then
  return { S = S, CFG = CFG, step = controlStep, nav = navProcess, handle = handle, setOut = setOut }
end
if args[1] == "scan" then return scanMode() end
if args[1] == "test" then return testMode() end

local modem = peripheral.find("modem", function(_, m) return m.isWireless() end)
assert(modem, "Main computer needs a wireless or ender modem")
rednet.open(peripheral.getName(modem))
S.lastActive = os.clock()

while true do
  local ok, err = pcall(parallel.waitForAny, navTask, controlTask, commsTask, screenTask)
  pcall(propsOff)
  saveT("trim.db", { trim = S.trim })
  if not ok and err == "Terminated" then
    term.clear(); term.setCursorPos(1, 1)
    print("Flight computer stopped. Props stopped, burners left as they were.")
    break
  end
  printError("Crashed: " .. tostring(err))
  print("Restarting in 3 s...")
  sleep(3)
  enterManual()
end