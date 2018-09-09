local addon, ns = ...
local cfg = ns.cfg
local tags = ns.tags
local _, playerClass = UnitClass('player')
local _, class = UnitClass('player')

local blankTex = "Interface\\Buttons\\WHITE8x8"
local backdrop = {edgeFile = blankTex, edgeSize = 1}
local backdrop2 = {bgFile = blankTex}
local backdrop3 = {bgFile = blankTex, insets = { left = -1, right = -1, top = -1, bottom = -1}}

-- change some colors
local colors = setmetatable({
	power = setmetatable({
	["MANA"] = {0.36, 0.45, 0.88},
	["RAGE"] = {0.8, 0.21, 0.31},
	["FUEL"] = {0, 0.55, 0.5},
	["FOCUS"] = {0.71, 0.43, 0.27},
	["ENERGY"] = {0.85, 0.83, 0.35},
	["AMMOSLOT"] = {0.8, 0.6, 0},
	["RUNIC_POWER"] = {0, 0.82, 1},
	["POWER_TYPE_STEAM"] = {0.55, 0.57, 0.61},
	["POWER_TYPE_PYRITE"] = {0.60, 0.09, 0.17},
	}, {__index = oUF.colors.power}),
}, {__index = oUF.colors})

-- format numbers
function round(num, idp)
  if idp and idp > 0 then
    local mult = 10^idp
    return math.floor(num * mult + 0.5) / mult
  end
  return math.floor(num + 0.5)
end

function CoolNumber(num)
	if(num >= 1e6) then
		return round(num/1e6,1).."m"
	elseif(num >= 1e3) then
		return round(num/1e3,1).."k"
	else
		return num
	end
end

-- font string creator
fs = function(parent, layer, font, fontsize, outline, r, g, b, justify)
    local string = parent:CreateFontString(nil, layer)
    string:SetFont(font, fontsize, outline)
    string:SetShadowOffset(0, 0)
    string:SetTextColor(r, g, b)
    if justify then
        string:SetJustifyH(justify)
    end
    return string
end

-- frame creator
framebd = function(parent, anchor)
    local frame = CreateFrame('Frame', nil, parent)
    frame:SetFrameStrata('BACKGROUND')
    frame:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -4, 4)
    frame:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', 4, -4)
    frame:SetBackdrop({
    bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
    insets = {left = 3, right = 3, top = 3, bottom = 3}})
    frame:SetBackdropColor(.05, .05, .05)
    frame:SetBackdropBorderColor(0, 0, 0)
    return frame
end

local fixStatusbar = function(bar)
    bar:GetStatusBarTexture():SetHorizTile(false)
    bar:GetStatusBarTexture():SetVertTile(false)
end

-- bar creator
createStatusbar = function(parent, tex, layer, height, width, r, g, b, alpha)
    local bar = CreateFrame'StatusBar'
    bar:SetParent(parent)
    if height then
        bar:SetHeight(height)
    end
    if width then
        bar:SetWidth(width)
    end
    bar:SetStatusBarTexture(tex, layer)
    bar:SetStatusBarColor(r, g, b, alpha)
    fixStatusbar(bar)
    return bar
end

-- health update
local PostUpdateHealth = function(Health, unit, min, max)
	local self = Health:GetParent()
  local d =(round(min/max, 2)*100)
	local c = UnitClassification(unit)

	local HPheight = Health:GetHeight()
	self.Health.bg:SetPoint('LEFT', Health:GetStatusBarTexture(), 'RIGHT')
	self.Health.bg:SetHeight(HPheight)

	-- set health background color for transparency mode
	if cfg.TransparencyMode then
		local _, class = UnitClass(unit)
		local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]

		if UnitIsPlayer(unit) and color then
			self.Health.bg:SetVertexColor(color.r, color.g, color.b, 0.9)
		else
			local r, g, b = UnitSelectionColor(unit)
			self.Health.bg:SetVertexColor(r, g, b, 0.9)
		end
	else
		if UnitIsDeadOrGhost(unit) == 1 then
			self.Health.bg:SetVertexColor(200/255, 20/255, 40/255, 0.5)
		else
			hpBGr, hpBGg, hpBGb = unpack(cfg.HPBackgroundColor)
			self.Health.bg:SetVertexColor(hpBGr, hpBGg, hpBGb, 1)
		end
	end
end

-- power update
local PostUpdatePower = function(Power, unit, min, max)
Power.value:SetText()

	if(min == 0 or max == 0 or not UnitIsConnected(unit)) then
		Power.value:SetText()
		Power:SetValue(0)
	elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
		Power:SetValue(0)
		Power.value:SetText()
	elseif(unit == "player") then
			Power.value:Show()
			Power.value:SetText(CoolNumber(min))
	else
		Power.value:SetText(CoolNumber(min))
	end

	-- color power text by power type
	local _, ptype = UnitPowerType(unit)
        if(colors.power[ptype]) then
		r, g, b = unpack(colors.power[ptype])
	end
	Power.value:SetTextColor(r, g, b)
end

-- power update for raid, no text values set for raid power so we use a seperate function
local PostUpdatePowerRaid = function(Power, unit)
	local powertype, _ = UnitPowerType(unit)
		Power:Show()
end

-- custom castbar text (curCastTime/maxCastTime)
local function CustomTimeText(self, duration)
	if self.casting then
		self.Time:SetFormattedText('%.2f /', (self.max - duration))
		self.Time2:SetFormattedText(' %.2f', self.max)
	elseif self.channeling then
		self.Time:SetFormattedText('%.2f /', duration)
		self.Time2:SetFormattedText(' %.2f', self.max)
	end
end

--------------------
-- aura functions --
--------------------

-- format time for auras
local FormatTime = function(s)
	local day, hour, minute = 86400, 3600, 60
	if s >= day then
		return format("%dd", floor(s/day + 0.5)), s % day
	elseif s >= hour then
		return format("%dh", floor(s/hour + 0.5)), s % hour
	elseif s >= minute then
		if s <= minute * 5 then
			return format('%d:%02d', floor(s/60), s % minute), s - floor(s)
		end
		return format("%dm", floor(s/minute + 0.5)), s % minute
	elseif s >= minute / 12 then
		return floor(s + 0.5), (s * 100 - floor(s * 100))/100
	end
	return format("%d", s), (s * 100 - floor(s * 100))/100
end


-- aura timer
local CreateAuraTimer = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed >= 0.1 then
		if not self.first then
			self.timeLeft = self.timeLeft - self.elapsed
		else
			self.timeLeft = self.timeLeft - GetTime()
			self.first = false
		end
		if self.timeLeft > 0 then
			local time = FormatTime(self.timeLeft)
			self.time:SetText(time)
			if self.timeLeft < 5 then
				self.time:SetTextColor(1, 1, 1)
			else
				self.time:SetTextColor(1, 1, 1)
			end
		else
			self.time:Hide()
			self:SetScript("OnUpdate", nil)
			end
			self.elapsed = 0
		end
end

-- icon style
local PostCreateIcon = function(Auras, button)
	local buttonwidth = button:GetWidth()
	button.cd.noOCC = false		 		-- hide OmniCC CDs
	button.cd.noCooldownCount = false	-- hide CDC CDs
	button.cd.disableCooldown = false
	Auras.disableCooldown = true		-- hide CD spiral
	Auras.showDebuffType = cfg.showDebuffColorPerType			-- show debuff border type color

	button.overlay:SetTexture("Interface\\Addons\\oUF_Farva\\media\\flash")
  button.overlay:SetPoint("TOPLEFT", button.icon, "TOPLEFT", -2, 2)
  button.overlay:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", 2, -2)
	button.overlay:SetTexCoord(0, 1, 0, 1)

	button.overlay.Hide = function(self) self:SetVertexColor(unpack(cfg.brdcolor)) end

	button.time = button:CreateFontString(nil, 'OVERLAY')
	button.time:SetFont(cfg.NumbFont, cfg.NumbFS, cfg.fontFNum)
	button.time:SetPoint("TOPLEFT", button, 3, -2)
	button.time:SetJustifyH('CENTER')
	button.time:SetVertexColor(unpack(cfg.sndcolor))
	button:SetSize(cfg.BuffSize, cfg.BuffSize)

	local count = button.count
	count:ClearAllPoints()
	count:SetPoint("BOTTOMRIGHT", button, 0, 2)
	count:SetFont(cfg.NumbFont, cfg.NumbFS, cfg.fontFNum)
	count:SetVertexColor(unpack(cfg.sndcolor))

	button.icon:SetTexCoord(.08, .92, .08, .92)
end

-- update icon
local PostUpdateIcon
do
	local playerUnits = {
		player = true,
		pet = true,
		vehicle = true,
	}

	PostUpdateIcon = function(icons, unit, icon, index, offset, filter, isDebuff)
	local _, _, _, dtype, duration, expirationTime, unitCaster, _, _, _, _, _, _, _, _ = UnitAura(unit, index, icon.filter)
	local texture = icon.icon

	if duration and duration > 0 then
		icon.time:Show()
		icon.timeLeft = expirationTime
		icon:SetScript("OnUpdate", CreateAuraTimer)
	else
		icon.time:Hide()
		icon.timeLeft = math.huge
		icon:SetScript("OnUpdate", nil)
	end
	icon.first = true
	end
end

-- update aurawatch icon
local AWIcon = function(AWatch, icon, spellID, name, self)
	local count = fs(icon, 'OVERLAY', cfg.NumbFont, cfg.NumbFS, cfg.fontFNum, 1, 1, 1)
	count:SetPoint('BOTTOMRIGHT', icon, 5, -5)
	icon.count = count

	if cfg.AWCooldownCount then
		local f = CreateFrame('Frame', nil, icon)
		f:SetAllPoints(icon)
		local tex = f:CreateTexture()
		tex:SetAllPoints()
		tex:SetTexture(nil)
		local cd = CreateFrame("Cooldown", "cd", f, "CooldownFrameTemplate")
		cd:SetAllPoints()
		icon.cd = cd
	end
end

-- initial creation of aurawatch
local createAuraWatch = function(self, unit)
	if cfg.aw.enable then
		local auras = CreateFrame('Frame', nil, self)
		auras:SetAllPoints(self.Health)

		auras.onlyShowPresent = cfg.aw.onlyShowPresent
		auras.anyUnit = cfg.aw.anyUnit
		auras.icons = {}
		auras.PostCreateIcon = AWIcon

		for i, v in pairs(cfg.spellIDs[class]) do
			local icon = CreateFrame('Frame', nil, auras)
			icon.spellID = v[1]
			icon:SetSize(8, 8)
			if v[3] then
				icon:SetPoint(v[3])
			else
			  icon:SetPoint('BOTTOMLEFT', self.Health, 'BOTTOMRIGHT', -8 * i, 16)
			end
			icon:SetBackdrop(backdrop_1px)
	   	icon:SetBackdropColor(0, 0, 0, 1)

			local tex = icon:CreateTexture()
			tex:SetAllPoints()
			tex:SetTexture(cfg.texture)
			tex:SetVertexColor(unpack(v[2]))
			icon.icon = tex

			auras.icons[v[1]] = icon
		end
		self.AuraWatch = auras
	end
end

-- mouseover highlight
local UnitFrame_OnEnter = function(self)
	UnitFrame_OnEnter(self)
	self.Mouseover:Show()
end
local UnitFrame_OnLeave = function(self)
	UnitFrame_OnLeave(self)
	self.Mouseover:Hide()
end

-- hide/show unitname/spellname while casting
local PostCastStart = function(Castbar, unit, spell, spellrank)
	Castbar:GetParent().Name:Hide()
	Castbar:GetParent().Status:Hide()

	if Castbar.notInterruptible and UnitCanAttack("player", unit) then
		Castbar:SetStatusBarColor(1, 1, 0, 1)
		if cfg.useSpellIcon then
			Castbar.IconGlow:SetBackdropColor(0.9, 0, 1.0, 0.6)
		end
	else
		local cbbR, cbbG, cbbB, cbbA= unpack(cfg.CastbarColor)
		Castbar:SetStatusBarColor(cbbR, cbbG, cbbB, cbbA)
		if cfg.useSpellIcon then
			Castbar.IconGlow:SetBackdropColor(unpack(cfg.brdcolor))
		end
	end
end

-- restore status
local PostCastStop = function(Castbar, unit)
	local self = Castbar:GetParent()
	self.Name:Show()
	self.Status:Show()
end

local PostCastStopUpdate = function(self, event, unit)
	if(unit ~= self.unit) then return end
	return PostCastStop(self.Castbar, unit)
end

-- skin mirror bars
function MirrorBars()
	if(MirrorBars) then
		for _, bar in pairs({
			'MirrorTimer1',
			'MirrorTimer2',
			'MirrorTimer3',
	}) do
		local bg = select(1, _G[bar]:GetRegions())
		bg:Hide()

			_G[bar]:SetBackdrop(backdrop3)
			_G[bar]:SetBackdropColor(unpack(cfg.brdcolor))

			_G[bar..'Border']:Hide()

			_G[bar]:SetParent(UIParent)
			_G[bar]:SetScale(1)
			_G[bar]:SetHeight(4)
			_G[bar]:SetWidth(160)

			_G[bar..'Background'] = _G[bar]:CreateTexture(bar..'Background', 'BACKGROUND', _G[bar])
			_G[bar..'Background']:SetTexture(blankTex)
			_G[bar..'Background']:SetAllPoints(_G[bar])
			_G[bar..'Background']:SetVertexColor(0, 0, 0, 0.5)

			_G[bar..'Text']:SetFont(cfg.NameFont, cfg.NameFS, cfg.FontF)
			_G[bar..'Text']:ClearAllPoints()
			_G[bar..'Text']:SetPoint('TOP', MirrorTimer1StatusBar, 'BOTTOM', 0, -2)

			_G[bar..'StatusBar']:SetStatusBarTexture(cfg.HPtex)

			_G[bar..'StatusBar']:SetAllPoints(_G[bar])
		end
	end
end

--------------------------------
-- shared stuff for all units --
--------------------------------
local Shared = function(self, unit, isSingle)
local _, playerClass = UnitClass('player')

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks"AnyUp"

	-- set/clear focus with shift + left click
	if cfg.ShiftClickFocus then
		local ModKey = 'Shift'
		local MouseButton = 1
		local key = ModKey .. '-type' .. (MouseButton or '')
		if(self.unit == 'focus') then
			self:SetAttribute(key, 'macro')
			self:SetAttribute('macrotext', '/clearfocus')
		else
			self:SetAttribute(key, 'focus')
		end
	end

	-- hp
	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetStatusBarTexture(cfg.HPtex)
	hp:SetPoint"TOP"
	hp:SetPoint"LEFT"
	hp:SetPoint"RIGHT"
	hp:GetStatusBarTexture():SetHorizTile(true)
	hp:SetFrameLevel(3)
	hp.frequentUpdates = true
	if cfg.SmoothHealthUpdate then
		hp.Smooth = true
	end
	self.Health = hp

	if cfg.TransparencyMode then
		local tmR, tmG, tmB = unpack(cfg.hpTransMcolor)
		hp:SetStatusBarColor(tmR, tmG, tmB, cfg.hpTransMalpha)
		self.Health.PostUpdate = PostUpdateHealth
	else
		hp.colorTapping = true
		hp.colorClass = true
		hp.colorReaction = true
		self.Health.PostUpdate = PostUpdateHealth
	end

	-- hp border
	self.Glow = CreateFrame("Frame", nil, hp)
	self.Glow:SetPoint("TOPLEFT", hp, "TOPLEFT", -1, 1)
	self.Glow:SetPoint("BOTTOMRIGHT", hp, "BOTTOMRIGHT", 1, -1)
	self.Glow:SetBackdrop(backdrop)
	self.Glow:SetBackdropBorderColor(unpack(cfg.brdcolor))
	self.Glow:SetFrameLevel(3)

	local Framewidth = self:GetWidth()

	-- hp bg
	hpbg = hp:CreateTexture(nil, "BACKGROUND")
	hpbg:SetTexture(cfg.Itex)
	hp.bg = hpbg

	if cfg.TransparencyMode then
		hpbg:SetPoint"LEFT"
		hpbg:SetPoint"RIGHT"
		hpbg:SetPoint("LEFT", hp:GetStatusBarTexture(), "RIGHT")
	else
		hpbg:SetAllPoints(hp)
		hpbg:SetAlpha(0.6)
		hpbg.multiplier = 0
	end

	-- pp
	local pp = CreateFrame("StatusBar", nil, self)
	pp:SetSize(cfg.widthP, cfg.heightPP)
	pp:SetStatusBarTexture(cfg.PPtex)
	pp:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -cfg.PPyOffset)
	pp:GetStatusBarTexture():SetHorizTile(true)
	pp:SetFrameLevel(1)

	pp.frequentUpdates = true
	pp.colorPower = false
	self.Power = pp
	self.Power.PostUpdate = PostUpdatePower
	if cfg.SmoothPowerUpdate then
		self.Power.Smooth = true
	end
	self.Power.colorPower = false
	self.Power.colorClass = true

	-- pp border
	self.Glow.pp = CreateFrame("Frame", nil, pp)
	self.Glow.pp:SetPoint("TOPLEFT", pp, "TOPLEFT", -1, 1)
	self.Glow.pp:SetPoint("BOTTOMRIGHT", pp, "BOTTOMRIGHT", 1, -1)
	self.Glow.pp:SetBackdrop(backdrop)
	self.Glow.pp:SetBackdropBorderColor(unpack(cfg.brdcolor))
	self.Glow.pp:SetFrameLevel(1)

	-- pp bg
	local ppBG = pp:CreateTexture(nil, 'BORDER')
	ppBG:SetAllPoints()
	ppBG:SetTexture(cfg.Itex)
	ppBG.multiplier = 0.4
	ppBG:SetAlpha(0.5)
	pp.bg = ppBG

	if cfg.TransparencyMode then
		pp:SetAlpha(0.8)
	else
		pp:SetAlpha(1)
	end

	-- enable custom colors
	self.colors = colors

	-- font strings
	self.Health.value = hp:CreateFontString(nil, "OVERLAY")
	self.Health.value:SetFont(cfg.NumbFont, cfg.hpNumbFS, cfg.fontFNum)

	self.Power.value = hp:CreateFontString(nil, "OVERLAY")
	self.Power.value:SetFont(cfg.NumbFont, cfg.PowerFS, cfg.fontFNum)

	self.Name = hp:CreateFontString(nil, "OVERLAY")
	self.Name:SetFont(cfg.NameFont, cfg.NameFS, cfg.FontF)
	self:Tag(self.Name, '[raidcolor][abbrevname]')

	self.Status = hp:CreateFontString(nil, "OVERLAY")
	self.Status:SetFont(cfg.NameFont, cfg.NameFS, cfg.FontF)
	self:Tag(self.Status, '[afkdnd][difficulty][smartlevel] ')

	-- mouseover highlight
	local mov = self.Health:CreateTexture(nil, "OVERLAY")
	mov:SetAllPoints(self.Health)
	mov:SetTexture("Interface\\AddOns\\oUF_Farva\\media\\highlight")
	mov:SetVertexColor(1, 1, 1, 0.3)
	mov:SetTexCoord(0,1,1,0)
	mov:SetBlendMode("ADD")
	mov:Hide()
	self.Mouseover = mov

	local StringParent = CreateFrame('Frame', nil, self)
	StringParent:SetFrameLevel(20)
	self.StringParent = StringParent

	if(unit ~= 'player') then
		local pIcon = self.Health:CreateTexture(nil, 'OVERLAY')
		pIcon:SetSize(18, 18)
		self.PhaseIndicator = pIcon
	end

	-- raid icons for all frames
	local RaidTarget = StringParent:CreateTexture(nil, 'OVERLAY')
	RaidTarget:SetPoint('TOP', self, 0, 8)
	RaidTarget:SetSize(16, 16)
	self.RaidTargetIndicator = RaidTarget
end

----------------------
-- object functions --
----------------------

-- castbar
local createCastbar = function(self, unit)
	local cb = CreateFrame("StatusBar", nil, self)
	cb:SetStatusBarTexture(cfg.CBtex)
	cb:GetStatusBarTexture():SetHorizTile(true)
	cb:SetFrameLevel(4)

	self.Castbar = cb

	cb.Text = cb:CreateFontString(nil, 'ARTWORK')
	cb.Text:SetJustifyH("LEFT")
	cb.Text:SetFont(cfg.NameFont, cfg.CastFS, cfg.FontF)
	cb.Text:SetTextColor(unpack(cfg.sndcolor))

	cb.Time = cb:CreateFontString(nil, 'ARTWORK')
	cb.Time:SetFont(cfg.NumbFont, cfg.CastFS, cfg.fontFNum)
	cb.Time:SetJustifyH('RIGHT')
	cb.Time:SetTextColor(unpack(cfg.sndcolor))

	cb.Time2 = cb:CreateFontString(nil, 'ARTWORK')
	cb.Time2:SetFont(cfg.NumbFont, cfg.CastFS, cfg.fontFNum)
	cb.Time2:SetJustifyH('RIGHT')
	cb.Time2:SetTextColor(unpack(cfg.sndcolor))

	cb.CustomTimeText = CustomTimeText

	if cfg.useSpellIcon then
		cb.Icon = cb:CreateTexture(nil, 'OVERLAY')
		cb.Icon:SetSize(28,28)
		cb.Icon:SetTexCoord(0.1,0.9,0.1,0.9)

		cb.IconGlow = CreateFrame("Frame", nil, cb)
		cb.IconGlow:SetPoint("TOPLEFT", cb.Icon, "TOPLEFT", -1, 1)
		cb.IconGlow:SetPoint("BOTTOMRIGHT", cb.Icon, "BOTTOMRIGHT", 1, -1)
		cb.IconGlow:SetBackdrop(backdrop2)
		cb.IconGlow:SetBackdropColor(unpack(cfg.brdcolor))
		cb.IconGlow:SetFrameLevel(0)
	end

	cb.Spark = cb:CreateTexture(nil, 'OVERLAY')
	cb.Spark:SetBlendMode('ADD')
	cb.Spark:SetSize(6, cfg.heightP*2.5)

	self:RegisterEvent('UNIT_NAME_UPDATE', PostCastStopUpdate)
	table.insert(self.__elements, PostCastStopUpdate)

	cb.PostCastStart = PostCastStart
	cb.PostChannelStart = PostCastStart
	cb.PostCastStop = PostCastStop
	cb.PostChannelStop = PostCastStop
end

-- buffs
local createBuffs = function(self)
	local Buffs = CreateFrame("Frame", nil, self)
	self.Buffs = Buffs
	Buffs.PostCreateIcon = PostCreateIcon
	Buffs.PostUpdateIcon = PostUpdateIcon
end

-- debuffs
local createDebuffs = function(self)
	local Debuffs = CreateFrame("Frame", nil, self)
	self.Debuffs = Debuffs
	Debuffs.PostCreateIcon = PostCreateIcon
	Debuffs.PostUpdateIcon = PostUpdateIcon
end

-- plugin support
local SpellRange = function(self)
	self.SpellRange = {
	insideAlpha = 1,
	outsideAlpha = cfg.FadeOutAlpha}
end

-------------------------
-- unit specific stuff --
-------------------------
local UnitSpecific = {
	player = function(self, ...)
		Shared(self, ...)
		MirrorBars()

		if cfg.useCastbar then
			createCastbar(self)

			-- disable blizzards pet castbar
			PetCastingBarFrame:UnregisterAllEvents()
			PetCastingBarFrame.Show = function() end
			PetCastingBarFrame:Hide()

			if cfg.useSpellIcon then
				self.Castbar.Icon:SetPoint("TOPRIGHT", self.Health, "TOPLEFT", -6, 0)
			end
		end

		self.Health:SetHeight(cfg.heightP)
		self.Health:SetWidth(cfg.widthP)
		self.Power:SetWidth(cfg.widthP)

		local htext = self.Health.value
			if cfg.showExperienceBar then
				if UnitLevel('player') < MAX_PLAYER_LEVEL then
					htext:SetPoint('RIGHT', 2, -31)
					self.Castbar:SetAllPoints(self.Health)
					self.Castbar.Text:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -19)
					self.Castbar.Time:SetPoint("BOTTOMLEFT", self.Castbar.Text, "BOTTOMRIGHT", 2, 0)
					self.Castbar.Time2:SetPoint("BOTTOMLEFT", self.Castbar.Time, "BOTTOMRIGHT", 0, 0)
				else
				htext:SetPoint('RIGHT', 2, -19)
				self.Castbar:SetAllPoints(self.Health)
				self.Castbar.Text:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -2)
				self.Castbar.Time:SetPoint("BOTTOMLEFT", self.Castbar.Text, "BOTTOMRIGHT", 2, 0)
				self.Castbar.Time2:SetPoint("BOTTOMLEFT", self.Castbar.Time, "BOTTOMRIGHT", 0, 0)
				end
			end
		htext.frequentUpdates = .1
    self:Tag(htext, '[player:hp]')
		self.Power.value:SetPoint("TOPRIGHT", htext, "BOTTOMRIGHT", 0, -2)

		-- Icons
		local Ihld = CreateFrame("Frame", nil, self)
		Ihld:SetAllPoints(self.Health)
		Ihld:SetFrameLevel(6)

		RIc = Ihld:CreateTexture(nil, 'OVERLAY')
		RIc:SetSize(14, 14)
		RIc:SetPoint("TOPLEFT", self.Health, 4, 6)
		self.RestingIndicator = RIc

		CIc = Ihld:CreateTexture(nil, 'OVERLAY')
		CIc:SetSize(16, 16)
		CIc:SetPoint("LEFT", RIc, "RIGHT", 4, 0)
		self.CombatIndicator = CIc

		LIc = Ihld:CreateTexture(nil, "OVERLAY")
		LIc:SetSize(14, 14)
		LIc:SetPoint("LEFT", CIc, "RIGHT", 4, 0)
		self.LeaderIndicator = LIc

		-- plugins

		--experience bar
		if cfg.showExperienceBar then
			local expbar = createStatusbar(self, cfg.texture, nil, cfg.heightP, cfg.widthP, 0, .7, 1, 1)
			expbar:SetFrameStrata('LOW')
			expbar:SetPoint("BOTTOM", self, "BOTTOM", 0, -9)
			expbar.Rested = createStatusbar(expbar, cfg.texture, nil, nil, nil, 0, .5, .5, .6)
			expbar.Rested:SetAllPoints(expbar)
			expbar.bg = expbar.Rested:CreateTexture(nil, 'BORDER')
			expbar.bg:SetAllPoints(expbar)
			expbar.bg:SetTexture(cfg.texture)
			expbar.bg:SetVertexColor(.5, .5, .5, 0.4)
			local xptext = expbar:CreateFontString(nil, 'OVERLAY')
			xptext:SetAllPoints(expbar)
			xptext:SetFont(cfg.NameFont, cfg.NameFS, cfg.fontF)
			self:Tag(xptext, '[experience:cur] / [experience:max]   [experience:per]%')

			--only show on mouseover
			xptext:Hide()
			expbar:SetScript('OnEnter', function(self)UIFrameFadeIn(xptext, 0.3, 0, 1)end)
			expbar:SetScript('OnLeave', function(self)UIFrameFadeOut(xptext, 0.3, 1, 0)end)

			expbar.bd = framebd(expbar, expbar)
			self.Experience = expbar
		end

		if cfg.threat.enable then
	    local threat = createStatusbar(UIParent, cfg.texture, nil, cfg.threat.height, cfg.threat.width, 1, 1, 1, 1)
				threat:SetFrameStrata('LOW')
	      threat:SetPoint(unpack(cfg.threat.pos))
				threat.useRawThreat = false
				threat.usePlayerTarget = false
				threat.bg = threat:CreateTexture(nil, 'BACKGROUND')
	      threat.bg:SetAllPoints(threat)
	      threat.bg:SetTexture(cfg.texture)
	      threat.bg:SetVertexColor(1, 0, 0, 0.2)
	      threat.bg = framebd(threat, threat)
			self.ThreatBar = threat
		end
		if cfg.PlayerDebuffs then
			createDebuffs(self)
			self.Debuffs.size = cfg.PlayerDebuffSize
			self.Debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 4)
			self.Debuffs.initialAnchor = "BOTTOMLEFT"
			self.Debuffs["growth-x"] = "RIGHT"
			self.Debuffs["growth-y"] = "UP"
			self.Debuffs.spacing = 3
			self.Debuffs.num = 14
			self.Debuffs:SetSize(cfg.widthP, self.Debuffs.size)
			self:SetSize(cfg.widthP, cfg.heightP + cfg.NumbFS + cfg.PPyOffset)
		end
	end,

	target = function(self, ...)
		Shared(self, ...)
		self.Health:SetHeight(cfg.heightT)
		self.Health:SetWidth(cfg.widthT)
		self.Power:SetWidth(cfg.widthT)

		if cfg.useCastbar then
			createCastbar(self)
			self.Castbar:SetAllPoints(self.Health)
			self.Castbar.Text:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -2)
			self.Castbar.Time2:SetPoint("BOTTOMRIGHT", self.Castbar.Text, "BOTTOMLEFT", -5, 0)
			self.Castbar.Time:SetPoint("BOTTOMRIGHT", self.Castbar.Time2, "BOTTOMLEFT", 0, 0)

			if cfg.useSpellIcon then
				self.Castbar.Icon:SetPoint("TOPRIGHT", self.Health, "TOPLEFT", -6, 0)
			end
		end

		self.Power.frequentUpdates = .1
		self.Name:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -3)
		self.Status:SetPoint("TOPRIGHT", self.Name, "TOPLEFT", 0, 0)

		local htext = self.Health.value
    htext:SetPoint('LEFT', 0, -19)
		htext.frequentUpdates = .1
    self:Tag(htext, '[player:hp]')
		self.Power.value:SetPoint("TOPLEFT", htext, "BOTTOMLEFT", 0, -2)

		if cfg.showTargetBuffs then
			createBuffs(self)
			self.Buffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 4)
			self.Buffs.initialAnchor = "BOTTOMLEFT"
			self.Buffs["growth-x"] = "RIGHT"
			self.Buffs.num = 18
			self.Buffs.size = cfg.BuffSize
			self.Buffs.spacing = 4
			self.Buffs:SetSize(cfg.widthT, self.Buffs.size)

			if cfg.onlyShowPlayerBuffsTarget then
				self.Buffs.onlyShowPlayer = true
			end
		end

		if cfg.showTargetDebuffs then
			createDebuffs(self)
			self.Debuffs:SetPoint("LEFT", self.Health, "RIGHT", 3, -3)
			self.Debuffs.initialAnchor = "LEFT"
			self.Debuffs["growth-x"] = "RIGHT"
			self.Debuffs["growth-y"] = "UP"
			self.Debuffs.num = 4
			self.Debuffs.size = cfg.DebuffSize
			self.Debuffs.spacing = 4
			self.Debuffs:SetSize(self.Debuffs.size*self.Debuffs.num+(self.Debuffs.spacing*self.Debuffs.num), self.Debuffs.size)

			if cfg.onlyShowPlayerDebuffsTarget then
				self.Debuffs.onlyShowPlayer = true
			end
		end

		-- plugins
		SpellRange(self)

		 --Icons
		local Ihld = CreateFrame("Frame", nil, self)
		Ihld:SetAllPoints(self.Health)
		Ihld:SetFrameLevel(6)

		LIc = Ihld:CreateTexture(nil, "OVERLAY")
		LIc:SetSize(14, 14)
		LIc:SetPoint("LEFT", htext, "RIGHT", 4, 0)
		self.LeaderIndicator = LIc

		--target of target frame
		local TTFrame = CreateFrame("Frame", nil, self)
		TTFrame:SetPoint("TOPLEFT", self, "TOPLEFT", -4, 4)
		TTFrame:SetPoint("BOTTOMRIGHT", self.Power, "BOTTOMRIGHT", 4, -4)
		TTFrame:SetFrameLevel(0)

		self:SetSize(cfg.widthT, cfg.heightT + cfg.NumbFS + cfg.PPyOffset)
	end,

	focus = function(self, ...)
		Shared(self, ...)
		self.Health:SetHeight(cfg.heightF)
		self.Health:SetWidth(cfg.widthF)
		self.Power:SetWidth(cfg.widthF)

		if cfg.useCastbar then
			createCastbar(self)
			self.Castbar:SetAllPoints(self.Health)
			self.Castbar.Text:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -2)
			self.Castbar.Time2:SetPoint("BOTTOMRIGHT", self.Castbar.Text, "BOTTOMLEFT", -5, 0)
			self.Castbar.Time:SetPoint("BOTTOMRIGHT", self.Castbar.Time2, "BOTTOMLEFT", 0, 0)

			if cfg.useSpellIcon then
				self.Castbar.Icon:SetPoint("TOPRIGHT", self.Health, "TOPLEFT", -6, 0)
			end
		end

		self.Name:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -3)
		self.Status:SetPoint("TOPRIGHT", self.Name, "TOPLEFT", 0, 0)

		local htext = self.Health.value
		htext:SetPoint('LEFT', 0, -19)
		htext.frequentUpdates = .1
		self:Tag(htext, '[player:hp]')
		self.Power.value:SetPoint("TOPLEFT", htext, "BOTTOMLEFT", 0, -2)

		if cfg.showFocusBuffs then
			createBuffs(self)
			self.Buffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 4)
			self.Buffs.initialAnchor = "BOTTOMLEFT"
			self.Buffs["growth-x"] = "RIGHT"
			self.Buffs["growth-y"] = "UP"
			self.Buffs.num = 14
			self.Buffs.size = cfg.BuffSize
			self.Buffs.spacing = 5
			self.Buffs:SetSize(cfg.widthF, self.Buffs.size)

			if cfg.onlyShowPlayerBuffsFocus then
				self.Buffs.onlyShowPlayer = true
			end
		end

		if cfg.showFocusDebuffs then
			createDebuffs(self)
			self.Debuffs:SetPoint("LEFT", self.Health, "RIGHT", 4, -3)
			self.Debuffs.initialAnchor = "LEFT"
			self.Debuffs["growth-x"] = "RIGHT"
			self.Debuffs["growth-y"] = "UP"
			self.Debuffs.num = 5
			self.Debuffs.size = cfg.DebuffSize
			self.Debuffs.spacing = 4
			self.Debuffs:SetSize(self.Debuffs.size*self.Debuffs.num+(self.Debuffs.spacing*self.Debuffs.num), self.Debuffs.size)

			if cfg.onlyShowPlayerDebuffsFocus then
				self.Debuffs.onlyShowPlayer = true
			end
		end

		-- plugins
		SpellRange(self)

		-- Icons
		local Ihld = CreateFrame("Frame", nil, self)
		Ihld:SetAllPoints(self.Health)
		Ihld:SetFrameLevel(6)

		self:SetSize(cfg.widthF, cfg.heightF + cfg.NumbFS + cfg.PPyOffset)
	end,

	pet = function(self, ...)
		Shared(self, ...)

		self.Health:SetHeight(cfg.heightS)
		self.Health:SetWidth(cfg.widthS)
		self.Power:SetWidth(cfg.widthS)
		self.Name:SetPoint("TOP", self.Power, "BOTTOM", 0, -3)
		self:Tag(self.Name, '[raidcolor][shortname]')

		self.Power.colorPower = true

		-- plugins
		SpellRange(self)

		self:SetSize(cfg.widthS, cfg.heightS + cfg.NumbFS + cfg.PPyOffset)
	end,

	targettarget = function(self, ...)
		Shared(self, ...)

		self.Health:SetHeight(cfg.heightS)
		self.Health:SetWidth(cfg.widthS)
		self.Power:SetWidth(cfg.widthS)
		self.Name:SetPoint("TOP", self.Power, "BOTTOM", 0, -3)
		self:Tag(self.Name, '[raidcolor][shortname]')

		-- plugins
		SpellRange(self)

		self:SetSize(cfg.widthS, cfg.heightS + cfg.NumbFS + cfg.PPyOffset)
	end,

	focustarget = function(self, ...)
		Shared(self, ...)

		self.Health:SetHeight(cfg.heightS)
		self.Health:SetWidth(cfg.widthS)
		self.Power:SetWidth(cfg.widthS)
		self.Name:SetPoint("TOP", self.Power, "BOTTOM", 0, -3)
		self:Tag(self.Name, '[raidcolor][shortname]')

		-- plugins
		SpellRange(self)

		self:SetSize(cfg.widthS, cfg.heightS + cfg.NumbFS + cfg.PPyOffset)
	end,

	boss = function(self, ...)
		Shared(self, ...)

		self.Health:SetHeight(cfg.heightM)
		self.Health:SetWidth(cfg.widthM)
		self.Power:SetWidth(cfg.widthM)
		self.Name:SetPoint("TOPLEFT", self.Health, 0, cfg.NameFS/2)
		self:Tag(self.Name, '[afkdnd][raidcolor][abbrevname]')

		local htext = self.Health.value
    htext:SetPoint('LEFT', 0, -16)
		htext.frequentUpdates = .1
    self:Tag(htext, '[player:hp]')
		self.Power.value:SetPoint("TOPLEFT", htext, "BOTTOMLEFT", 0, -1)

		local alttext = fs(self.Health, 'OVERLAY', cfg.NameFont, cfg.NameFS, cfg.FontF, 1, 1, 1)
    alttext:SetPoint('RIGHT', 0, -16)
		alttext.frequentUpdates = .1
    self:Tag(alttext, '[altpower]')

		-- plugins
		SpellRange(self)

		self:SetSize(cfg.widthM, cfg.heightM + cfg.NumbFS + cfg.PPyOffset)
	end,

	MainTank = function(self, ...)
		Shared(self, ...)

		self.Health:SetHeight(cfg.heightM)
		self.Health:SetWidth(cfg.widthM)
		self.Power:Hide()
		self.Name:SetPoint("TOPLEFT", self.Health, 0, cfg.NameFS/2)
		self:Tag(self.Name, '[afkdnd][raidcolor][abbrevname]')
		self.Health.value:SetPoint("TOPRIGHT", self.Health, 0, cfg.NameFS/2)

		-- plugins
		SpellRange(self)

	end,

	arenaframes = function(self, ...)
		Shared(self, ...)
		self.Health:SetHeight(cfg.heightPA)
		self.Health:SetWidth(cfg.widthPA)
		self.Power:SetWidth(cfg.widthPA)

		self.Status:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -2)
		self.Name:SetPoint("TOPLEFT", self.Status, "TOPRIGHT", 0, 0)

		local htext = self.Health.value
    htext:SetPoint('RIGHT', 2, -19)
		htext.frequentUpdates = .1
    self:Tag(htext, '[player:hp]')
		self.Power.value:SetPoint("TOPRIGHT", htext, "BOTTOMRIGHT", 0, -2)

		local Auras = CreateFrame("Frame", nil, self)
		Auras:SetHeight(cfg.heightPA)
		Auras:SetPoint("TOPRIGHT", self, "TOPLEFT", 300, 30)
		Auras.initialAnchor = "TOPLEFT"
		Auras.size = cfg.BuffSize
		Auras:SetWidth(Auras.size * 13)
		Auras.gap = false
		Auras.numBuffs = 8
		Auras.numDebuffs = 4
		Auras.spacing = 2
		Auras["growth-x"] = "RIGHT"

		Auras.PostCreateIcon = PostCreateIcon
		self.Auras = Auras

		-- plugins
		SpellRange(self)

		self:SetSize(cfg.widthPA, cfg.heightPA + cfg.NumbFS + cfg.PPyOffset)
	end,

	arenatargets = function(self, ...)
		Shared(self, ...)

		self.Health.value:ClearAllPoints()
		self.Power.value:ClearAllPoints()

		self.Health:SetHeight(cfg.heightPA)
		self.Health:SetWidth(cfg.widthS)
		self.Power:SetWidth(cfg.widthS)
		self.Name:SetPoint("CENTER", self.Health, 0, 0)
		self:Tag(self.Name, '[raidcolor][shortname]')

		self:SetSize(cfg.widthS, cfg.heightPA + cfg.NumbFS + cfg.PPyOffset)
	end,
}

-- raid, party
do
	local range = {
		insideAlpha = 1,
		outsideAlpha = cfg.FadeOutAlpha,
	}

	UnitSpecific.party = function(self, ...)
		Shared(self, ...)

		self.unit = 'party'

		self.Health:SetHeight(cfg.heightPA)
		self.Health:SetWidth(cfg.widthPA)
		self.Power:SetWidth(cfg.widthPA)

		self.Health.value:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -2)
		self.Power.value:SetPoint("RIGHT", self.Health.value, "LEFT", -2, 0)
		self.Status:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -2)
		self.Name:SetPoint("TOPLEFT", self.Status, "TOPRIGHT", 0, 0)
		if cfg.RaidDebuffs then
			local d = CreateFrame('Frame', nil, self)
			d:SetSize(cfg.raidDebuffSize, cfg.raidDebuffSize)
			d:SetPoint('CENTER', 0, 4)
			d:SetFrameStrata'HIGH'
			d:SetBackdrop(backdrop3)
			d.icon = d:CreateTexture(nil, 'OVERLAY')
			d.icon:SetAllPoints(d)
			d.time = fs(d, 'OVERLAY', cfg.NumbFont, cfg.RaidFS, cfg.fontFNum, 0.8, 0.8, 0.8)
			d.time:SetPoint('TOPLEFT', d, 'TOPLEFT', 0, 0)
			d.count = fs(d, 'OVERLAY', cfg.NumbFont, cfg.RaidFS, cfg.fontFNum, 0.8, 0.8, 0.8)
			d.count:SetPoint('BOTTOMRIGHT', d, 'BOTTOMRIGHT', 2, 0)
			d.ShowBossDebuff = true
	   self.RaidDebuffs = d
	 	end

		-- plugins
		self.Range = range

		LfDR = self.Health:CreateTexture(nil, 'OVERLAY')
		LfDR:SetSize(12, 12)
		LfDR:SetPoint("TOPLEFT", self.Health, 2, 6)
		self.GroupRoleIndicator = LfDR

		LIc = self.Health:CreateTexture(nil, "OVERLAY")
		LIc:SetSize(12, 12)
		LIc:SetPoint("LEFT", LfDR, "RIGHT", 4, 0)
		self.LeaderIndicator = LIc

		rChk = self.Health:CreateTexture(nil, 'OVERLAY')
		rChk:SetSize(18, 18)
		rChk:SetPoint("CENTER", self.Health, 0, 0)
		rChk.fadeTimer = 6
		rChk.finishedTimer = 6
		self.ReadyCheckIndicator = rChk

		-- party pets
		if (self:GetAttribute("unitsuffix") == "pet") then

			-- clear up the inherited mess ...
			self.Auras:ClearAllPoints()
			self.Name:ClearAllPoints()
			self.Health.value:ClearAllPoints()
			self.Power.value:ClearAllPoints()
			self.Status:ClearAllPoints()
			self.PhaseIndicator:ClearAllPoints()

			self.Health:SetWidth(cfg.widthS)
			self.Power:SetWidth(cfg.widthS)
			self.Name:SetPoint("TOP", self.Power, "BOTTOM", 0, -2)
			self:Tag(self.Name, '[raidcolor][shortname]')

			self:SetSize(cfg.widthS, cfg.heightPA + cfg.NumbFS + cfg.PPyOffset)
		end
	end

	UnitSpecific.raid = function(self, ...)
		Shared(self, ...)
		createAuraWatch(self)

		self.Health:SetHeight(cfg.heightR)
		self.Health:SetWidth(cfg.widthR)
		self.Power:SetWidth(cfg.widthR*0.7)
		self.Power:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 13, 0)
		self.Power:SetFrameLevel(4)
		self.Power.PostUpdate = PostUpdatePowerRaid
		self.Power.classColor = true

		local name = fs(self.Health, 'OVERLAY', cfg.NameFont, cfg.NameFS, cfg.FontF, 1, 1, 1)
		name:SetPoint('LEFT', 2, 6)
    name:SetJustifyH'LEFT'
		self:Tag(name, '[color][veryshort:name]')

	  local htext = self.Health.value
	  htext:SetPoint('RIGHT', -2, -5)
		htext:SetJustifyH'RIGHT'
		htext.frequentUpdates = true
    self:Tag(htext, '[raid:hp]')

		local rDhF = CreateFrame("Frame", nil, self)
		rDhF:SetAllPoints(self.Health)
		rDhF:SetFrameLevel(10)
		if cfg.RaidDebuffs then
			local d = CreateFrame('Frame', nil, self)
			d:SetSize(cfg.raidDebuffSize, cfg.raidDebuffSize)
			d:SetPoint('CENTER', 0, 4)
			d:SetFrameStrata'HIGH'
			d:SetBackdrop(backdrop3)
			d.icon = d:CreateTexture(nil, 'OVERLAY')
			d.icon:SetAllPoints(d)
			d.time = fs(d, 'OVERLAY', cfg.NumbFont, cfg.RaidFS, cfg.fontFNum, 0.8, 0.8, 0.8)
			d.time:SetPoint('TOPLEFT', d, 'TOPLEFT', 0, 0)
			d.count = fs(d, 'OVERLAY', cfg.NumbFont, cfg.RaidFS, cfg.fontFNum, 0.8, 0.8, 0.8)
			d.count:SetPoint('BOTTOMRIGHT', d, 'BOTTOMRIGHT', 2, 0)
			d.ShowBossDebuff = true
	   self.RaidDebuffs = d
	 	end
		-- plugins
		self.Range = range
		if cfg.SmoothHealthUpdate then
			self.Health.Smooth = true
		end
		if cfg.SmoothPowerUpdate then
			self.Power.Smooth = true
		end

		LfDR = self.Health:CreateTexture(nil, 'OVERLAY')
		LfDR:SetSize(12, 12)
		LfDR:SetPoint("TOPLEFT", self.Health, 2, 6)
		self.GroupRoleIndicator = LfDR

		LIc = self.Health:CreateTexture(nil, "OVERLAY")
		LIc:SetSize(12, 12)
		LIc:SetPoint("LEFT", LfDR, "RIGHT", 4, 0)
		self.LeaderIndicator = LIc

		rChk = self.Health:CreateTexture(nil, 'OVERLAY')
		rChk:SetSize(18, 18)
		rChk:SetPoint("CENTER", self.Health, 0, 0)
		rChk.fadeTimer = 6
		rChk.finishedTimer = 6
		self.ReadyCheckIndicator = rChk
	end

	UnitSpecific.r40 = UnitSpecific.raid
end

---------------------------------------
-- register style(s) and spawn units --
---------------------------------------
 oUF:RegisterStyle("Farva", Shared)

for unit,layout in next, UnitSpecific do
	oUF:RegisterStyle('Farva - ' .. unit:gsub("^%l", string.upper), layout)
end

local spawnHelper = function(self, unit, ...)
	if(UnitSpecific[unit]) then
		self:SetActiveStyle('Farva - ' .. unit:gsub("^%l", string.upper))
		local object = self:Spawn(unit)
		object:SetPoint(...)
		return object
	else
		self:SetActiveStyle'Farva'
		local object = self:Spawn(unit)
		object:SetPoint(...)
		return object
	end
end

if cfg.ArenaFrames then
oUF:RegisterStyle('oUF_Farva_Arena', UnitSpecific.arenaframes)
oUF:SetActiveStyle('oUF_Farva_Arena')
local arena = {}
local arenatarget = {}
	for i = 1, 5 do
		arena[i] = oUF:Spawn("arena"..i, "oUF_Arena"..i)
		if i == 1 then
			arena[i]:SetPoint('LEFT', UIParent, 'LEFT', 250, -200)
		else
			arena[i]:SetPoint("BOTTOMRIGHT", arena[i-1], "TOPRIGHT", 0, 50)
		end
	end

oUF:RegisterStyle("oUF_Farva_ArenaTarget", UnitSpecific.arenatargets)
oUF:SetActiveStyle("oUF_Farva_ArenaTarget")
	for i = 1, 5 do
		arenatarget[i] = oUF:Spawn("arena"..i.."target", "oUF_Arena"..i.."target"):SetPoint("TOPLEFT",arena[i], "TOPRIGHT", 8, 0)
	end
end



oUF:Factory(function(self)

	local player = spawnHelper(self, 'player', "BOTTOM", -338, 233)
	spawnHelper(self, 'pet', "RIGHT", player, "LEFT", -10, 0)
	local target = spawnHelper(self, 'target', "BOTTOM", 338, 233)
	spawnHelper(self, 'targettarget', "BOTTOM", 436, 191)
	local focus = spawnHelper(self, 'focus', "CENTER", 360, -164)
	spawnHelper(self, 'focustarget', "CENTER", 436, -209)

	local spec = GetSpecialization()
	local class = UnitClass("Player")

	if cfg.PartyFrames then
		local EventFrame = CreateFrame("Frame")
		EventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
		EventFrame:SetScript("OnEvent", function(self, event, ...)
				self[event](self, ...)
		end)

	    self:SetActiveStyle'Farva - Raid'
      local party = self:SpawnHeader('oUF_Party', nil, 'custom  [@raid6, exists] hide; show',
			'showPlayer',
			true,'showSolo',false,'showParty',true ,'point','RIGHT','xOffset',-5,
			'oUF-initialConfigFunction', ([[
			self:SetWidth(%d)
			self:SetHeight(%d)
			]]):format(cfg.widthR, cfg.heightR + cfg.NumbFS))

			--priest spec 1,2
			--paladin spec 1
			--shaman spec 3
			--monk spec 2
			--druid spec 4

			--function fired after spec changes
			function EventFrame:PLAYER_TALENT_UPDATE()
				if cfg.PartyFrames then
						if(cfg.healer) then
							party:ClearAllPoints()
							local spec = GetSpecialization()
							if((class == "Priest" and spec == 1)
							or (class == "Priest" and spec == 2)
							or (class == "Shaman" and spec == 3)
							or (class == "Paladin" and spec == 1)
							or (class == "Monk" and spec == 2)
							or (class == "Druid" and spec == 4)) then
								party:SetPoint("CENTER", cfg.healerX, cfg.healerY)
							else
								party:SetPoint("BOTTOMRIGHT", cfg.partyX, cfg.partyY)
							end
						else
							party:SetPoint("BOTTOMRIGHT", cfg.partyX, cfg.partyY)
						end
				end
			end

			--initial setpoints
			if(cfg.healer) then
				if((class == "Priest" and spec == 1)
				or (class == "Priest" and spec == 2)
				or (class == "Shaman" and spec == 3)
				or (class == "Paladin" and spec == 1)
				or (class == "Monk" and spec == 2)
				or (class == "Druid" and spec == 4)) then
					party:SetPoint("CENTER", cfg.healerX, cfg.healerY)
				else
					party:SetPoint("BOTTOMRIGHT", cfg.partyX, cfg.partyY)
				end
			else
				party:SetPoint("BOTTOMRIGHT", cfg.partyX, cfg.partyY)
			end
	end

	local arenaprep = {}
	for i = 1, 5 do
	  arenaprep[i] = CreateFrame('Frame', 'oUF_ArenaPrep'..i, UIParent)
	  arenaprep[i]:SetAllPoints(_G['oUF_Arena'..i])
	  arenaprep[i]:SetFrameStrata('BACKGROUND')
		arenaprep[i].framebd = framebd(arenaprep[i], arenaprep[i])

	  arenaprep[i].Health = CreateFrame('StatusBar', nil, arenaprep[i])
	  arenaprep[i].Health:SetAllPoints()
	  arenaprep[i].Health:SetStatusBarTexture(cfg.blanktexture)

	  arenaprep[i].Spec = fs(arenaprep[i].Health, 'OVERLAY', cfg.NumbFont, cfg.NumbFS, cfg.fontFNum, 1, 1, 1)
	  arenaprep[i].Spec:SetPoint('CENTER')
		arenaprep[i].Spec:SetJustifyH'CENTER'

	  arenaprep[i]:Hide()
	end

	local arenaprepupdate = CreateFrame('Frame')
	arenaprepupdate:RegisterEvent('PLAYER_LOGIN')
	arenaprepupdate:RegisterEvent('PLAYER_ENTERING_WORLD')
	arenaprepupdate:RegisterEvent('ARENA_OPPONENT_UPDATE')
	arenaprepupdate:RegisterEvent('ARENA_PREP_OPPONENT_SPECIALIZATIONS')
	arenaprepupdate:SetScript('OnEvent', function(self, event)
	  if event == 'PLAYER_LOGIN' then
	    for i = 1, 5 do
		    arenaprep[i]:SetAllPoints(_G['oUF_Arena'..i])
	    end
	  elseif event == 'ARENA_OPPONENT_UPDATE' then
	    for i = 1, 5 do
		    arenaprep[i]:Hide()
	    end
	  else
	    local numOpps = GetNumArenaOpponentSpecs()
	    if numOpps > 0 then
		    for i = 1, 5 do
			    local f = arenaprep[i]

			    if i <= numOpps then
				    local s = GetArenaOpponentSpec(i)
				    local _, spec, class = nil, 'UNKNOWN', 'UNKNOWN'

				    if s and s > 0 then
					    _, spec, _, _, _, _, class = GetSpecializationInfoByID(s)
				    end

				    if class and spec then
					    local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
						if cfg.class_colorbars and color then
						    f.Health:SetStatusBarColor(color.r, color.g, color.b)
						else
							f.Health:SetStatusBarColor(40/255, 40/255, 40/255)
						end
					    f.Spec:SetText(spec..'  -  '..LOCALIZED_CLASS_NAMES_MALE[class])
					    f:Show()
				    end
			    else
				    f:Hide()
			    end
		    end
	    else
		    for i = 1, 5 do
			    arenaprep[i]:Hide()
		    end
	    end
	  end
	end)

	if cfg.RaidFrames then
		local EventFrame = CreateFrame("Frame")
		EventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
		EventFrame:SetScript("OnEvent", function(self, event, ...)
				self[event](self, ...)
		end)

		self:SetActiveStyle"Farva - Raid"
		local raid = self:SpawnHeader(nil, nil, 'custom [@raid6,exists] show; hide',
			'showPlayer', true,
			'showSolo', true,
			'showParty', true,
			'showRaid', true,
			'xoffset', 5,
			'yOffset', -10,
			'point', 'LEFT',
			'groupFilter', '1,2,3,4,5,6,7,8',
			'groupingOrder', '1,2,3,4,5,6,7,8',
			'groupBy', 'GROUP',
			'maxColumns', 8,
			'unitsPerColumn', 5,
			'columnSpacing', -1,
			'sortMethod', 'INDEX',
			'columnAnchorPoint', 'TOP',
			'oUF-initialConfigFunction', ([[
			self:SetWidth(%d)
			self:SetHeight(%d)
			]]):format(cfg.widthR, cfg.heightR + cfg.NumbFS))

			--priest spec 1,2
			--paladin spec 1
			--shaman spec 3
			--monk spec 2
			--druid spec 4

			--function fired after spec changes
			function EventFrame:PLAYER_TALENT_UPDATE()
				if cfg.RaidFrames then
						if(cfg.healer) then
							raid:ClearAllPoints()
							local spec = GetSpecialization()
							if((class == "Priest" and spec == 1)
							or (class == "Priest" and spec == 2)
							or (class == "Shaman" and spec == 3)
							or (class == "Paladin" and spec == 1)
							or (class == "Monk" and spec == 2)
							or (class == "Druid" and spec == 4)) then
								raid:SetPoint("CENTER", cfg.healerX, cfg.healerY)
							else
								raid:SetPoint("BOTTOMRIGHT", cfg.partyX, cfg.partyY)
							end
						else
							raid:SetPoint("BOTTOMRIGHT", cfg.partyX, cfg.partyY)
						end
				end
			end

			--initial setpoints
			if(cfg.healer) then
				if((class == "Priest" and spec == 1)
				or (class == "Priest" and spec == 2)
				or (class == "Shaman" and spec == 3)
				or (class == "Paladin" and spec == 1)
				or (class == "Monk" and spec == 2)
				or (class == "Druid" and spec == 4)) then
					raid:SetPoint("CENTER", cfg.healerX, cfg.healerY)
				else
					raid:SetPoint("BOTTOMRIGHT", cfg.partyX, cfg.partyY)
				end
			else
				raid:SetPoint("BOTTOMRIGHT", cfg.partyX, cfg.partyY)
			end
	end

	if cfg.BossFrames then
		self:SetActiveStyle"Farva - Boss"
		local boss = {}
			for i = 1, MAX_BOSS_FRAMES do
				local unit = self:Spawn("boss"..i, "oUF_FarvaBoss"..i)

				if i==1 then
					unit:SetPoint("LEFT", 25, -162)
				else
					unit:SetPoint("TOPLEFT", boss[i-1], "BOTTOMLEFT", 0, -10)
				end
				boss[i] = unit
			end
	end

	if cfg.MTFrames then
		self:SetActiveStyle"Farva - MainTank"
		local Main_Tank = self:SpawnHeader("oUF_MainTank", nil, 'raid, party, solo',
			'showRaid', true,
			"groupFilter", "MAINTANK",
			'yOffset', -10,
			"template", "oUF_FarvaMTartemplate",		-- MT Target
			'oUF-initialConfigFunction', ([[
				self:SetWidth(%d)
				self:SetHeight(%d)
			]]):format(cfg.widthM, cfg.heightM))
		Main_Tank:SetPoint("TOPLEFT", 22, -251)
	end
end)

-- disable blizzard raidframe manager
if cfg.disableRaidFrameManager then
		CompactRaidFrameManager:UnregisterAllEvents()
    CompactRaidFrameManager:HookScript('OnShow', function(s) s:Hide() end)
    CompactRaidFrameManager:Hide()
    CompactRaidFrameContainer:UnregisterAllEvents()
    CompactRaidFrameContainer:HookScript('OnShow', function(s) s:Hide() end)
    CompactRaidFrameContainer:Hide()
end

-------------
-- The End --
-------------
