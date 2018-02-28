commandArray = {}

date = os.date("*t")

StartHour = 23
StopHour = 5

if (
    ( devicechanged['AlarmMotion-Jakub'] and tonumber( devicechanged['AlarmMotion-Jakub'] ) > 1 )
    or
--    ( devicechanged['AlarmMotion-Office'] and tonumber( devicechanged['AlarmMotion-Office'] ) > 1 )
--    or
    ( devicechanged['AlarmMotion-Michael'] and tonumber( devicechanged['AlarmMotion-Michael'] ) > 1 )
    or
    ( devicechanged['AlarmMotion-Bedroom'] and tonumber( devicechanged['AlarmMotion-Bedroom'] ) > 1 )
    or
    ( devicechanged['AlarmMotion-Bathroom'] and tonumber( devicechanged['AlarmMotion-Bathroom'] ) > 1 )
    ) then
    if ( date.hour >= StartHour or date.hour <= StopHour ) then

        commandArray['Scene:nightlights-on-motion']='On'

    end
end

return commandArray
