-------------------------------------------------------------------------------
--
-- tm_target_utils.lua
--
-- Use at own risk without warranty.
--
-- Utility functions for formating Thrustmaster Target TCP packets.
--
-- Author: slughead
-- Date: 26/11/2023
--
------------------------------------------------------------------------------

local P = {}
tm_target_utils = P

    -- command types
    P.QUIT    = "q" -- simulation exit
    P.RESET   = "r" -- reset led states, ejct, die, etc
    P.MODULE  = "m" -- module / acircraft name
    P.UPDATE  = "u" -- update lamp states
    P.VERSION = "v" -- version

local function bitand(a, b)

    local result = 0
    local bitval = 1

    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
            result = result + bitval      -- set the current bit
        end
        bitval = bitval * 2 -- shift left
        a = math.floor(a/2) -- shift right
        b = math.floor(b/2)
    end

    return result

end

function P.pack_data(data)

    -- header is the length of the data plus leader of the header (2 bytes)
    -- header is in little endian format
    -- payload is big endian format

    local len = #data + 2
    local header = {}
    header[1] = bitand(len, 0xFF) -- len & 0xFF
    header[2] = bitand(math.floor( len / 2^8 ), 0xFF) -- (len >> 8) & 0xFF

    return string.char( header[1], header[2] ) .. data -- two bytes of header plus payload

end

return tm_target_utils