--
-- Fishtank-Temp
-- Chris Polewiak
-- version 1 - control temperature of Fishtank
--

-- Preset Values
heating_tempmin = 24.0;
heating_tempmax = 24.5;
cooling_tempmin = 26.0;
turnofflight_tempmin = 26.5;


commandArray = {}

-- If Fishtank Water Temp is metered
if (otherdevices['Climate-Fishtank-Water'] > '0' and otherdevices['Climate-Fishtank-Water'] < '85') then

    -- If Fishtank Water Temp is very high turn off light
    if ( tonumber(otherdevices['Climate-Fishtank-Water']) > turnofflight_tempmin and otherdevices['Switch-Fishtank-s01-light']=='On') then
        commandArray['Switch-Fishtank-s01-light']='Off'
    end

    -- If Fishtank Water Temp is high turn on fan
    if ( tonumber(otherdevices['Climate-Fishtank-Water']) > cooling_tempmin and otherdevices['Switch-Fishtank-s03-fan']=='Off') then
        commandArray['Switch-Fishtank-s03-fan']='On'

    -- If Fishtank Water Temp back to normal, turn off fan
    elseif ( tonumber(otherdevices['Climate-Fishtank-Water']) < cooling_tempmin and otherdevices['Switch-Fishtank-s03-fan']=='On') then
        commandArray['Switch-Fishtank-s03-fan']='Off'
    end

    -- If Fishtank Water Temp back to normal, turn off heater
    if ( tonumber(otherdevices['Climate-Fishtank-Water']) > heating_tempmax and otherdevices['Switch-Fishtank-s04-heater']=='On') then
        commandArray['Switch-Fishtank-s04-heater']='Off'

    -- If Fishtank Water Temp is to low, turn on heater
    elseif ( tonumber(otherdevices['Climate-Fishtank-Water']) < heating_tempmin and otherdevices['Switch-Fishtank-s04-heater']=='Off' ) then
        commandArray['Switch-Fishtank-s04-heater']='On'
    end

end

return commandArray
