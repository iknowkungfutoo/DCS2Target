-------------------------------------------------------------------------------
--
-- jf_17_lamps.lua
--
-- Use at own risk without warranty.
--
-- Utility functions for retrieving DCS JF-17 lamp states and packaging
-- for TCP packet transmission to Thrustmaster Target TMHotasLEDSync.tmc
-- script.
--
-- Author: Tigershark2005
-- Date: 6/2/2024
--
------------------------------------------------------------------------------

-- Output bytes are in the order of, gear nose, gear left, gear right, gear warning, gear transit, aircraft master warning
-- DCS World\Mods\aircraft\JF-17\Cockpit\Scripts\MainPanel\lamps.lua

local P = {}
jf_17_lamps = P

    P.GEAR_TRANSIT   = 100
    P.GEAR_NOSE      = 101
    P.GEAR_LEFT      = 102
    P.GEAR_RIGHT     = 103
    P.GEAR_WARNING   = 107
    P.MASTER_WARNING = 130

    P.gear_transit_status       = nil
    P.gear_nose_status          = nil
    P.gear_left_status          = nil
    P.gear_right_status         = nil
    P.gear_warning_status       = nil
    P.master_warning_status     = nil

local function get_lamp_status( id, status )
    local updated = false
    local value

    local device = Export.GetDevice("LIGHTS")
    if type(device) ~= "number" and device ~= nil then
        value = device:get_argument_value(id) -- returns 0 (Off) 1 (On)
        if status ~= value then
            updated = true
        end
    end

    return updated, value
end

function P.create_lamp_status_payload(self)

    local updated        = false
    local status_changed = false
    local payload
    
    local device = Export.GetDevice("LIGHTS")
    if type(device) ~= "number" and device ~= nil then
        status_changed, self.gear_nose_status = get_lamp_status( self.GEAR_NOSE, self.gear_nose_status )
        updated = updated or status_changed

        status_changed, self.gear_left_status = get_lamp_status( self.GEAR_LEFT, self.gear_left_status )
        updated = updated or status_changed

        status_changed, self.gear_right_status = get_lamp_status( self.GEAR_RIGHT, self.gear_right_status )
        updated = updated or status_changed

        status_changed, self.gear_warning_status = get_lamp_status( self.GEAR_WARNING, self.gear_warning_status )
        updated = updated or status_changed

        status_changed, self.gear_transit_status = get_lamp_status( self.GEAR_TRANSIT, self.gear_transit_status )
        updated = updated or status_changed

        status_changed, self.master_warning_status = get_lamp_status( self.MASTER_WARNING, self.master_warning_status )
        updated = updated or status_changed

        payload = string.format( "%d%d%d%d%d%d",
                                 self.gear_nose_status,
                                 self.gear_left_status,
                                 self.gear_right_status,
                                 self.gear_warning_status,
                                 self.gear_transit_status,
                                 self.master_warning_status
                                 )
    end

    return updated, payload

end

return jf_17_lamps