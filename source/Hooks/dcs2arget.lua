-------------------------------------------------------------------------------
--
-- DCS "hooks" lua file for Thrustmaster HOTAS devices.
--
-- Use at own risk without warranty.
--
-- The following lamps/indicators are exported:
--
--   F-16:
--      GEAR Nose
--      GEAR Left
--      GEAR Right
--      GEAR Warning (handle)
--      RWR AUX search
--      RWR AUX Activity
--      RWR AUX ActPower
--      RWR AUX Alt Low
--      RWR AUX Alt
--      RWR Power
--      Speed brake position
--
--  A-10C:
--      Speed brake position
--      Console light control level
--
--  F/A-18C Hornet:
--      Speed brake position
--      Console light control level
--
--  JF-17:
--      GEAR Nose
--      GEAR Left
--      GEAR Right
--      GEAR Warning (handle)
--      GEAR Transit
--      Master warning (on/off)
--
--
-- Author: slughead
-- Last edit: 13/2/2024
--
-- Version 1.0.7 - Added JF-17 aircraft files for Viper TQS (Tigershark2005)
-- Version 1.0.6 - Added logic for A-10C/A-10C2/F/A-18C left and right engine
--                 logic for console illumination.
-- Version 1.0.5 - Added F/A-18C Hornet console light control.
-- Version 1.0.4 - Converted from export.lua to "hooks" file.
-- Version 1.0.3 - Added A-10C console light control.
--
------------------------------------------------------------------------------

local tm_target_utils
local generic_aircraft_utils

local dcs2target = {}

    dcs2target.VERSION = "DCS2TARGET v1.0.7"

    dcs2target.lastUpdateTime = DCS.getModelTime()

    dcs2target.aircraft               = nil
    dcs2target.previous_aircraft_name = nil

    dcs2target.aircraft_lamp_utils    = nil


local function create_version_payload()
    return tm_target_utils.VERSION..dcs2target.VERSION
end

function dcs2target.onSimulationStart()
    log.set_output('dcs2target', 'dcs2target', log.INFO, log.MESSAGE + log.TIME_UTC + log.LEVEL)
    log.write('dcs2target', log.INFO, dcs2target.VERSION)
    log.write('dcs2target', log.INFO, 'onSimulationStart')

    package.path  = package.path..";"..lfs.writedir().."Scripts\\dcs2target\\?.lua"
    package.path  = package.path..";"..lfs.currentdir().."\\LuaSocket\\?.lua"
    package.cpath = package.cpath..";"..lfs.currentdir().."\\LuaSocket\\?.dll"

    tm_target_utils = require("tm_target_utils")
    socket = require("socket")

    host = host or "localhost"
    port = port or 2323

    target_socket = socket.try(socket.connect(host, port))
    log.write('dcs2target', log.INFO, 'Connected to T.A.R.G.E.T.')

    if target_socket then
        target_socket:setoption("tcp-nodelay", true)

        local payload = create_version_payload()
        socket.try(target_socket:send( tm_target_utils.pack_data(payload) ))
    end

    generic_aircraft_utils = require('generic_aircraft_utils')
end

function dcs2target.onSimulationStop()
    log.write('dcs2target', log.INFO, 'onSimulationStop')

    dcs2target.aircraft_lamp_utils = nil

    if target_socket then
        socket.try(target_socket:send( tm_target_utils.pack_data(tm_target_utils.QUIT) ))
        target_socket:close()
    end

    log.set_output('dcs2target', '', 0, 0)
end

function dcs2target.onSimulationFrame()
    local now = DCS.getModelTime()
    if (now >= dcs2target.lastUpdateTime and now < dcs2target.lastUpdateTime + 0.1) then
        return
    end
    dcs2target.lastUpdateTime = now

    dcs2target.aircraft = Export.LoGetSelfData()

    if (dcs2target.aircraft == nil and dcs2target.previous_aircraft_name ~= nil) then
        dcs2target.previous_aircraft_name = nil
        socket.try(target_socket:send( tm_target_utils.pack_data(tm_target_utils.RESET) ))
    end

    if (dcs2target.aircraft ~= nil) then
        if (dcs2target.previous_aircraft_name ~= dcs2target.aircraft.Name) then
            dcs2target.previous_aircraft_name = dcs2target.aircraft.Name

            if target_socket then
                local payload = tm_target_utils.MODULE..dcs2target.aircraft.Name
                socket.try(target_socket:send( tm_target_utils.pack_data(payload) ))
            end

            if (dcs2target.aircraft.Name == "A-10C" or dcs2target.aircraft.Name == "A-10C_2") then
                dcs2target.aircraft_lamp_utils = require("a-10c_lamps")
            elseif (dcs2target.aircraft.Name == "F-16C_50") then
                dcs2target.aircraft_lamp_utils = require("f-16c_50_lamps")
            elseif (dcs2target.aircraft.Name == "FA-18C_hornet") then
                dcs2target.aircraft_lamp_utils = require("fa-18c_hornet_lamps")
            elseif (dcs2target.aircraft.Name == "JF-17") then
                dcs2target.aircraft_lamp_utils = require("jf-17_lamps")
            end

            if (dcs2target.aircraft_lamp_utils ~= nil) then
                dcs2target.aircraft_lamp_utils.init()
            end
        end

        local send_update = false
        local payload

        if ( dcs2target.aircraft.Name == "Su-25T" or
             dcs2target.aircraft.Name == "Su-33" ) then

            local speedbrake_status_payload
            local updated = false

            updated, speedbrake_status_payload = generic_aircraft_utils:create_speedbrake_status_payload( dcs2target.aircraft.Name )
            payload = speedbrake_status_payload
            send_update = updated
        end

        if (dcs2target.aircraft.Name == "A-10C" or dcs2target.aircraft.Name == "A-10C_2") then
            local lamp_status_payload
            local updated = false

            updated, lamp_status_payload = dcs2target.aircraft_lamp_utils:create_lamp_status_payload()
            payload = lamp_status_payload
            send_update = updated
        end

        if (dcs2target.aircraft.Name == "F-16C_50") then
            local lamp_status_payload
            local speedbrake_status_payload
            local updated = false

            updated, lamp_status_payload = dcs2target.aircraft_lamp_utils:create_lamp_status_payload()
            payload = lamp_status_payload
            send_update = send_update or updated

            updated, speedbrake_status_payload = generic_aircraft_utils:create_speedbrake_status_payload( dcs2target.aircraft.Name )
            payload = payload..speedbrake_status_payload
            send_update = send_update or updated
        end

        if (dcs2target.aircraft.Name == "FA-18C_hornet") then
            local lamp_status_payload
            local updated = false

            updated, lamp_status_payload = dcs2target.aircraft_lamp_utils:create_lamp_status_payload()
            payload = lamp_status_payload
            send_update = updated
        end

        if (dcs2target.aircraft.Name == "JF-17") then
            local lamp_status_payload
            local updated = false

            updated, lamp_status_payload = dcs2target.aircraft_lamp_utils:create_lamp_status_payload()
            payload = lamp_status_payload
            send_update = updated
        end

        if send_update then
            if target_socket then
                payload = tm_target_utils.UPDATE..payload
                socket.try(target_socket:send( tm_target_utils.pack_data(payload) ))
            end
        end
    end
end

DCS.setUserCallbacks(dcs2target)