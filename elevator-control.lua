local protocol_floor = "floor0"
local protocol_request = "request0"

-- CONFIG PARAMETERS
local clutch = "left"
local clutch_mask = false -- (true|false) XOR Mask applied to value of clutch (needed if direction is reversed)
local gearbox = "right"
local gearbox_mask = -1 -- (1 | -1) Multiplicative mask applied to value of gearbox (needed if direction is reversed)
local modem = "back"
local min_floor = 0
local max_floor = 4
local min_stop_time = 5 -- min stop time at a floor in seconds
-- END CONFIG PARAMETERS


-- TRACKING VARIABLES, used to keep track of the position of the elevator
-- Number of last floor encountered.
-- Floor numbers are monotonically increasing from lowest to highest floor.
local floor = min_floor
-- count of floors ofc
local floor_count = max_floor - min_floor + 1
-- 1 if going up, 0 if stopped, -1 if going down
local movement = 0
-- current target
local target_floor = nil
-- initialize floor requests to false
local floors = {}
for i = min_floor, max_floor do
    floors[i] = false
end

-- Returns the closest requested floor number, or nil
local function closest_requested()
    for i = 0, floor_count do
        if floors[floor + i] then
            return floor + i
        elseif floors[floor - i] then
            return floor - i
        end
    end

    return nil
end

local function setStopped(stopped) redstone.setOutput(clutch, stopped ~= clutch_mask) end

-- GEARBOX/CLUTCH FUNCTIONS, to move the elevator
local function setMovement(movement)
    local dir = movement * gearbox_mask
    if dir == 1 then
        redstone.setOutput(gearbox, true)
        setStopped(false)
    elseif dir == -1 then
        redstone.setOutput(gearbox, false)
        setStopped(false)
    else
        setStopped(true)
    end
end

-- Start moving towards the wanted floor, or do nothing if already there (don't stop! What if in between floors?)
local function move_to(target)
    if floor < target then
        print("Moving UP to floor " .. target)
        setMovement(1)
    elseif floor > target then
        print("Moving DOWN floor " .. target)
        setMovement(-1)
    end
end

local function choose_target_floor_ifn()
    -- Choose target floor if not yet chosen and start moving
    if target_floor == nil then
        local n = closest_requested()
        if n ~= nil then
            target_floor = n
            print("Chosen new target floor " .. n)
        end
    end
end

-- REDNET functions to communicate with floor stations
rednet.open(modem)




-- Handle a "floor request" event
local function handle_req()
    while (true) do
        local id, f = rednet.receive(protocol_request)

        -- skip if number is wrong
        if not (f < min_floor or f > max_floor) then
            print("Requested floor " .. f)

            floors[f] = true -- simply set floor value to true

            choose_target_floor_ifn()
            move_to(target_floor)
        end
    end
end

-- Handle a "floor reached" event
local function handle_floor()
    while (true) do
        local id, f = rednet.receive(protocol_floor)
        print("Reached floor " .. f)

        -- check floor valid
        if not (f < min_floor or f > max_floor) then
            -- handle case where the world was shut down with a moving elevator.
            -- Stop if at the first station reached
            if target_floor == nil then
                setMovement(0)
            end

            floor = f
            -- If target floor, unset target floor. Otherwise default stuff
            if f == target_floor then
                floors[f] = false -- unset req and remove target floor
                target_floor = nil
                setMovement(0)
                print("Stopped at target floor")
                choose_target_floor_ifn()
                if target_floor ~= nil then
                    sleep(min_stop_time)
                    move_to(target_floor)
                end
            elseif floors[f] then
                floors[f] = false
                setMovement(0)
                print("Stopped at floor " .. f)
                sleep(min_stop_time)
                move_to(target_floor)
            end
        end
    end
end

print("Waiting for requests...")

-- Program loop
while (true) do
    parallel.waitForAny(handle_req, handle_floor)
end
