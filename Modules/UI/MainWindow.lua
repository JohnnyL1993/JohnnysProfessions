-- The main window: a sidebar of pages on the left (icon + label, item
-- tracker button and the current character at the bottom), and the selected
-- page on the right under a large title + subtitle. Each page registers from
-- its own file (UI\Tab*.lua) with :Build(holder) and :Refresh().
--
-- Page content area is CONTENT_W x CONTENT_H (see below); pages anchor to
-- their holder rather than hard-coding the window size.
local NS = JohnnysProfessions
NS.MainWindow = {}
local MW = NS.MainWindow

local WIDTH, HEIGHT = 900, 560
local SIDEBAR_W = 180
local HEADER_H = 86
MW.CONTENT_W = WIDTH - SIDEBAR_W - 16 - 14
MW.CONTENT_H = HEIGHT - HEADER_H - 12

local pages = {}   -- name -> page
local order = {}   -- array of names, sorted by opts.order
local frame, titleText, subtitleText, charName, charInfo
local navButtons = {}
local current

-- opts: { order = n, label = "Home", icon = "Interface\\Icons\\...",
--         title = "Welcome back", subtitle = "Your character at a glance" }
-- title/subtitle may be functions returning text (evaluated on show).
function MW:AddPage(name, page, opts)
	page.opts = opts or {}
	pages[name] = page
	table.insert(order, name)
	table.sort(order, function(a, b)
		return (pages[a].opts.order or 99) < (pages[b].opts.order or 99)
	end)
end

local function Eval(v)
	if type(v) == "function" then
		return v()
	end
	return v
end

local function UpdateCharacter()
	if not charName then
		return
	end
	local _, classFile = UnitClass("player")
	charName:SetText(NS:ClassColoredName(UnitName("player"), classFile))
	charInfo:SetText(string.format("Level %d %s", UnitLevel("player"), UnitClass("player")))
end

local function Build()
	local W = NS.Widgets
	frame = W:CreateWindow("Main", "Johnny's Professions", WIDTH, HEIGHT)
	frame.title:ClearAllPoints()
	frame.title:SetPoint("TOP", 0, -9)

	NS.VersionCheck:AttachNotice(frame)

	-- Sidebar
	local side = CreateFrame("Frame", nil, frame)
	side:SetPoint("TOPLEFT", 1, -30)
	side:SetPoint("BOTTOMLEFT", 1, 1)
	side:SetWidth(SIDEBAR_W)
	local sideBg = side:CreateTexture(nil, "BACKGROUND")
	sideBg:SetAllPoints()
	sideBg:SetTexture(NS.Skin.WHITE)
	sideBg:SetVertexColor(0, 0, 0, 0.55)
	local divider = side:CreateTexture(nil, "BORDER")
	divider:SetTexture(NS.Skin.WHITE)
	divider:SetVertexColor(0.25, 0.25, 0.25, 1)
	divider:SetPoint("TOPRIGHT")
	divider:SetPoint("BOTTOMRIGHT")
	divider:SetWidth(1)
	local topLine = frame:CreateTexture(nil, "BORDER")
	topLine:SetTexture(NS.Skin.WHITE)
	topLine:SetVertexColor(0.25, 0.25, 0.25, 1)
	topLine:SetPoint("TOPLEFT", 1, -30)
	topLine:SetPoint("TOPRIGHT", -1, -30)
	topLine:SetHeight(1)

	local y = -12
	for _, name in ipairs(order) do
		local opts = pages[name].opts
		local b = W:CreateNavButton(side, SIDEBAR_W - 12, opts.label or name, opts.icon)
		b:SetPoint("TOPLEFT", 6, y)
		b:SetScript("OnClick", function() MW:ShowTab(name) end)
		navButtons[name] = b
		y = y - 30
	end

	charInfo = W:Label(side)
	charInfo:SetPoint("BOTTOMLEFT", 14, 12)
	charInfo:SetTextColor(unpack(W.COLORS.muted))
	charName = W:Label(side, "GameFontHighlight")
	charName:SetPoint("BOTTOMLEFT", charInfo, "TOPLEFT", 0, 3)

	local tracker = NS.Skin:CreateButton(side, SIDEBAR_W - 28, 24, "Item tracker")
	tracker:SetPoint("BOTTOMLEFT", charName, "TOPLEFT", 0, 12)
	tracker:SetScript("OnClick", function() NS.TrackerWindow:Toggle() end)

	-- Header
	titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	titleText:SetPoint("TOPLEFT", SIDEBAR_W + 16, -40)
	titleText:SetTextColor(1, 1, 1)
	subtitleText = W:Label(frame, "GameFontHighlight")
	subtitleText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -4)
	subtitleText:SetTextColor(unpack(W.COLORS.muted))

	-- Pages
	for _, name in ipairs(order) do
		local page = pages[name]
		local holder = CreateFrame("Frame", nil, frame)
		holder:SetPoint("TOPLEFT", SIDEBAR_W + 16, -HEADER_H)
		holder:SetPoint("BOTTOMRIGHT", -14, 12)
		holder:Hide()
		page.frame = holder
		page:Build(holder)
	end

	frame:SetScript("OnShow", function()
		UpdateCharacter()
		MW:Refresh()
	end)
end

function MW:ShowTab(name)
	if not pages[name] then
		name = order[1]
	end
	if not frame then
		Build()
	end
	NS.db.profile.ui.tab = name
	current = name
	for n, b in pairs(navButtons) do
		b:SetSelected(n == name)
	end
	for n, p in pairs(pages) do
		if n == name then
			p.frame:Show()
		else
			p.frame:Hide()
		end
	end
	frame:Show()
	self:Refresh()
end

function MW:Toggle()
	if frame and frame:IsShown() then
		frame:Hide()
	else
		self:ShowTab(NS.db.profile.ui.tab or "Home")
	end
end

function MW:IsShown()
	return frame and frame:IsShown()
end

function MW:Current()
	return current
end

function MW:Refresh()
	if not self:IsShown() or not current then
		return
	end
	local opts = pages[current].opts
	titleText:SetText(Eval(opts.title) or opts.label or current)
	subtitleText:SetText(Eval(opts.subtitle) or "")
	UpdateCharacter()
	pages[current]:Refresh()
end

-- Opens the Professions page on a given profession.
function MW:ShowGuide(prof)
	NS.db.profile.ui.guide = prof
	self:ShowTab("Professions")
end
