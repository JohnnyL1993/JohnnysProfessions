-- Minimap button + key bindings. Left-click toggles the main window,
-- Shift-click the item tracker, right-click the mini-guide. Drag it around
-- the minimap edge; the angle is saved per character. Works with round and
-- square minimaps (GetMinimapShape, set by minimap addons that change it).
local NS = JohnnysProfessions
NS.MinimapButton = {}
local MB = NS.MinimapButton

-- Key bindings (Bindings.xml) - the labels the Key Bindings window shows.
BINDING_HEADER_JOHNNYSPROFESSIONS = "Johnny's Professions"
BINDING_NAME_JOHNNYSPROFESSIONS_TOGGLE = "Show / hide the main window"
BINDING_NAME_JOHNNYSPROFESSIONS_TRACKER = "Show / hide the item tracker"
BINDING_NAME_JOHNNYSPROFESSIONS_MINIGUIDE = "Show / hide the mini-guide"

NS:RegisterOption("minimapButton", true, "Minimap",
	"Show the minimap button",
	"Left-click: main window. Shift-click: item tracker. Right-click: mini-guide. Drag to move it.")

local DEFAULT_ANGLE = 200
local button

-- How far from the centre the button sits on each side; square corners
-- push it out to the corner instead of following the circle.
local SQUARE_SHAPES = {
	SQUARE = true, CORNER_TOPLEFT = true, CORNER_TOPRIGHT = true,
	CORNER_BOTTOMLEFT = true, CORNER_BOTTOMRIGHT = true,
}

local function UpdatePosition()
	local angle = math.rad(NS.db.profile.ui.minimapAngle or DEFAULT_ANGLE)
	local x, y = math.cos(angle), math.sin(angle)
	local radius = Minimap:GetWidth() / 2 + 8
	local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
	if SQUARE_SHAPES[shape] then
		-- Stretch the circle out to the square's edge (clamped).
		x = math.max(-1, math.min(1, x * 1.41))
		y = math.max(-1, math.min(1, y * 1.41))
	end
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", x * radius, y * radius)
end

local function OnDragUpdate()
	local mx, my = Minimap:GetCenter()
	local cx, cy = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	cx, cy = cx / scale, cy / scale
	NS.db.profile.ui.minimapAngle = math.deg(math.atan2(cy - my, cx - mx)) % 360
	UpdatePosition()
end

local function OnClick(_, mouse)
	if mouse == "RightButton" then
		NS.MiniGuide:Toggle()
	elseif IsShiftKeyDown() then
		NS.TrackerWindow:Toggle()
	else
		NS.MainWindow:Toggle()
	end
end

local function OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:AddLine("Johnny's Professions", 1, 1, 1)
	GameTooltip:AddLine("Click: show / hide the window", 0.7, 0.7, 0.7)
	GameTooltip:AddLine("Shift-click: item tracker", 0.7, 0.7, 0.7)
	GameTooltip:AddLine("Right-click: mini-guide", 0.7, 0.7, 0.7)
	GameTooltip:AddLine("Drag: move this button", 0.7, 0.7, 0.7)
	GameTooltip:Show()
end

local function Build()
	button = CreateFrame("Button", "JohnnysProfessionsMinimapButton", Minimap)
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetSize(20, 20)
	bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	bg:SetPoint("TOPLEFT", 7, -5)

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(18, 18)
	icon:SetTexture("Interface\\Icons\\Trade_BlackSmithing")
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	icon:SetDesaturated(true)
	icon:SetPoint("TOPLEFT", 7, -6)
	button.icon = icon

	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetSize(53, 53)
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetPoint("TOPLEFT")

	button:SetScript("OnClick", OnClick)
	button:SetScript("OnEnter", OnEnter)
	button:SetScript("OnLeave", GameTooltip_Hide)
	button:SetScript("OnMouseDown", function() icon:SetTexCoord(0, 1, 0, 1) end)
	button:SetScript("OnMouseUp", function() icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) end)
	button:SetScript("OnDragStart", function(self)
		GameTooltip:Hide()
		self:SetScript("OnUpdate", OnDragUpdate)
	end)
	button:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	end)
	UpdatePosition()
end

-- Shows or hides the button to match the option.
function MB:Update()
	if not NS.db then
		return
	end
	if NS:Option("minimapButton") then
		if not button then
			Build()
		end
		UpdatePosition()
		button:Show()
	elseif button then
		button:Hide()
	end
end

-- The Settings page toggles options through NS:SetOption; follow it so the
-- button appears/disappears right away.
local origSetOption = NS.SetOption
function NS:SetOption(key, value)
	origSetOption(self, key, value)
	if key == "minimapButton" then
		MB:Update()
	end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
	MB:Update()
end)

NS:RegisterSlash("minimap", function()
	NS:SetOption("minimapButton", not NS:Option("minimapButton"))
	NS:Print("Minimap button " .. (NS:Option("minimapButton") and "shown." or "hidden."))
end, "/jp minimap - show or hide the minimap button")
