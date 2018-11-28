--
-- Window-Open-When-Cold
-- Chris Polewiak
-- version 1 - detect when window or doors are opened
--

-- Preset Values
commandArray = {}

min_time_window_open_to_close_heating = 5
window_opened_val = 0
printDebug = false

local function update(dev, value )
    local cmd = string.format("%d|0|%.2f", otherdevices_idx[dev], value)
    table.insert (commandArray, { ['UpdateDevice'] = cmd } )
end

window_opened = false

if(printDebug) then
    print('Window Opened Check')
end

if (otherdevices['Window-Kitchen-Sensor01'] == 'Open') then
    window_opened = true
end
if (otherdevices['Door-Main-Sensor01'] == 'Open') then
    window_opened = true
end
if (otherdevices['Window-Bedroom-Sensor01'] == 'Open') then
    window_opened = true
end
if (otherdevices['Window-Salon-Sensor01'] == 'Open') then
    window_opened = true
end

update('Window-Opened-Status', 0 )
if ( window_opened ) then

    if(printDebug) then
        print('-- main loop')
    end

    window_opened_val = tonumber(otherdevices['Window-Opened-Status']) + 1

    if(printDebug) then
        print('-- window_opened_val = ' .. window_opened_val)
    end

    update('Window-Opened-Status', window_opened_val)

    if ( window_opened_val >= min_time_window_open_to_close_heating ) then

        if(printDebug) then
            print('-- Heating turning Off')
        end

        -- If Heating is turned on - turn it off
        if ( otherdevices['Switch-Heating-Furnace'] == 1 ) then
            commandArray['Switch-Heating-Furnace']='Off'
        end

    end

end

return commandArray
