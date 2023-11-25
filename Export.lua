-------------------------------------------------------------------------------
--
-- DCS export lua file for F-16C module and Thrustmaster Viper TQS LED control.
--
-- Use at own risk without warranty.
--
-- The following lamps/indicators are exported:
--
--   GEAR Nose
--   GEAR Left
--   GEAR Right
--   GEAR Warning (handle)
--   RWR AUX search
--   RWR AUX Activity
--   RWR AUX ActPower
--   RWR AUX Alt Low
--   RWR AUX Alt
--   RWR Power
--
-- To use, place in Saved Games\DCS.openbeta\Scripts or Saved Games\DCS\Scripts
-- folder.
--
-- Supported for singleplayer missions.
-- Multiplayer is not supported and may or may not work. Multiplayer servers
-- may need the export of DCS parameters enabled.
--
-- Author: slughead
-- Date: 17/11/2023
--
------------------------------------------------------------------------------

local default_output_file = nil
local target_socket = nil

local tm_target_utils
local aircraft_lamp_utils

local aircraft
local previous_aircraft_name


function LuaExportStart()

    --default_output_file = io.open(lfs.writedir().."/Logs/Export.log", "w")
    if default_output_file then
        default_output_file:write("LuaExportStart: Export started.\n")
    end

    package.path  = package.path..";"..lfs.writedir().."/Scripts/?.lua"
    package.path  = package.path..";"..lfs.currentdir().."/LuaSocket/?.lua"
    package.cpath = package.cpath..";"..lfs.currentdir().."/LuaSocket/?.dll"

    tm_target_utils = require("tm_target_utils")
    socket = require("socket")

    host = host or "localhost"
    port = port or 2323

    target_socket = socket.try(socket.connect(host, port))
    if target_socket then
        target_socket:setoption("tcp-nodelay", true)
    end

end


function LuaExportStop()

    if default_output_file then
        default_output_file:close()
        default_output_file = nil
    end

    if target_socket then
        socket.try(target_socket:send( tm_target_utils.pack_data(tm_target_utils.QUIT) ))
        target_socket:close()
    end

end


function LuaExportBeforeNextFrame()
-- Works just before every simulation frame.

end


function LuaExportAfterNextFrame()
-- Works just after every simulation frame.

end

local speedbrakes_value = nil

function create_speedbrake_status_payload( aircraft_name )

    local updated = false
    local payload

    local lMechInfo = LoGetMechInfo() -- mechanical components,  e.g. Flaps, Wheelbrakes,...
    if (lMechInfo ~= nil) then
        local value = lMechInfo.speedbrakes.value

        -- fudge factor for aircraft that do not use the full 0 to 1.0 range for speedbrake
        if (aircraft_name == "A-10C")   then value = value * 1.3; end
        if (aircraft_name == "A-10C_2") then value = value * 1.3; end

        -- ensure full range is used for aircraft that almost reach 1.0
        if (value >= 0.9) then value = 1.0 end

        value = math.floor(value * 5)

        if (speedbrakes_value ~= value) then
            speedbrakes_value = value

            payload = string.format("%d", value)
            updated = true;
        else
            payload = string.format("%d", speedbrakes_value)
        end
    else
        payload = string.format("%d", 0)
    end

    return updated, payload
end

function LuaExportActivityNextEvent(t)

    if default_output_file then
        --default_output_file:write("LuaExportActivityNextEvent: enter\n")
    end

    aircraft = LoGetSelfData()

    if (aircraft == nil and previous_aircraft_name ~= nil) then
        previous_aircraft_name = nil
        socket.try(target_socket:send( tm_target_utils.pack_data(tm_target_utils.RESET) ))
    end

    if (aircraft ~= nil) then
        if (previous_aircraft_name ~= aircraft.Name) then
            previous_aircraft_name = aircraft.Name

            if target_socket then
                local payload = tm_target_utils.MODULE..aircraft.Name
                socket.try(target_socket:send( tm_target_utils.pack_data(payload) ))
            end

            if (aircraft.Name == "F-16C_50") then
                aircraft_lamp_utils = require("f-16c_50_lamps")
            end
        end


        local send_update = false
        local payload

        if ( aircraft.Name == "A-10C" or
             aircraft.Name == "A-10C_2" or
             aircraft.Name == "FA-18C_hornet" or
             aircraft.Name == "Su-25T" or
             aircraft.Name == "Su-33" ) then

            local speedbrake_status_payload
            local updated = false

            updated, speedbrake_status_payload = create_speedbrake_status_payload( aircraft.Name )
            payload = speedbrake_status_payload
            send_update = send_update or updated
        end

        if (aircraft.Name == "F-16C_50") then
            local lamp_status_payload
            local speedbrake_status_payload
            local updated = false

            updated, lamp_status_payload = aircraft_lamp_utils:create_lamp_status_payload()
            payload = lamp_status_payload
            send_update = send_update or updated

            updated, speedbrake_status_payload = create_speedbrake_status_payload( aircraft.Name )
            payload = payload..speedbrake_status_payload
            send_update = send_update or updated
        end

        if send_update then
            if target_socket then
                payload = tm_target_utils.UPDATE..payload
                socket.try(target_socket:send( tm_target_utils.pack_data(payload) ))
            end
        end
    end

    return t + 0.1 -- trigger every 100ms
end



