local protocol_floor = "floor0"
local protocol_request = "request0"

-- CONFIG
local contact = "back"
local floor = 0
--END CONFIG

rednet.open("right")

local function broadcast_floor()
    rednet.broadcast(floor, protocol_floor)
end

local function sleep1() sleep(1) end

local function wait_for_redstone_event() os.pullEvent("redstone") end

while true do
    if redstone.getInput(contact) then
        broadcast_floor()
        print("Elevator reached this floor")
    end

    parallel.waitForAny(wait_for_redstone_event, sleep1)
end
