local protocol_request = "request0"

-- CONFIG
local min_floor = 0
local max_floor = 5
local columns = 5
-- END CONFIG

local positions = {}
local mon = peripheral.find("monitor")
rednet.open("left")


local function getPosition(x, y)
    return positions[x .. "," .. y]
end

local function setPosition(x, y, v)
    positions[x .. "," .. y] = v
end

local function draw()
    positions = {}

    mon.setTextScale(0.5)
    mon.setBackgroundColor(colors.white)
    mon.setTextColor(colors.black)
    mon.clear()

    mon.setTextColor(colors.black)
    mon.setBackgroundColor(colors.red)

    for f = min_floor, max_floor do
        local x = 1 + 3 * (f % columns)
        local y = 1 + 2 * math.floor(f / columns)
        mon.setCursorPos(x, y)
        mon.write("" .. f)

        local characters = math.floor(math.log(math.max(1, math.abs(f))) / math.log(10))
        if f < 0 then
            characters = characters + 1 -- for 0 or -1, extra character needed
        end

        for j = 0, characters do -- support negative floors
            print("Set " .. f)
            setPosition(x + j, y, f)
        end
    end

    print(textutils.serialize(positions))
end

while (true) do
    draw()

    local ev, side, x, y = os.pullEvent("monitor_touch")

    local floor = getPosition(x, y)
    if floor ~= nil then
        rednet.broadcast(floor, protocol_request)
        print("Clicked floor " .. floor .. ", requested")
    end
end
