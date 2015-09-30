--[[--------------------------------------------------------------------
	Better Archaeology UI
	Improves the Blizzard archaeology UI.
	Copyright (c) 2015 Phanx. All rights reserved.
	http://www.wowinterface.com/downloads/info23693
	http://www.curse.com/addons/wow/better-archaeology-ui
	https://github.com/Phanx/BetterArchaeologyUI
----------------------------------------------------------------------]]

local _, private = ...

local L = setmetatable({}, { __index = function(t, k) t[k] = k return k end })
private.L = L
if GetLocale() == "deDE" then
	-- Core.lua
	L["Small chance to be found in %s."] = "Eine geringe Chance, in %s gefunden zu werden."
	-- CurrentArtifacts.lua
	L["%s is now solvable!"] = "%s kann jetzt restauriert werden."
	L["%s is now solvable with keystones."] = "%s kann jetzt mit Schlüsselsteine restauriert werden."
	L["Click for artifact details."] = "Klick für Artefakt-Einzelheiten."
	L["Created by: %s"] = "Hergestellt von: %s" -- not used
	L["Fragments required:"] = "Fragmente benötigt:" -- not used
	L["Race:"] = "Volk:" -- not used
	L["Right-click to solve artifact."] = "Rechtsklick, um das Artefakt zu restaurieren."
	L["Right-click to solve using %d keystones."] = "Rechtsklick, um das Artefakt mit %d Schlüsselsteine zu restaurieren."
	L["Shift-right-click to solve without keystones."] = "Shift-Rechtsklick, um das Artefakt ohne Schlüsselsteine zu restaurieren."
	L["Warning: %d/%d %s fragments is near the maximum!"] = "Achtung! %d/%d Archäologie-Fragmente von %s hat die Obergrenze fast erreicht!"
	-- MissingArtifacts.lua
	L["Future Artifacts"] = "Zukünftige Artifakte"
	L["This tab shows interesting artifacts you have not yet discovered."] = "Dieser Reiter zeigt interessante Artifakte, die Ihr nicht noch entdeckt habt."
	L["You have already completed all of the interesting artifacts for this race."] = "Ihr habt alle interessanten Artefakte dieses Volkes bereits restauriert."
elseif GetLocale():match("^es") then
	-- Core.lua
	L["Small chance to be found in %s."] = "Una pequeña posibilidad de que se puede encontrar en %s."
	-- CurrentArtifacts.lua
	L["%s is now solvable!"] = "%s es ahora completable."
	L["%s is now solvable with keystones."] = "%s es ahora completable con piedras angulares."
	L["Click for artifact details."] = "Clic para detailles sobre este artefacto"
	L["Created by: %s"] = "Criado por: %s" -- not used
	L["Fragments required:"] = "Piezas necesarios:" -- not used
	L["Race:"] = "Raza:" -- not used
	L["Right-click to solve artifact."] = "Clic derecho para completar este artefacto."
	L["Right-click to solve using %d keystones."] = "Clic derecho para completar este artefacto con %d piedras angulares."
	L["Shift-right-click to solve without keystones."] = "Mayús-clic derecho para completar este artefacto sin piedras angulares."
	L["Warning: %d/%d %s fragments is near the maximum!"] = "¡Advertencia! %d/%d piezas de arqueología de %s se encuentra cerca del máximo!"
	-- MissingArtifacts.lua
	L["Future Artifacts"] = "Artefactos futuros"
	L["This tab shows interesting artifacts you have not yet discovered."] = "Esta pestaña muestra artefactos interesantes que aún no se ha descubierto."
	L["You have already completed all of the interesting artifacts for this race."] = "Ya has completado todos los artefactos interesantes de esta raza."
end

------------------------------------------------------------------------

local data = {
	-- keystoneID,raceIndex,itemID1,itemID2,...
	{109585,false,117382,117354}, -- Arakkoa
	{64394,false,64456,64457}, -- Draenei
	{108439,false,117380,116985}, -- Draenor Clans
	{52843,false,64489,64373,64372,64488}, -- Dwarf
	{0,false,69764,60954,69776,60955,69821}, -- Fossil
	{95373,false,95391,95392}, -- Mantid
	{79869,false,89614,89611}, -- Mogu
	{64396,false,64481,64482}, -- Nerubian
	{63127,false,64646,64643,64645,64651,64361,64358,64383}, -- Night Elf
	{109584,false,117385,117384}, -- Ogre
	{64392,false,64644}, -- Orc
	{79868,false,89685,89684}, -- Pandaren
	{64397,false,60847,64881,64904,64883,64885,64880,64657}, -- Tol'vir
	{63128,false,64377,69777,69824}, -- Troll
	{64395,false,64460,69775}, -- Vrykul
}

------------------------------------------------------------------------

local itemFromSpell = {
	-- used where the project name doesn't match the item name
	-- spellID = itemID
	[172466] = 117380, -- Ancient Frostwolf Fang -> Frostwolf Ghostpup
}
private.itemFromSpell = itemFromSpell

local itemContains = {
	[64657] = { 67538, text = L["Small chance to be found in %s."] } -- Canopic Jar -> Recipe: Vial of the Sands
}
private.itemContains = itemContains

local sortedItems, linkFromItem, raceFromItem = {}, {}, {}
private.sortedItems, private.linkFromItem, private.raceFromItem = sortedItems, linkFromItem, raceFromItem

local raceNames = {} -- nothing special, just to save from having to look them up repeatedly
private.raceNames = raceNames

------------------------------------------------------------------------

private.UpdateItemList = function()
	for race = #data, 1, -1 do
		local raceData = data[race]
		-- raceData = { keystoneID, raceIndex, itemID1, ... }
		local i, item = 3, raceData[3]
		while item do
			local name, link = GetItemInfo(item)
			if name and link then
				name = name .. "|" .. raceNames[raceData[2]] -- Blizzard in their infinite wisdom decided to give items with the same name to multiple races in the spirit of AU TIME TRAVEL LOLZ
				linkFromItem[name] = link
				raceFromItem[name] = raceData[2]
				tinsert(sortedItems, name)
				tremove(raceData, i)
			else
				i = i + 1
			end
			item = raceData[i]
		end
		if not item then
			tremove(data, race)
		end
	end
	table.sort(sortedItems)

	for spell, item in next, itemFromSpell do
		if type(spell) == "number" then
			local spellName = GetSpellInfo(spell)
			local itemName, itemLink = GetItemInfo(item)
			if spellName and itemName and itemLink then
				-- Fuckery to find the race-appended item name since Blizz
				-- thought it was cool to have multiple items with the same
				-- name for different races in their timetravel AU.
				local itemFullName
				for name, link in pairs(linkFromItem) do
					if link == itemLink then
						itemFullName = name
						break
					end
				end
				if itemFullName then
					spellName = spellName .. strmatch(itemFullName, "|.+")
					-- Map link/race from spell name
					-- It's already mapped from the itemname
					linkFromItem[spellName] = itemLink
					raceFromItem[spellName] = raceFromItem[itemFullName]
					-- Update this table
					itemFromSpell[spellName] = itemFullName
					itemFromSpell[spell] = nil
				end
			end
		end
	end

	for item, data in next, itemContains do
		if type(item) == "number" then
			local _, itemLink = GetItemInfo(item)
			local _, contentsLink = GetItemInfo(data[1])
			if itemLink and contentsLink then
				data.link = contentsLink
				itemContains[itemLink] = data
				itemContains[item] = nil
			end
		end
	end
end

------------------------------------------------------------------------

-- Some assumptions are made here:
-- 1. Race indices will never change during gameplay.
-- 2. Fossil is the only race without a keystone.
for i = 1, GetNumArchaeologyRaces() do
	local name, _, keystoneID = GetArchaeologyRaceInfo(i)
	private.raceNames[i] = name
	for j = 1, #data do
		if data[j][1] == keystoneID then
			data[j][2] = i
		end
	end
end
for i = 1, #data do
	if not data[i][2] then
		print("Error identifying race by keystone:", data[i][1], (GetItemInfo(data[i][1])))
	end
end

private.UpdateItemList()
