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
-- Date: 26/12/2025
--
------------------------------------------------------------------------------

-- DCS World OpenBeta\Mods\aircraft\FA-18C\Cockpit\Scripts\clickabledata.lua
-- elements["pnt_404"]		= default_3_position_tumb(_("Battery Switch, ON/OFF/ORIDE"),				devices.ELEC_INTERFACE, elec_commands.BattSw,				404)
-- elements["pnt_402"]		= default_2_position_tumb(_("Left Generator Control Switch, NORM/OFF"),		devices.ELEC_INTERFACE, elec_commands.LGenSw,				402)
-- elements["pnt_403"]		= default_2_position_tumb(_("Right Generator Control Switch, NORM/OFF"),	devices.ELEC_INTERFACE, elec_commands.RGenSw,				403)
-- elements["pnt_413"]		= default_axis_limited(_("CONSOLES Lights Dimmer Control"),			devices.CPT_LIGHTS,		cptlights_commands.Consoles,	413, 0, 0.15, nil, nil, nil, {90, -135}, {90, -45})

-- DCS World OpenBeta\Mods\aircraft\FA-18C\Cockpit\Scripts\MainPanel\lamps.lua
-- APU Control Panel
-- create_caution_lamp(166,	CautionLights.CPT_LTS_NOSE_GEAR)
-- create_caution_lamp(165,	CautionLights.CPT_LTS_LEFT_GEAR)
-- create_caution_lamp(167,	CautionLights.CPT_LTS_RIGHT_GEAR)
-- create_caution_lamp(227, CautionLights.CPT_LTS_LDG_GEAR_HANDLE)
-- create_caution_lamp(376,	CautionLights.CPT_LTS_APU_READY)


local P = {}
fa_18c_hornet_lamps = P

    P.CPT_LTS_NOSE_GEAR              = 166
    P.CPT_LTS_LEFT_GEAR              = 165
    P.CPT_LTS_RIGHT_GEAR             = 167

    P.CPT_LTS_LDG_GEAR_HANDLE        = 227
    P.CPT_LTS_APU_READY              = 376

    P.LEFT_GENERATOR_CONTROL_SWITCH  = 402
    P.RIGHT_GENERATOR_CONTROL_SWITCH = 403
    P.BATTERY_SWITCH                 = 404
    P.CONSOLE_LIGHT_DIAL             = 413

    P.landing_gear_handle_lamp = nil
    P.nose_gear_lamp           = nil
    P.left_gear_lamp           = nil
    P.right_gear_lamp          = nil
    P.apu_lamp                 = nil
    P.battery_switch           = nil
    P.console_light            = nil


local function get_lamp( id, status )
    local updated = false
    local value

    local device = Export.GetDevice(0)
    if type(device) ~= "number" and device ~= nil then
        value = device:get_argument_value(id) -- returns 0 (Off) 1 (On)
        if status ~= value then
            updated = true
        end
    end

    return updated, value
end

local function get_battery_switch( current_value )

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

local function get_console_light( current_value )
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

function P.init( self )

    P.landing_gear_handle_lamp = nil
    P.gear_nose_lamp           = nil
    P.gear_left_lamp           = nil
    P.gear_right_lamp          = nil
    P.apu_lamp                 = nil
    P.battery_switch           = nil
    P.console_light            = nil

end

function P.create_lamp_status_payload( self )

    local updated        = false
    local status_changed = false
    local payload        = "000000"

    local console_light  = 0

    local device = Export.GetDevice(0)
    if (type(device) ~= "number" and device ~= nil) then
        status_changed, self.gear_nose_lamp = get_lamp( self.CPT_LTS_NOSE_GEAR, self.gear_nose_lamp )
        updated = updated or status_changed

        status_changed, self.gear_left_lamp = get_lamp( self.CPT_LTS_LEFT_GEAR, self.gear_left_lamp )
        updated = updated or status_changed

        status_changed, self.gear_right_lamp = get_lamp( self.CPT_LTS_RIGHT_GEAR, self.gear_right_lamp )
        updated = updated or status_changed

        status_changed, self.landing_gear_handle_lamp = get_lamp( self.CPT_LTS_LDG_GEAR_HANDLE, self.landing_gear_handle_lamp )
        updated = updated or status_changed

        status_changed, self.apu_lamp = get_lamp( self.CPT_LTS_APU_READY, self.apu_lamp )
        updated = updated or status_changed

        status_changed, self.battery_switch = get_battery_switch( self.battery_switch )
        updated = updated or status_changed

        status_changed, self.console_light = get_console_light( self.console_light )
        updated = updated or status_changed

        if (self.battery_switch == 1 and self.console_light == 0) then
            -- set console lights to minimum (not off) so that the Warthog LEDs can be seen, e.g. the APU light
            console_light = 1
        else
            console_light = self.console_light
        end

        payload = string.format( "%d%d%d%d%d%d",
                                    self.gear_nose_lamp,
                                    self.gear_left_lamp,
                                    self.gear_right_lamp,
                                    self.landing_gear_handle_lamp,
                                    self.apu_lamp,
                                    console_light )
    end

    return updated, payload

end

return fa_18c_hornet_lamps