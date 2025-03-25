-------------------------------------------------------------------------------
--
-- f-16c_50_lamps.lua
--
-- Use at own risk without warranty.
--
-- Utility functions for retrieving DCS F-16C_50 lamp states and packaging
-- for TCP packet transmission to Thrustmaster Target TMHotasLEDSync.tmc
-- script.
--
-- Author: slughead
-- Last edit: 03/03/2024
--
------------------------------------------------------------------------------

-- DCS World OpenBeta\Mods\aircraft\F-16C\Cockpit\Scripts\MainPanel\lamps.lua
-- LG Control Panel
-- create_caution_lamp(350, CautionLights.GEAR_NOSE)
-- create_caution_lamp(351, CautionLights.GEAR_LEFT)
-- create_caution_lamp(352, CautionLights.GEAR_RIGHT)
-- create_caution_lamp(369, CautionLights.GEAR_WARNING)

-- create_caution_lamp(446, CautionLights.JFS_RUN)
-- create_caution_lamp(512, CautionLights.MAIN_GEN)
-- create_caution_lamp(515, CautionLights.STBY_GEN)
-- create_caution_lamp(518, CautionLights.FLCS_RLY)
-- create_caution_lamp(524, CautionLights.HYDRAZN)
-- create_caution_lamp(523, CautionLights.AIR)
-- create_caution_lamp(526, CautionLights.EPU)



-- rwr_Search           = create_rwr_lights(396, RWRLights.SEARCH)
-- rwr_Activity         = create_rwr_lights(398, RWRLights.ACTIVITY)
-- rwr_ActPower         = create_rwr_lights(423, RWRLights.ACT_POWER)
-- rwr_Alt_Low          = create_rwr_lights(400, RWRLights.ALT_LOW)
-- rwr_Alt              = create_rwr_lights(424, RWRLights.ALT)
-- rwr_Power            = create_rwr_lights(402, RWRLights.POWER)
-- rwr_Hand_Up          = create_rwr_lights(142, RWRLights.HANDOFF_UP)
-- rwr_Hand_H           = create_rwr_lights(136, RWRLights.HANDOFF_H)
-- rwr_Launch           = create_rwr_lights(144, RWRLights.MSL_LAUNCH)
-- rwr_Mode_Pri         = create_rwr_lights(146, RWRLights.MODE_PRI)
-- rwr_Mode_Open        = create_rwr_lights(137, RWRLights.MODE_OPEN)
-- rwr_Ship_U           = create_rwr_lights(153, RWRLights.SHIP_U)
-- rwr_Ship_unkn        = create_rwr_lights(148, RWRLights.SHIP_UNKNOWN)
-- rwr_Sys_On           = create_rwr_lights(154, RWRLights.SYSTEST_ON)
-- rwr_Sys              = create_rwr_lights(150, RWRLights.SYSTEST)
-- rwr_Sep_Up           = create_rwr_lights(152, RWRLights.TGTSEP_UP)
-- rwr_Sep_Down         = create_rwr_lights(138, RWRLights.TGTSEP_DOWN)

local P = {}
f_16c_50_lamps = P

    P.GEAR_NOSE     = 350
    P.GEAR_LEFT     = 351
    P.GEAR_RIGHT    = 352
    P.GEAR_WARNING  = 369

    P.RWR_SEARCH    = 396
    P.RWR_ACTIVITY  = 398
    P.RWR_ACT_POWER = 423
    P.RWR_ALT_LOW   = 400
    P.RWR_ALT       = 424
    P.RWR_POWER     = 402

    P.JFS_RUN       = 446
    P.MAIN_GEN      = 512
    P.STBY_GEN      = 515
    P.FLCS_RLY      = 518
    P.EPU           = 526

    P.gear_nose_status     = nil
    P.gear_left_status     = nil
    P.gear_right_status    = nil
    P.gear_warning_status  = nil
    P.rwr_search_status    = nil
    P.rwr_activity_status  = nil
    P.rwr_act_power_status = nil
    P.rwr_alt_low_status   = nil
    P.rwr_alt_status       = nil
    P.rwr_power_status     = nil

    P.jfs_run_status       = nil
    P.main_gen_status      = nil
    P.stby_gen_status      = nil
    P.flcs_rly_status      = nil
    P.epu_status           = nil


local function get_lamp_status( id, status )
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

function P.init( self )

    P.gear_nose_status     = nil
    P.gear_left_status     = nil
    P.gear_right_status    = nil
    P.gear_warning_status  = nil
    P.rwr_search_status    = nil
    P.rwr_activity_status  = nil
    P.rwr_act_power_status = nil
    P.rwr_alt_low_status   = nil
    P.rwr_alt_status       = nil
    P.rwr_power_status     = nil
    P.jfs_run_status       = nil
    P.main_gen_status      = nil
    P.stby_gen_status      = nil
    P.flcs_rly_status      = nil
    P.epu_status           = nil

end

function P.create_lamp_status_payload(self)

    local updated        = false
    local status_changed = false
    local payload

    local device = Export.GetDevice(0)
    if type(device) ~= "number" and device ~= nil then
        status_changed, self.gear_nose_status = get_lamp_status( self.GEAR_NOSE, self.gear_nose_status )
        updated = updated or status_changed

        status_changed, self.gear_left_status = get_lamp_status( self.GEAR_LEFT, self.gear_left_status )
        updated = updated or status_changed

        status_changed, self.gear_right_status = get_lamp_status( self.GEAR_RIGHT, self.gear_right_status )
        updated = updated or status_changed

        status_changed, self.gear_warning_status = get_lamp_status( self.GEAR_WARNING, self.gear_warning_status )
        updated = updated or status_changed

        status_changed, self.rwr_search_status = get_lamp_status( self.RWR_SEARCH, self.rwr_search_status )
        updated = updated or status_changed

        status_changed, self.rwr_activity_status = get_lamp_status( self.RWR_ACTIVITY, self.rwr_activity_status )
        updated = updated or status_changed

        status_changed, self.rwr_act_power_status = get_lamp_status( self.RWR_ACT_POWER, self.rwr_act_power_status )
        updated = updated or status_changed

        status_changed, self.rwr_alt_low_status = get_lamp_status( self.RWR_ALT_LOW, self.rwr_alt_low_status )
        updated = updated or status_changed

        status_changed, self.rwr_alt_status = get_lamp_status( self.RWR_ALT, self.rwr_alt_status )
        updated = updated or status_changed

        status_changed, self.rwr_power_status = get_lamp_status( self.RWR_POWER, self.rwr_power_status )
        updated = updated or status_changed

        status_changed, self.jfs_run_status = get_lamp_status( self.JFS_RUN, self.jfs_run_status )
        updated = updated or status_changed

        status_changed, self.main_gen_status = get_lamp_status( self.MAIN_GEN, self.main_gen_status )
        updated = updated or status_changed

        status_changed, self.stby_gen_status = get_lamp_status( self.STBY_GEN, self.stby_gen_status )
        updated = updated or status_changed

        status_changed, self.flcs_rly_status = get_lamp_status( self.FLCS_RLY, self.flcs_rly_status )
        updated = updated or status_changed

        status_changed, self.epu_status = get_lamp_status( self.EPU, self.epu_status )
        updated = updated or status_changed

        payload = string.format( "%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d",
                                 self.gear_nose_status,
                                 self.gear_left_status,
                                 self.gear_right_status,
                                 self.gear_warning_status,
                                 self.rwr_search_status,
                                 self.rwr_activity_status,
                                 self.rwr_act_power_status,
                                 self.rwr_alt_low_status,
                                 self.rwr_alt_status,
                                 self.rwr_power_status,
                                 self.jfs_run_status,
                                 self.main_gen_status,
                                 self.stby_gen_status,
                                 self.flcs_rly_status,
                                 self.epu_status )
    end

    return updated, payload

end

return f_16c_50_lamps