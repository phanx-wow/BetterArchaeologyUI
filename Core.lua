--[[--------------------------------------------------------------------
	Better Archaeology UI
	Improves the Blizzard archaeology UI.
	Copyright (c) 2015, 2016 Phanx. All rights reserved.
	https://github.com/Phanx/BetterArchaeologyUI
	https://mods.curse.com/addons/wow/better-archaeology-ui
	http://www.wowinterface.com/downloads/info23693
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
	{
		109585, false, -- Arakkoa
		117354, -- Ancient Nest Guardian
		117382, -- Beakbreaker of Terokk
	},
	{
		130905, false, -- Demonic
		131743, -- Blood of Young Mannoroth
		131724, -- Crystalline Eye of Undravius
		131735, -- Imp Generator
		131732, -- Purple Hills of Mac'Aree
		136922, -- Wyrmy Tunkins
	}, 
	{
		64394, false, -- Draenei
		64456, -- Arrival of the Naaru
		64457, -- The Last Relic of Argus
	},
	{
		108439, false, -- Draenor Clans
		117380, -- Frostwolf Ghostpup
		116985, -- Headdress of the First Shaman
	},
	{
		52843, false, -- Dwarf
		64373, -- Chalice of the Mountain Kings
		64372, -- Clockwork Gnome
		64489, -- Staff of Sorcerer-Thane Thaurissan
		64488, -- The Innkeeper's Daughter
	},
	{
		0, false, -- Fossil
		69776, -- Ancient Amber
		69764, -- Extinct Turtle Shell
		60955, -- Fossilized Hatchling
		60954, -- Fossilized Raptor
		69821, -- Pterrordax Hatchling
	},
	{
		130903, false, -- Highborne
		131740, -- Crown Jewels of Suramar
		131745, -- Key of Kalyndras
		131744, -- Key to Nar'thalas Academy
		131717, -- Starlight Beacon
	},
	{
		130904, false, -- Highmountain Tauren
		131736, -- Prizerock Neckband
		131733, -- Spear of Rethu
		131734, -- Spirit of Eche'ro
	},
	{
		95373, false, -- Mantid
		95391, -- Mantid Sky Reaver
		95392, -- Sonic Pulse Generator
	},
	{
		79869, false, -- Mogu
		89614, -- Anatomical Dummy
		89611, -- Quilen Statuette
	},
	{
		64396, false, -- Nerubian
		64481, -- Blessing of the Old God
		64482, -- Puzzle Box of Yogg-Saron
	},
	{
		63127, false, -- Night Elf
		64646, -- Bones of Transformation
		64361, -- Druid and Priest Statue Set
		64358, -- Highborne Soul Mirror
		64383, -- Kaldorei Wind Chimes
		64643, -- Queen Azshara's Dressing Gown
		64645, -- Tyrande's Favorite Doll
		64651, -- Wisp Amulet
	},
	{
		109584, false, -- Ogre
		117385, -- Sorcerer-King Toe Ring
		117384, -- Warmaul of the Warmaul Chieftain
	},
	{
		64392, false, -- Orc
		64644 -- Headdress of the First Shaman
	},
	{
		79868, false, -- Pandaren
		89685, -- Spear of Xuen
		89684, -- Umbrella of Chi-Ji
	},
	{
		64397, false, -- Tol'vir
		64657, -- Canopic Jar
		60847, -- Crawling Claw
		64881, -- Pendant of the Scarab Storm
		64904, -- Ring of the Boy Emperor
		64883, -- Scepter of Azj'Aqir
		64885, -- Scimitar of the Sirocco
		64880, -- Staff of Ammunae
	},
	{
		63128, false, -- Troll
		69777, -- Haunted War Drum
		69824, -- Voodoo Figurine
		64377, -- Zin'rokh, Destroyer of Worlds
	},
	{
		64395, false, -- Vrykul
		64460, -- Nifflevar Bearded Axe
		69775, -- Vrykul Drinking Horn
	},
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
C_Timer.After(5, private.UpdateItemList) -- lazy solution to items not in cache
