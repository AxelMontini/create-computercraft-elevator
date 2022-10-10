local protocol_floor = "floor0"
local protocol_request = "request0"

-- CONFIG
local contact = "back"
local floor = 0
local text_color = colors.black
local button_text_color = colors.white
local button_bg_color = colors.black
local bg_color_called = colors.green
local bg_color = colors.lightGray
--END CONFIG

local called = false
local current = 0

local mon = peripheral.find("monitor")
rednet.open("right")

local function broadcast_floor()
    current = floor
    rednet.broadcast(floor, protocol_floor)
end

local function request_floor()
    rednet.broadcast(floor, protocol_request)
end

local function draw()
    print("DRAW")
    if called then
        mon.setBackgroundColor(bg_color_called)
    else
        mon.setBackgroundColor(bg_color)
    end
    mon.clear()
    mon.setTextScale(1)
    mon.setCursorPos(1, 3)
    mon.setTextColor(button_text_color)
    mon.setBackgroundColor(button_bg_color)
    mon.write("CALL " .. floor)
    mon.setCursorPos(3, 1)
    mon.setTextColor(text_color)
    mon.setBackgroundColor(bg_color)
    mon.write("AT " .. current)
end

local function sleep1() sleep(5) end

local function wait_for_redstone_event() os.pullEvent("redstone") end

local function handle_reached_floor()
    local id, f = rednet.receive(protocol_floor)
    current = f
    print("Elevator reached floor " .. f)
    draw()
end

local function handle_call_click()
    local ev, side, x, y = os.pullEvent("monitor_touch")
    -- CALL BUTTON
    if y == 3 then
        print("Pressed CALL button")
        request_floor() -- req controller through rednet
        called = true
        draw()
        sleep(3)
    end
end

while true do
    if redstone.getInput(contact) then
        broadcast_floor()
        print("Elevator reached this floor")
    end
    draw()
    parallel.waitForAny(wait_for_redstone_event, sleep1, handle_reached_floor, handle_call_click)
    called = false
end
