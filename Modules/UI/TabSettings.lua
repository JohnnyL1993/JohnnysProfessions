-- Settings page: built-in toggles, every option feature modules registered
-- through NS:RegisterOption (grouped by section), and "reset" buttons for
-- stored data. Scrolls, since modules can add any number of options.
local NS = JohnnysProfessions
local Page = {}
NS.MainWindow:AddPage("Settings", Page, {
	order = 9, label = "Settings", icon = "Interface\\Icons\\INV_Misc_Gear_01",
	title = "Settings", subtitle = "Options and stored data",
})

local ROW_H, GAP = 48, 8
local toggles = {}
local priceText

local function Card(parent, y)
	local card = NS.Widgets:CreateCard(parent)
	card:SetPoint("TOPLEFT", 0, y)
	card:SetPoint("RIGHT", 0, 0)
	card:SetHeight(ROW_H)
	return card
end

-- White label + grey description. The description wraps within the card
-- (leaving `rightInset` free for a button) and the card grows to fit it.
local function Texts(card, x, label, desc, rightInset)
	local W = NS.Widgets
	local title = W:Label(card, "GameFontHighlight")
	title:SetPoint("TOPLEFT", x, -9)
	title:SetText(label)
	local sub = W:Label(card)
	sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
	sub:SetWidth(NS.MainWindow.CONTENT_W - 26 - x - rightInset)
	sub:SetJustifyV("TOP")
	sub:SetTextColor(unpack(W.COLORS.muted))
	sub:SetText(desc or "")
	local h = 9 + title:GetStringHeight() + 3 + sub:GetStringHeight() + 9
	card:SetHeight(math.max(ROW_H, math.ceil(h)))
	return sub
end

-- One card row: checkbox + white label + grey description.
local function Toggle(parent, y, label, desc, get, set)
	local card = Card(parent, y)
	local box = NS.Skin:CreateCheckbox(card, 18, get(), set)
	box:SetPoint("LEFT", 12, 0)
	Texts(card, 42, label, desc, 12)
	table.insert(toggles, { box = box, get = get })
	return y - card:GetHeight() - GAP
end

-- One card row: button on the right, label + description on the left.
local function Action(parent, y, label, desc, buttonText, onClick)
	local card = Card(parent, y)
	local sub = Texts(card, 12, label, desc, 150)
	local btn = NS.Skin:CreateButton(card, 130, 22, buttonText)
	btn:SetPoint("RIGHT", -12, 0)
	btn:SetScript("OnClick", onClick)
	return y - card:GetHeight() - GAP, sub
end

local function Section(parent, y, text)
	local fs = NS.Widgets:SectionTitle(parent, text)
	fs:SetPoint("TOPLEFT", 2, y - 4)
	return y - 22
end

function Page:Build(f)
	local scroll = CreateFrame("ScrollFrame", "JohnnysProfessionsSettingsScroll", f, "UIPanelScrollFrameTemplate")
	NS.Skin:StyleScrollBar(scroll)
	scroll:SetPoint("TOPLEFT", 0, 0)
	scroll:SetPoint("BOTTOMRIGHT", -24, 0)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(NS.MainWindow.CONTENT_W - 26, 10)
	scroll:SetScrollChild(content)

	local ui = NS.db.profile.ui
	local y = 0
	y = Section(content, y, "General")
	y = Toggle(content, y, "Show the mini-guide with profession windows",
		"Pops up the current guide step whenever you open a profession that has a guide.",
		function() return NS.db.profile.ui.showMiniGuide end,
		function(v) NS.db.profile.ui.showMiniGuide = v end)
	y = Toggle(content, y, "Announce ready cooldowns at login",
		"Lists this character's profession cooldowns that are ready again in chat.",
		function() return NS.db.profile.ui.cooldownAlerts end,
		function(v) NS.db.profile.ui.cooldownAlerts = v end)

	-- Options registered by feature modules, in section order of first use.
	local sections, bySection = {}, {}
	for _, o in ipairs(NS.optionList) do
		if not bySection[o.section] then
			bySection[o.section] = {}
			table.insert(sections, o.section)
		end
		table.insert(bySection[o.section], o)
	end
	for _, section in ipairs(sections) do
		y = Section(content, y, section)
		for _, o in ipairs(bySection[section]) do
			local key = o.key
			y = Toggle(content, y, o.label, o.desc,
				function() return NS:Option(key) end,
				function(v) NS:SetOption(key, v) end)
		end
	end

	y = Section(content, y, "Windows and data")
	y = Action(content, y, "Window scale and opacity", "Resize or fade any of this addon's windows.",
		"Open", function() NS.WindowSettings:Toggle() end)
	y = Action(content, y, "Reset window positions", "Moves every window back to the middle of the screen (after /reload).",
		"Reset", function()
			wipe(ui.positions)
			NS:Print("Window positions reset - /reload to apply.")
		end)
	y, priceText = Action(content, y, "Forget AH prices", "",
		"Clear prices", function()
			wipe(NS:RealmDB().prices)
			NS:Print("AH prices for this realm cleared.")
			NS:RequestRedraw()
		end)
	y = Action(content, y, "Clear the item tracker", "Removes every tracked item goal on this character.",
		"Clear tracker", function()
			NS.Tracker:Clear()
			NS:Print("Item tracker cleared.")
		end)
	content:SetHeight(-y)
end

function Page:Refresh()
	for _, t in ipairs(toggles) do
		t.box:SetChecked(t.get())
	end
	local count, oldest = NS.Prices:Summary()
	if oldest then
		priceText:SetText(string.format("%d prices stored for this realm, oldest scanned %s ago.",
			count, NS:FormatDuration(math.max(60, time() - oldest))))
	else
		priceText:SetText("No prices stored for this realm yet.")
	end
end
