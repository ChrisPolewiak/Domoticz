--
-- Fishtank-Temp
-- Chris Polewiak
-- history:
--  1.0 - control temperature of Fishtank
--  2.0 - dzvents version

return {
	on = {
		timer = {'every 15 minutes'},
	},
	logging = {
        level = domoticz.LOG_INFO,
        marker = 'fishtank-temp'
    },
	execute = function(domoticz, triggeredItem)

        local heating_tempmin = 24.0;
        local heating_tempmax = 24.5;

        local cooling_tempmax = 25.5;
        local cooling_tempmin = 25.0;

        local turnofflight_tempmin = 26.0;
        local sensor_WaterTemp_IDX  = 54        -- Climate-Fishtank-Temp
        local device_FishtankLight_IDX = 62     -- Switch-Fishtank-s01-light
        local device_FishtankFan_IDX = 64        -- Switch-Fishtank-s03-fan
        local device_FishtankHeater_IDX = 65    -- Switch-Fishtank-s04-heater

        local current_water_temp = domoticz.devices( sensor_WaterTemp_IDX ).temperature

        -- If Fishtank Water Temp is metered
        if ( current_water_temp > 0 and domoticz.devices( sensor_WaterTemp_IDX ).temperature < 85 ) then

            -- Cooling
            -- If Fishtank Water Temp is very high turn off light
            if ( current_water_temp > turnofflight_tempmin ) then
                domoticz.log('Fishtank temp ' .. current_water_temp .. ' > ' .. turnofflight_tempmin .. ': Turn Light Off', INFO)
                domoticz.devices( device_FishtankLight_IDX ).switchOff()
                domoticz.devices( device_FishtankFan_IDX ).switchOn().afterSec(1)
            end

            -- Cooling
            -- If Fishtank Water Temp is high turn on fan
            if ( current_water_temp > cooling_tempmax ) then
                domoticz.log('Fishtank temp ' .. current_water_temp .. ' > ' .. cooling_tempmax .. ': Turn On Fan', INFO)
                domoticz.devices( device_FishtankFan_IDX ).switchOn()
                domoticz.devices( device_FishtankHeater_IDX ).switchOff().afterSec(1)
            -- If Fishtank Water Temp back to normal, turn off fan
            elseif ( current_water_temp < cooling_tempmin ) then
                domoticz.log('Fishtank temp ' .. current_water_temp .. ' < ' .. cooling_tempmin .. ': Turn Off Fan', INFO)
                domoticz.devices( device_FishtankFan_IDX ).switchOff()
            end

            -- Heating
            -- If Fishtank Water Temp back to normal, turn off heater
            if ( current_water_temp > heating_tempmax ) then
                domoticz.log('Fishtank temp ' .. current_water_temp .. ' > ' .. heating_tempmax .. ': Turn Heating Off', INFO)
                domoticz.devices( device_FishtankHeater_IDX ).switchOff()
            -- If Fishtank Water Temp is to low, turn on heater
            elseif ( current_water_temp < heating_tempmin ) then
                domoticz.log('Fishtank temp ' .. current_water_temp .. ' < ' .. heating_tempmin .. ': Turn Heating On', INFO)
                domoticz.devices( device_FishtankHeater_IDX ).switchOn()
                domoticz.devices( device_FishtankFan_IDX ).switchOff().afterSec(1)
            end

        end
    end
}

