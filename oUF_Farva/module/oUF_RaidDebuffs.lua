local _, ns = ...
local oUF = ns.oUF or oUF
local cfg = ns.cfg
local Plugin = CreateFrame("Frame")

local addon = {}
ns.oUF_RaidDebuffs = addon
if not _G.oUF_RaidDebuffs then
	_G.oUF_RaidDebuffs = addon
end

local debuff_data = {}
addon.DebuffData = debuff_data

addon.ShowDispelableDebuff = true
addon.FilterDispellableDebuff = true
addon.MatchBySpellName = false

addon.priority = 10

local function add(spell)
	if addon.MatchBySpellName and type(spell) == "number" then
		spell = GetSpellInfo(spell)
	end

	debuff_data[spell] = addon.priority
	addon.priority = addon.priority + 1
end

function addon:RegisterDebuffs(t)
	for _, v in next, t do
		add(v)
	end
end

function addon:ResetDebuffData()
	wipe(debuff_data)
	addon.priority = 10
end

local DispellColor = {
	["Magic"] = {.2, .6, 1},
	["Curse"] = {.6, 0, 1},
	["Disease"] = {.6, .4, 0},
	["Poison"] = {0, .6, 0},
	["nil"] = {1, 0, 0}
}

local DispellPriority = {
	["Magic"] = 4,
	["Curse"] = 3,
	["Disease"] = 2,
	["Poison"] = 1
}

local DispellFilter
do
	local dispellClasses = {
		["PRIEST"] = {
			["Magic"] = true,
			["Disease"] = true
		},
		["SHAMAN"] = {
			["Magic"] = false,
			["Curse"] = true
		},
		["PALADIN"] = {
			["Poison"] = true,
			["Magic"] = false,
			["Disease"] = true
		},
		["MAGE"] = {
			["Curse"] = true
		},
		["DRUID"] = {
			["Magic"] = false,
			["Curse"] = true,
			["Poison"] = true
		},
		["MONK"] = {
			["Poison"] = true,
			["Magic"] = false,
			["Disease"] = true
		}
	}

	DispellFilter = dispellClasses[select(2, UnitClass("player"))] or {}
end

local function CheckSpec(self, event)
	local spec = GetSpecialization()
	if select(2, UnitClass("player")) == "DRUID" then
		if (spec == 4) then
			DispellFilter.Magic = true
		else
			DispellFilter.Magic = false
		end
	elseif select(2, UnitClass("player")) == "MONK" then
		if (spec == 2) then
			DispellFilter.Magic = true
		else
			DispellFilter.Magic = false
		end
	elseif select(2, UnitClass("player")) == "PALADIN" then
		if (spec == 1) then
			DispellFilter.Magic = true
		else
			DispellFilter.Magic = false
		end
	elseif select(2, UnitClass("player")) == "SHAMAN" then
		if (spec == 3) then
			DispellFilter.Magic = true
		else
			DispellFilter.Magic = false
		end
	elseif select(2, UnitClass("player")) == "PRIEST" then
		if (spec == 3) then
			DispellFilter.Disease = false
			DispellFilter.Magic = false
		else
			DispellFilter.Disease = true
			DispellFilter.Magic = true
		end
	end
end
Plugin:RegisterEvent("PLAYER_TALENT_UPDATE")
Plugin:SetScript("OnEvent", CheckSpec)

local function formatTime(s)
	if s > 60 then
		return format("%dm", s / 60), s % 60
	elseif s < 1 then
		return format("%.1f", s), s - floor(s)
	else
		return format("%d", s), s - floor(s)
	end
end

local abs = math.abs
local function OnUpdate(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed >= 0.1 then
		local timeLeft = self.endTime - GetTime()
		if self.reverse then
			timeLeft = abs((self.endTime - GetTime()) - self.duration)
		end
		if timeLeft > 0 then
			local text = formatTime(timeLeft)
			self.time:SetText(text)
		else
			self:SetScript("OnUpdate", nil)
			self.time:Hide()
		end
		self.elapsed = 0
	end
end

local function UpdateDebuff(self, name, icon, count, debuffType, duration, endTime, spellId)
	local f = self.RaidDebuffs
	if name then
		f.icon:SetTexture(icon)
		f.icon:Show()
		f.duration = duration

		if f.count then
			if count and (count > 0) then
				f.count:SetText(count)
				f.count:Show()
			else
				f.count:Hide()
			end
		end

		if f.time then
			if duration and (duration > 0) then
				f.endTime = endTime
				f.nextUpdate = 0
				f:SetScript("OnUpdate", OnUpdate)
				f.time:Show()
			else
				f:SetScript("OnUpdate", nil)
				f.time:Hide()
			end
		end

		if f.cd then
			if duration and (duration > 0) then
				f.cd:SetCooldown(endTime - duration, duration)
				f.cd:Show()
			else
				f.cd:Hide()
			end
		end
		local c = DispellColor[debuffType]
		--filter raiddebuff list and color if player can dispel, red if can't dispel
		if cfg.ColorRaidDebuffPerType then
			if
				(debuffType == "Magic" and DispellFilter.Magic == true) or (debuffType == "Poison" and DispellFilter.Poison == true) or
					(debuffType == "Curse" and DispellFilter.Curse == true) or
					(debuffType == "Disease" and DispellFilter.Disease == true)
			 then
				f:SetBackdropColor(c[1], c[2], c[3])
			else
				f:SetBackdropColor(1, 0, 0)
			end
		else
			f:SetBackdropColor(cfg.RaidDebuffColor[1], cfg.RaidDebuffColor[2], cfg.RaidDebuffColor[3])
		end
		f:Show()
	else
		f:Hide()
	end
end

local function Update(self, event, unit)
	if unit ~= self.unit then
		return
	end
	local _name, _icon, _count, _dtype, _duration, _endTime, _spellId
	local _priority, priority = 0
	for i = 1, 40 do
		local name,
			icon,
			count,
			debuffType,
			duration,
			expirationTime,
			unitCaster,
			isStealable,
			nameplateShowPersonal,
			spellId,
			canApplyAura,
			isBossDebuff,
			isCastByPlayer,
			nameplateShowAll,
			timeMod = UnitAura(unit, i, "HARMFUL")
		if (not name) then
			break
		end

		if addon.ShowDispelableDebuff and debuffType and debuffType ~= "" then --empty string is returned when enrage == debuffType, cant dispell enrage as healer
			if addon.FilterDispellableDebuff then
				DispellPriority[debuffType] = DispellPriority[debuffType] + addon.priority --Make Dispell buffs on top of Boss Debuffs
				priority = DispellFilter[debuffType] and DispellPriority[debuffType]
			else
				priority = DispellPriority[debuffType]
			end

			if priority and (priority > _priority) then
				_priority, _name, _icon, _count, _dtype, _duration, _endTime, _spellId =
					priority,
					name,
					icon,
					count,
					debuffType,
					duration,
					expirationTime,
					spellId
			end
		end

		priority = debuff_data[addon.MatchBySpellName and name or spellId]
		if (priority and (priority > _priority)) then
			_priority, _name, _icon, _count, _dtype, _duration, _endTime, _spellId =
				priority,
				name,
				icon,
				count,
				debuffType,
				duration,
				expirationTime,
				spellId
		end
	end

	UpdateDebuff(self, _name, _icon, _count, _dtype, _duration, _endTime, _spellId)

	--Reset the DispellPriority
	DispellPriority = {
		["Magic"] = 4,
		["Curse"] = 3,
		["Disease"] = 2,
		["Poison"] = 1
	}
end

local function Enable(self)
	local rd = self.RaidDebuffs
	if rd then
		self:RegisterEvent("UNIT_AURA", Update)
		return true
	end
end

local function Disable(self)
	local rd = self.RaidDebuffs
	if rd then
		self:UnregisterEvent("UNIT_AURA", Update)
	end
end

oUF:AddElement("RaidDebuffs", Update, Enable, Disable)
