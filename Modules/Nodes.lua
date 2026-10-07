-- Records every herb and mining node you gather, for all characters, so
-- NodesMap.lua can pin them on the world map and minimap. The node's name
-- comes from UNIT_SPELLCAST_SENT's target (the object you clicked); it's
-- stored once the gather cast succeeds, at your map position.
--
-- Saved as db.global.nodes[mapFile][nodeName] = { {x, y, count, last}, ... }
-- where mapFile is GetMapInfo()'s map file name (same in every locale) and
-- x, y are 0-1 map coordinates. Points within MERGE_YARDS of each other are
-- one node.
local NS = JohnnysProfessions
NS.Nodes = {}
local Nodes = NS.Nodes

local MERGE_YARDS = 15
local MERGE_MAP = 0.005  -- fallback when the zone's size isn't known
local RESPAWN = 300      -- seconds a gathered node is shown greyed out

local GATHER_SPELLS = {} -- localized cast name -> profession
local pending            -- { name=, spell=, time= } between SENT and SUCCEEDED
local listeners = {}

function Nodes:OnChange(fn)
	table.insert(listeners, fn)
end

local function Store()
	local g = NS.db.global
	g.nodes = g.nodes or {}
	return g.nodes
end

-- All recorded nodes for a map file: { [nodeName] = { {x, y, count, last}, ... } }
function Nodes:ForMap(mapFile)
	return mapFile and Store()[mapFile]
end

function Nodes:Info(name)
	return NS.NODES[name]
end

-- Your current skill in the profession that gathers `name`, or nil.
function Nodes:PlayerSkill(name)
	local info = NS.NODES[name]
	local s = info and NS.Characters:Me().skills[info.prof]
	return s and s.rank
end

-- Skill-up colour for a node at your skill: r, g, b, label.
-- red = can't gather yet, orange/yellow/green = skill-ups getting rarer,
-- grey = no more skill-ups.
local COLORS = {
	red = { 1, 0.15, 0.15 },
	orange = { 1, 0.5, 0.15 },
	yellow = { 1, 1, 0 },
	green = { 0.25, 0.9, 0.25 },
	grey = { 0.55, 0.55, 0.55 },
}
function Nodes:SkillColor(name)
	local info = NS.NODES[name]
	local skill = self:PlayerSkill(name)
	local label
	if not info or not skill then
		label = "grey"
	elseif skill < info.skill then
		label = "red"
	elseif skill < info.skill + 25 then
		label = "orange"
	elseif skill < info.skill + 50 then
		label = "yellow"
	elseif skill < info.skill + 100 then
		label = "green"
	else
		label = "grey"
	end
	local c = COLORS[label]
	return c[1], c[2], c[3], label
end

-- Whether gathering `name` can still raise your skill.
function Nodes:GivesSkillUp(name)
	local _, _, _, label = self:SkillColor(name)
	return label == "orange" or label == "yellow" or label == "green"
end

function Nodes:IsRespawning(point)
	return point[4] and (time() - point[4]) < RESPAWN
end

----------------------------------------------------------------------------
-- Player position on their own zone map
----------------------------------------------------------------------------
-- Returns mapFile, x, y for the player, or nil when it can't be known (inside
-- an instance map with levels, or the world map is open on another zone).
-- The map is only switched back to your zone (SetMapToCurrentZone, which
-- fires WORLD_MAP_UPDATE for every addon) when it isn't already showing it,
-- and never while the world map is open, so it can't move a map you're
-- looking at.
local function ReadPosition()
	if GetCurrentMapZone() == 0 or (GetCurrentMapDungeonLevel and GetCurrentMapDungeonLevel() > 0) then
		return nil
	end
	local x, y = GetPlayerMapPosition("player")
	if not x or (x == 0 and y == 0) then
		return nil
	end
	return GetMapInfo(), x, y
end

function Nodes:PlayerPosition()
	local mapFile, x, y = ReadPosition()
	if not mapFile and not (WorldMapFrame and WorldMapFrame:IsShown()) then
		SetMapToCurrentZone()
		mapFile, x, y = ReadPosition()
	end
	return mapFile, x, y
end

-- Yards between two points on one map, or nil if the map size is unknown.
function Nodes:Yards(mapFile, x1, y1, x2, y2)
	local size = NS.ZONE_SIZES[mapFile]
	if not size then
		return nil
	end
	local dx, dy = (x2 - x1) * size[1], (y2 - y1) * size[2]
	return math.sqrt(dx * dx + dy * dy)
end

local function Record(name)
	local mapFile, x, y = Nodes:PlayerPosition()
	if not mapFile then
		return
	end
	local store = Store()
	store[mapFile] = store[mapFile] or {}
	local list = store[mapFile][name] or {}
	store[mapFile][name] = list

	local now = time()
	for _, p in ipairs(list) do
		local yards = Nodes:Yards(mapFile, p[1], p[2], x, y)
		local close
		if yards then
			close = yards <= MERGE_YARDS
		else
			close = math.abs(p[1] - x) <= MERGE_MAP and math.abs(p[2] - y) <= MERGE_MAP
		end
		if close then
			-- Average toward the new reading so repeat visits refine the spot.
			local n = p[3] or 1
			p[1] = (p[1] * n + x) / (n + 1)
			p[2] = (p[2] * n + y) / (n + 1)
			p[3] = n + 1
			p[4] = now
			for _, fn in ipairs(listeners) do
				fn(mapFile)
			end
			return
		end
	end
	table.insert(list, { x, y, 1, now })
	for _, fn in ipairs(listeners) do
		fn(mapFile)
	end
end

----------------------------------------------------------------------------
-- Events
----------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("UNIT_SPELLCAST_SENT")
events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
events:RegisterEvent("UNIT_SPELLCAST_FAILED")
events:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
events:SetScript("OnEvent", function(_, event, unit, spell, _, target)
	if event == "PLAYER_LOGIN" then
		-- Localized cast names: Mining (2575) and Herb Gathering (2366).
		for spellID, prof in pairs({ [2575] = "Mining", [2366] = "Herbalism" }) do
			local name = GetSpellInfo(spellID)
			if name then
				GATHER_SPELLS[name] = prof
			end
		end
		return
	end
	if unit ~= "player" or not GATHER_SPELLS[spell] then
		return
	end
	if event == "UNIT_SPELLCAST_SENT" then
		if target and NS.NODES[target] then
			pending = { name = target, spell = spell, time = GetTime() }
		else
			pending = nil
		end
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		if pending and pending.spell == spell and GetTime() - pending.time < 15 then
			Record(pending.name)
		end
		pending = nil
	else
		pending = nil
	end
end)

----------------------------------------------------------------------------
-- Tracking ("Find Minerals" / "Find Herbs")
----------------------------------------------------------------------------
-- Localized tracking names, filled lazily (GetSpellInfo works any time).
local TRACKING_SPELLS = { Mining = 2580, Herbalism = 2383 }

-- Index into GetTrackingInfo for a profession's tracking, and whether it's
-- active. nil if you don't have that tracking ability.
function Nodes:TrackingFor(prof)
	local wanted = TRACKING_SPELLS[prof] and GetSpellInfo(TRACKING_SPELLS[prof])
	if not wanted then
		return nil
	end
	for i = 1, GetNumTrackingTypes() do
		local name, _, active = GetTrackingInfo(i)
		if name == wanted then
			return i, active and true or false
		end
	end
	return nil
end

function Nodes:IsTracking(prof)
	local _, active = self:TrackingFor(prof)
	return active
end
