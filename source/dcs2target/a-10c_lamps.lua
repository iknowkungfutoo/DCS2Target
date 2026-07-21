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
-- Last edit: 21/07/2026
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
-- caution_lamp(404,SystemsSignals.flag_MASTER_WARNING_STUB)	-- MASTER WARNING
-- caution_lamp(484,SystemsSignals.flag_ANTISKID)			-- CAUTION LIGHT PANEL
-- caution_lamp(527,SystemsSignals.flag_INST_INV)			-- CAUTION LIGHT PANEL, Instrument Inverter
-- caution_lamp(215,SystemsSignals.flag_L_ENG_FIRE)
-- caution_lamp(216,SystemsSignals.flag_APU_FIRE)
-- caution_lamp(217,SystemsSignals.flag_R_ENG_FIRE)

-- Only a single fire warning LED is available on the TARGET side, so the
-- three individual fire lamps (left engine, APU, right engine) are combined
-- with OR logic into one fire_warning status bit.


local tm_target_utils = require("tm_target_utils")

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

    P.MASTER_CAUTION           = 404
    P.ANTI_SKID                = 484
    P.INST_INVERTER            = 527
    P.L_ENG_FIRE               = 215
    P.APU_FIRE                 = 216
    P.R_ENG_FIRE               = 217

    P.canopy_unlocked_lamp     = nil
    P.gear_nose_lamp           = nil
    P.gear_left_lamp           = nil
    P.gear_right_lamp          = nil
    P.landing_gear_handle_lamp = nil
    P.battery_switch           = nil
    P.console_light            = nil
    P.master_caution_lamp      = nil
    P.anti_skid_lamp           = nil
    P.inverter_lamp            = nil
    P.fire_warning_status      = nil


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

local function get_fire_warning_status( current_value )
    local updated = false
    local value = 0

    local device = Export.GetDevice(0)
    if type(device) ~= "number" and device ~= nil then
        local aircraft_lamp_utils = require("a-10c_lamps")

        if (device:get_argument_value(aircraft_lamp_utils.L_ENG_FIRE) == 1 or
            device:get_argument_value(aircraft_lamp_utils.APU_FIRE)   == 1 or
            device:get_argument_value(aircraft_lamp_utils.R_ENG_FIRE) == 1)
        then
            value = 1
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
    P.master_caution_lamp      = nil
    P.anti_skid_lamp           = nil
    P.inverter_lamp            = nil
    P.fire_warning_status      = nil

end

function P.create_lamp_status_payload( self )

    local updated        = false
    local status_changed = false
    local payload        = ""

    local device = Export.GetDevice(0)
    if type(device) ~= "number" and device ~= nil then
        status_changed, self.gear_nose_lamp = get_lamp( self.LANDING_GEAR_N_SAFE, self.gear_nose_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("N", self.gear_nose_lamp, 1) end
        updated = updated or status_changed

        status_changed, self.gear_left_lamp = get_lamp( self.LANDING_GEAR_L_SAFE, self.gear_left_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("L", self.gear_left_lamp, 1) end
        updated = updated or status_changed

        status_changed, self.gear_right_lamp = get_lamp( self.LANDING_GEAR_R_SAFE, self.gear_right_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("R", self.gear_right_lamp, 1) end
        updated = updated or status_changed

        status_changed, self.landing_gear_handle_lamp = get_lamp( self.HANDLE_GEAR_WARNING, self.landing_gear_handle_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("H", self.landing_gear_handle_lamp, 1) end
        updated = updated or status_changed

        status_changed, self.canopy_unlocked_lamp = get_lamp( self.CANOPY_UNLOCKED, self.canopy_unlocked_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("K", self.canopy_unlocked_lamp, 1) end
        updated = updated or status_changed

        local battery_changed
        battery_changed, self.battery_switch = get_battery_switch( self.battery_switch )
        updated = updated or battery_changed

        local console_raw_changed
        console_raw_changed, self.console_light = get_console_light( self.console_light )
        updated = updated or console_raw_changed

        -- console_light tag reflects a derived value (raw dial reading, or a
        -- forced minimum brightness when the battery is on but the dial
        -- reads off), so it needs sending whenever EITHER contributing raw
        -- field changes, not just when the dial itself does.
        if (battery_changed or console_raw_changed) then
            local console_light
            if (self.battery_switch == 1 and self.console_light == 0) then
                -- set console lights to minimum (not off) so that the Warthog LEDs can be seen, e.g. the APU light
                console_light = 1
            else
                console_light = self.console_light
            end
            payload = payload..tm_target_utils.tag_entry("C", console_light, 1)
        end
    end

    return updated, payload

end

function P.create_caution_status_payload( self )

    local updated        = false
    local status_changed = false
    local payload         = ""

    local device = Export.GetDevice(0)
    if type(device) ~= "number" and device ~= nil then
        status_changed, self.master_caution_lamp = get_lamp( self.MASTER_CAUTION, self.master_caution_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("M", self.master_caution_lamp, 1) end
        updated = updated or status_changed

        status_changed, self.anti_skid_lamp = get_lamp( self.ANTI_SKID, self.anti_skid_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("S", self.anti_skid_lamp, 1) end
        updated = updated or status_changed

        status_changed, self.inverter_lamp = get_lamp( self.INST_INVERTER, self.inverter_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("I", self.inverter_lamp, 1) end
        updated = updated or status_changed

        status_changed, self.fire_warning_status = get_fire_warning_status( self.fire_warning_status )
        if status_changed then payload = payload..tm_target_utils.tag_entry("F", self.fire_warning_status, 1) end
        updated = updated or status_changed
    end

    return updated, payload

end

return a_10c_lamps