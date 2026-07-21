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
-- Last edit: 21/07/2026
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
-- create_caution_lamp(13,		CautionLights.CPT_LTS_MASTER_CAUTION)

-- DCS World OpenBeta\Mods\aircraft\FA-18C\Cockpit\Scripts\clickabledata.lua
-- elements["pnt_233"] = default_button2(_("Launch Bar Control Switch, EXTEND/RETRACT"), devices.GEAR_INTERFACE, gear_commands.LaunchBarSw, 233, anim_speed_default)

-- Neither wing fold nor arresting hook have a cockpit indicator lamp
-- reachable through this module's own MainPanel/lamps.lua excerpt above.
-- Hook DOES have one elsewhere though: device argument 294, "CPT_LTS_HOOK"
-- under "Arresting Hook Control Handle" (confirmed against a community DCS
-- export-argument reference) - read via get_lamp() like the other lamps
-- below, not LoGetMechInfo().hook, which was never populated for this
-- aircraft and left the hook LED permanently dark on the TARGET side.
-- Wing fold genuinely has no lamp or LoGetMechInfo() field at all (confirmed
-- by dumping every key LoGetMechInfo() returns for this aircraft - see
-- create_carrier_status_payload()), so its status is read from the wing
-- fold handle's own PULL/STOW device argument (296) instead, as a proxy for
-- "handle engaged" rather than true wing position.


local tm_target_utils = require("tm_target_utils")

local P = {}
fa_18c_hornet_lamps = P

    P.CPT_LTS_NOSE_GEAR              = 166
    P.CPT_LTS_LEFT_GEAR              = 165
    P.CPT_LTS_RIGHT_GEAR             = 167

    P.CPT_LTS_LDG_GEAR_HANDLE        = 227
    P.CPT_LTS_APU_READY              = 376
    P.CPT_LTS_MASTER_CAUTION         = 13
    P.CPT_LTS_HOOK                   = 294

    P.LEFT_GENERATOR_CONTROL_SWITCH  = 402
    P.RIGHT_GENERATOR_CONTROL_SWITCH = 403
    P.BATTERY_SWITCH                 = 404
    P.CONSOLE_LIGHT_DIAL             = 413
    P.LAUNCH_BAR_SWITCH              = 233
    P.WING_FOLD_HANDLE_PULL          = 296

    P.landing_gear_handle_lamp = nil
    P.nose_gear_lamp           = nil
    P.left_gear_lamp           = nil
    P.right_gear_lamp          = nil
    P.apu_lamp                 = nil
    P.battery_switch           = nil
    P.console_light            = nil
    P.master_caution_lamp      = nil
    P.wing_fold_status         = nil
    P.launch_bar_status        = nil
    P.hook_status              = nil


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

-- Thresholded like a mechanization-info value would be, but for a raw
-- clickable-device argument instead - the argument may animate through
-- intermediate values while moving, unlike the cockpit lamps get_lamp()
-- reads, which are clean 0/1 booleans.
local function get_argument_status( current_value, arg_value )
    local updated = false
    local value = 0

    if (arg_value ~= nil and arg_value >= 0.5) then
        value = 1
    end

    if current_value ~= value then
        updated = true
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
    P.master_caution_lamp      = nil
    P.wing_fold_status         = nil
    P.launch_bar_status        = nil
    P.hook_status              = nil

end

function P.create_lamp_status_payload( self )

    local updated        = false
    local status_changed = false
    local payload        = ""

    local device = Export.GetDevice(0)
    if (type(device) ~= "number" and device ~= nil) then
        status_changed, self.gear_nose_lamp = get_lamp( self.CPT_LTS_NOSE_GEAR, self.gear_nose_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("N", self.gear_nose_lamp, 1) end
        updated = updated or status_changed

        status_changed, self.gear_left_lamp = get_lamp( self.CPT_LTS_LEFT_GEAR, self.gear_left_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("L", self.gear_left_lamp, 1) end
        updated = updated or status_changed

        status_changed, self.gear_right_lamp = get_lamp( self.CPT_LTS_RIGHT_GEAR, self.gear_right_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("R", self.gear_right_lamp, 1) end
        updated = updated or status_changed

        status_changed, self.landing_gear_handle_lamp = get_lamp( self.CPT_LTS_LDG_GEAR_HANDLE, self.landing_gear_handle_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("H", self.landing_gear_handle_lamp, 1) end
        updated = updated or status_changed

        status_changed, self.apu_lamp = get_lamp( self.CPT_LTS_APU_READY, self.apu_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("P", self.apu_lamp, 1) end
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

function P.create_carrier_status_payload( self )

    local updated        = false
    local status_changed = false
    local payload         = ""

    local device = Export.GetDevice(0)
    if (type(device) ~= "number" and device ~= nil) then
        status_changed, self.master_caution_lamp = get_lamp( self.CPT_LTS_MASTER_CAUTION, self.master_caution_lamp )
        if status_changed then payload = payload..tm_target_utils.tag_entry("M", self.master_caution_lamp, 1) end
        updated = updated or status_changed

        status_changed, self.launch_bar_status = get_lamp( self.LAUNCH_BAR_SWITCH, self.launch_bar_status )
        if status_changed then payload = payload..tm_target_utils.tag_entry("X", self.launch_bar_status, 1) end
        updated = updated or status_changed

        status_changed, self.hook_status = get_lamp( self.CPT_LTS_HOOK, self.hook_status )
        if status_changed then payload = payload..tm_target_utils.tag_entry("O", self.hook_status, 1) end
        updated = updated or status_changed

        -- LoGetMechInfo() has no wing-fold field at all for this aircraft
        -- (confirmed: keys are speedbrakes/parachute/canopy/wheelbrakes/gear/
        -- controlsurfaces/refuelingboom/flaps - no .wing, nothing hook/fold
        -- related), and there's no cockpit lamp for it either. Reading the
        -- wing fold handle's own PULL/STOW position instead, as a proxy for
        -- "handle engaged" - thresholded via get_argument_status() since
        -- it's a device argument that may animate through intermediate
        -- values while moving.
        local wing_fold_handle_value = device:get_argument_value( self.WING_FOLD_HANDLE_PULL )
        status_changed, self.wing_fold_status = get_argument_status( self.wing_fold_status, wing_fold_handle_value )
        if status_changed then payload = payload..tm_target_utils.tag_entry("D", self.wing_fold_status, 1) end
        updated = updated or status_changed
    end

    return updated, payload

end

return fa_18c_hornet_lamps