return {
    on =        {   devices         =   { 287 },
	},
	logging =   {   level           =   domoticz.LOG_INFO,
                    marker          =   "watering"
    },
	execute = function(domoticz, item)

        local ForecastRain_AllowedMin = 20
        local ForecastRain = domoticz.devices( 272 ).percentage
        local ForecastTemp_AllowedMin = 15
        local ForecastTemp = domoticz.devices( 286 ).temperature
        
        local button_switch_IDX = 24
        
        local Start_Watering = false
        local WateringPhase_Morning = false
        local WateringPhase_Evening = false
        previous_Watering_Time = 0
        
        local var_watering_force_idx = 15

        local Valves = {
            {   Name = 'DripLineFence',     IDX = 201,  Morning = { Watering_Time = 15, }, Evening = { Watering_Time = 5, }, },
            {   Name = 'DripLineTerrace',   IDX = 203,  Morning = { Watering_Time = 15, }, Evening = { Watering_Time = 5, }, },
            {   Name = 'GrassInside',       IDX = 202,  Morning = { Watering_Time = 5, }, Evening = { Watering_Time = 0, }, },
            {   Name = 'GrassLines',        IDX = 204,  Morning = { Watering_Time = 5, }, Evening = { Watering_Time = 0, }, },
        }

	    date = os.date("*t")
	    domoticz.log( '=== WATERING ===', domoticz.LOG_INFO )
	    domoticz.log( 'Current Hour: ' .. date.hour .. ', workday: ' .. date.wday, domoticz.LOG_DEBUG )

        if ( item._state == 'On' ) then
        
            -- Turn On watering force
            if ( domoticz.variables( var_watering_force_idx ).value == 1 ) then
                domoticz.log( 'Turn On watering force', domoticz.LOG_INFO )
                domoticz.variables( var_watering_force_idx ).set(0)

                Start_Watering = true
	            WateringPhase_Morning = true

            -- Turn On watering by scheduler
            else
                domoticz.log( 'Turn On watering by scheduler', domoticz.LOG_INFO )

                if ( date.hour < 12 ) then
                    domoticz.log( 'Morning watering', domoticz.LOG_DEBUG )
                    WateringPhase_Morning = true
                
        	        if ( ForecastRain > ForecastRain_AllowedMin ) then
            	        domoticz.log( 'Rain forecast ' .. ForecastRain .. '% > ' .. ForecastRain_AllowedMin .. '%. Watering is not allowed', domoticz.LOG_INFO )
                    else
            	        domoticz.log( 'Rain forecast ' .. ForecastRain .. '% <= ' .. ForecastRain_AllowedMin .. '%. Watering is allowed', domoticz.LOG_INFO )
            
            	        if ( ForecastTemp < ForecastTemp_AllowedMin ) then
                	        domoticz.log( 'Temp forecast ' .. ForecastTemp .. 'C <= ' .. ForecastTemp_AllowedMin .. 'C. Watering is not allowed', domoticz.LOG_INFO )
                        else
                	        domoticz.log( 'Rain forecast ' .. ForecastTemp .. 'C > ' .. ForecastTemp_AllowedMin .. 'C. Watering is allowed', domoticz.LOG_INFO )
                	        Start_Watering = true
                        end
                    end
                else
                    domoticz.log( 'Evening watering', domoticz.LOG_DEBUG )
                    WateringPhase_Evening = true
                
        	        if ( ForecastRain > ForecastRain_AllowedMin ) then
            	        domoticz.log( 'Rain forecast ' .. ForecastRain .. '% > ' .. ForecastRain_AllowedMin .. '%. Watering is not allowed', domoticz.LOG_INFO )
                    else
            	        domoticz.log( 'Rain forecast ' .. ForecastRain .. '% <= ' .. ForecastRain_AllowedMin .. '%. Watering is allowed', domoticz.LOG_INFO )
            
            	        if ( ForecastTemp < ForecastTemp_AllowedMin ) then
                	        domoticz.log( 'Temp forecast ' .. ForecastTemp .. 'C <= ' .. ForecastTemp_AllowedMin .. 'C. Watering is not allowed', domoticz.LOG_INFO )
                        else
                	        domoticz.log( 'Rain forecast ' .. ForecastTemp .. 'C > ' .. ForecastTemp_AllowedMin .. 'C. Watering is allowed', domoticz.LOG_INFO )
                	        Start_Watering = true
                        end
                    end
                end
            end

        -- Turn off watering
        else
            domoticz.log( 'Turn off watering', domoticz.LOG_INFO )

            Start_Watering = false
            for id,valveData in ipairs(Valves) do
                if ( domoticz.devices( valveData.IDX )._state == 'On' ) then
                    domoticz.log( 'Valve ' .. valveData.Name .. ' Switch Off', domoticz.LOG_INFO )
                    domoticz.devices( valveData.IDX ).switchOff()
                end
            end
        end

        if ( Start_Watering ) then
            domoticz.log( 'Start Watering. Main loop', domoticz.LOG_INFO )
            for id,valveData in ipairs(Valves) do
                if ( WateringPhase_Morning ) then
                    WateringData = valveData.Morning
                end
                if ( WateringPhase_Evening ) then
                    WateringData = valveData.Evening
                end
                Watering_Time = WateringData.Watering_Time * 60

                domoticz.log( 'Valve: ' .. valveData.Name .. '(' .. valveData.IDX .. '), open for: ' .. Watering_Time .. ' sec, after: ' .. previous_Watering_Time .. ' sec', domoticz.LOG_DEBUG )

                if ( Watering_Time > 0 ) then
                    domoticz.devices( valveData.IDX ).switchOn().forSec( Watering_Time ).afterSec( previous_Watering_Time )
                    previous_Watering_Time = Watering_Time + previous_Watering_Time + 5
                end
            end
        end
    end
}
