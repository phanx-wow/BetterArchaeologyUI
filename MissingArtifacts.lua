local _, private = ...
local L = private.L
local itemLink = private.itemLink
local itemRace = private.itemRace
local sortedItems = private.sortedItems
local UpdateItemList = private.UpdateItemList

local ARTIFACTS_PER_PAGE = 12

------------------------------------------------------------------------

local complete, missing = {}, {}

local function Update(self)
	UpdateItemList()

	for i = 1, GetNumArchaeologyRaces() do
		for j = 1, GetNumArtifactsByRace(i) do
			complete[(GetArtifactInfoByRace(i, j))] = true
		end
	end
	wipe(missing)
	for i = 1, #sortedItems do
		local name = sortedItems[i]
		if not complete[name] then
			tinsert(missing, name)
		end
	end

	for i = 1, ARTIFACTS_PER_PAGE do
		local button = self.artifacts[i]
		local name = missing[i + (ARTIFACTS_PER_PAGE * (self.currentPage - 1))]
		local link = name and items[name]
		if link then
			local _, _, quality, _, _, _, _, _, _, icon = GetItemInfo(link)
			button.icon:SetTexture(icon)
			button.artifactName:SetText(name)
			button.artifactSubText:SetText(itemRace[name])
			button.link = link
			button:Show()
		else
			button:Hide()
		end
	end

	self.pageText:SetFormattedText(PAGE_NUMBER, self.currentPage)
	if self.currentPage == 1 then
		self.prevPageButton:SetButtonState("NORMAL")
		self.prevPageButton:Disable()
	else
		self.prevPageButton:Enable()
	end
	if #missing <= (self.currentPage * ARTIFACTS_PER_PAGE) then
		self.nextPageButton:SetButtonState("NORMAL")
		self.nextPageButton:Disable()
	else
		self.nextPageButton:Enable()
	end

	-- TODO: enable filtering by race
	ArchaeologyFrame.raceFilterDropDown:Hide()
end

------------------------------------------------------------------------

do
	local tab = CreateFrame("Button", nil, "ArchaeologyFrame")
	tab:SetPoint("TOPLEFT", ArchaeologyFrame, "TOPRIGHT", -22, -190) -- tab1 -50, tab2 -120
	tab:SetSize(63, 57)
	tab:SetID(3)
	ArchaeologyFrame.tab3 = tab

	tab:SetScript("OnClick", function(self)
		ArchaeologyFrame_OnTabClick(self)
		PlaySound("igSpellBookOpen")
	end)
	tab:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetText(L["Missing Artifacts"])
		GameTooltip:AddLine(L["This tab shows interesting artifacts you have not yet discovered."])
	end)
	tab:SetScript("OnLeave", GameTooltip_Hide)

	tab:SetNormalTexture([[Interface\Archeology\ArchaeologyParts]])
	tab:GetNormalTexture():SetSize(48, 57)
	tab:GetNormalTexture():SetPoint("TOPLEFT")
	tab:GetNormalTexture():SetTexCoord(0.3125, 0.40625, 0.5625, 0.78515625)

	tab:SetHighlightTexture([[Interface\Archeology\ArchaeologyParts]])
	tab:GetHighlightTexture():SetBlendMode("ADD")
	tab:GetHighlightTexture():SetSize(48, 57)
	tab:GetHighlightTexture():SetPoint("TOPLEFT")
	tab:GetHighlightTexture():SetTexCoord(0.3125, 0.40625, 0.5625, 0.78515625)
	tab:GetHighlightTexture():SetAlpha(0.3)

	hooksecurefunc("ArchaeologyFrame_OnTabClick", function(self)
		page:SetShown(self:GetID() == 3)
	end)
end

------------------------------------------------------------------------

do
	local page = CreateFrame("Frame", nil, "ArchaeologyFrame")
	page:Hide()
	ArchaeologyFrame.missingPage = page

	page:SetPoint("TOPLEFT", ArchaeologyFrameInset, 45, -15)
	page:SetPoint("BOTTOMRIGHT", ArchaeologyFrameInset)

	local title = page:CreateFontString(nil, "OVERLAY", "SystemFont_Med1")
	title:SetText(L["Missing Artifacts"])
	title:SetPoint("TOP", 0, -55)
	title:SetTextColor(0.25, 0.13, 0)

	local titleLeft = page:CreateTexture(nil, "OVERLAY")
	titleLeft:SetPoint("RIGHT", pageTitle, "LEFT", -8, 0)
	titleLeft:SetSize(42, 27)
	titleLeft:SetTexture([[Interface\Archeology\ArchaeologyParts]])
	titleLeft:SetTexCoord(0.11132813, 0.19335938, 0.78906250, 0.89453125)

	local titleRight = page:CreateTexture(nil, "OVERLAY")
	titleRight:SetPoint("LEFT", pageTitle, "RIGHT", 8, 0)
	titleRight:SetSize(42, 27)
	titleRight:SetTexture([[Interface\Archeology\ArchaeologyParts]])
	titleRight:SetTexCoord(0.00195313, 0.08398438, 0.84375000, 0.94921875)

	local pageText = page:CreateFontString(nil, "OVERLAY", "GameFontBlack")
	pageText:SetJustifyH("RIGHT")
	pageText:SetSize(102, 0)
	pageText:SetPoint("BOTTOMRIGHT", -110, 22)
	pageText:SetTextColor(0.13, 0.06, 0)
	page.pageText = pageText

	page.artifacts = {}
	local function enterArtifact(self)
		if self.link then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:SetHyperlink(self.link)
		end
	end
	for i = 1, ARTIFACTS_PER_PAGE do
		local button = CreateFrame("Button", "$parentArtifact"..i, page, "ArchaeologyArtifactTemplate")
		button:SetScript("OnEnter", enterArtifact)
		page.artifacts[i] = button
		if i == 1 then
			button:SetPoint("TOPLEFT", 35, -90)
		elseif i == 2 then
			button:SetPoint("LEFT", page.artifact[i-1], "RIGHT", 20, 0)
		else
			button:SetPoint("TOP", page.artifact[i-2], "BOTTOM", 0, -20)
		end
	end

	local prevPageButton = CreateFrame("Button", "$parentPrevPageButton", page, "UIPanelSquareButton")
	prevPageButton:SetPoint("LEFT", page.pageText, "RIGHT", 8, 0)
	SquareButton_SetIcon(prevPageButton, "LEFT")
	prevPageButton:SetScript("OnClick", function()
		PlaySound("igSpellBookOpen")
		page.currentPage = page.currentPage - 1
		Update(page)
	end)
	page.prevPageButton = prevPageButton

	local nextPageButton:SetPoint("LEFT", prevPageButton, "RIGHT", 8, 0)
	SquareButton_SetIcon(nextPageButton, "RIGHT")
	nextPageButton:SetScript("OnClick", function()
		PlaySound("igSpellBookOpen")
		page.currentPage = page.currentPage + 1
		Update(page)
	end)
	page.nextPageButton = nextPageButton

	hooksecurefunc("ArchaeologyFrame_OnMouseWheel", function(self, value)
		if self.currentFrame == page then
			(value > 0 and page.prevPageButton or page.nextPageButton):Click()
		end
	end)
end