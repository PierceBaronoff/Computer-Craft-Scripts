-- hello.lua
-- Example script so the setup menu has something to show.

-- Check for updates first (reboots if this script changed).
if fs.exists("/update.lua") then shell.run("/update.lua", "--check") end

print("Hello from the Script Hub!")
print("Computer #" .. os.getComputerID() .. (os.getComputerLabel() and (" (" .. os.getComputerLabel() .. ")") or ""))
