-- SimpleNBTCommand.lua
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

local NBT = luajava.bindClass("de.tr7zw.nbtapi.NBT")
local NBTType = luajava.bindClass("de.tr7zw.nbtapi.NBTType")
local NBTTypeCompound = NBTType.NBTTagCompound

local NBTSetter = {
    boolean = function(compound, key, str) compound:setBoolean(key, str == "true") end,
    byte    = function(compound, key, str) compound:setByte(key, tonumber(str)) end,
    double  = function(compound, key, str) compound:setDouble(key, tonumber(str)) end,
    float   = function(compound, key, str) compound:setFloat(key, tonumber(str)) end,
    int     = function(compound, key, str) compound:setInteger(key, tonumber(str)) end,
    long    = function(compound, key, str) compound:setLong(key, tonumber(str)) end,
    short   = function(compound, key, str) compound:setShort(key, tonumber(str)) end,
    string  = function(compound, key, str) compound:setString(key, str) end
}

-- split nbt path string to an array
-- example: "abc.def.key" -> {"abc", "def", "key"}
local function splitNbtPath(path)
    local split = {}
    for p in string.gmatch(path, '[^.]*') do
        table.insert(split, p)
    end
    return split
end

local function getItemInMainHand(sender)
    local item = sender:getInventory():getItemInMainHand()
    if not item or item:getAmount() == 0 then
        sender:sendMessage("You are not holding an item!")
        return nil
    end
    return item
end

-- set nbt
local function setNbt(sender, args)
    if #args < 3 then sender:sendMessage("command wrong!") end
    local item = getItemInMainHand(sender)
    local path, type, value = args[1], args[2], args[3]
    local keys = splitNbtPath(path)
    if not item or #keys == 0 then
        return
    end
    for i = 4, #args do value = value .. " " .. args[i] end

    NBT:modify(item, luaBukkit.helper:consumer(function (nbt)
        local size = #keys
        local idx = 1
        local compound = nbt
        while idx < size do
            if compound:hasTag(keys[idx], NBTTypeCompound) then
                compound = compound:getCompound(keys[idx])
            else
                compound = compound:resolveOrCreateCompound(keys[idx])
            end
            idx = idx + 1
        end
        local setter = NBTSetter[type]
        if not setter then setter = NBTSetter.string end
        setter(compound, keys[idx], value)
        sender:sendMessage("Set '" .. path .. "=" .. value .. "' in the item you are holding!")
    end))

end

-- command: set string nbt
local function setString(sender, args)
    local item = getItemInMainHand(sender)
    if not item then return end
    local key, value = args[1], args[2]
    NBT:modify(item, luaBukkit.helper:consumer(function (nbt)
        nbt:setString(key, value)
    end))
    sender:sendMessage("Set '" .. key .. "=" .. value .. "' in the item you are holding!")
end

-- command: print item nbt
local function printNbt(sender, args)
    local item = getItemInMainHand(sender)
    if not item then return end
    local nbt = NBT:readNbt(item)
    if nbt then
        sender:sendMessage(nbt:toString())
    else
        sender:sendMessage("No nbt!")
    end
end

-- command: remove key
local function removeNbtKey(sender, args)
    local item = getItemInMainHand(sender)
    local path = args[1]
    local keys = splitNbtPath(path)
    if #keys == 0 or not item then return end
    NBT:modify(item, luaBukkit.helper:consumer(function (nbt)
        local size = #keys
        local idx = 1
        local compound = nbt
        while idx < size do
            if compound:hasTag(keys[idx], NBTTypeCompound) then
                compound = compound:getCompound(keys[idx])
            else
                return
            end
            idx = idx + 1
        end
        compound:removeKey(keys[idx])
    end))
    sender:sendMessage("Removed!")
end

-- build a command class
local commands = {
    {
        command = "setString",
        description = "set a string nbt",
        args = {"key", "value"},
        needPlayer = true,
        handler = setString
    },
    {
        command = "print",
        description = "print nbt as json",
        needPlayer = true,
        handler = printNbt
    },
    {
        command = "remove",
        description = "remove nbt tag",
        args = {"key"},
        needPlayer = true,
        handler = removeNbtKey
    },
    {
        command = "set",
        description = "set nbt tag, type is byte, short, int, long, float, double, boolean, string",
        args = {"key", "type", "value"},
        needPlayer = true,
        unlimitedArgs = true,
        handler = setNbt
    }
}

-- register command
local topCommandClass = luaBukkit.env
                                 :commandClassBuilder()
                                 :commands(commands)
                                 :build("NBT")
local result = luaBukkit.env:registerCommand("NBT", {topCommandClass})
if result:isError() then
    luaBukkit.log:info("[SimpleNBTCommand] Register command failed!")
else
    luaBukkit.log:info("[SimpleNBTCommand] Register command successes! enter '/nbt help' to show help!")
end