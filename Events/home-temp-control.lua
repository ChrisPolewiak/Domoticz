--
-- Home-Temp-Control
-- Chris Polewiak
--
-- based on https://www.domoticz.com/wiki/EQ3_MAX!#Max_Script
-- 

return {
    active = true,
	on = {
        ['timer'] = { 'every 5 minutes' }
    },    
	logging = {
        level = domoticz.LOG_INFO,
        marker = 'temp-control'
    },
	execute = function(domoticz, item, triggerInfo)

        local function round(num, numDecimalPlaces)
            local mult = 10^(numDecimalPlaces or 0)
            return math.floor(num * mult + 0.5) / mult
        end

        local BoilerSwitchOn = false
        local BoilerSwitchOff = false
        local OutdoorTempToStartHeating = 12    -- If outdoor temperarute below, then override Heating Switch
        local OutdoorTemp_IDX = 197
        
        local BoilerOnPercent = 20              -- percentage valve open at which the boiler will be turned on
        local RadiatorMinToSwitchOnHeating = 100    -- max percentage valve when heating will be enabled
        local HysterysisOffPercent = 20         -- percentage below BoilerOnPercent to switch off the boiler
        local MinValves = 2                     -- Number of Valves that need to be open before boiler is turned on
        local ValvePercentOveride = 100         -- Percentage value of valve open required to override MinValves value (one room is very cold)
        local HolidayMinTemp = 10               -- Minimum room temperature before boiler is turned on during holiday period
        local HolidayHysterysisTemp = 2         -- Value to increase house temperature by while in holiday mode if boiler is turned on due to low temperatures
        local MissingDevicesTime = 86400        -- Value in seconds to allow before reporting a device has not been updated
        local HeatingSwitch_IDX = 142           -- Switch-Heating-Active
        local BoilerSwitch_IDX  = 71            -- Switch-Heating-Furnace
        local HolidaySwitch_IDX = 141           -- Switch-Heating-Holiday

        local AirConditionTempOn = 26.5         -- Temperature when AirCondition will Switch On
        local AirConditionTempOff = 25.5        -- Temperature when AirCondition will Switch Off
        local OfficeTemp_IDX = 160              -- IDX of Temp Sensor in Office
        local AirConditionSwitch_IDX = 270      -- IDX of Switch AirCondition Switch On

        local WindowSensorKitchen01 = 153       -- Window-Kitchen-Sensor01
        local WindowSensorMainDoor = 152        -- Door-Main-Sensor01
        local WindowSensorSleeping01 = 151      -- Window-Sleeping-Sensor01
        local WindowSensorSalon01 = 7           -- Window-Salon-Sensor01
        local WindowSensorMichal01 = 189        -- Window-Salon-Sensor01

        local Sensor2Valve = {
            Kitchen = {
                IDX = 153,  -- DoorSensor-Kitchen01
                Valves = {
                    172,    -- Climate-KitchenFloor-Valve
                    262,    -- Climate-Salon1-Valve
                    263,    -- Climate-Salon2-Valve
                }
            },
            Maciek = {
                IDX = 191,  -- DoorSensor-Maciek01
                Valves = {
                    248,    -- Climate-Maciej-Valve
                }
            },
            Michal = {
                IDX = 189,  -- DoorSensor-Michal01
                Valves = {
                    250,    -- Climate-Michal-Valve
                }
            },
            SalonDoor02 = {
                IDX = 190,  -- DoorSensor-Salon02
                Valves = {
                    172,    -- Climate-KitchenFloor-Valve
                    262,    -- Climate-Salon1-Valve
                    263,    -- Climate-Salon2-Valve
                }
            },
            SalonDoorTerrace01 = {
                IDX = 7,    -- DoorSensor-SalonTerrace01
                Valves = {
                    172,    -- Climate-KitchenFloor-Valve
                    262,    -- Climate-Salon1-Valve
                    263,    -- Climate-Salon2-Valve
                }
            },
            Bedroom = {
                IDX = 151,   -- DoorSensor-Sleeping01
                Valves = {
                    252,    -- Climate-Bedroom-Valve
                }
            },
        }

        local FloorHeating = {
            Kitchen = {
                Stat_IDX = 173,                 -- Climate-KitchenFloor-Stat
                Temp_IDX = 96,                  -- Climate-KitchenFloor-Temp
                --Temp_IDX = 196,                  -- Climate-KitchenFloor-Temp
                Valve_IDX = 172,                -- Climate-KitchenFloor-Valve
                FloorHeatingSwitch_IDX = 217,        -- Switch-Heating-KitchenFloor
                HeatingDifference = 2,          -- Difference from max temp when turn off heating
            },
            Toilet = {
                Stat_IDX = 243,                 -- Climate-KitchenFloor-Stat
                Temp_IDX = 241,                 -- Climate-KitchenFloor-Temp
                --Temp_IDX = 238,                 -- Climate-KitchenFloor-Temp
                Valve_IDX = 244,                -- Climate-KitchenFloor-Valve
                FloorHeatingSwitch_IDX = 171,        -- Switch-Heating-KitchenFloor
                HeatingDifference = 2,          -- Difference from max temp when turn off heating
            },
            Bathroom = {
                Stat_IDX = 186,                 -- Climate-BathroomFloor-Stat
                Temp_IDX = 93,                  -- Climate-BathroomFloor-Temp
                --Temp_IDX = 195,                  -- Climate-BathroomFloor-Temp
                Valve_IDX = 185,                -- Climate-BathroomFloor-Valve
                FloorHeatingSwitch_IDX = 184,        -- Switch-Heating-BathroomFloor
                HeatingDifference = 2,          -- Difference from max temp when turn off heating
            }
        }

--
-- Logic for manage Air Condition
--
        domoticz.log('##### Logic: Air Condition ----------', domoticz.LOG_DEBUG)
        office_temp = domoticz.devices( OfficeTemp_IDX ).temperature
        domoticz.log('AirCondition: Current: ' .. office_temp .. ', Turn On: ' .. AirConditionTempOn .. ', Turn Off: ' .. AirConditionTempOff, domoticz.LOG_DEBUG)
        if ( office_temp > AirConditionTempOn ) then
            if ( domoticz.devices( AirConditionSwitch_IDX )._state == 'On' ) then
                domoticz.log('Current Temp: ' .. office_temp .. ' > ' .. AirConditionTempOn .. ' -- Turn AirCondition On', domoticz.LOG_INFO)
            end
        elseif ( office_temp < AirConditionTempOff ) then
            if ( domoticz.devices( AirConditionSwitch_IDX )._state == 'Off' ) then
                domoticz.log('Current Temp: ' .. office_temp .. ' < ' .. AirConditionTempOff .. ' -- Turn AirCondition Off', domoticz.LOG_INFO)
            end
        end


--
-- Logic to checking VALVES in the rooms to override WindowOpenedStatus for heating in some situations
--
        domoticz.log('##### Logic: Checking Window Status ----------', domoticz.LOG_DEBUG)
        local WindowOpenedStatus = false
        for sensorName, sensorData in pairs(Sensor2Valve) do
            domoticz.log('sensorName=' .. sensorName .. ', IDX=' .. sensorData.IDX .. ', state=' .. domoticz.devices( sensorData.IDX )._state, domoticz.LOG_DEBUG)

            if ( domoticz.devices( sensorData.IDX )._state == 'Open' ) then

                for ID, valveIDX in pairs(sensorData.Valves) do
                    domoticz.log('Window: ' .. sensorName .. ' opened, valve ' .. valveIDX .. ':' .. domoticz.devices( valveIDX ).percentage .. '%', domoticz.LOG_DEBUG)

                    if ( domoticz.devices( valveIDX ).percentage < RadiatorMinToSwitchOnHeating ) then
                        domoticz.log('Window ' .. sensorName .. ' are opened, valve ' .. valveIDX .. ': ' .. domoticz.devices( valveIDX ).percentage .. '% > ' .. RadiatorMinToSwitchOnHeating .. '%', domoticz.LOG_INFO)
                        WindowOpenedStatus = true
                    end
                end
            end
        end

--
-- Logic to manage floor heating.
-- Switch on/off valves by scheduler and sensor requirements
--
        domoticz.log('##### Logic: Floor Heating ----------', domoticz.LOG_DEBUG)
        for deviceName, deviceData in pairs(FloorHeating) do

            temperature = tonumber( domoticz.devices( deviceData['Temp_IDX'] ).temperature )
            thermostat  = tonumber( domoticz.devices( deviceData['Stat_IDX'] ).setPoint )
            
            if ( temperature < thermostat ) then
                domoticz.log('' .. deviceName .. ' floor Temperature ' .. round(temperature,1) .. 'C < ' .. thermostat .. 'C, switch On', domoticz.LOG_DEBUG)

                if ( domoticz.devices( HolidaySwitch_IDX )._state == 'Off') then -- Not on holiday
                    if ( domoticz.devices( HeatingSwitch_IDX )._state == 'On') then -- It's time to heat the house
            
                        if ( domoticz.devices( deviceData['FloorHeatingSwitch_IDX'] )._state == 'Off') then
                            domoticz.log('' .. deviceName .. ' floor Temperature ' .. round(temperature,1) .. 'C < ' .. thermostat .. 'C, switch On', domoticz.LOG_INFO)
                            domoticz.devices( deviceData['FloorHeatingSwitch_IDX'] ).switchOn()
                            domoticz.devices( deviceData['Valve_IDX'] ).updatePercentage( 50 )
                        end    
                    end
                end
            
            elseif ( (temperature + deviceData['HeatingDifference']) > thermostat ) then
                domoticz.log('' .. deviceName .. ' floor Temperature ' .. round(temperature,1) .. 'C > ' .. thermostat .. 'C, switch Off', domoticz.LOG_DEBUG)
                if ( domoticz.devices( deviceData['FloorHeatingSwitch_IDX'] )._state == 'On') then
                    domoticz.log('' .. deviceName .. ' floor Temperature ' .. round(temperature,1) .. 'C < ' .. thermostat .. 'C, switch On', domoticz.LOG_INFO)
                    domoticz.devices( deviceData['FloorHeatingSwitch_IDX'] ).switchOff()
                    domoticz.devices( deviceData['Valve_IDX'] ).updatePercentage( 0 )
                end
            end
        end

        PercentMax = 0
        TempMin = 10
        ValveCount = 0

--
-- Read valves status
--
        domoticz.log('##### Logic: Read Valves ----------', domoticz.LOG_DEBUG)
        local myDevice = domoticz.devices().forEach( function(device) -- Get all devices in the database
            v = device.name:sub(-6,-1) -- Grab the last six characters of the device name
            
            if (v == '-Valve') then
                -- are the last four characters "-Valve"? If so we have a Radiator Valve
                RoomName = device.name:sub(1,-7) -- Get the rest of the name, which will be the room name
                RoomName = RoomName:sub(9)

                sValvePercentOpen = tonumber(device.percentage)

                -- get the % value of the most open Radiator Valve
                if ( sValvePercentOpen > PercentMax ) then
                    PercentMax = sValvePercentOpen
                end

                -- Count the number of valves that are open more than BoilerOnPercent
                if ( sValvePercentOpen >= BoilerOnPercent ) then
                    ValveCount = ValveCount + 1
                end
                
                domoticz.log('Valve: ' .. RoomName .. ' ' .. sValvePercentOpen .. '%', domoticz.LOG_DEBUG)
            end
        end)

--
-- Read thermostat status
--
        domoticz.log('##### Logic: Read Thermostats ----------', domoticz.LOG_DEBUG)
        local myDevice = domoticz.devices().forEach( function(device) -- Get all devices in the database
            v = device.name:sub(-5,-1) -- Grab the last five characters of the device name

            if (v == '-Stat') then
                -- are the last five characters "-Stat "? If so we have an EQ-3 Thermostat
                RoomName = device.name:sub(1,-6) -- Get the rest of the name, which will be the room name
                RoomName = RoomName:sub(9)

                sTemp = device.setPoint -- get the temperature   
                domoticz.log('' .. RoomName .. ' thermostat is ' .. sTemp .. ' C', domoticz.LOG_DEBUG)
             
                -- get the lowest temperature of the thermostats
                if (sTemp < TempMin) then
                    TempMin = tonumber(sTemp)
                end
            end
        end)

        domoticz.log('Highest valve open value is ' .. PercentMax .. '% ', domoticz.LOG_DEBUG)
        domoticz.log('Lowest thermostat reading is ' .. TempMin .. 'C ', domoticz.LOG_DEBUG)

        if ( domoticz.devices( BoilerSwitch_IDX )._state == 'On') then
            domoticz.log('Current state - Boiler is ON ', domoticz.LOG_DEBUG)
        else
            domoticz.log('Current state - Boiler is OFF ', domoticz.LOG_DEBUG)
        end       
        if ( domoticz.devices( HeatingSwitch_IDX )._state == 'On') then
            domoticz.log('Current state - Heating is allowed ', domoticz.LOG_DEBUG)
        else
            domoticz.log('Current state - Heating is denied ', domoticz.LOG_DEBUG)
        end       

--
-- Logging result of logic for debuggin
--
        domoticz.log('PercentMax = ' .. PercentMax .. '%. ' .. 'Boiler switch On on value >= ' .. BoilerOnPercent .. '%. ' .. 'Boiler Off on value <= ' .. (BoilerOnPercent - HysterysisOffPercent) .. '% ', domoticz.LOG_DEBUG)
        domoticz.log('Number of valves opened more than ' .. BoilerOnPercent .. '% is ' .. ValveCount .. '. Minimum valves required ' .. MinValves .. '.', domoticz.LOG_DEBUG)
        domoticz.log('Maximum open value ' .. PercentMax .. '%' .. '. Override value is ' .. ValvePercentOveride .. '%', domoticz.LOG_DEBUG)

        BoilerSwitchOn = false
        BoilerSwitchOff = true

--
-- Main logic to start heating with verification several sensors
--
        domoticz.log('##### Logic: Perform analytics ----------', domoticz.LOG_DEBUG)
        -- Not on holiday
        domoticz.log('- Check: Is Holiday = ' .. domoticz.devices( HolidaySwitch_IDX )._state .. ', and ...', domoticz.LOG_INFO)
        if ( domoticz.devices( HolidaySwitch_IDX )._state == 'Off') then

            -- If all Windows are closed
            domoticz.log('- Check: Are Windows opened = ' .. tostring(WindowOpenedStatus) .. ', and ...', domoticz.LOG_INFO)
            if ( WindowOpenedStatus == false ) then

                -- If heating enabled
                domoticz.log('- Check: Is Heating enabled = ' .. domoticz.devices( HeatingSwitch_IDX )._state .. ' or ...', domoticz.LOG_INFO)
                domoticz.log('- Check: Outdoor temperature ' .. domoticz.devices( OutdoorTemp_IDX ).temperature .. ' is below ' .. OutdoorTempToStartHeating .. ', and ...', domoticz.LOG_INFO)
                if ( domoticz.devices( HeatingSwitch_IDX )._state == 'On'
                     or domoticz.devices( OutdoorTemp_IDX ).temperature < OutdoorTempToStartHeating
                    ) then

                    if (ValveCount >= MinValves) then
                        domoticz.log('- Check: Valves amount opened: ' .. ValveCount .. ' >= ' .. MinValves .. ' required', domoticz.LOG_INFO)
                        BoilerSwitchOn = true
                        BoilerSwitchOff = false
                    end     

                    if (PercentMax >= ValvePercentOveride) then
                        domoticz.log('- Check: Single valve threshold: ' .. PercentMax .. '% >= ' .. BoilerOnPercent .. '% required', domoticz.LOG_INFO)
                        BoilerSwitchOn = true
                        BoilerSwitchOff = false
                    end     

                end
            end

--[[
            -- If the number of valves open more than BoilerOnPercent minus HysterysisOffPercent        
            if (PercentMax < (BoilerOnPercent - HysterysisOffPercent) or (ValveCount < MinValves)) and ( domoticz.devices( BoilerSwitch_IDX)._state == 'On') then
                BoilerSwitchOn = false
                BoilerSwitchOff = true
            end
]]--

        else -- on holiday
            domoticz.log('Holiday Mode', domoticz.LOG_INFO)
            if ( TempMin <= HolidayMinTemp ) and ( domoticz.devices( BoilerSwitch_IDX )._state == 'Off' ) then  -- house is very cold
                domoticz.log('Overall temperature is to low', domoticz.LOG_INFO)
                BoilerSwitchOn = true
                BoilerSwitchOff = false
            end
         
            if ( TempMin >= (HolidayMinTemp + HolidayHysterysisTemp)) and ( domoticz.devices( BoilerSwitch_IDX )._state == 'On' ) then  -- house is warm enough
                domoticz.log('Overall temperature over limit', domoticz.LOG_INFO)
                BoilerSwitchOn = false
                BoilerSwitchOff = true
            end
        end

        if ( BoilerSwitchOn ) then
            if ( domoticz.devices( BoilerSwitch_IDX )._state == 'Off') then
                domoticz.devices( BoilerSwitch_IDX ).switchOn()
                domoticz.log('Turn On Boiler', domoticz.LOG_INFO)
            end
        elseif ( BoilerSwitchOff ) then
            if ( domoticz.devices( BoilerSwitch_IDX )._state == 'On') then
                domoticz.devices( BoilerSwitch_IDX ).switchOff()
                domoticz.log('Turn Off Boiler', domoticz.LOG_INFO)
            end
        end
    
    end
}
