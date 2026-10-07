-- Cooldowns page: a card per character, a bar per profession cooldown
-- filling up toward "Ready". Characters with something ready come first.
local NS = JohnnysProfessions
local Page = {}
NS.MainWindow:AddPage("Cooldowns", Page, {
	order = 7, label = "Cooldowns", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
	title = "Cooldowns", subtitle = "Transmutes, research and cloth cooldowns on every character",
})

local ROW_H = 24
local HEAD_H = 34
local CARD_GAP = 8
local BAR_W = 250

local scroll, content, emptyText, alertBox
local cards = {}

local function NewCard()
	local W = NS.Widgets
	local card = W:CreateCard(content)
	card.name = W:Label(card, "GameFontNormalLarge")
	card.name:SetPoint("TOPLEFT", 12, -9)
	card.summary = W:Label(card)
	card.summary:SetPoint("TOPRIGHT", -12, -12)
	card.summary:SetJustifyH("RIGHT")
	card.summary:SetTextColor(unpack(W.COLORS.muted))
	card.rows = {}
	return card
end

local function CardRow(card, i)
	local row = card.rows[i]
	if row then
		return row
	end
	local W = NS.Widgets
	row = CreateFrame("Frame", nil, card)
	row:SetHeight(ROW_H)
	row:SetPoint("TOPLEFT", 12, -HEAD_H - (i - 1) * ROW_H)
	row:SetPoint("RIGHT", -12, 0)
	row.group = W:Label(row, "GameFontHighlight")
	row.group:SetPoint("LEFT", 0, 0)
	row.group:SetWidth(170)
	row.prof = W:Label(row)
	row.prof:SetPoint("LEFT", 174, 0)
	row.prof:SetWidth(100)
	row.prof:SetTextColor(unpack(W.COLORS.muted))
	row.bar = W:CreateProgressBar(row, BAR_W, 8)
	row.bar:SetPoint("LEFT", 280, 0)
	row.time = W:Label(row)
	row.time:SetPoint("RIGHT", 0, 0)
	row.time:SetJustifyH("RIGHT")
	card.rows[i] = row
	return row
end

function Page:Build(f)
	local W = NS.Widgets
	scroll = CreateFrame("ScrollFrame", "JohnnysProfessionsCooldownScroll", f, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 0, 0)
	scroll:SetPoint("BOTTOMRIGHT", -24, 30)
	content = CreateFrame("Frame", nil, scroll)
	content:SetSize(NS.MainWindow.CONTENT_W - 26, 10)
	scroll:SetScrollChild(content)

	emptyText = W:Label(f, "GameFontHighlight")
	emptyText:SetPoint("TOP", 0, -60)
	emptyText:SetWidth(520)
	emptyText:SetJustifyH("CENTER")
	emptyText:SetText("No cooldown recipes known yet. Open each profession window on each character once so they can be read.")

	alertBox = NS.Skin:CreateCheckbox(f, 18, NS.db.profile.ui.cooldownAlerts, function(checked)
		NS.db.profile.ui.cooldownAlerts = checked
	end)
	alertBox:SetPoint("BOTTOMLEFT", 0, 4)
	local label = W:Label(f)
	label:SetPoint("LEFT", alertBox, "RIGHT", 6, 0)
	label:SetText("Tell me in chat at login when this character's cooldowns are ready")

	-- Countdowns tick down while the page is open.
	local elapsedSince = 0
	f:SetScript("OnUpdate", function(_, elapsed)
		elapsedSince = elapsedSince + elapsed
		if elapsedSince > 30 then
			elapsedSince = 0
			Page:Refresh()
		end
	end)
end

function Page:Refresh()
	alertBox:SetChecked(NS.db.profile.ui.cooldownAlerts)
	local now = time()

	-- Group rows by character.
	local byChar, order = {}, {}
	for name, char in pairs(NS.Characters:All()) do
		local rows = NS.Cooldowns:ForChar(name, char)
		if #rows > 0 then
			local ready = 0
			for _, r in ipairs(rows) do
				if not r.used or r.expires <= now then
					ready = ready + 1
				end
			end
			byChar[name] = { char = char, rows = rows, ready = ready }
			table.insert(order, name)
		end
	end
	table.sort(order, function(a, b)
		if (byChar[a].ready > 0) ~= (byChar[b].ready > 0) then
			return byChar[a].ready > 0
		end
		return a < b
	end)

	local y = 0
	for i, name in ipairs(order) do
		local info = byChar[name]
		local card = cards[i] or NewCard()
		cards[i] = card
		card:ClearAllPoints()
		card:SetPoint("TOPLEFT", 0, y)
		card:SetPoint("RIGHT", content, "RIGHT", 0, 0)
		local height = HEAD_H + #info.rows * ROW_H + 8
		card:SetHeight(height)
		NS.Widgets:StyleCard(card, name == NS.Characters.name)
		card.name:SetText(NS:ClassColoredName(name, info.char.class))
		card.summary:SetText(string.format("%d of %d ready", info.ready, #info.rows))

		for r, cd in ipairs(info.rows) do
			local row = CardRow(card, r)
			row.group:SetText(cd.group)
			row.prof:SetText(cd.prof)
			row.bar:SetProgress(NS.Cooldowns:Progress(cd, now), 1)
			if not cd.used then
				row.bar:SetFillColor(0.85, 0.85, 0.85)
				row.time:SetText("|cff40ff40Ready|r |cff808080(not used yet)|r")
			elseif cd.expires <= now then
				row.bar:SetFillColor(0.85, 0.85, 0.85)
				row.time:SetText("|cff40ff40Ready|r")
			else
				row.bar:SetFillColor(0.45, 0.45, 0.45)
				row.time:SetText(NS:FormatDuration(cd.expires - now))
			end
			row:Show()
		end
		for r = #info.rows + 1, #card.rows do
			card.rows[r]:Hide()
		end
		card:Show()
		y = y - height - CARD_GAP
	end
	for i = #order + 1, #cards do
		cards[i]:Hide()
	end
	content:SetHeight(math.max(1, -y))

	if #order == 0 then
		emptyText:Show()
	else
		emptyText:Hide()
	end
end
