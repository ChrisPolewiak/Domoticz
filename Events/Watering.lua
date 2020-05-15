--
-- Home-Watering-Control
-- Chris Polewiak
-- 

return {
    on =        {   timer           =   { "at 4:00", "at 21:16" },
--                     devices         =   { 24 },
	},
	logging =   {   level           =   domoticz.LOG_DEBUG,
                    marker          =   "watering"
    },
	execute = function(domoticz, item)

local ForecastRain_AllowedMin = 10
        local ForecastRain = domoticz.devices( 272 ).percentage * 100
        local ForecastTemp_AllowedMin = 5
        local ForecastTemp = domoticz.devices( 286 ).temperature
        
        local WateringEnabled_IDX = 287

        local Start_Watering = false
        local WateringPhase_Morning = false
        local WateringPhase_Evening = false
        previous_Watering_Time = 0

        local Valves = {
            {   Name = 'DripLineFence',     IDX = 201,  Morning = { Watering_Time = 15, },   Evening = { Watering_Time = 5, },   },
            {   Name = 'DripLineTerrace',   IDX = 203,  Morning = { Watering_Time = 15, },  Evening = { Watering_Time = 5, },  },
            {   Name = 'GrassInside',       IDX = 202,  Morning = { Watering_Time = 15,  },  Evening = { Watering_Time = 5,  },  },
            {   Name = 'GrassLines',        IDX = 204,  Morning = { Watering_Time = 15, },  Evening = { Watering_Time = 5, },  },
        }
-- 285	2020-05-13 16:57:08	Watering-Section7	Off	0/0
-- 284	2020-05-13 16:57:23	Watering-Section6	Off	0/0
-- 283	2020-05-13 18:56:34	Watering-Section5	Off	0/0
-- 282	2020-05-13 19:40:27	Watering-Section4

	    date = os.date("*t")
	    domoticz.log( '=== WATERING ===', domoticz.LOG_INFO )
	    domoticz.log( 'Current Hour: ' .. date.hour .. ', workday: ' .. date.wday, domoticz.LOG_DEBUG )

        if ( domoticz.devices( WateringEnabled_IDX )._state == 'Off') then
    	    domoticz.log( 'Watering Main Switch Disabled', domoticz.LOG_DEBUG )
        else
    	    domoticz.log( 'Watering Main Switch Enabled', domoticz.LOG_DEBUG )
            if ( date.hour < 12 ) then
                domoticz.log( 'Morning watering', domoticz.LOG_DEBUG )
                WateringPhase_Morning = true
    
    	        if ( ForecastRain > ForecastRain_AllowedMin ) then
        	        domoticz.log( 'Rain forecast ' .. ForecastRain .. '% > ' .. ForecastRain_AllowedMin .. '%. Watering is not allowed', domoticz.LOG_DEBUG )
        	        Start_Watering = false
                else
        	        domoticz.log( 'Rain forecast ' .. ForecastRain .. '% <= ' .. ForecastRain_AllowedMin .. '%. Watering is allowed', domoticz.LOG_DEBUG )
        	        Start_Watering = true
    
        	        if ( ForecastTemp < ForecastTemp_AllowedMin ) then
            	        domoticz.log( 'Temp forecast ' .. ForecastTemp .. 'C <= ' .. ForecastTemp_AllowedMin .. 'C. Watering is not allowed', domoticz.LOG_DEBUG )
        	            Start_Watering = false
                    else
            	        domoticz.log( 'Rain forecast ' .. ForecastTemp .. 'C > ' .. ForecastTemp_AllowedMin .. 'C. Watering is allowed', domoticz.LOG_DEBUG )
            	        Start_Watering = true
                    end
                end
    
            else
                domoticz.log( 'Evening watering', domoticz.LOG_DEBUG )
                WateringPhase_Evening = true
    
    	        if ( ForecastRain > ForecastRain_AllowedMin ) then
        	        domoticz.log( 'Rain forecast ' .. ForecastRain .. '% > ' .. ForecastRain_AllowedMin .. '%. Watering is not allowed', domoticz.LOG_DEBUG )
        	        Start_Watering = false
                else
        	        domoticz.log( 'Rain forecast ' .. ForecastRain .. '% <= ' .. ForecastRain_AllowedMin .. '%. Watering is allowed', domoticz.LOG_DEBUG )
        	        Start_Watering = true
    
        	        if ( ForecastTemp < ForecastTemp_AllowedMin ) then
            	        domoticz.log( 'Temp forecast ' .. ForecastTemp .. 'C <= ' .. ForecastTemp_AllowedMin .. 'C. Watering is not allowed', domoticz.LOG_DEBUG )
        	            Start_Watering = false
                    else
            	        domoticz.log( 'Rain forecast ' .. ForecastTemp .. 'C > ' .. ForecastTemp_AllowedMin .. 'C. Watering is allowed', domoticz.LOG_DEBUG )
            	        Start_Watering = true
                    end
                end
    
            end
    
            if ( Start_Watering ) then
    
                domoticz.log( 'Start Watering. Main loop', domoticz.LOG_DEBUG )
                for id,valveData in ipairs(Valves) do
                    if ( WateringPhase_Morning ) then
                        WateringData = valveData.Morning
                    end
                    if ( WateringPhase_Evening ) then
                        WateringData = valveData.Evening
                    end
                    domoticz.log( 'Valve: ' .. valveData.Name .. '(' .. valveData.IDX .. '), open for: ' .. WateringData.Watering_Time .. ' min, after: ' .. previous_Watering_Time .. ' min', domoticz.LOG_INFO )
                    --domoticz.log('Current state: ' .. domoticz.devices( valveData.IDX )._state, domoticz.LOG_DEBUG )
    
                    if ( WateringData.Watering_Time > 0 ) then
                        domoticz.devices( valveData.IDX ).switchOn().forMin( WateringData.Watering_Time ).afterMin( previous_Watering_Time )
        --                domoticz.devices( valveData.IDX ).switchOn().forSec( WateringData.Watering_Time ).afterSec( previous_Watering_Time )
                        previous_Watering_Time = WateringData.Watering_Time + previous_Watering_Time
                    end
    
                end
            end
        end
    end
}
