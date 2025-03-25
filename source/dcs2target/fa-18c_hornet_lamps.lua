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
-- Date: 23/03/2025
--
------------------------------------------------------------------------------

-- DCS World OpenBeta\Mods\aircraft\FA-18C\Cockpit\Scripts\clickabledata.lua
-- elements["pnt_404"]		= default_3_position_tumb(_("Battery Switch, ON/OFF/ORIDE"),				devices.ELEC_INTERFACE, elec_commands.BattSw,				404)
-- elements["pnt_402"]		= default_2_position_tumb(_("Left Generator Control Switch, NORM/OFF"),		devices.ELEC_INTERFACE, elec_commands.LGenSw,				402)
-- elements["pnt_403"]		= default_2_position_tumb(_("Right Generator Control Switch, NORM/OFF"),	devices.ELEC_INTERFACE, elec_commands.RGenSw,				403)
-- elements["pnt_413"]		= default_axis_limited(_("CONSOLES Lights Dimmer Control"),			devices.CPT_LIGHTS,		cptlights_commands.Consoles,	413, 0, 0.15, nil, nil, nil, {90, -135}, {90, -45})

-- DCS World OpenBeta\Mods\aircraft\FA-18C\Cockpit\Scripts\MainPanel\lamps.lua
-- APU Control Panel
-- create_caution_lamp(227, CautionLights.CPT_LTS_LDG_GEAR_HANDLE)
-- create_caution_lamp(376,	CautionLights.CPT_LTS_APU_READY)


local P = {}
fa_18c_hornet_lamps = P

    P.CPT_LTS_LDG_GEAR_HANDLE = 227
    P.CPT_LTS_APU_READY       = 376

    P.LEFT_GENERATOR_CONTROL_SWITCH  = 402
    P.RIGHT_GENERATOR_CONTROL_SWITCH = 403
    P.BATTERY_SWITCH                 = 404
    P.CONSOLE_LIGHT_DIAL             = 413

    P.landing_gear_handle_lamp_value = nil
    P.apu_lamp_value                 = nil
    P.battery_switch_value           = nil
    P.console_light_value            = nil
    P.speedbrakes_value              = nil


local function get_battery_switch_value( current_value )

    local updated = false
    local value = 0

    local device = Export.GetDevice(0)
    if (type(device) ~= "number" and device ~= nil) then
        local aircraft_lamp_utils = require("fa-18c_hornet_lamps")

        value = device:get_argument_value(aircraft_lamp_utils.BATTERY_SWITCH)

        if current_value ~= value then
            updated = true
        end
    end

    return updated, value

end

local function get_landing_gear_handle_lamp_value( current_value )

    local updated = false
    local value = 0

    local device = Export.GetDevice(0)
    if (type(device) ~= "number" and device ~= nil) then
        local aircraft_lamp_utils = require("fa-18c_hornet_lamps")

        value = device:get_argument_value(aircraft_lamp_utils.CPT_LTS_LDG_GEAR_HANDLE)

        if current_value ~= value then
            updated = true
        end
    end

    return updated, value
end

local function get_apu_lamp_value( current_value )

    local updated = false
    local value = 0

    local device = Export.GetDevice(0)
    if (type(device) ~= "number" and device ~= nil) then
        local aircraft_lamp_utils = require("fa-18c_hornet_lamps")

        value = device:get_argument_value(aircraft_lamp_utils.CPT_LTS_APU_READY)

        if current_value ~= value then
            updated = true
        end
    end

    return updated, value
end

local function get_console_light_value( current_value )
    local updated = false
    local value = 0

    local device = Export.GetDevice(0)
    if (type(device) ~= "number" and device ~= nil) then
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

        value = math.floor(value * 4)

        if (current_value ~= value) then
            updated = true;
        end
    end

    return updated, value
end

function P.init( self )

    P.landing_gear_handle_lamp_value = nil
    P.apu_lamp_value                 = nil
    P.battery_switch_value           = nil
    P.console_light_value            = nil
    P.speedbrakes_value              = nil

end

function P.create_lamp_status_payload( self )

    local updated        = false
    local status_changed = false

    local console_light_value = 0

    local payload = "0000"

    local device = Export.GetDevice(0)
    if (type(device) ~= "number" and device ~= nil) then

        status_changed, self.landing_gear_handle_lamp_value = get_landing_gear_handle_lamp_value( self.landing_gear_handle_lamp_value )
        updated = updated or status_changed

        status_changed, self.apu_lamp_value = get_apu_lamp_value( self.apu_lamp_value )
        updated = updated or status_changed

        status_changed, self.speedbrakes_value = get_speedbrake_value( self.speedbrakes_value )
        updated = updated or status_changed

        status_changed, self.battery_switch_value = get_battery_switch_value( self.battery_switch_value )
        updated = updated or status_changed

        status_changed, self.console_light_value = get_console_light_value( self.console_light_value )
        updated = updated or status_changed

        if (updated) then
            if (self.battery_switch_value == 1 and self.console_light_value == 0) then
                -- set console lights to minimum (not off) so that the Warthog LEDs can be seen, e.g. the APU light
                console_light_value = 1
            else
                console_light_value = self.console_light_value
            end

            payload = string.format( "%d%d%d%d",
                                        self.apu_lamp_value,
                                        self.speedbrakes_value,
                                        console_light_value,
                                        self.landing_gear_handle_lamp_value )
        end
    end

    return updated, payload

end

return fa_18c_hornet_lamps