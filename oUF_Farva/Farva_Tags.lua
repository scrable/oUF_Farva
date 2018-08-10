local addon, ns = ...
local cfg = ns.cfg
local tags = CreateFrame("Frame")

local sValue = function(val)
	if (val >= 1e6) then
        return ('%.fm'):format(val / 1e6)
    elseif (val >= 1e3) then
        return ('%.fk'):format(val / 1e3)
    else
        return ('%d'):format(val)
    end
end

local utf8sub = function(string, i, dots)
	local bytes = string:len()
	if (bytes <= i) then
		return string
	else
		local len, pos = 0, 1
		while(pos <= bytes) do
			len = len + 1
			local c = string:byte(pos)
			if c > 240 then
				pos = pos + 4
			elseif c > 225 then
				pos = pos + 3
			elseif c > 192 then
				pos = pos + 2
			else
				pos = pos + 1
			end
			if (len == i) then break end
		end

		if (len == i and pos <= bytes) then
			return string:sub(1, pos - 1)..(dots and "..." or "")
		else
			return string
		end
	end
end

local function hex(r, g, b)
    if not r then return '|cffFFFFFF' end
    if(type(r) == 'table') then
        if(r.r) then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
    end
    return ('|cff%02x%02x%02x'):format(r * 255, g * 255, b * 255)
end

oUF.colors.power['MANA'] = {0.37, 0.6, 1}
oUF.colors.power['RAGE']  = {0.9,  0.3,  0.23}
oUF.colors.power['FOCUS']  = {1, 0.81,  0.27}
oUF.colors.power['RUNIC_POWER']  = {0, 0.81, 1}
oUF.colors.power['AMMOSLOT'] = {0.78,1, 0.78}
oUF.colors.power['FUEL'] = {0.9,  0.3,  0.23}
oUF.colors.power['POWER_TYPE_STEAM'] = {0.55, 0.57, 0.61}
oUF.colors.power['POWER_TYPE_PYRITE'] = {0.60, 0.09, 0.17}
oUF.colors.power['POWER_TYPE_HEAT'] = {0.55,0.57,0.61}
oUF.colors.power['POWER_TYPE_OOZE'] = {0.76,1,0}
oUF.colors.power['POWER_TYPE_BLOOD_POWER'] = {0.7,0,1}

-----------------
-- custom tags --
-----------------
oUF.Tags.Methods['veryshort:name'] = function(u, r)
    local name = UnitName(realUnit or u or r)
    return utf8sub(name, 5, false)
end
oUF.Tags.Events['veryshort:name'] = 'UNIT_NAME_UPDATE'

oUF.Tags.Methods['player:hp']  = function(u)
    local power = UnitPower(u)
    local min, max = UnitHealth(u), UnitHealthMax(u)
    local _, str, r, g, b = UnitPowerType(u)
    local t = oUF.colors.power[str]
    if t then
        r, g, b = t[1], t[2], t[3]
    end
    if UnitIsDead(u) then
        return '|cff559655 Dead|r'
    elseif UnitIsGhost(u) then
        return '|cff559655 Ghost|r'
    elseif not UnitIsConnected(u) then
        return '|cff559655 D/C|r'
    elseif (min<max) then
            return ('|cffAF5050'..sValue(min))..' | '..math.floor(min/max*100+.5)..'%'
    else
            return ('|cff559655'..sValue(min))
    end
end
oUF.Tags.Events['player:hp'] = 'UNIT_HEALTH UNIT_POWER_UPDATE UNIT_CONNECTION'


oUF.Tags.Methods['color'] = function(u, r)
    local reaction = UnitReaction(u, 'player')
		if (UnitIsPlayer(u)) and not cfg.class_colorbars then
        local _, class = UnitClass(u)
        return hex(oUF.colors.class[class])
    elseif reaction and not (UnitIsPlayer(u)) then
        return hex(oUF.colors.reaction[reaction])
    else
        return hex(1, 1, 1)
    end
end
oUF.Tags.Events['color'] = 'UNIT_HEALTH'

oUF.Tags.Methods["afkdnd"] = function(unit)
	if unit then
		return UnitIsAFK(unit) and "|cffffffff<AFK>|r " or UnitIsDND(unit) and "|cffffffff<DND>|r "
	end
end
oUF.Tags.Events["afkdnd"] = "PLAYER_FLAGS_CHANGED"

oUF.Tags.Methods["abbrevname"] = function(unit)
	local oldName = UnitName(unit)
	local newName = (string.len(oldName) > 14) and string.gsub(oldName, "%s?(.[\128-\191]*)%S+%s", "%1. ") or oldName

	if not UnitIsPlayer(unit) then
		return utf8sub(newName, 14, false)
	else
		return oldName
	end
end
oUF.Tags.Events["abbrevname"] = "UNIT_NAME_UPDATE"

if (not oUF.Tags.Methods["shortname"]) then
	oUF.Tags.Methods["shortname"] = function(unit)
		local oldName = UnitName(unit)
		local newName = (string.len(oldName) > 6) and string.gsub(oldName, "%s?(.[\128-\191]*)%S+%s", "%1. ") or oldName
		return utf8sub(newName, 6, false)
	end
end
oUF.Tags.Events["shortname"] = "UNIT_NAME_UPDATE"

oUF.Tags.Methods['raid:hp'] = function(u)
    local d = oUF.Tags.Methods['missinghp'](u) or 0
    if UnitIsDead(u) then
        return '|cff559655 Dead|r'
    elseif UnitIsGhost(u) then
        return '|cff559655 Ghost|r'
    elseif not UnitIsConnected(u) then
        return '|cff559655 D/C|r'
	elseif (d > 2e3) then
	    return '|cffAF5050-'..sValue(d)..'|r'
	else
        return nil
    end
end
oUF.Tags.Events['raid:hp'] = 'UNIT_HEALTH UNIT_CONNECTION'

oUF.Tags.Methods['altpower'] = function(u)
	local cur = UnitPower(u, ALTERNATE_POWER_INDEX)
	local max = UnitPowerMax(u, ALTERNATE_POWER_INDEX)
	local name = select(10, UnitAlternatePowerInfo(u))
    local per = math.floor(cur/max*100+.5)
	if name and per > 0 then
        return(name..': '..'|cffAF5050'..format('%d%%', per))
    elseif name then
        return(name..': '..'|cffAF5050'..'0%')
    else
        return ('|cffAF5050'..'0%')
	end
end
oUF.Tags.Events['altpower'] = 'UNIT_POWER_UPDATE UNIT_MAXPOWER'

ns.tags = tags
