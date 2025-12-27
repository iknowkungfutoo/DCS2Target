-------------------------------------------------------------------------------
--
-- a-10c_lamps.lua
--
-- Use at own risk without warranty.
--
-- Utility functions for retrieving DCS A-10C simulation data and packaging
-- for TCP packet transmission to Thrustmaster Target TMHotasLEDSync.tmc
-- script.
--
-- Author: slughead
-- Date: 26/12/2025
--
------------------------------------------------------------------------------

-- DCS World OpenBeta\Mods\aircraft\A-10C\Cockpit\Scripts\clickabledata.lua
-- DCS World OpenBeta\Mods\aircraft\A-10C_2\Cockpit\Scripts\clickabledata.lua

-- elements["PTR-EPP-APU-GEN-PWR"] = default_2_position_tumb(_("APU Generator On/Off"), 	 devices.ELEC_INTERFACE, device_commands.Button_1, 241 )
-- elements["PTR-EPP-AC-GEN-PWR-L"]= default_2_position_small_tumb(_("Left AC Generator Power"),  devices.ELEC_INTERFACE, device_commands.Button_4, 244 )
-- elements["PTR-EPP-AC-GEN-PWR-R"]= default_2_position_small_tumb(_("Right AC generator Power"), devices.ELEC_INTERFACE, device_commands.Button_5, 245 )
-- elements["PTR-EPP-BATTERY-PWR"] = default_2_position_small_tumb(_("Battery Power"), 			 devices.ELEC_INTERFACE, device_commands.Button_6, 246 )
-- elements["PTR-LGHTCP-CONSOLE"]			= default_axis(_("Console Light"), devices.LIGHT_SYSTEM, device_commands.Button_6, 297, nil, nil, nil, nil, nil, {70, -135},{180,-45})

-- DCS World OpenBeta\Mods\aircraft\A-10C\Cockpit\Scripts\mainpanel_init.lua
-- APU_RPM.arg_number	= 13
-- gear_handle.arg_number	= 716
-- caution_lamp(665,SystemsSignals.flag_CANOPY_UNLOCKED)
-- caution_lamp(659,SystemsSignals.flag_LANDING_GEAR_N_SAFE)
-- caution_lamp(660,SystemsSignals.flag_LANDING_GEAR_L_SAFE)
-- caution_lamp(661,SystemsSignals.flag_LANDING_GEAR_R_SAFE)
-- caution_lamp(737,SystemsSignals.flag_HANDLE_GEAR_WARNING)


local P = {}
a_10c_lamps = P

    P.CANOPY_UNLOCKED          = 665
    P.LANDING_GEAR_N_SAFE      = 659
    P.LANDING_GEAR_L_SAFE      = 660
    P.LANDING_GEAR_R_SAFE      = 661
    P.HANDLE_GEAR_WARNING      = 737

    P.APU_RPM_GUAGE            = 13
    P.APU_GEN_PWR_SWITCH       = 241
    P.LEFT_AC_GENERATOR_POWER  = 244
    P.RIGHT_AC_GENERATOR_POWER = 245
    P.BATTERY_POWER            = 246
    P.CONSOLE_LIGHT_DIAL       = 297

    P.canopy_unlocked_lamp     = nil
    P.gear_nose_lamp           = nil
    P.gear_left_lamp           = nil
    P.gear_right_lamp          = nil
    P.landing_gear_handle_lamp = nil
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
        local aircraft_lamp_utils = require("a-10c_lamps")

        value = device:get_argument_value(aircraft_lamp_utils.BATTERY_POWER)

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
    if type(device) ~= "number" and device ~= nil then
        local aircraft_lamp_utils = require("a-10c_lamps")

        -- get apu rpm
        local apu_rpm = device:get_argument_value(aircraft_lamp_utils.APU_RPM_GUAGE)
        local apu_gen_pwr_switch = device:get_argument_value(aircraft_lamp_utils.APU_GEN_PWR_SWITCH)

        -- get engine info
        local lEngInfo = Export.LoGetEngineInfo()

        if ((apu_rpm > 0.8 and apu_gen_pwr_switch == 1) or
            (lEngInfo.RPM.left  > 50 and device:get_argument_value(aircraft_lamp_utils.LEFT_AC_GENERATOR_POWER)  == 1) or
            (lEngInfo.RPM.right > 50 and device:get_argument_value(aircraft_lamp_utils.RIGHT_AC_GENERATOR_POWER) == 1) )
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

    P.canopy_unlocked_lamp     = nil
    P.gear_nose_lamp           = nil
    P.gear_left_lamp           = nil
    P.gear_right_lamp          = nil
    P.landing_gear_handle_lamp = nil
    P.battery_switch           = nil
    P.console_light            = nil

end

function P.create_lamp_status_payload( self )

    local updated        = false
    local status_changed = false
    local payload        = "000000"

    local console_light  = 0

    local device = Export.GetDevice(0)
    if type(device) ~= "number" and device ~= nil then
        status_changed, self.gear_nose_lamp = get_lamp( self.LANDING_GEAR_N_SAFE, self.gear_nose_lamp )
        updated = updated or status_changed

        status_changed, self.gear_left_lamp = get_lamp( self.LANDING_GEAR_L_SAFE, self.gear_left_lamp )
        updated = updated or status_changed

        status_changed, self.gear_right_lamp = get_lamp( self.LANDING_GEAR_R_SAFE, self.gear_right_lamp )
        updated = updated or status_changed

        status_changed, self.landing_gear_handle_lamp = get_lamp( self.HANDLE_GEAR_WARNING, self.landing_gear_handle_lamp )
        updated = updated or status_changed

        status_changed, self.canopy_unlocked_lamp = get_lamp( self.CANOPY_UNLOCKED, self.canopy_unlocked_lamp )
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
                                    self.canopy_unlocked_lamp,
                                    console_light )
    end

    return updated, payload

end

return a_10c_lamps