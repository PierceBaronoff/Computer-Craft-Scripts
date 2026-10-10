-- hello.lua
-- Example script so the setup menu has something to show.

print("Hello from the Script Hub!")
print("Computer #" .. os.getComputerID() .. (os.getComputerLabel() and (" (" .. os.getComputerLabel() .. ")") or ""))
