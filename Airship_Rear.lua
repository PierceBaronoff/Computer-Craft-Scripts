--[[ AIRSHIP REAR HEADING NODE v1
  Sits 14 blocks behind and 1 block above the main computer, on the ship's centreline.
  Answers "fix" requests from the main computer with its own GPS position.
  Needs a wireless or ender modem.
]]

local MAIN_ID = 0                 -- PLACEHOLDER: main (front) computer ID
local HPROTO  = "airship-hdg"

local modem = peripheral.find("modem", function(_, m) return m.isWireless() end)
assert(modem, "Rear node needs a wireless or ender modem")
rednet.open(peripheral.getName(modem))

term.clear(); term.setCursorPos(1, 1)
print(("Rear heading node #%d, serving main #%d"):format(os.getComputerID(), MAIN_ID))

local served, lastFix = 0, nil
while true do
  local id, msg = rednet.receive(HPROTO)
  if id == MAIN_ID and msg == "fix" then
    local x, y, z = gps.locate(0.5)
    rednet.send(MAIN_ID, x and { x = x, y = y, z = z } or false, HPROTO)
    served = served + 1
    lastFix = x and ("%.1f %.1f %.1f"):format(x, y, z) or "NO GPS FIX"
    term.setCursorPos(1, 3); term.clearLine()
    write(("Fixes sent: %d"):format(served))
    term.setCursorPos(1, 4); term.clearLine()
    write("Last: " .. lastFix)
  end
end