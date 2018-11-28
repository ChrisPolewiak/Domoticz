--
-- Home-Temp-Control
-- Chris Polewiak
-- version 3 - manual switch Heater when valve is opened
--
-- based on https://www.domoticz.com/wiki/EQ3_MAX!#Max_Script
-- 

-- Preset Values
BoilerOnPercent = 35            -- percentage valve open at which the boiler will be turned on
HysterysisOffPercent = 20       -- percentage below BoilerOnPercent to switch off the boiler
MinValves = 2                   -- Number of Valves that need to be open before boiler is turned on
ValvePercentOveride = 75        -- Percentage value of valve open required to override MinValves value (one room is very cold)
HolidayMinTemp = 10             -- Minimum room temperature before boiler is turned on during holiday period
HolidayHysterysisTemp = 2       -- Value to increase house temperature by while in holiday mode if boiler is turned on due to low temperatures
MissingDevicesTime = 86400      -- Value in seconds to allow before reporting a device has not been updated

-- Script Variables
PercentMax = 0
TempMin = 10
ValveCount = 0
MissingDeviceCount = 0
Notify = false
HeatingSwitch = "Switch-Heating-Active"
BoilerSwitch = "Switch-Heating-Furnace"
HolidaySwitch = "Switch-Heating-Holiday"
WindowOpened = false
 
-- Set printing to log options (true / false)
printData = false
printDebug = false
 
 
-- Get current date & time
t1 = os.time()
local currentDate = os.date("*t");  -- sets up currentDate.[table]
-- (currentDate.year [full], .month [1-12], .day [1-31], .hour [0-23], .min [0-59], .sec [0-59], .wday [0-6 {Sun-Sat}])
sCurrentTime = currentDate.year .. "-" .. currentDate.month .. "-" .. currentDate.day .. " " .. currentDate.hour .. ":" .. currentDate.min .. ":" .. currentDate.sec

function TimeElapsed(s) -- expects date & time in the form of 2010-01-23 12:34:56
   year = string.sub(s, 1, 4)
   month = string.sub(s, 6, 7)
   day = string.sub(s, 9, 10)
   hour = string.sub(s, 12, 13)
   minutes = string.sub(s, 15, 16)
   seconds = string.sub(s, 18, 19)
   t1 = os.time()
   t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
   difference = os.difftime (t1, t2)
   return difference -- in seconds
end


commandArray = {}

-- print blank line in log
if printData == true then
    print (" ")
    print (" *** Heating Script Output ***")
    print (" ")
end

-- check if any window or door are opened
if ( tonumber(otherdevices['Window-Opened-Status']) > 0 ) then
    WindowOpened = true
end


-- Get Data from Radiator Valves
for i, v in pairs(otherdevices) do
    -- Get all devices in the database
    v = i:sub(-6,-1)
    -- Grab the last four characters of the device name
 
    if (v == '-Valve') then
        -- are the last four characters "-Valve"? If so we have a Radiator Valve
 
        RoomName = i:sub(1,-7) -- Get the rest of the name, which will be the room name
        RoomName = RoomName:sub(9)

        sSetTempValue = otherdevices_svalues['Climate-' .. RoomName .. '-Stat']
        sValvePercentOpen = otherdevices_svalues[i]
        sLastUpdateTime = otherdevices_lastupdate[i]
        sElapsedTime = TimeElapsed(otherdevices_lastupdate[i])
        message = RoomName .. " valve is open " .. sValvePercentOpen .. "%, setpoint temperature is " .. sSetTempValue .. "C"  -- for debug
--        message2 = RoomName .. " last seen " .. sLastUpdateTime  ..  " Elapsed time " .. sElapsedTime
        if printData == true then
            print (message)
--            print (message2)
        end
 
        -- check for missing devices
        if sElapsedTime > MissingDevicesTime then
            Notify = false
            MissingDeviceCount = MissingDeviceCount + 1
        end
 
        -- get the % value of the most open Radiator Valve
        if tonumber(sValvePercentOpen) > PercentMax then
            PercentMax = tonumber(sValvePercentOpen)
        end
 
        -- Count the number of valves that are open more than BoilerOnPercent
        if tonumber(sValvePercentOpen) >= BoilerOnPercent then
            ValveCount = ValveCount + 1
        end   

    end
end
if printData == true then
    print (" ")
end

-- Get Data from Thermostats
for i, v in pairs(otherdevices) do -- Get all devices in the database
    v = i:sub(-5,-1) -- Grab the last five characters of the device name
    if (v == '-Stat') then -- are the last five characters "-Stat "? If so we have an EQ-3 Thermostat
 
        RoomName = i:sub(1,-6) -- Get the rest of the name, which will be the room name
        RoomName = RoomName:sub(9)
        sTemp = otherdevices_svalues[i] -- get the temperature   
        sLastUpdateTime = otherdevices_lastupdate[i]
        sElapsedTime = TimeElapsed(otherdevices_lastupdate[i])               
        message = RoomName.." temperature is " .. sTemp .. " C"  -- for debug
--        message2 = RoomName .. " last seen " .. sLastUpdateTime  ..  " Elapsed time " .. sElapsedTime
        if printData == true then
            print(message)
            print(message2)
        end
 
        -- check for missing devices
        if sElapsedTime > MissingDevicesTime then
            Notify = false
            MissingDeviceCount = MissingDeviceCount + 1
        end

        -- get the lowest temperature of the thermostats
        if tonumber(sTemp) < TempMin then
            TempMin = tonumber(sTemp)
        end
 
    end   
end

if printData == true then
    print (" ")
    print ("Number of valves open more than " .. BoilerOnPercent .. "% is " .. ValveCount .." valves")
    print("Highest valve open value is " .. PercentMax .." percent ")
    print("Lowest thermostat reading is " .. TempMin .." Centigrade ")
    print (" ")

    if (otherdevices[BoilerSwitch] == 'On') then
        print ("Current state - Boiler is ON ")
    else
        print ("Current state - Boiler is OFF ")
    end   
end       

-- Check the elapsed time and email if overdue
if (Notify == true) then
    print (" ")
    print("Heating Script: missing device notify");
    notifyString = os.date("Domoticz Alert # The current time is %X on %A Lost contact with " .. MissingDeviceCount .. " Heating script devices, check if Max!Buddy is running.  #")
    print(notifyString)
    commandArray['TriggerIFTTT'] = notifyString
end


-- Perform logic
if (printDebug == true) then
    -- view the settings to understand logic performance
    print ("PercentMax (" .. PercentMax .. "%) " .. "Boiler On value (" .. BoilerOnPercent .. "%) " .. "Boiler Off value (" .. (BoilerOnPercent - HysterysisOffPercent) .. ")% ")
    print ("Number of valves open more than " .. BoilerOnPercent .. "% is " .. ValveCount .." valves. Minimum valves setting " .. MinValves )
    print ("Maximum open value " .. PercentMax .. "%" .. " Override value " .. ValvePercentOveride .."%")
 
    print (" ")
end   

if (otherdevices[HolidaySwitch] == 'Off') then -- Not on holiday
    if (otherdevices[HeatingSwitch] == 'On') then -- It's time to heat the house
        if (WindowOpened == false) then -- If all Windows are closed
            if (printDebug == true) then
                print ("Test passed - All Windows are closed")
            end   
            if (otherdevices[BoilerSwitch] == 'Off') then --If a minimum of 'MinValves' valves are on by more that pre-set value BoilerOnPercent
                if (printDebug == true) then
                    print ("Test passed - Boiler is OFF ")
                end   
                if (PercentMax > BoilerOnPercent) then
                    if (printDebug == true) then
                        print ("Test passed - Radiators are open beyond the threshold ")
                    end               
                    if (ValveCount >= MinValves) or (BoilerOnPercent >= ValvePercentOveride) then
                        if (printDebug == true) then
                            print ("Test passed - Either multiple valves are open or override count is reached ")
                        end   
    
                        commandArray[BoilerSwitch]='On' -- turn on boiler
    
                        if (printData == true) then
                            print ("Command sent - Turn ON Boiler ")
                        end
                    end     
                end
            end
        end
    end

    if (PercentMax < (BoilerOnPercent - HysterysisOffPercent) or (ValveCount < MinValves)) and (otherdevices[BoilerSwitch] == 'On')  then -- If the number of valves open more than BoilerOnPercent minus HysterysisOffPercent

        commandArray[BoilerSwitch]='Off' -- turn off boiler

        if (printData == true) then
            print ("Command sent - Turn OFF Boiler ")
        end   
    end

else -- on holiday
    if (TempMin <= HolidayMinTemp) and (otherdevices[BoilerSwitch] == 'Off') then  -- house is very cold

        commandArray[BoilerSwitch]='On' -- turn on boiler

    end
 
    if (TempMin >= (HolidayMinTemp + HolidayHysterysisTemp)) and (otherdevices[BoilerSwitch] == 'On') then  -- house is warm enough

        commandArray[BoilerSwitch]='Off' -- turn on boiler

    end
end

if printData == true then
    print (" ")
end
 

return commandArray
