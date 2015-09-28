local _, private = ...
BAUI = private

local L = setmetatable({}, { __index = function(t, k) t[k] = k return k end })
private.L = L
if GetLocale() == "deDE" then
	-- CurrentArtifacts.lua
	L["%s is now solvable with keystones."] = "%s kann jetzt mit Schlüsselsteine restauriert werden."
	L["%s is now solvable!"] = "%s kann jetzt restauriert werden."
	L["Click for artifact details."] = "Klick für Artefakt-Einzelheiten."
	L["Right-click to solve artifact."] = "Rechtsklick, um das Artefakt zu restaurieren."
	L["Right-click to solve using %d keystones."] = "Rechtsklick, um das Artefakt mit %d Schlüsselsteine zu restaurieren."
	L["Shift-right-click to solve without keystones."] = "Shift-Rechtsklick, um das Artefakt ohne Schlüsselsteine zu restaurieren."
	L["Warning: %d/%d %s fragments is near the maximum!"] = "Achtung! %d%d Archäologie-Fragmente (%s) hat die Obergrenze fast erreicht!"
	-- MissingArtifacts.lua
	L["Missing Artifacts"] = "Fehlende Artifakte"
	L["This tab shows interesting artifacts you have not yet discovered."] = "Dieser Reiter zeigt interessante Artifakte, die Ihr nicht noch restauriert habt."
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
	[172466] = 117380, -- Ancient Frostwolf Fang -> Frostwolf Ghostpup
}
private.itemFromSpell = itemFromSpell

local items, itemLink, itemRace = {}, {}, {}
private.items, private.itemLink, private.itemRace = items, itemLink, itemRace

------------------------------------------------------------------------

private.UpdateItemList = function()
	for race = #data, 1, -1 do
		local raceData = data[race]
		-- raceData = { keystoneID, raceIndex, itemID1, ... }
		local i, item = 3, raceData[3]
		while item do
			local name, link = GetItemInfo(item)
			if name and link then
				itemLink[name] = link
				itemRace[name] = raceData[2]
				tinsert(items, name)
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
	table.sort(items)
	for spell, item in next, itemFromSpell do
		if type(spell) == "number" then
			local name = GetSpellInfo(spell)
			if name then
				itemFromSpell[name] = item
			end
		end
	end
end

------------------------------------------------------------------------

-- Some assumptions are made here:
-- 1. Race indices will never change during gameplay.
-- 2. Fossil is the only race without a keystone.
for i = 1, GetNumArchaeologyRaces() do
	local _, _, keystoneID = GetArchaeologyRaceInfo(i)
	for j = 1, #data do
		if data[i][1] == keystoneID then
			data[i][2] = i
		end
	end
end
for i = 1, #data do
	if not data[i][2] then
		print("Error identifying race by keystone:", data[i][1], (GetItemInfo(data[i][1])))
	end
end

private.UpdateItemList()
