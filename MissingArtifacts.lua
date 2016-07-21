--[[--------------------------------------------------------------------
	Better Archaeology UI
	Improves the Blizzard archaeology UI.
	Copyright (c) 2015, 2016 Phanx. All rights reserved.
	https://github.com/Phanx/BetterArchaeologyUI
	http://www.curse.com/addons/wow/better-archaeology-ui
	http://www.wowinterface.com/downloads/info23693
----------------------------------------------------------------------]]

local _, private = ...
local L = private.L
local itemContains   = private.itemContains
local linkFromItem   = private.linkFromItem
local raceFromItem   = private.raceFromItem
local raceNames      = private.raceNames
local sortedItems    = private.sortedItems
local UpdateItemList = private.UpdateItemList

local ARCHAEOLOGY_FUTURE_TAB = 3
local ARTIFACTS_PER_PAGE = 12

local futurePage, futureTab

------------------------------------------------------------------------

local completedItems, missingItems = {}, {}

local function Update(self)
	UpdateItemList()

	for i = 1, GetNumArchaeologyRaces() do
		for j = 1, GetNumArtifactsByRace(i) do
			completedItems[GetArtifactInfoByRace(i, j) .. "|" .. raceNames[i]] = true -- append race name to differentiate same named items
		end
	end
	wipe(missingItems)
	for i = 1, #sortedItems do
		local name = sortedItems[i]
		if not completedItems[name] and (self.raceFilter == 0 or self.raceFilter == raceFromItem[name]) then
			tinsert(missingItems, name)
		end
	end
	-- No need to sort `missingItems` since `sortedItems` is already
	-- sorted and items are inserted into `missingItems` in the order
	-- they are seen in `sortedItems`.

	for i = 1, ARTIFACTS_PER_PAGE do
		local button = self.artifacts[i]
		local name = missingItems[i + ARTIFACTS_PER_PAGE * (self.currentPage - 1)]
		local link = name and linkFromItem[name]
		if link then
			local _, _, quality, _, _, _, _, _, _, icon = GetItemInfo(link)
			button.icon:SetTexture(icon)
			button.artifactName:SetText(strmatch(name, "^([^|]+)")) -- strip race name, appended to differentiate same named items
			button.artifactSubText:SetText(raceNames[raceFromItem[name]])
			button.link = link
			button:Show()
		else
			button:Hide()
		end
	end
	self.infoText:SetShown(not self.artifacts[1]:IsShown())

	self.pageText:SetFormattedText(PAGE_NUMBER, self.currentPage)
	if self.currentPage == 1 then
		self.prevPageButton:SetButtonState("NORMAL")
		self.prevPageButton:Disable()
	else
		self.prevPageButton:Enable()
	end
	if #missingItems <= (self.currentPage * ARTIFACTS_PER_PAGE) then
		self.nextPageButton:SetButtonState("NORMAL")
		self.nextPageButton:Disable()
	else
		self.nextPageButton:Enable()
	end
end

------------------------------------------------------------------------

local function RaceFilterSet(self, arg1)
	if arg1 == 0 then
		UIDropDownMenu_SetText(ArchaeologyFrame.raceFilterDropDown, ALL)
	else
		UIDropDownMenu_SetText(ArchaeologyFrame.raceFilterDropDown, raceNames[arg1])
	end
	futurePage.raceFilter = arg1
	futurePage.currentPage = 1
	Update(futurePage)
end

local InitRaceFilter = ArchaeologyFrame_InitRaceFilter
function ArchaeologyFrame_InitRaceFilter()
	if ArchaeologyFrame.currentFrame == futurePage then
		local current = futurePage.raceFilter
		local info = UIDropDownMenu_CreateInfo()
		info.func = RaceFilterSet

		info.text = ALL
		info.arg1 = 0
		info.checked = current == 0
		UIDropDownMenu_AddButton(info)

		for i = 1, GetNumArchaeologyRaces() do
			info.text = raceNames[i]
			info.arg1 = i
			info.checked = current == i
			UIDropDownMenu_AddButton(info)
		end
	else
		InitRaceFilter()
	end
end

ArchaeologyFrame.raceFilterDropDown.initialize = ArchaeologyFrame_InitRaceFilter

------------------------------------------------------------------------

do
	futureTab = CreateFrame("Button", "$parentFutureButton", ArchaeologyFrame)
	futureTab:SetPoint("TOPLEFT", ArchaeologyFrame, "TOPRIGHT", -22, -190) -- tab1 -50, tab2 -120
	futureTab:SetSize(63, 57)
	futureTab:SetID(ARCHAEOLOGY_FUTURE_TAB)
	ArchaeologyFrame.tab3 = futureTab

	futureTab:SetScript("OnClick", function(self)
		ArchaeologyFrame_OnTabClick(self)
		PlaySound("igSpellBookOpen")
	end)
	futureTab:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetText(L["Future Artifacts"])
		GameTooltip:AddLine(L["This tab shows interesting artifacts you have not yet discovered."], 1, 1, 1, true)
		GameTooltip:Show()
	end)
	futureTab:SetScript("OnLeave", GameTooltip_Hide)

	futureTab:SetNormalTexture([[Interface\Archeology\ArchaeologyParts]])
	futureTab.normalTexture = futureTab:GetNormalTexture()
	futureTab.normalTexture:ClearAllPoints()
	futureTab.normalTexture:SetPoint("TOPLEFT")
	futureTab.normalTexture:SetSize(48, 57)
	futureTab.normalTexture:SetDesaturated(true) -- visually distinguish it from the Completed futureTab
	futureTab.normalTexture:SetTexCoord(0.3125, 0.40625, 0.5625, 0.78515625)

	futureTab:SetHighlightTexture([[Interface\Archeology\ArchaeologyParts]])
	futureTab.highlightTexture = futureTab:GetHighlightTexture()
	futureTab.highlightTexture:ClearAllPoints()
	futureTab.highlightTexture:SetPoint("TOPLEFT")
	futureTab.highlightTexture:SetSize(48, 57)
	futureTab.highlightTexture:SetAlpha(0.3)
	futureTab.highlightTexture:SetBlendMode("ADD")
	futureTab.highlightTexture:SetTexCoord(0.3125, 0.40625, 0.5625, 0.78515625)

	-- Assign shortcuts to avoid looking them up repeatedly:
	ArchaeologyFrameSummarytButton.normalTexture = ArchaeologyFrameSummarytButton:GetNormalTexture()
	ArchaeologyFrameSummarytButton.highlightTexture = ArchaeologyFrameSummarytButton:GetHighlightTexture()
	-- ^ Summaryt is an intentional typo to match the Blizzard UI code
	ArchaeologyFrameCompletedButton.normalTexture = ArchaeologyFrameCompletedButton:GetNormalTexture()
	ArchaeologyFrameCompletedButton.highlightTexture = ArchaeologyFrameCompletedButton:GetHighlightTexture()

	local function SelectTab(tab)
		tab.normalTexture:SetSize(63, 57)
		tab.highlightTexture:SetSize(63, 57)
		if tab == ArchaeologyFrameSummarytButton then -- intentional typo to match Blizz
			tab.normalTexture:SetTexCoord(0.85546875, 0.97851563, 0.00390625, 0.2265625)
			tab.highlightTexture:SetTexCoord(0.85546875, 0.97851563, 0.00390625, 0.2265625)
			tab.factionIcon:SetPoint("CENTER", -6, 0)
		else
			-- ArchaeologyFrameCompletedButton and our tab use the same texture
			tab.normalTexture:SetTexCoord(0.72851563, 0.85156250, 0.00390625, 0.22656250)
			tab.highlightTexture:SetTexCoord(0.72851563, 0.85156250, 0.00390625, 0.22656250)
		end
	end
	local function DeselectTab(tab)
		tab.normalTexture:SetSize(48, 57)
		tab.highlightTexture:SetSize(48, 57)
		if tab == ArchaeologyFrameSummarytButton then -- intentional typo to match Blizz
			tab.normalTexture:SetTexCoord(0.21484375, 0.30859375, 0.5625, 0.78515625)
			tab.highlightTexture:SetTexCoord(0.21484375, 0.30859375, 0.5625, 0.78515625)
			tab.factionIcon:SetPoint("CENTER", -13, 0)
		else
			-- ArchaeologyFrameCompletedButton and our tab use the same texture
			tab.normalTexture:SetTexCoord(0.3125, 0.40625, 0.5625, 0.78515625)
			tab.highlightTexture:SetTexCoord(0.3125, 0.40625, 0.5625, 0.78515625)
		end
	end
	hooksecurefunc("ArchaeologyFrame_OnTabClick", function(self)
		local selected = ArchaeologyFrame.selectedTab
		if selected == ARCHAEOLOGY_FUTURE_TAB then
			SelectTab(futureTab)
			DeselectTab(ArchaeologyFrameSummarytButton)
			DeselectTab(ArchaeologyFrameCompletedButton)

			ArchaeologyFrame.raceFilterDropDown:Show()
			ArchaeologyFrame.currentFrame = futurePage

			futurePage.raceFilter = 0
			futurePage.currentPage = 1
			futurePage:Show()
		else
			futurePage:Hide()
			DeselectTab(futureTab)
		end
	end)
end

------------------------------------------------------------------------

do
	futurePage = CreateFrame("Frame", "$parentFuturePage", ArchaeologyFrame)
	futurePage:Hide()
	ArchaeologyFrame.futurePage = futurePage

	futurePage:SetPoint("TOPLEFT", ArchaeologyFrameInset, 45, -15)
	futurePage:SetPoint("BOTTOMRIGHT", ArchaeologyFrameInset)

	local title = futurePage:CreateFontString(nil, "OVERLAY", "SystemFont_Med1")
	title:SetPoint("TOP", 0, -55)
	title:SetTextColor(0.25, 0.13, 0)
	title:SetText(L["Future Artifacts"])

	local titleLeft = futurePage:CreateTexture(nil, "OVERLAY")
	titleLeft:SetPoint("RIGHT", title, "LEFT", -8, 0)
	titleLeft:SetSize(42, 27)
	titleLeft:SetTexture([[Interface\Archeology\ArchaeologyParts]])
	titleLeft:SetTexCoord(0.11132813, 0.19335938, 0.78906250, 0.89453125)

	local titleRight = futurePage:CreateTexture(nil, "OVERLAY")
	titleRight:SetPoint("LEFT", title, "RIGHT", 8, 0)
	titleRight:SetSize(42, 27)
	titleRight:SetTexture([[Interface\Archeology\ArchaeologyParts]])
	titleRight:SetTexCoord(0.00195313, 0.08398438, 0.84375000, 0.94921875)

	local infoText = futurePage:CreateFontString(nil, "OVERLAY", "SystemFont_Med1")
	infoText:SetPoint("CENTER")
	infoText:SetWidth(380)
	infoText:SetTextColor(0.25, 0.13, 0)
	infoText:SetText(L["You have already completed all of the interesting artifacts for this race."])
	futurePage.infoText = infoText

	futurePage.artifacts = {}
	local function enterArtifact(self)
		local artifactLink = self.link
		if artifactLink then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
			local contents = itemContains[artifactLink]
			if contents then -- Canopic Jar
				GameTooltip:SetHyperlink(contents.link)
				GameTooltip:AddLine("|n|TInterface\\Minimap\\Tracking\\QuestBlob:0|t "..format(contents.text, self.artifactName:GetText()), nil, nil, nil, true)
				GameTooltip:Show()
			else
				GameTooltip:SetHyperlink(artifactLink)
			end
			-- GameTooltip:AddDoubleLine(L["Race:"], self.artifactSubText:GetText(), nil, nil, nil, 1, 1, 1)
			-- ^ don't really need this since it's already shown on the button
			-- but it could be nice to, at some point in the future, add data
			-- about how many fragments are required for each item, maybe.
		end
	end
	for i = 1, ARTIFACTS_PER_PAGE do
		local button = CreateFrame("Button", "$parentArtifact"..i, futurePage, "ArchaeologyArtifactTemplate")
		if i == 1 then
			button:SetPoint("TOPLEFT", 35, -90)
		elseif i == 2 then
			button:SetPoint("LEFT", futurePage.artifacts[i-1], "RIGHT", 20, 0)
		else
			button:SetPoint("TOP", futurePage.artifacts[i-2], "BOTTOM", 0, -15)
		end
		button:SetScript("OnEnter", enterArtifact)
		futurePage.artifacts[i] = button
	end

	local pageText = futurePage:CreateFontString(nil, "OVERLAY", "GameFontBlack")
	pageText:SetPoint("BOTTOMRIGHT", -110, 22)
	pageText:SetWidth(102)
	pageText:SetJustifyH("RIGHT")
	pageText:SetTextColor(0.13, 0.06, 0)
	pageText:SetFormattedText(PAGE_NUMBER, 1)
	futurePage.pageText = pageText

	local prevPageButton = CreateFrame("Button", "$parentPrevPageButton", futurePage, "UIPanelSquareButton")
	prevPageButton:SetPoint("LEFT", futurePage.pageText, "RIGHT", 8, 0)
	SquareButton_SetIcon(prevPageButton, "LEFT")
	prevPageButton:SetScript("OnClick", function()
		PlaySound("igSpellBookOpen")
		futurePage.currentPage = futurePage.currentPage - 1
		Update(futurePage)
	end)
	futurePage.prevPageButton = prevPageButton

	local nextPageButton = CreateFrame("Button", "$parentNextPageButton", futurePage, "UIPanelSquareButton")
	nextPageButton:SetPoint("LEFT", prevPageButton, "RIGHT", 8, 0)
	SquareButton_SetIcon(nextPageButton, "RIGHT")
	nextPageButton:SetScript("OnClick", function()
		PlaySound("igSpellBookOpen")
		futurePage.currentPage = futurePage.currentPage + 1
		Update(futurePage)
	end)
	futurePage.nextPageButton = nextPageButton

	futurePage:SetScript("OnShow", Update)

	futurePage:EnableMouseWheel(true)
	futurePage:SetScript("OnMouseWheel", function(self, value)
		(value > 0 and futurePage.prevPageButton or futurePage.nextPageButton):Click()
	end)
end
