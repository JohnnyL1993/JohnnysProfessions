-- The main window: a sidebar of pages on the left (grouped under small
-- headings, each with an icon, label and - where it means something - a live
-- count), then price freshness, the item tracker button and the current
-- character at the bottom; and the selected page on the right under a
-- one-line title + subtitle. Each page registers from its own file
-- (UI\Tab*.lua) with :Build(holder) and :Refresh().
--
-- Page content area is CONTENT_W x CONTENT_H (see below); pages anchor to
-- their holder rather than hard-coding the window size.
local NS = JohnnysProfessions
NS.MainWindow = {}
local MW = NS.MainWindow

local WIDTH, HEIGHT = 900, 560
local SIDEBAR_W = 180
-- Title and subtitle share one line, which leaves the pages about two more
-- list rows than the old stacked header did.
local HEADER_H = 62
MW.CONTENT_W = WIDTH - SIDEBAR_W - 16 - 14
MW.CONTENT_H = HEIGHT - HEADER_H - 12

-- Sidebar order. Pages are still registered by their own files (AddPage);
-- this only decides which heading each sits under. Anything registered that
-- isn't named here is listed at the end under "More", so a new page can
-- never go missing from the sidebar.
local NAV_GROUPS = {
	{ pages = { "Home" } },
	{ label = "LEVELLING", pages = { "Professions", "Specializations", "Shopping" } },
	{ label = "ACCOUNT", pages = { "Alts", "Materials", "Cooldowns" } },
	{ label = "GOLD", pages = { "Gold", "Crafters" } },
	{ pages = { "Settings" } },
}
-- Our own scan's prices are treated as old after this long (same threshold
-- Prices.lua uses per item).
local PRICES_OLD_AFTER = 48 * 3600
-- Sidebar counts and price age are recomputed at most this often - redraws
-- can come in bursts.
local STATUS_CACHE_SECONDS = 2

local pages = {}   -- name -> page
local order = {}   -- array of names, sorted by opts.order
local frame, titleText, subtitleText, charName, charInfo
local trackerButton, priceText, priceScanButton
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

local function Age(seconds)
	if seconds < 3600 then
		return math.max(1, math.floor(seconds / 60)) .. " min"
	elseif seconds < 86400 then
		local hours = math.floor(seconds / 3600)
		return hours .. (hours == 1 and " hour" or " hours")
	end
	local days = math.floor(seconds / 86400)
	return days .. (days == 1 and " day" or " days")
end

-- Counts shown in the sidebar, and when prices were last scanned. Each part
-- is pcall'd: these only decorate the sidebar and must never be able to stop
-- a page from drawing.
local status, statusAt = {}, 0
local function Status()
	local now = GetTime()
	if (now - statusAt) < STATUS_CACHE_SECONDS then
		return status
	end
	statusAt = now
	local s = {}

	pcall(function()
		local ready, t = 0, time()
		for _, row in ipairs(NS.Cooldowns:All()) do
			-- Only cooldowns that have been used at least once, so a
			-- never-used recipe doesn't count as "ready" forever.
			if row.used and row.expires <= t then
				ready = ready + 1
			end
		end
		s.Cooldowns = ready
	end)

	pcall(function()
		local short = 0
		for _, entry in ipairs(NS.Guide:ShoppingList(NS.Guide:MyGuidedProfessions())) do
			if entry.short > 0 then
				short = short + 1
			end
		end
		s.Shopping = short
	end)

	pcall(function()
		local open = 0
		for _, goal in ipairs(NS.Tracker:List()) do
			if goal.count < goal.target then
				open = open + 1
			end
		end
		s.tracker = open
	end)

	pcall(function()
		local newest
		for _, p in pairs(NS:RealmDB().prices) do
			if p.time and (not newest or p.time > newest) then
				newest = p.time
			end
		end
		s.newestScan = newest
		s.externalPrices = NS.Prices:ExternalSourceName()
	end)

	status = s
	return s
end

local function UpdateSidebarStatus()
	if not priceText then
		return
	end
	local C = NS.Skin.C
	local s = Status()

	for name, button in pairs(navButtons) do
		local count = s[name]
		if count and count > 0 then
			button.num:SetText(tostring(count))
			button.hasCount = true
		else
			button.num:SetText("")
			button.hasCount = false
		end
		button:SetSelected(name == current)
	end

	local open = s.tracker or 0
	trackerButton.text:SetText(open > 0 and string.format("Item tracker (%d)", open) or "Item tracker")

	-- Price freshness. Prices from TSM / Auctionator keep their own history
	-- and are never "old" here; only this addon's own scan ages.
	local Scan = NS.AuctionScan
	local amber = { 1, 0.85, 0.40 }
	local color, text = C.muted, nil
	if Scan:IsRunning() then
		local index, total = Scan:Progress()
		text = string.format("Scanning prices... %d / %d", index or 0, total or 0)
		color = C.text
	elseif s.externalPrices then
		text = "Prices from " .. s.externalPrices
	elseif s.newestScan then
		local age = time() - s.newestScan
		text = "Prices scanned " .. Age(age) .. " ago"
		if age > PRICES_OLD_AFTER then
			text = text .. " - rescan at the auction house"
			color = amber
		end
	else
		text = "No prices yet - scan at the auction house"
		color = amber
	end
	priceText:SetText(text)
	priceText:SetTextColor(color[1], color[2], color[3])

	if Scan:IsRunning() then
		priceScanButton.text:SetText("Stop scan")
		priceScanButton:Show()
	elseif Scan:IsAHOpen() then
		priceScanButton.text:SetText("Scan prices now")
		priceScanButton:Show()
	else
		priceScanButton:Hide()
	end
end

local function Build()
	local W = NS.Widgets
	local Skin = NS.Skin
	local C = Skin.C
	frame = W:CreateWindow("Main", "Johnny's Professions", WIDTH, HEIGHT)

	-- The update notice anchors itself to its host's top-left corner, which
	-- the title now occupies, so give it a host left of the Cfg button.
	local noticeHost = CreateFrame("Frame", nil, frame)
	noticeHost:SetSize(220, Skin.HEADER_HEIGHT)
	noticeHost:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -76, 2)
	NS.VersionCheck:AttachNotice(noticeHost)

	-- Sidebar
	local side = CreateFrame("Frame", nil, frame)
	side:SetPoint("TOPLEFT", 1, -(Skin.HEADER_HEIGHT + 1))
	side:SetPoint("BOTTOMLEFT", 1, 1)
	side:SetWidth(SIDEBAR_W)
	local sideBg = side:CreateTexture(nil, "BACKGROUND")
	sideBg:SetAllPoints()
	sideBg:SetTexture(Skin.WHITE)
	sideBg:SetVertexColor(0.039, 0.051, 0.055, 0.6)
	local divider = side:CreateTexture(nil, "BORDER")
	divider:SetTexture(Skin.WHITE)
	divider:SetVertexColor(0.180, 0.224, 0.243, 1)
	divider:SetPoint("TOPRIGHT")
	divider:SetPoint("BOTTOMRIGHT")
	divider:SetWidth(1)

	local y = -8
	local placed = {}
	local function PlaceButton(name)
		if not pages[name] or placed[name] then
			return
		end
		placed[name] = true
		local opts = pages[name].opts
		local b = W:CreateNavButton(side, SIDEBAR_W - 12, opts.label or name, opts.icon)
		b:SetPoint("TOPLEFT", 6, y)
		b:SetScript("OnClick", function() MW:ShowTab(name) end)
		navButtons[name] = b
		y = y - 28
	end
	local function PlaceHeading(text)
		y = y - 6
		local fs = Skin:Heading(side, 10, C.dim)
		fs:SetPoint("TOPLEFT", 16, y - 3)
		fs:SetText(text)
		y = y - 18
	end

	for _, group in ipairs(NAV_GROUPS) do
		local any = false
		for _, name in ipairs(group.pages) do
			if pages[name] then
				any = true
			end
		end
		if any then
			if group.label then
				PlaceHeading(group.label)
			elseif y < -8 then
				y = y - 6
			end
			for _, name in ipairs(group.pages) do
				PlaceButton(name)
			end
		end
	end
	local leftovers = false
	for _, name in ipairs(order) do
		if not placed[name] then
			if not leftovers then
				leftovers = true
				PlaceHeading("MORE")
			end
			PlaceButton(name)
		end
	end

	-- Bottom of the sidebar, built upward: character, tracker, prices.
	charInfo = W:Label(side)
	charInfo:SetPoint("BOTTOMLEFT", 14, 10)
	charInfo:SetTextColor(unpack(W.COLORS.muted))
	charName = W:Label(side, "GameFontHighlight")
	charName:SetPoint("BOTTOMLEFT", charInfo, "TOPLEFT", 0, 3)

	trackerButton = Skin:CreateButton(side, SIDEBAR_W - 28, 22, "Item tracker")
	trackerButton:SetPoint("BOTTOMLEFT", charName, "TOPLEFT", 0, 10)
	trackerButton:SetScript("OnClick", function() NS.TrackerWindow:Toggle() end)

	priceScanButton = Skin:CreateButton(side, SIDEBAR_W - 28, 20, "Scan prices now")
	priceScanButton:SetPoint("BOTTOMLEFT", trackerButton, "TOPLEFT", 0, 6)
	priceScanButton:SetScript("OnClick", function()
		if NS.AuctionScan:IsRunning() then
			NS.AuctionScan:Stop()
		else
			NS.AuctionScan:Start()
		end
	end)
	priceScanButton:Hide()

	-- Anchored above the scan button's slot whether or not it's showing, so
	-- the text doesn't jump when the auction house opens.
	priceText = W:Label(side)
	priceText:SetPoint("BOTTOMLEFT", trackerButton, "TOPLEFT", 0, 32)
	priceText:SetWidth(SIDEBAR_W - 28)
	priceText:SetJustifyV("BOTTOM")

	-- Header: title, with the subtitle following it on the same line.
	titleText = Skin:Heading(frame, 20)
	titleText:SetPoint("TOPLEFT", SIDEBAR_W + 16, -36)
	subtitleText = W:Label(frame)
	subtitleText:SetPoint("BOTTOMLEFT", titleText, "BOTTOMRIGHT", 12, 2)
	subtitleText:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
	subtitleText:SetHeight(12)
	if subtitleText.SetWordWrap then
		subtitleText:SetWordWrap(false)
	end
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
	UpdateSidebarStatus()
	pages[current]:Refresh()
end

-- Opens the Professions page on a given profession.
function MW:ShowGuide(prof)
	NS.db.profile.ui.guide = prof
	self:ShowTab("Professions")
end
