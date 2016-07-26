local bossGUID = nil
local DS_BarAnimationDelay = 1 -- in seconds
local DS_BarAnimationUpdateInterval = 0 -- in seconds
local DS_BarAnimationPixelsPerSecond = 200

-- Initialize player health frame
function DS_initPlayerFrame()
	print("DSHP Loaded")
	DS_PlayerFrame:RegisterEvent("UNIT_HEALTH_FREQUENT")
	DS_PlayerFrame:RegisterEvent("UNIT_MAXHEALTH")
	DS_PlayerFrame:RegisterEvent("UNIT_POWER")
	DS_PlayerFrame:RegisterEvent("UNIT_MAXPOWER")
	DS_PlayerFrame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")

	UnregisterUnitWatch(PlayerFrame)
	PlayerFrameHealthBar:UnregisterAllEvents()
	PlayerFrameManaBar:UnregisterAllEvents()

	PlayerFrameHealthBar:SetScript("OnShow", DS_hideEverything)
	PlayerFrameManaBar:SetScript("OnShow", DS_hideEverything)

	--hooksecurefunc("UnitFrame_Initialize", DS_hideEverything)
	--hooksecurefunc("UnitFrameHealthBar_Update", DS_hideEverything)
	--hooksecurefunc("UnitFrameManaBar_Update", DS_hideEverything)
	--hooksecurefunc("ToggleCharacter", DS_loadCharacterFrameHooks)
	hooksecurefunc("ToggleCharacter", DS_hideEverything)
	hooksecurefunc("TextStatusBar_OnEvent", DS_hideEverything)
	hooksecurefunc("TextStatusBar_UpdateTextStringWithValues", DS_hideEverything)
	hooksecurefunc("ShowTextStatusBarText", DS_hideEverything)
	hooksecurefunc("HideTextStatusBarText", DS_hideEverything)
	hooksecurefunc("UnitFrameHealPredictionBars_Update", DS_hideEverything)
	hooksecurefunc("UnitFrame_UpdateThreatIndicator", DS_hideEverything)
	hooksecurefunc("PlayerFrame_UpdateStatus", DS_hidePlayerFrameGlow)

	DS_hidePlayerFrameGlow()

	local point, relativeTo, relativePoint, xOfs, yOfs = PlayerFrame:GetPoint()
	DS_PlayerFrame:SetPoint(point, relativeTo, relativePoint, 0, 50)

	DS_PlayerHealthString:SetText(DS_formatHealth(UnitHealth("player")))
	DS_PlayerHealthBar:SetMinMaxValues(0,UnitHealthMax("player"))
	DS_PlayerHealthBar:SetValue(UnitHealth("player"))
	DS_PlayerPowerBar:SetMinMaxValues(0,UnitPowerMax("player"))
	DS_PlayerPowerBar:SetValue(UnitPower("player"))
end

--[[function DS_loadCharacterFrameHooks()
	print("Loaded CharacterFrame hooks")
	hooksecurefunc("CharacterFrame_OnLoad", DS_hideEverything)
	hooksecurefunc("CharacterFrame_OnShow", DS_hideEverything)
	hooksecurefunc("CharacterFrame_OnHide", DS_hideEverything)
end--]]

function DS_hideEverything()
	PlayerName:Hide()
	PlayerFrameHealthBarText:Hide()
	PlayerFrameManaBarText:Hide()
	PlayerFrameHealthBar:Hide()
	PlayerFrameManaBar:Hide()
	PlayerFrameBackground:Hide()
	PlayerFrameTexture:Hide()
	PlayerFrameTotalAbsorbBar:Hide()
	PlayerFrameOverAbsorbGlow:Hide()
	PlayerFrame.threatIndicator:Hide()
end

function DS_hidePlayerFrameGlow()
	PlayerStatusTexture:Hide()
	PlayerStatusGlow:Hide()
end

function DS_initPlayerHealthFrameYellow()
	DS_PlayerHealthBarYellow:SetMinMaxValues(0,UnitHealthMax("player"))
	DS_PlayerHealthBarYellow:SetValue(UnitHealth("player"))
	local point, relativeTo, relativePoint, xOfs, yOfs = PlayerFrame:GetPoint()
	DS_PlayerHealthFrameYellow:SetPoint(point, relativeTo, relativePoint, 0, 50)
end

function DS_initPlayerPowerFrameYellow()
	DS_PlayerPowerFrameYellow:RegisterEvent("UNIT_POWER")
	DS_PlayerPowerFrameYellow:RegisterEvent("UNIT_MAXPOWER")
	DS_PlayerPowerBarYellow:SetMinMaxValues(0,UnitPowerMax("player"))
	DS_PlayerPowerBarYellow:SetValue(UnitPower("player"))
	local point, relativeTo, relativePoint, xOfs, yOfs = PlayerFrame:GetPoint()
	DS_PlayerPowerFrameYellow:SetPoint(point, relativeTo, relativePoint, 0, 50)
end

function DS_initPlayerAbsorbFrame()
	local point, relativeTo, relativePoint, xOfs, yOfs = PlayerFrame:GetPoint()
	DS_PlayerAbsorbFrame:SetPoint(point, relativeTo, relativePoint, 0, 50)
	DS_PlayerAbsorbBar:SetMinMaxValues(0,UnitHealth("player"))
	DS_PlayerAbsorbBar:SetValue(UnitGetTotalAbsorbs("player"))
end

function DS_initBossHealthFrameYellow()
	DS_BossHealthFrameYellow:RegisterEvent("PLAYER_TARGET_CHANGED")
	DS_BossHealthBarYellow:SetMinMaxValues(0,100)
	DS_BossHealthFrameYellow:Hide()
end

-- Initialize boss health frame
function DS_initBossHealthFrame()
	DS_BossHealthFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	DS_BossHealthFrame:RegisterEvent("UNIT_HEALTH_FREQUENT")
	DS_BossHealthFrame:RegisterEvent("UNIT_MAXHEALTH")
	DS_BossHealthFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	DS_BossHealthFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	DS_BossHealthFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	DS_BossHealthBar:SetMinMaxValues(0,100)
	DS_BossHealthFrame:Hide()
end


function DS_playerEventHandler(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		DS_initPlayerFrame()
	elseif event == "UNIT_HEALTH_FREQUENT" then
		DS_updatePlayerHealth()
	elseif event == "UNIT_MAXHEALTH" then
		DS_updatePlayerHealthMax()
	elseif event == "UNIT_POWER" then
		DS_updatePlayerPower()
	elseif event == "UNIT_MAXPOWER" then
		DS_updatePlayerPowerMax()
	elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
		DS_updatePlayerAbsorb()
	end
end

function DS_bossEventHandler(self, event, ...)
	if event == "PLAYER_TARGET_CHANGED" then
		if UnitExists("target") and UnitCanAttack("player","target") then
			local bosses = DS_getBosses()
			if (next(bosses) ~= nil and bosses[UnitGUID("target")]) or next(bosses) == nil then -- boss exists, targeting a boss || no bosses
				DS_updateBossHealthBars()
			end
		end
	elseif event == "UNIT_MAXHEALTH" or event == "UNIT_HEALTH_FREQUENT" then
		DS_setBossHealth(DS_getUpdatedBossHealth())
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" and IsInGroup() then
		local timestamp, etype, hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags, destFlags2 = select(1, ...)
		if etype == "SPELL_DAMAGE" and destGUID == bossGUID then
			DS_setBossHealth(DS_getUpdatedBossHealth())
		end
	end
end

-- Update player health
function DS_updatePlayerHealth()
	DS_PlayerHealthString:SetText(DS_formatHealth(UnitHealth("player")))
	DS_PlayerHealthBar:SetValue(UnitHealth("player"))
	if DS_PlayerHealthBarYellow:GetValue() < DS_PlayerHealthBar:GetValue() then
		DS_PlayerHealthBarYellow:SetValue(DS_PlayerHealthBar:GetValue())
	end
	DS_movePlayerAbsorbFrame()
end

-- Update player health max
function DS_updatePlayerHealthMax()
	DS_PlayerHealthBar:SetMinMaxValues(0,UnitHealthMax("player"))
	DS_PlayerHealthBarYellow:SetMinMaxValues(DS_PlayerHealthBar:GetMinMaxValues())
	if DS_PlayerHealthBarYellow:GetValue() < DS_PlayerHealthBar:GetValue() then
		DS_PlayerHealthBarYellow:SetValue(DS_PlayerHealthBar:GetValue())
	end
	DS_PlayerAbsorbBar:SetMinMaxValues(0,UnitHealth("player"))
	DS_movePlayerAbsorbFrame()
end

-- Update player power
function DS_updatePlayerPower()
	DS_PlayerPowerString:SetText(DS_formatPower(UnitPower("player")))
	DS_PlayerPowerBar:SetValue(UnitPower("player"))
	if DS_PlayerPowerBarYellow:GetValue() < DS_PlayerPowerBar:GetValue() then
		DS_PlayerPowerBarYellow:SetValue(UnitPower("player"))
	end
end

-- Update player power max
function DS_updatePlayerPowerMax()
	DS_PlayerPowerBar:SetMinMaxValues(0,UnitPowerMax("player"))
	DS_PlayerPowerBarYellow:SetMinMaxValues(0,UnitPowerMax("player"))
end

-- Update player absorb
function DS_updatePlayerAbsorb()
	DS_PlayerAbsorbBar:SetValue(UnitGetTotalAbsorbs("player"))
end

function DS_movePlayerAbsorbFrame()
	local healthMin, healthMax = DS_PlayerHealthBar:GetMinMaxValues()
	local multiplier = DS_PlayerHealthBar:GetValue() / healthMax
	local pixelWidth = DS_PlayerHealthBar:GetWidth() * multiplier -- number of pixels taken up by width of bar
	local point, relativeTo, relativePoint, xOfs, yOfs = PlayerFrame:GetPoint()
	DS_PlayerAbsorbFrame:SetPoint(point, relativeTo, relativePoint, pixelWidth, 50)
end

function DS_updateBossHealthBars()
	bossGUID = UnitGUID("target")
	DS_BossNameString:SetText(UnitName("target"))
	local tempBossHealth, tempBossHealthMax = DS_getUpdatedBossHealth()
	DS_setBossHealth(tempBossHealth, tempBossHealthMax)
	--if DS_BossHealthBarYellow:GetValue() < DS_BossHealthBar:GetValue() then
		DS_BossHealthBarYellow:SetValue((tempBossHealth/tempBossHealthMax)*100)
	--end
end

function DS_formatHealth(hp)
	if hp > 10000 then
		return math.floor(hp/1000) .. "k"
	end
	return hp
end

function DS_formatPower(p)
	if p > 10000 then
		return math.floor(p/1000) .. "k"
	end
	return p
end

function DS_getBosses()
	local bosses = {}
	for i=1,5 do
		if UnitExists("boss" .. i) then
			bosses[UnitGUID("boss" .. i)] = "boss" .. i
		end
	end
	return bosses
end

function DS_setBossHealth(bossHp, bossHpMax)
	-- Ghetto checking for NaN
	if bossHp ~= bossHp or bossHpMax ~= bossHpMax then
		DS_BossHealthFrame:Hide()
		DS_BossHealthFrameYellow:Hide()
	elseif bossHp == 0 then
		DS_BossHealthBar:SetValue(0)
		DS_BossHealthString:SetText("0%")
		DS_BossHealthFrame:Hide()
		DS_BossHealthFrameYellow:Hide()
	else
		local healthPercent = (bossHp/bossHpMax)*100
		DS_BossHealthBar:SetValue(healthPercent)
		DS_BossHealthString:SetText(string.format("%i", healthPercent) .. "%")
		DS_BossHealthFrame:Show()
		DS_BossHealthFrameYellow:Show()
	end
end

function DS_animatePlayerHealthBarYellow(self, elapsed)
	if DS_PlayerHealthBar:GetValue() < DS_PlayerHealthBarYellow:GetValue() then
		if self.TimeSinceLastUpdate < DS_BarAnimationDelay then
			self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
		else
			DS_PlayerHealthBarYellow:SetValue(
				DS_PlayerHealthBarYellow:GetValue() - DS_getScaledAnimationIncrement(
					DS_PlayerHealthBar, elapsed
				)
			)
		end
	else
		self.TimeSinceLastUpdate = 0
	end
end

function DS_animatePlayerPowerBarYellow(self, elapsed)
	if DS_PlayerPowerBar:GetValue() < DS_PlayerPowerBarYellow:GetValue() then
		if self.TimeSinceLastUpdate < DS_BarAnimationDelay then
			self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
		else
			DS_PlayerPowerBarYellow:SetValue(
				DS_PlayerPowerBarYellow:GetValue() - DS_getScaledAnimationIncrement(
					DS_PlayerPowerBar, elapsed
				)
			)
		end
	else
		self.TimeSinceLastUpdate = 0
	end
end

function DS_animateBossHealthBarYellow(self, elapsed)
	if DS_BossHealthBar:GetValue() < DS_BossHealthBarYellow:GetValue() then
		if self.TimeSinceLastUpdate < DS_BarAnimationDelay then
			self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
		else
			DS_BossHealthBarYellow:SetValue(
				DS_BossHealthBarYellow:GetValue() - DS_getScaledAnimationIncrement(
					DS_BossHealthBar, elapsed
				)
			)
		end
	else
		self.TimeSinceLastUpdate = 0
	end
end

function DS_getScaledAnimationIncrement(bar, elapsed)
	local minValue, maxValue = bar:GetMinMaxValues()
	local incPixelRatio = (elapsed * DS_BarAnimationPixelsPerSecond) / bar:GetWidth()
	local scaledIncrement = incPixelRatio * maxValue
	return scaledIncrement
end

function DS_getUpdatedBossHealth()
	if UnitExists("target") and UnitGUID("target") == bossGUID then
		return UnitHealth("target"), UnitHealthMax("target")
	end
	for k,_ in pairs(DS_groupTargetingBoss()) do
		return UnitHealth(k .. "target"), UnitHealthMax(k .. "target")
	end
	return 0,0
end

function DS_groupTargetingBoss()
	local playersTargeting = {}
	if IsInGroup() then
		for i=1,GetNumGroupMembers() do
			local c = "party" .. i
			if IsInRaid() then
				c = "raid" .. i
			end
			if DS_isUnitTargetingBoss(c) then
				--table.insert(playersTargeting, c)
				playersTargeting[c] = true
			end
		end
	end
	return playersTargeting
end

function DS_isGroupTargetingBoss()
	local target = false
	if IsInGroup() then
		for i=1,GetNumGroupMembers() do
			local c = "party" .. i
			if IsInRaid() then
				c = "raid" .. i
			end
			if DS_isUnitTargetingBoss(c) then
				return true
			end
		end
	end
	return false
end

function DS_isUnitTargetingBoss(unit)
	local unitTarget = unit .. "target"
	if UnitExists(unit) and UnitExists(unitTarget) and UnitGUID(unitTarget) == bossGUID then
		return true
	end
	return false
end

function DS_trigger_animateYellowHealthBar(self, elasped)
end
