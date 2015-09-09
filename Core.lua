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

local data = {
	-- raceIndex,keystoneID,itemID1,itemID2,...
	{false,109585,117382,117354}, -- Arakkoa
	{false,64394,64456,64457}, -- Draenei
	{false,108439,117380,116985}, -- Draenor Clans
	{false,52843,64489,64373,64372,64488}, -- Dwarf
	{false,0,69764,60954,69776,60955,69821}, -- Fossil
	{false,95373,95391,95392}, -- Mantid
	{false,79869,89614,89611}, -- Mogu
	{false,64396,64481,64482}, -- Nerubian
	{false,63127,64646,64643,64645,64651,64361,64358,64383}, -- Night Elf
	{false,109584,117385,117384}, -- Ogre
	{false,64392,64644}, -- Orc
	{false,79868,89685,89684}, -- Pandaren
	{false,64397,60847,64881,64904,64883,64885,64880,64657}, -- Tol'vir
	{false,63128,64377,69777,69824}, -- Troll
	{false,64395,64460,69775}, -- Vrykul
}

local itemFromSpell = {
	[172466] = 117380, -- Ancient Frostwolf Fang -> Frostwolf Ghostpup
}

local itemLink = {}
local itemRace = {}
local sortedItems = {}

local private.items, private.itemFromSpell, private.itemLink, private.itemRace, private.sortedItems
	= items, itemFromSpell, itemLink, itemRace, sortedItems

for i = 1, GetNumArchaeologyRaces() do
	local _, _, keystoneID = GetArchaeologyRaceInfo(i)
	for j = 1, #data do
		if data[i][2] == keystoneID then
			data[i][1] = i
			data[i][2] = false
		end
	end
end
for i = 1, #data do
	if data[i][2] then
		print("Error identifying race:", strjoin(",", unpack(data)))
	end
end

private.UpdateItemList = function()
	for race = #data, 1, -1 do
		local raceData = data[race]
		for i = #raceData, 3, -1 do
			local id = raceData[i]
			local name, link = GetItemInfo(id)
			if name and link then
				itemLink[name] = link
				itemRace[name] = raceData[1]
				tinsert(sortedItems, name)
				tremove(raceData, i)
			end
		end
		if not raceData[3] then
			tremove(data[race])
		end
	end
	table.sort(sortedItems)
	for spell, item in next, itemFromSpell do
		if type(spell) == "number" then
			local name = GetSpellInfo(spell)
			if name then
				itemFromSpell[name] = item
				itemFromSpell[spell] = nil
			end
		end
	end
end

private.UpdateItemList()