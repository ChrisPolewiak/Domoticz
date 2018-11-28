--
-- Measure-Work-Times
-- Chris Polewiak
-- version 1 - measure time when switches are active
--

-- Preset Values
commandArray = {}

local function update(dev, value )
    local cmd = string.format("%d|0|%.2f", otherdevices_idx[dev], value)
--    print('device:' .. dev .. ', value:' .. value )
    table.insert (commandArray, { ['UpdateDevice'] = cmd } )
end

-- Get Data from Timered Items
for i, v in pairs(otherdevices) do
    -- Get all devices in the database
    dtest = i:sub(-6,-1)
    if (dtest == '-Timer') then
        devicename = i:sub(0,-7)

        if ( otherdevices[devicename] ~= nil) then

            update(devicename .. '-Timer', 0 )
            if otherdevices[devicename] == 'On' then
                turnedonval = tonumber(otherdevices[devicename .. '-Timer']) + 1
                update(devicename .. '-Timer', turnedonval)
                print('Device: ' .. devicename .. ' is actually turned On for ' .. turnedonval .. ' minutes')
            end

        end

    end
end

return commandArray

