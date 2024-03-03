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
-- Last edit: 03/03/2024
--
------------------------------------------------------------------------------

local P = {}
generic_aircraft_utils = P

    P.speedbrakes_value = nil

function P.init( self )
    self.speedbrakes_value   = nil
end

function P.create_speedbrake_status_payload( self, aircraft_name )

    local updated = false
    local payload

    local lMechInfo = Export.LoGetMechInfo() -- mechanical components,  e.g. Flaps, Wheelbrakes,...
    if (lMechInfo ~= nil) then
        local value = lMechInfo.speedbrakes.value

        -- fudge factor for aircraft that do not use the full 0 to 1.0 range for speedbrake
        --if (aircraft_name == "A-10C")   then value = value * 1.3; end
        --if (aircraft_name == "A-10C_2") then value = value * 1.3; end

        -- ensure full range is used for aircraft that almost reach 1.0
        if (value >= 0.9) then value = 1.0 end

        value = math.floor(value * 5)
        payload = string.format("%d", value)

        if (self.speedbrakes_value ~= value) then
            self.speedbrakes_value = value

            updated = true;
        end
    else
        payload = string.format("%d", 0)
    end

    return updated, payload
end

return generic_aircraft_utils