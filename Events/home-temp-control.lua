--
-- Home-Temp-Control
-- Chris Polewiak
--
-- based on https://www.domoticz.com/wiki/EQ3_MAX!#Max_Script
-- 
-- v. 2.00

return {
    active = true,
	on = {
        ['timer'] = { 'every 10 minutes' }
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
        local OutdoorTempToStartHeating = 15    -- If outdoor temperarute below, then override Heating Switch
        local OutdoorTemp_IDX = 197
        
        local BoilerOnPercent = 30              -- percentage valve open at which the boiler will be turned on
        local RadiatorMinToSwitchOnHeating=100  -- max percentage valve when heating will be enabled
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

        local Valve2WindowSensor = {
            Salon01 = { IDX = 262,
                Sensors = {
                    153,            -- DoorSensor-Kitchen01
                    152,            -- DoorSenser-Enterance
                    190,            -- SalonTerrace01
                    7,              -- SalonTerrace02
                }
            },
            Salon02 = { IDX = 263,
                Sensors = {
                    153,            -- DoorSensor-Kitchen01
                    152,            -- DoorSenser-Enterance
                    190,            -- SalonTerrace01
                    7,              -- SalonTerrace02
                }
            },
            KitchenFloor = { IDX = 172,
                Sensors = {
                    153,            -- DoorSensor-Kitchen01
                    152,            -- DoorSenser-Enterance
                    190,            -- SalonTerrace01
                    7,              -- SalonTerrace02
                }
            },
            Toilet = { IDX = 260, Sensors = { 0 } },
            ToiletFloor = { IDX = 244, Sensors = { 0 } },
            BathroomFloor = { IDX = 185, Sensors = { 0 } },
            Garage = { IDX = 258, Sensors = { 0 } },
            Laundry = { IDX = 265, Sensors = { 0 } },
            Office = { IDX = 256, Sensors = { 294 } },
            Michal = { IDX = 250, Sensors = { 189 } },
            Maciek = { IDX = 248, Sensors = { 191 } },
            Jakub = { IDX = 254, Sensors = { 293 } },
            Bathroom = { IDX = 245, Sensors = { 0 } },
            Bedroom = { IDX = 252, Sensors = { 151 } },
        }

        local FloorHeating = {
            Kitchen = {
                Stat_IDX = 173,                 -- Climate-KitchenFloor-Stat
                Temp_IDX = 96,                  -- Climate-KitchenFloor-Temp
                Valve_IDX = 172,                -- Climate-KitchenFloor-Valve
                FloorHeatingSwitch_IDX = 217,   -- Switch-Heating-KitchenFloor
                HeatingDifference = 3,          -- Difference from max temp when turn off heating
            },
            Toilet = {
                Stat_IDX = 243,                 -- Climate-KitchenFloor-Stat
                Temp_IDX = 237,                 -- Climate-KitchenFloor-Temp
                Valve_IDX = 244,                -- Climate-KitchenFloor-Valve
                FloorHeatingSwitch_IDX = 171,   -- Switch-Heating-KitchenFloor
                HeatingDifference = 4,          -- Difference from max temp when turn off heating
            },
            Bathroom = {
                Stat_IDX = 186,                 -- Climate-BathroomFloor-Stat
                Temp_IDX = 93,                  -- Climate-BathroomFloor-Temp
                Valve_IDX = 185,                -- Climate-BathroomFloor-Valve
                FloorHeatingSwitch_IDX = 184,   -- Switch-Heating-BathroomFloor
                HeatingDifference = 5,          -- Difference from max temp when turn off heating
            }
        }

--
-- Logic for manage Air Condition
--
        domoticz.log('##### Logic: Air Condition ----------', domoticz.LOG_DEBUG)
        office_temp = round( domoticz.devices( OfficeTemp_IDX ).temperature, 1 )
        domoticz.log('AC: Current: ' .. office_temp .. ', Turn On: ' .. AirConditionTempOn .. ', Turn Off: ' .. AirConditionTempOff, domoticz.LOG_INFO)
        if ( office_temp > AirConditionTempOn ) then
            domoticz.log('AC: Current Temp: ' .. office_temp .. ' > ' .. AirConditionTempOn .. ' -- Turn AirCondition On', domoticz.LOG_INFO)
--          if ( domoticz.devices( AirConditionSwitch_IDX )._state == 'Off' ) then
                domoticz.devices( AirConditionSwitch_IDX ).switchOn()forMin( 60 )
--          end
        elseif ( office_temp < AirConditionTempOff ) then
--            domoticz.log('Current Temp: ' .. office_temp .. ' < ' .. AirConditionTempOn .. ' -- Turn AirCondition force Off', domoticz.LOG_INFO)
          if ( domoticz.devices( AirConditionSwitch_IDX )._state == 'On' ) then
                domoticz.log('AC: Current Temp: ' .. office_temp .. ' < ' .. AirConditionTempOff .. ' -- Turn AirCondition Off', domoticz.LOG_INFO)
                domoticz.devices( AirConditionSwitch_IDX ).switchOff()
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
                if ( domoticz.devices( deviceData['FloorHeatingSwitch_IDX'] )._state == 'Off') then
                    domoticz.log('' .. deviceName .. ' floor Temperature ' .. round(temperature,1) .. 'C < ' .. thermostat .. 'C, switch On', domoticz.LOG_INFO)
                    domoticz.devices( deviceData['FloorHeatingSwitch_IDX'] ).switchOn()
                    domoticz.devices( deviceData['Valve_IDX'] ).updatePercentage( 50 )
                end
            
            elseif ( (temperature + deviceData['HeatingDifference']) > thermostat ) then
                if ( domoticz.devices( deviceData['FloorHeatingSwitch_IDX'] )._state == 'On') then
                    domoticz.log('' .. deviceName .. ' floor Temperature ' .. round( (temperature+deviceData['HeatingDifference']) ,1) .. 'C > ' .. thermostat .. 'C, switch Off', domoticz.LOG_INFO)
                    domoticz.devices( deviceData['FloorHeatingSwitch_IDX'] ).switchOff()
                    domoticz.devices( deviceData['Valve_IDX'] ).updatePercentage( 0 )
                end
            end
        end


--
-- Logic to checking VALVES
--
        PercentMax = 0
        TempMin = 0
        ValveCount = 0

        domoticz.log('##### Logic: Checking Valves and Sensor Status ----------', domoticz.LOG_DEBUG)
        -- check All Door Sensors matched with Valves

        for valveName, valveData in pairs( Valve2WindowSensor ) do
            sValvePercentOpen = tonumber( domoticz.devices( valveData.IDX ).percentage )

            domoticz.log('-- valve : ' .. valveName .. '(' .. valveData.IDX .. '), percentage=' .. sValvePercentOpen .. '%', domoticz.LOG_DEBUG)

            -- get the % value of the most open Radiator Valve
            if ( sValvePercentOpen > PercentMax ) then
                PercentMax = sValvePercentOpen
            end

            -- Count the number of valves that are open more than BoilerOnPercent
            if ( sValvePercentOpen >= BoilerOnPercent ) then

                WindowClosedStatus = true

                for ID, sensorId in pairs( valveData.Sensors ) do
                    if ( sensorId > 0 ) then
                        domoticz.log('   sensor: ' .. domoticz.devices( sensorId ).name .. '(' .. sensorId .. '), state=' .. domoticz.devices( sensorId )._state, domoticz.LOG_DEBUG)

                        if ( domoticz.devices( sensorId )._state == 'Open' ) then
                            WindowClosedStatus = false
                        end
                    end
                end

                if ( WindowClosedStatus ) then
                    ValveCount = ValveCount + 1
domoticz.log('ValveCount: ' .. ValveCount, domoticz.LOG_DEBUG)
                end

            end

        end

--
-- Logging result of logic for debuggin
--
        domoticz.log('Summary: Current boiler status = ' .. domoticz.devices( BoilerSwitch_IDX )._state, domoticz.LOG_INFO)
        domoticz.log('Summary: Number of valves opened more than ' .. BoilerOnPercent .. '% is ' .. ValveCount .. '. Minimum valves required ' .. MinValves .. '.', domoticz.LOG_INFO)
        domoticz.log('Summary: Maximum open valve ' .. PercentMax .. '%' .. '. Override value is ' .. ValvePercentOveride .. '%', domoticz.LOG_INFO)
        OutdoorTemp = round(domoticz.devices( OutdoorTemp_IDX ).temperature,1)
        domoticz.log('Summary: Heating enabled switch = ' .. domoticz.devices( HeatingSwitch_IDX )._state, domoticz.LOG_INFO)
        domoticz.log('Summary: Outdoor temp = ' .. OutdoorTemp .. '. Min required to override heating switch = ' .. OutdoorTempToStartHeating, domoticz.LOG_INFO)
        BoilerSwitchOn = false
        BoilerSwitchOff = true

--
-- Main logic to start heating with verification several sensors
--
        domoticz.log('##### Logic: Perform analytics ----------', domoticz.LOG_DEBUG)

        -- Normal day
        domoticz.log('- is Holiday = ' .. domoticz.devices( HolidaySwitch_IDX )._state, domoticz.LOG_DEBUG)
        if ( domoticz.devices( HolidaySwitch_IDX )._state == 'Off') then

            -- If heating enabled or outdoor temp below minimum required
            if ( domoticz.devices( HeatingSwitch_IDX )._state == 'On' or OutdoorTemp < OutdoorTempToStartHeating ) then

                -- If min opened valves larger than required
                if (ValveCount >= MinValves) then
                    BoilerSwitchOn = true
                    BoilerSwitchOff = false
                end     

                -- If single valve over max required
                if (PercentMax >= ValvePercentOveride) then
                    BoilerSwitchOn = true
                    BoilerSwitchOff = false
                end     
            end

        else -- on holiday
            domoticz.log('Holiday Mode', domoticz.LOG_INFO)
            if ( TempMin <= HolidayMinTemp ) and ( domoticz.devices( BoilerSwitch_IDX )._state == 'Off' ) then  -- house is very cold
                domoticz.log('Overall temperature is below ' .. HolidayMinTemp .. '. Force start heating', domoticz.LOG_INFO)
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

        domoticz.log('END', domoticz.LOG_INFO)
    
    end
}
