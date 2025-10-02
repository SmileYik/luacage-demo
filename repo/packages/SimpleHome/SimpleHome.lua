-- SimpleHome.lua
--
-- Copyright (c) 2025 SmileYik
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local DATA_FORDER_NAME = "SimpleHome"
local json = require "@json/json"
local Player = luajava.bindClass("org.bukkit.entity.Player")

-- read json from file and decode to lua table
local function readJsonFile(name)
    local filepath = luaBukkit.env:path({DATA_FORDER_NAME, name})
    local file = io.open(filepath)
    if file then
        local str = file:read("*a")
        file:close()
        return json.decode(str)
    end
    return {}
end

-- encode lua table to json string and write to target file.
local function writeJsonFile(t, name)
    local filepath = luaBukkit.env:path({DATA_FORDER_NAME, name})
    local file = io.open(filepath, "w")
    if file then
        local str = json.encode(t)
        file:write(str)
        file:close()
        return true
    end
    return false
end

-- convert lua table to Location instance
local function tableToLocation(tLoc)
    return luajava.newInstance(
        "org.bukkit.Location",
        luaBukkit.server:getWorld(tLoc.world),
        tLoc.x, tLoc.y, tLoc.z
    )
end

-- convert Location instance to lua table
local function locationToTable(loc)
    return {
        world = loc:getWorld():getName(),
        x = loc:getX(),
        y = loc:getY(),
        z = loc:getZ()
    }
end

-- register home command
luaBukkit.env:registerRawCommand("home", function (sender, command, label, args)
    if not luajava.class2Obj(Player):isInstance(sender) then
        sender:sendMessage("Only player can use this command!")
        return false
    end
    local homes = readJsonFile(sender:getName() .. ".json")
    if not homes.home then
        sender:sendMessage("You have not set a home yet")
        return true
    end
    local loc = tableToLocation(homes.home)
    sender:teleport(loc)
    return true
end)

-- register sethome command
luaBukkit.env:registerRawCommand("sethome", function (sender, command, label, args)
    if not luajava.class2Obj(Player):isInstance(sender) then
        sender:sendMessage("Only player can use this command!")
        return false
    end
    local file = sender:getName() .. ".json"
    local homes = readJsonFile(file)
    local loc = sender:getLocation()
    homes.home = locationToTable(loc)
    if writeJsonFile(homes, file) then
        sender:sendMessage("Home set successful!")
    else
        sender:sendMessage("Home set failed!")
    end
    return true
end)

-- create data folder
local dataFolder = luaBukkit.env:file(DATA_FORDER_NAME)
if not dataFolder:exists() then
    dataFolder:mkdirs()
end