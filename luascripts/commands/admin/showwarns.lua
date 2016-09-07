
-- WolfAdmin module for Wolfenstein: Enemy Territory servers.
-- Copyright (C) 2015-2016 Timo 'Timothy' Smit

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- at your option any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local auth = require "luascripts.wolfadmin.auth.auth"
local util = require "luascripts.wolfadmin.util.util"
local settings = require "luascripts.wolfadmin.util.settings"
local pagination = require "luascripts.wolfadmin.util.pagination"
local db = require "luascripts.wolfadmin.db.db"

local commands = require "luascripts.wolfadmin.commands.commands"
local warns = require "luascripts.wolfadmin.admin.warns"

function commandShowWarns(clientId, cmdArguments)
    if settings.get("g_warnHistory") == 0 or not db.isconnected() then
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay "..clientId.." \"^dshowwarns: ^9warn history is disabled.\";")
        
        return true
    elseif cmdArguments[1] == nil then
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay "..clientId.." \"^dshowwarns usage: "..commands.getadmin("showwarns")["syntax"].."\";")
        
        return true
    elseif tonumber(cmdArguments[1]) == nil then
        cmdClient = et.ClientNumberFromString(cmdArguments[1])
    else
        cmdClient = tonumber(cmdArguments[1])
    end
    
    if cmdClient == -1 then
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay "..clientId.." \"^dshowwarns: ^9no or multiple matches for '^7"..cmdArguments[1].."^9'.\";")
        
        return true
    elseif not et.gentity_get(cmdClient, "pers.netname") then
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay "..clientId.." \"^dshowwarns: ^9no connected player by that name or slot #\";")
        
        return true
    end
    
    local count = warns.getcount(cmdClient)
    local limit, offset = pagination.calculate(count, 30, tonumber(cmdArguments[2]))
    local playerWarns = warns.getlimit(cmdClient, limit, offset)
    
    if not (playerWarns and #playerWarns > 0) then
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay "..clientId.." \"^dshowwarns: ^9there are no warnings for player ^7"..et.gentity_get(cmdClient, "pers.netname").."^9.\";")
    else
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay "..clientId.." \"^dWarns for ^7"..et.gentity_get(cmdClient, "pers.netname").."^d:\";")
        for _, warn in pairs(playerWarns) do
            et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay "..clientId.." \"^f"..string.format("%4s", warn["id"]).." ^7"..string.format("%-20s", util.removeColors(db.getlastalias(warn["admin_id"])["alias"])).." ^f"..os.date("%d/%m/%Y", warn["datetime"]).." ^7"..warn["reason"].."\";")
        end
        
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay "..clientId.." \"^9Showing results ^7"..(offset + 1).." ^9- ^7"..limit.." ^9of ^7"..count.."^9.\";")
        et.trap_SendConsoleCommand(et.EXEC_APPEND, "cchat "..clientId.." \"^dshowwarns: ^9warnings for ^7"..et.gentity_get(cmdClient, "pers.netname").." ^9were printed to the console.\";")
    end
    
    return true
end
commands.addadmin("showwarns", commandShowWarns, auth.PERM_LISTWARNS, "display warnings for a specific player", "^9[^3name|slot#^9] ^9(^hoffset^9)", function() return (settings.get("g_warnHistory") == 0 or not db.isconnected()) end)