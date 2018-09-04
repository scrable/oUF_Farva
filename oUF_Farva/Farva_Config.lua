﻿local addon, ns = ...
local cfg = CreateFrame("Frame")
local mediaFolder = "Interface\\AddOns\\oUF_Farva\\media\\"	-- don't touch this ...
local blankTex = "Interface\\Buttons\\WHITE8x8"

cfg.texture = "Interface\\Addons\\oUF_Farva\\media\\texture.tga"

------------
-- colors --
------------
	cfg.maincolor = {53/255, 69/255, 105/255}				-- portrait BG, raid health bar, castbar color
	cfg.sndcolor = {255/255, 255/255, 255/255}				-- font color, ...
	cfg.trdcolor = {85/255, 150/255, 85/255}
	cfg.backdropcolor = {26/255, 25/255, 31/255}			-- backdrop color
	cfg.brdcolor = {0/255, 0/255, 0/255}					-- border color
	cfg.enemycast = {85/255, 150/255, 85/255}				--enemy interruptable cast color

	cfg.TransparencyMode = true						-- enable/disable Transparency Mode - transparent healthbars, with class/reaction colored background. Besides looking nifty, it's especially nice for healers.
	cfg.hpTransMcolor = {40/255, 40/255, 40/255}			-- health bar color - Transparency Mode, only
	cfg.hpTransMalpha = 0.4									-- healthbar alpha - Transparency Mode, only

-----------
-- media --
-----------
	cfg.HPtex = mediaFolder.."dM3"							-- health bar texture
	cfg.PPtex = mediaFolder.."dM2"							-- power bar texture
	cfg.CBtex = mediaFolder.."dM2"							-- castbar texture
	cfg.Itex = blankTex										-- BG texture

	cfg.NameFont = "Interface\\Addons\\oUF_Farva\\media\\SKURRI.ttf"				-- font used for text (names)
	cfg.NumbFont = "Interface\\Addons\\oUF_Farva\\media\\SKURRI.ttf"				-- font used for numbers
	cfg.NameFS = 7											-- name font size
	cfg.NumbFS = 7  										-- number font size (power value, etc.)
	cfg.hpNumbFS = 7										-- health value font size (player, target, focus)
	cfg.CastFS = 7											-- castbar font size
	cfg.ComboFS = 7										-- combo point and class points font size
	cfg.RaidFS = 7											-- font size for numbers (aura, class tags) on raid frames
	cfg.FontF = "OUTLINE MONOCHROME"						-- "THINOUTLINE", "OUTLINE MONOCHROME", "OUTLINE" or nil (no outline)
	cfg.fontFNum = "OUTLINE MONOCHROME"

----------------------
-- general settings --
----------------------
	cfg.FadeOutAlpha = 0.3 					-- alpha for out of range units
	cfg.SmoothHealthUpdate = true		-- makes the updates for health smooth
	cfg.SmoothPowerUpdate = true		-- makes the updates for the power smooth

	cfg.useCastbar = true					-- show/hide player, target, focus castbar

	cfg.useSpellIcon = false				-- show/hide castbar spellicon
	cfg.ShiftClickFocus = true				-- enable/disable using shift + click for creating a focus

	cfg.buSize = 24							-- aura size for all frames except player debuff

	cfg.threat = {
		showEverywhere = false, -- false = only show in combat
		enable = true,
		pos = {'BOTTOM', UIParent, 1, 2},
		width = 260,
		height = 8,
	}

------------
-- player --
------------

	cfg.PlayerDebuffs = true				-- show debuffs acting on the player
	cfg.showDebuffColorPerType = true -- show colors for different spell types - green = poison, blue = magic, purple = curse, disease = yellow, red is undispellable
	cfg.showExperienceBar = true		-- show an experience bar under the player frame

------------
-- target --
------------
	cfg.showTargetBuffs = true
	cfg.showTargetDebuffs = false
	cfg.onlyShowPlayerBuffsTarget = false 		-- only show buffs casted by player (target and focus)
	cfg.onlyShowPlayerDebuffsTarget = true		-- only show debuffs casted by player (target and focus)

-----------
-- focus --
-----------

	cfg.showFocusBuffs = true
	cfg.showFocusDebuffs = true
	cfg.onlyShowPlayerBuffsFocus = false
	cfg.onlyShowPlayerDebuffsFocus = true

-----------
-- party & Raid--
-----------

	--Coordinate values here will be overwritten by oUF_MovableFrames
	--If you want to have these values work, don't move the anchor in oUF_MovableFrames
	--Healer mode requires OMF values removed/cleared/deleted for party and raid
	cfg.PartyFrames = true 					-- set to false to disable party frames
	cfg.partyX = -45								--X coordinate for party and raid frames
	cfg.partyY = 9									--Y coordinate for party and raid frames

	cfg.healer = true							--set to true to have two different frame positions depending if healing or not
	cfg.healerX = -1									-- X coordinate for raid frame
	cfg.healerY =	-295								-- Y coordinate for raid frame

	cfg.RaidFrames = true	 				-- set to false to disable raid frame
	cfg.disableRaidFrameManager = true		-- enable/disable blizzards raidframe manager
	cfg.RaidDebuffs = true					-- enable/disable raid debuffs
	cfg.raidDebuffSize = 20					--size for debuffs in raid frames

-----------
-- arena --
-----------
	cfg.ArenaFrames = true	 				-- enable/disable arena frames

---------------
-- main tank --
---------------
	cfg.MTFrames = false	 					-- enable/disable main tank frames

----------
-- boss --
----------
	cfg.BossFrames = true	 				-- enable/disable boss frames


--***********************
--aurawatch
cfg.aw = {
        enable = true,						--enable/disable oUF_Aurawatch
        onlyShowPresent = true,
				anyUnit = false,						--show only player auras or everyones auras
}
	cfg.AWCooldownCount = true		--enable/disable aurawatch icons spiral. false displays a solid color modified below in the spellids


cfg.spellIDs = {		--spellIDs of auras to track with aurawatch
	    DRUID = {
	            {8936, {0.8, 0.4, 0}, 'TOPLEFT'},		-- Regrowth
	            {102342, {0.38, 0.22, 0.1}},		    -- Ironbark
	            {48438, {0.4, 0.8, 0.2}, 'BOTTOMLEFT'},	-- Wild Growth
	            {774, {0.8, 0.4, 0.8},'TOPRIGHT'},		-- Rejuvenation
	            },
	     MONK = {
	            {119611, {0.2, 0.7, 0.7}},			    -- Renewing Mist
	            {124682, {0.4, 0.8, 0.2}},			    -- Enveloping Mist
	            {124081, {0.7, 0.4, 0}},			    -- Zen Pulse
	            {116849, {0.81, 0.85, 0.1}},		    -- Life Cocoon
	            },
	  PALADIN = {
	            {6940, {0.89, 0.1, 0.1}, 'BOTTOMLEFT'}, -- Hand of Sacrifice
	            {1022, {0.2, 0.2, 1}, 'BOTTOMLEFT'},	-- Hand of Protection
	            {1044, {0.89, 0.45, 0}, 'BOTTOMLEFT'},  -- Hand of Freedom
	            {53563, {0.7, 0.3, 0.7}, 'TOPRIGHT'},   -- Beacon of Light
							{25771,{0.7, 0.3, 0.7}, 'BOTTOM'},
	            },
	   PRIEST = {
	            {41635, {0.2, 0.7, 0.2}},			    -- Prayer of Mending
	            {33206, {0.89, 0.1, 0.1}},			    -- Pain Suppress
	            {194384, {0.86, 0.52, 0}, 'BOTTOMRIGHT'},			    -- Atonement
	            {6788, {1, 0, 0}, 'BOTTOMLEFT'},	    -- Weakened Soul
	            {17, {0.81, 0.85, 0.1}, 'TOPLEFT'},	    -- Power Word: Shield
	            {139, {0.4, 0.7, 0.2}, 'TOPRIGHT'},     -- Renew
	            },
	   SHAMAN = {
	            {61295, {0.7, 0.3, 0.7}, 'TOPRIGHT'},   -- Riptide
	            },
  DEATHKNIGHT = {
	            },
	DEMONHUNTER = {
							},
	   HUNTER = {
	            {34477, {0.2, 0.2, 1}},				    -- Misdirection
	            },
	     MAGE = {
	            },
	    ROGUE = {
	            {57934, {0.89, 0.1, 0.1}},			    -- Tricks of the Trade
	            },
	  WARLOCK = {
	            {20707, {0.7, 0.32, 0.75}},			    -- Soulstone
	            },
	  WARRIOR = {
	            {114030, {0.2, 0.2, 1}},			    -- Vigilance
	            },
 }

 --**************************

---------------
-- framesize --
---------------
	-- height
	cfg.heightP = 10		-- player
	cfg.heightT = 10		-- target
	cfg.heightF = 10		-- Focus
	cfg.heightS = 10 		-- ToT, FocusTarget, pet
	cfg.heightM = 10 		-- MT, boss frames
	cfg.heightPA = 10		-- party, party pet - arena
	cfg.heightR = 24		-- raid
	cfg.heightCB = 30		-- class bar

	-- width
	cfg.widthP = 250		-- player
	cfg.widthT = 250		-- target
	cfg.widthF = 200		-- Focus
	cfg.widthM = 140 		-- MT, boss frames
	cfg.widthS = 48 		-- ToT, FocusTarget, pet, party pet
	cfg.widthPA = 200 		-- party - arena
	cfg.widthR = 80 		-- raid
	cfg.widthCB = 30		-- class bar

	-- hp|pp height, pp|info offset (optional)
	cfg.heightHP = 18		-- change frame height above, instead
	cfg.heightPP = 2		-- power height
	cfg.PPyOffset = 4		-- power y-Offset, can be a positiv/negative (down/up) value


ns.cfg = cfg	-- don't touch this ...
