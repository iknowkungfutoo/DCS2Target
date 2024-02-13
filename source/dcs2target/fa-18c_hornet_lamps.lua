-------------------------------------------------------------------------------
--
-- fa-18c_hornet_lamps.lua
--
-- Use at own risk without warranty.
--
-- Utility functions for retrieving DCS F/A-18C Hornet simulation data
-- and packaging for TCP packet transmission to Thrustmaster Target
-- TMHotasLEDSync.tmc script.
--
-- Author: slughead
-- Date: 03/12/2023
--
------------------------------------------------------------------------------

local P = {}
fa_18c_hornet_lamps = P

    P.CONSOLE_LIGHT_DIAL = 413
    P.LEFT_GENERATOR_CONTROL_SWITCH = 402
    P.RIGHT_GENERATOR_CONTROL_SWITCH = 403

    P.speedbrakes_value   = nil
    P.console_light_value = nil


local function get_console_light_value( current_value )
    local updated = false
    local value = 0

    local device = Export.GetDevice(0)
    if type(device) ~= "number" and device ~= nil then
        local aircraft_lamp_utils = require("fa-18c_hornet_lamps")

        -- get engine info
        local lEngInfo = Export.LoGetEngineInfo()

        if ((lEngInfo.RPM.left  > 60 and device:get_argument_value(aircraft_lamp_utils.LEFT_GENERATOR_CONTROL_SWITCH)  == 1) or
            (lEngInfo.RPM.right > 60 and device:get_argument_value(aircraft_lamp_utils.RIGHT_GENERATOR_CONTROL_SWITCH) == 1))
        then
            value = device:get_argument_value(aircraft_lamp_utils.CONSOLE_LIGHT_DIAL)
            value = math.floor(value * 5)
        end

        if current_value ~= value then
            updated = true
        end
    end

    return updated, value
end

local function get_speedbrake_value( current_value )

    local updated = false
    local value = 0

    local lMechInfo = Export.LoGetMechInfo() -- mechanical components,  e.g. Flaps, Wheelbrakes,...
    if (lMechInfo ~= nil) then
        value = lMechInfo.speedbrakes.value

        -- ensure full range is used for aircraft that almost reach 1.0
        if (value >= 0.9) then value = 1.0 end

        value = math.floor(value * 5)

        if (current_value ~= value) then
            updated = true;
        end
    end

    return updated, value
end

function P.init( self )
    self.speedbrakes_value   = nil
    self.console_light_value = nil
end

function P.create_lamp_status_payload( self )

    local updated        = false
    local status_changed = false
    local payload

    local device = Export.GetDevice(0)
    if type(device) ~= "number" and device ~= nil then
        status_changed, self.speedbrakes_value = get_speedbrake_value( self.speedbrakes_value )
        updated = updated or status_changed

        status_changed, self.console_light_value = get_console_light_value( self.console_light_value )
        updated = updated or status_changed

        payload = string.format( "%d%d",
                                 self.speedbrakes_value,
                                 self.console_light_value )
    else
        payload = "00"
    end

    return updated, payload

end

return fa_18c_hornet_lamps