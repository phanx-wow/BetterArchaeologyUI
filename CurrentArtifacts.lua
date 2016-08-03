--[[--------------------------------------------------------------------
	Better Archaeology UI
	Improves the Blizzard archaeology UI.
	Copyright (c) 2015, 2016 Phanx. All rights reserved.
	https://github.com/Phanx/BetterArchaeologyUI
	https://mods.curse.com/addons/wow/better-archaeology-ui
	http://www.wowinterface.com/downloads/info23693
----------------------------------------------------------------------]]

local _, private = ...
local L = private.L
local itemContains   = private.itemContains
local itemFromSpell  = private.itemFromSpell
local linkFromItem   = private.linkFromItem
local UpdateItemList = private.UpdateItemList

------------------------------------------------------------------------

local rarityColor = {
	[0] = ITEM_QUALITY_COLORS[1].hex,
	[1] = ITEM_QUALITY_COLORS[3].hex,
}
local rarityText = {
	[0] = ITEM_QUALITY1_DESC,
	[1] = ITEM_QUALITY3_DESC,
}

local raceData = {}
local keystoneFragments = {}

local function RaceButton_OnEnter(self)
	local data = raceData[self:GetID()]
	local artifactName = data.artifactName
	local artifactLink = data.artifactLink
	local artifactRarity = data.artifactRarity
	local bonusFragments = data.bonusFragments
	local haveFragments = data.haveFragments
	local needFragments = data.needFragments
	local numKeystones = data.numKeystones
	local numSockets = data.numSockets
	local numSocketsFilled = data.numSocketsFilled

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

	if artifactLink then
		local contents = itemContains[artifactLink]
		if contents then -- Canopic Jar
			GameTooltip:SetHyperlink(contents.link)
			GameTooltip:AddLine(format(contents.text, artifactName), nil, nil, nil, nil, true)
			GameTooltip:Show()
		else
			GameTooltip:SetHyperlink(artifactLink)
		end
	elseif GetCVarBool("colorblindMode") then
		GameTooltip:SetText(artifactName .. " (" .. rarityText[artifactRarity] .. ")")
	else
		GameTooltip:SetText(rarityColor[artifactRarity] .. artifactName)
	end
--[[
	if itemFromSpell[artifactName] then
		GameTooltip:AddLine(format(L["Created by %s"].."|n", artifactName))
	end
]]
	GameTooltip:AddLine(L["Click for artifact details."])
	if (haveFragments + bonusFragments) >= needFragments then
		if numSocketsFilled > 0 then
			GameTooltip:AddLine(format(L["Right-click to solve using %d keystones."], numSocketsFilled))
			if haveFragments >= needFragments then
				GameTooltip:AddLine(L["Shift-right-click to solve without keystones."])
			end
		else
			GameTooltip:AddLine(L["Right-click to solve artifact."])
		end
	end
	GameTooltip:Show()
end

local function RaceButton_OnClick(self, button)
	if button == "LeftButton" then
		self:OnLeftClick()
	else
		local data = raceData[self:GetID()]
		local haveFragments, needFragments, maxFragments = data.haveFragments, data.needFragments, data.maxFragments
		local keystoneItemID, numKeystones = data.keystoneItemID, data.numKeystones
		local bonusFragments = data.bonusFragments
		local numSockets = data.numSockets
		if (IsShiftKeyDown() and (haveFragments < needFragments)) or (haveFragments + bonusFragments) < needFragments then
			return
		end
		SetSelectedArtifact(data.raceIndex)
		if numKeystones > 0 and numSockets > 0 and not IsShiftKeyDown() then
			for i = 1, min(numKeystones, numSockets) do
				if not SocketItemToArtifact() then
					break
				end
			end
		end
		--[[ DEBUG ]]
		for i = 1, numSockets do
			if not ItemAddedToArtifact(i) then
				print("Solving with " .. (i-1) .. "/" .. numSockets .. " keystones, " .. numKeystones .. " available")
				break
			end
		end
		if CanSolveArtifact() then
			SolveArtifact()
		end
	end
end

local function RaceButton_Update(self)
	local data = raceData[self:GetID()]
	local raceName = data.raceName
	local artifactName, artifactRarity = data.artifactName, data.artifactRarity
	local haveFragments, needFragments, maxFragments = data.haveFragments, data.needFragments, data.maxFragments
	local keystoneItemID, numKeystones = data.keystoneItemID, data.numKeystones
	local numSockets, numSocketsFilled, bonusFragments = data.numSockets, data.numSocketsFilled, data.bonusFragments

	self.raceName:SetText(raceName)
	self.bar:SetMinMaxValues(0, needFragments)

	if needFragments > 0 then
		self.bar:SetAlpha(1)
		if bonusFragments > 0 then
			self.bar:SetValue(haveFragments + bonusFragments)
			self.bar.text:SetText((haveFragments + bonusFragments) .. GREEN_FONT_COLOR_CODE.." (+" .. bonusFragments .. ")|r/" .. needFragments)
		else
			self.bar:SetValue(haveFragments)
			self.bar.text:SetText(haveFragments.."/"..needFragments)
		end
		-- Color text
		if (haveFragments + bonusFragments) > needFragments and haveFragments < needFragments then
			-- Can only solve with keystones
			self.bar.text:SetTextColor(1, 0.82, 0)
		else
			self.bar.text:SetTextColor(1, 1, 1)
		end
		-- Color bar
		if haveFragments >= maxFragments then
			self.bar:SetStatusBarColor(1, 0, 0)
		elseif (haveFragments + bonusFragments) < needFragments then
			self.bar:SetStatusBarColor(1, 0.82, 0)
		else
			self.bar:SetStatusBarColor(0, 0.85, 0)
		end
		-- Update tooltip
		if self:IsMouseOver() then
			self:GetScript("OnLeave")(self)
			self:GetScript("OnEnter")(self)
		end
	else
		self.bar:SetAlpha(0.5)
		self.bar:SetValue(0)
		self.bar.text:SetText("")
	end
end

local function Initialize(self)
	local numRaces = GetNumArchaeologyRaces()
	local colBreak = ceil(numRaces/2)+1
	ARCHAEOLOGY_MAX_RACES = numRaces
	for i = 1, numRaces do
		local raceButton = self["race"..i]
		if not raceButton then
			raceButton = CreateFrame("Button", "$parentRace"..i, self, "ArchaeologyRaceTemplate")
			raceButton:SetID(i)
			self["race"..i] = raceButton
		end

		raceData[i] = {
			raceIndex = i,
			haveFragments = 0,
			needFragments = 0,
			maxFragments = 0,
			new = true,
		}

		raceButton:SetSize(41, 47)
		raceButton.glow:SetSize(41, 47)
		raceButton:SetHitRectInsets(0, -133, 0, 0)
		raceButton:ClearAllPoints()
		if i == 1 then
			raceButton:SetPoint("TOPLEFT", self, 50, -50)
		elseif i == colBreak then
			raceButton:SetPoint("TOPLEFT", self, "TOP", 5, -50)
		else
			raceButton:SetPoint("TOPLEFT", self["race"..(i-1)], "BOTTOMLEFT", 0, 0)
		end

		raceButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		raceButton.OnLeftClick = raceButton:GetScript("OnClick")
		raceButton:SetScript("OnClick", RaceButton_OnClick)
		raceButton:SetScript("OnEnter", RaceButton_OnEnter)
		raceButton:SetScript("OnLeave", GameTooltip_Hide)

		raceButton.raceName:ClearAllPoints()
		raceButton.raceName:SetPoint("BOTTOMLEFT", raceButton, "RIGHT", 3, 1)
		raceButton.raceName:SetJustifyH("LEFT")
		raceButton.raceName:SetTextColor(0, 0, 0)
		raceButton.raceName:SetWidth(0)
		raceButton.raceName:SetWordWrap(false)

		local bar = CreateFrame("StatusBar", nil, raceButton)
		bar:SetPoint("TOPLEFT", raceButton, "RIGHT", 3, -1)
		bar:SetSize(130, 10)
		bar:SetStatusBarTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
		bar:SetStatusBarColor(0.03125, 0.85, 0)
		raceButton.bar = bar

		local barText = bar:CreateFontString(nil, "ARTWORK", "TextStatusBarText")
		barText:SetPoint("CENTER")
		bar.text = barText

		local barBG = bar:CreateTexture(nil, "BACKGROUND")
		barBG:SetAllPoints(true)
		barBG:SetTexture(0, 0, 0, 0.75)
		bar.bg = barBG
	end

	local title, leftSwirl, rightSwirl = self:GetRegions()
	title:Hide()
	leftSwirl:Hide()
	rightSwirl:Hide()
	self.pageText:Hide()
	self.prevPageButton:Hide()
	self.nextPageButton:Hide()
end

------------------------------------------------------------------------

local UPDATE_INTERVAL, updateQueue, UpdateNextArtifact = 0.1, {}

function UpdateNextArtifact()
	local self = tremove(updateQueue, 1)
	if self then
		local data = raceData[self:GetID()]
		local haveFragments, needFragments, maxFragments = data.haveFragments, data.needFragments, data.maxFragments
		local keystoneItemID, numKeystones = data.keystoneItemID, data.numKeystones
		SetSelectedArtifact(data.raceIndex)
		local artifactName, artifactDescription, rarity, icon, spellDescription, numSockets = GetSelectedArtifactInfo()
		local numSocketsFilled = min(numKeystones, numSockets)
		if numKeystones > 0 and numSockets > 0 and not keystoneFragments[keystoneItemID] then
			if SocketItemToArtifact() then
				local _, bonusFragments = GetArtifactProgress()
				if bonusFragments > 0 then
					keystoneFragments[keystoneItemID] = bonusFragments
				else
					print("Error getting bonus fragments for", data.raceName)
				end
			else
				print("Error socketing keystone for", data.raceName)
			end
		end
		local linkName = artifactName .. "|" .. data.raceName -- internal data stores item|race to differentiate same named items
		-- Update item data
		if rarity > 0 and not linkFromItem[linkName] then
			UpdateItemList()
		end
		-- Update data
		data.artifactName = artifactName
		data.artifactLink = linkFromItem[linkName]
		data.artifactRarity = rarity
		data.bonusFragments = numSocketsFilled * (keystoneFragments[keystoneItemID] or 0)
		data.numSockets = numSockets
		data.numSocketsFilled = numSocketsFilled
		-- Alert if newly solvable
		data.wasSolvable, data.isSolvable = data.isSolvable or 0, (haveFragments >= needFragments) and 2 or ((haveFragments + data.bonusFragments) >= needFragments) and 1 or 0
		if data.isSolvable > data.wasSolvable then
			UIErrorsFrame:AddMessage("|T" .. data.raceIcon .. ":20:23:0:10:128:128:73:83|t " .. format(canSolve == 2 and L["%s is now solvable!"] or L["%s is now solvable with keystones."], data.artifactName), 0.2, 1, 0.2)
		end
		-- Update UI
		RaceButton_Update(self)
		updateQueue[self] = nil
	end
	if #updateQueue > 0 then
		C_Timer.After(UPDATE_INTERVAL, UpdateNextArtifact)
	end
end

local function Update(self)
	UpdateItemList()

	if ARCHAEOLOGY_MAX_RACES < GetNumArchaeologyRaces() then
		Initialize(self)
	end

	for i = 1, ARCHAEOLOGY_MAX_RACES do
		local raceButton = self["race"..i]
		local raceName, raceIcon, keystoneItemID, haveFragments, needFragments, maxFragments = GetArchaeologyRaceInfo(i)
		local numKeystones = GetItemCount(keystoneItemID)

		local data = raceData[i]
		if data.new or data.haveFragments ~= haveFragments or data.needFragments ~= needFragments or data.numKeystones ~= numKeystones then
			-- Unknown data, set to dummy values pending update
			if data.new or (data.needFragments == needFragments and data.haveFragments < haveFragments) then
				-- Don't reset to dummy values if we just gained fragments
				data.artifactName = UNKNOWN
				data.artifactLink = nil
				data.artifactRarity = 0
				data.bonusFragments = 0
				data.numSockets = 0
				data.numSocketsFilled = 0
			end
			-- Alert if fragments at/near max
			if (haveFragments + 15) > maxFragments and (data.haveFragments < haveFragments) then
				UIErrorsFrame:AddMessage(format(L["Warning: %d/%d %s fragments is near the maximum!"], haveFragments, maxFragments, raceName))
			end
			-- Known data, set to current values
			data.haveFragments = haveFragments
			data.keystoneItemID = keystoneItemID
			data.needFragments = needFragments
			data.maxFragments = maxFragments
			data.numKeystones = numKeystones
			data.raceIcon = raceIcon
			data.raceName = raceName
			-- Queue update, skip if no projects for this race yet
			if needFragments > 0 and not updateQueue[raceButton] then
				-- Don't queue the same race twice
				tinsert(updateQueue, raceButton)
			end
			-- Remove flag on new things
			data.new = nil
		end

		RaceButton_Update(raceButton)
	end

	if #updateQueue > 0 then
		UpdateNextArtifact()
	end
end

hooksecurefunc("ArchaeologyFrame_UpdateSummary", Update)
hooksecurefunc(ArchaeologyFrame.summaryPage, "UpdateFrame", Update)
if ArchaeologyFrameSummaryPage:IsVisible() then
	Update(ArchaeologyFrameSummaryPage)
end

------------------------------------------------------------------------
-- Show tooltip when mousing over icon or name on the artifact page

local tipper = CreateFrame("Frame", "$parentTooltipper", ArchaeologyFrameArtifactPage)
tipper:SetPoint("LEFT", ArchaeologyFrameArtifactPageIcon)
tipper:SetSize(62 + 330, 62) -- icon is 62x62, name is 330 wide
tipper:SetScript("OnLeave", GameTooltip_Hide)
tipper:SetScript("OnEnter", function(self)
	if self.link then
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT")
		GameTooltip:SetHyperlink(self.link)
	end
end)

hooksecurefunc("ArchaeologyFrame_CurrentArtifactUpdate", function(self)
	local name = self.currentName .. "|" .. GetArchaeologyRaceInfo(self.raceID) -- race name appended to differentiate same named items
	if name then
		tipper.link = linkFromItem[name]
	end
	-- Also replace spell name with item name on the artifact page
	-- ex: the Ancient Frostwolf Fang project creates Frostwolf Ghostpup
	local item = itemFromSpell[name]
	if item then
		self.artifactName:SetText(item)
	end
end)
