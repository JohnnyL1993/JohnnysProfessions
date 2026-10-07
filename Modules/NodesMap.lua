-- Pins for recorded gathering nodes (Nodes.lua) on the world map and the
-- minimap. Pins are the node's yield icon framed in its skill-up colour (red
-- = can't gather yet, orange/yellow/green, grey = no skill-ups), dimmed for
-- ~5 minutes after a gather while the node respawns.
--
-- Minimap placement converts map coordinates to yards with the zone sizes in
-- Data\Nodes.lua, and yards to pixels with the minimap's view size for the
-- current zoom (indoor/outdoor), rotating with the minimap if that's on.
local NS = JohnnysProfessions
NS.NodesMap = {}
local NodesMap = NS.NodesMap
local Nodes = NS.Nodes

NS:RegisterOption("nodesWorldMap", true, "Gathering",
	"Show gathered nodes on the world map",
	"Pins every herb and mining node you've gathered, on any character, on the world map.")
NS:RegisterOption("nodesMinimap", true, "Gathering",
	"Show gathered nodes on the minimap",
	"Pins nearby nodes on the minimap (hidden in instances and combat).")
NS:RegisterOption("nodesOnlyTracking", true, "Gathering",
	"Only while Find Minerals / Find Herbs is on",
	"Show a profession's nodes only while its tracking is active. Turn off to always show them.")
NS:RegisterOption("nodesSkillUpsOnly", false, "Gathering",
	"Only nodes that still give skill-ups",
	"Hide nodes that are grey for you (and nodes you can't gather yet).")

local WORLD_PIN = 14
local MINI_PIN = 12
local MINI_UPDATE = 0.1

local worldPins, miniPins = {}, {}
local COS, SIN, SQRT = math.cos, math.sin, math.sqrt

----------------------------------------------------------------------------
-- Which nodes to show
----------------------------------------------------------------------------
-- Whether node `name` passes the profession / tracking / skill-up filters.
local function Visible(name)
	local info = NS.NODES[name]
	if not info then
		return false
	end
	if not NS.Characters:Me().skills[info.prof] then
		return false
	end
	if NS:Option("nodesOnlyTracking") and not Nodes:IsTracking(info.prof) then
		return false
	end
	if NS:Option("nodesSkillUpsOnly") and not Nodes:GivesSkillUp(name) then
		return false
	end
	return true
end

----------------------------------------------------------------------------
-- Pin frames
----------------------------------------------------------------------------
local function PinTooltip(pin)
	local name, point = pin.nodeName, pin.point
	local info = NS.NODES[name]
	GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
	GameTooltip:AddLine(name, 1, 1, 1)
	if info then
		local skill = Nodes:PlayerSkill(name)
		local r, g, b = Nodes:SkillColor(name)
		GameTooltip:AddLine(string.format("Requires %s %d%s", info.prof, info.skill,
			skill and string.format(" (you: %d)", skill) or ""), r, g, b)
	end
	GameTooltip:AddLine(string.format("%.1f, %.1f", point[1] * 100, point[2] * 100), 0.6, 0.6, 0.6)
	GameTooltip:AddLine(string.format("Gathered %d time%s", point[3] or 1, (point[3] or 1) == 1 and "" or "s"), 0.8, 0.8, 0.8)
	if point[4] then
		local ago = time() - point[4]
		if Nodes:IsRespawning(point) then
			GameTooltip:AddLine("Gathered just now - respawning", 0.6, 0.6, 0.6)
		else
			GameTooltip:AddLine("Last gathered " .. NS:FormatDuration(math.max(60, ago)) .. " ago", 0.6, 0.6, 0.6)
		end
	end
	GameTooltip:Show()
end

local function NewPin(parent, size)
	local pin = CreateFrame("Button", nil, parent)
	pin:SetSize(size, size)
	pin:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
	pin:SetBackdropColor(0, 0, 0, 1)
	local tex = pin:CreateTexture(nil, "ARTWORK")
	tex:SetPoint("TOPLEFT", 1, -1)
	tex:SetPoint("BOTTOMRIGHT", -1, 1)
	tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	pin.icon = tex
	pin:SetScript("OnEnter", PinTooltip)
	pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
	return pin
end

local function StylePin(pin, name, point)
	pin.nodeName, pin.point = name, point
	local info = NS.NODES[name]
	pin.icon:SetTexture((info and info.item and GetItemIcon(info.item)) or "Interface\\Icons\\INV_Misc_QuestionMark")
	local r, g, b = Nodes:SkillColor(name)
	pin:SetBackdropBorderColor(r, g, b, 1)
	if Nodes:IsRespawning(point) then
		pin.icon:SetDesaturated(true)
		pin:SetAlpha(0.45)
	else
		pin.icon:SetDesaturated(false)
		pin:SetAlpha(1)
	end
end

----------------------------------------------------------------------------
-- World map
----------------------------------------------------------------------------
function NodesMap:UpdateWorldMap()
	local n = 0
	if NS.db and NS.Characters:Me() and NS:Option("nodesWorldMap") and WorldMapButton and WorldMapFrame:IsShown()
		and GetCurrentMapZone() > 0 and not (GetCurrentMapDungeonLevel and GetCurrentMapDungeonLevel() > 0) then
		local nodes = Nodes:ForMap(GetMapInfo())
		if nodes then
			local w, h = WorldMapButton:GetWidth(), WorldMapButton:GetHeight()
			local level = WorldMapButton:GetFrameLevel() + 5
			for name, points in pairs(nodes) do
				if Visible(name) then
					for _, point in ipairs(points) do
						n = n + 1
						local pin = worldPins[n]
						if not pin then
							pin = NewPin(WorldMapButton, WORLD_PIN)
							worldPins[n] = pin
						end
						pin:SetFrameLevel(level)
						pin:ClearAllPoints()
						pin:SetPoint("CENTER", WorldMapButton, "TOPLEFT", point[1] * w, -point[2] * h)
						StylePin(pin, name, point)
						pin:Show()
					end
				end
			end
		end
	end
	for i = n + 1, #worldPins do
		worldPins[i]:Hide()
	end
end

----------------------------------------------------------------------------
-- Minimap
----------------------------------------------------------------------------
-- Indoor/outdoor: the minimap keeps a separate zoom per mode in the
-- minimapZoom / minimapInsideZoom CVars. When both hold the same value, nudge
-- the zoom and see which CVar follows (then put it back).
local indoors = false
local detecting = false
local ignoreUntil = 0
local function DetectIndoors()
	-- Our own SetZoom below fires MINIMAP_UPDATE_ZOOM again (now or a frame
	-- later); skip those echoes.
	if detecting or GetTime() < ignoreUntil then
		return
	end
	local zoom = Minimap:GetZoom()
	local outdoor = tonumber(GetCVar("minimapZoom")) or 0
	local inside = tonumber(GetCVar("minimapInsideZoom")) or 0
	if outdoor ~= inside then
		indoors = (inside == zoom)
		return
	end
	detecting = true
	Minimap:SetZoom(zoom < 2 and zoom + 1 or zoom - 1)
	indoors = (tonumber(GetCVar("minimapInsideZoom")) or 0) == Minimap:GetZoom()
	Minimap:SetZoom(zoom)
	detecting = false
	ignoreUntil = GetTime() + 0.5
end

local function MinimapHidden()
	if not NS.db or not NS.Characters:Me() or not NS:Option("nodesMinimap") then
		return true
	end
	if IsInInstance() or UnitAffectingCombat("player") then
		return true
	end
	return false
end

local function HideMini(from)
	for i = from, #miniPins do
		miniPins[i]:Hide()
	end
end

function NodesMap:UpdateMinimap()
	if MinimapHidden() then
		HideMini(1)
		return
	end
	local mapFile, px, py = Nodes:PlayerPosition()
	local size = mapFile and NS.ZONE_SIZES[mapFile]
	local nodes = mapFile and Nodes:ForMap(mapFile)
	if not size or not nodes then
		HideMini(1)
		return
	end

	local sizes = indoors and NS.MINIMAP_SIZES.indoor or NS.MINIMAP_SIZES.outdoor
	local diameter = sizes[Minimap:GetZoom()] or sizes[0]
	local radiusPx = Minimap:GetWidth() / 2
	local scale = Minimap:GetWidth() / diameter -- pixels per yard
	local square = GetMinimapShape and GetMinimapShape() == "SQUARE"
	local rotate = GetCVar("rotateMinimap") == "1"
	local facing = rotate and GetPlayerFacing() or 0
	local cosF, sinF = COS(facing), SIN(facing)

	local n = 0
	for name, points in pairs(nodes) do
		if Visible(name) then
			for _, point in ipairs(points) do
				-- East/north offset in pixels (map y grows southward).
				local sx = (point[1] - px) * size[1] * scale
				local sy = (py - point[2]) * size[2] * scale
				if rotate then
					sx, sy = sx * cosF - sy * sinF, sx * sinF + sy * cosF
				end
				local inside
				if square then
					inside = math.abs(sx) <= radiusPx - 4 and math.abs(sy) <= radiusPx - 4
				else
					inside = SQRT(sx * sx + sy * sy) <= radiusPx - 4
				end
				if inside then
					n = n + 1
					local pin = miniPins[n]
					if not pin then
						pin = NewPin(Minimap, MINI_PIN)
						miniPins[n] = pin
					end
					pin:SetFrameLevel(Minimap:GetFrameLevel() + 5)
					pin:ClearAllPoints()
					pin:SetPoint("CENTER", Minimap, "CENTER", sx, sy)
					StylePin(pin, name, point)
					pin:Show()
				end
			end
		end
	end
	HideMini(n + 1)
end

----------------------------------------------------------------------------
-- Wiring
----------------------------------------------------------------------------
local ticker = CreateFrame("Frame")
local wait = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
	wait = wait - elapsed
	if wait > 0 then
		return
	end
	wait = MINI_UPDATE
	-- Positions on the minimap are meaningless while the world map shows
	-- another zone; leave the pins as they are until it closes.
	if WorldMapFrame and WorldMapFrame:IsShown() then
		return
	end
	NodesMap:UpdateMinimap()
end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("WORLD_MAP_UPDATE")
events:RegisterEvent("MINIMAP_UPDATE_ZOOM")
events:RegisterEvent("MINIMAP_UPDATE_TRACKING")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_INDOORS")
events:RegisterEvent("ZONE_CHANGED")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		WorldMapFrame:HookScript("OnShow", function() NodesMap:UpdateWorldMap() end)
		Nodes:OnChange(function()
			if WorldMapFrame:IsShown() then
				NodesMap:UpdateWorldMap()
			end
		end)
		DetectIndoors()
	elseif event == "WORLD_MAP_UPDATE" then
		if WorldMapFrame:IsShown() then
			NodesMap:UpdateWorldMap()
		end
	elseif event == "MINIMAP_UPDATE_TRACKING" then
		if WorldMapFrame:IsShown() then
			NodesMap:UpdateWorldMap()
		end
	else
		DetectIndoors()
	end
end)
