commandArray = {}

if (devicechanged['Window-Livingroom-Deck-01'] == 'Open' and tonumber(otherdevices['Climate-Outdoor-T']) < 0) then

    Title = 'Domoticz'
    Message = 'Drzwi tarasowe zostały otwarte przy mrozie'    

    commandArray['SendNotification'] = Title .. '#' .. Message .. '#0'

end

if (devicechanged['Window-Livingroom-Deck-01'] == 'Closed' and tonumber(otherdevices['Climate-Outdoor-T']) < 0) then

    Title = 'Domoticz'
    Message = 'Drzwi tarasowe zostały zamknięte przy mrozie'    

    commandArray['SendNotification'] = Title .. '#' .. Message .. '#0'

end

return commandArray
