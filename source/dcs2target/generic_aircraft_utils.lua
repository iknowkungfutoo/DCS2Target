-------------------------------------------------------------------------------
--
-- generic_aircraft_utils.lua
--
-- Use at own risk without warranty.
--
-- Utility functions for retrieving generic DCS aircraft simulation data and
-- packaging for TCP packet transmission to Thrustmaster Target
-- TMHotasLEDSync.tmc script.
--
-- Author: slughead
-- Last edit: 21/07/2026
--
------------------------------------------------------------------------------

-- tm_target_utils is required (not just referenced as a global) because
-- dcs2target.lua's own copy is a file-local variable, not a real Lua
-- global - require() returns the same cached module instance either way.
local tm_target_utils = require("tm_target_utils")

local P = {}
generic_aircraft_utils = P

    P.speedbrakes_value = nil

function P.init( self )
    P.speedbrakes_value   = nil
end

function P.create_speedbrake_status_payload( self, aircraft_name )

    local updated = false
    local payload = ""

    local lMechInfo = Export.LoGetMechInfo() -- mechanical components,  e.g. Flaps, Wheelbrakes,...
    if (lMechInfo ~= nil) then
        local value = lMechInfo.speedbrakes.value

        -- fudge factor for aircraft that do not use the full 0 to 1.0 range for speedbrake
        if (aircraft_name == "A-10C_2") then value = value * 1.3; end

        -- ensure full range is used for aircraft that almost reach 1.0
        if (value >= 0.95) then value = 1.0 end

        local percent = math.floor(value * 100)

        if (P.speedbrakes_value ~= percent) then
            updated = true
            P.speedbrakes_value = percent
            payload = tm_target_utils.tag_entry("B", percent, 3)
        end
    end

    return updated, payload
end

return generic_aircraft_utils
