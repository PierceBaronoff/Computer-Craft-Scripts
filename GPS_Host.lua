local f = "gpspos"
if not fs.exists(f) then
  write("This computer's X Y Z: ")
  local h = fs.open(f, "w"); h.write(read()); h.close()
end
local h = fs.open(f, "r"); local s = h.readAll(); h.close()
local x, y, z = s:match("(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)")
shell.run("gps", "host", x, y, z)