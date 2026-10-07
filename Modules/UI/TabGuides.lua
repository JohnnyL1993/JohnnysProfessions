-- Professions page: Gathering / Crafting toggle, a card per profession, a
-- header card for the selected one (rank bar, current step, trainer hint,
-- buttons) and the leveling route as a list of step cards. The current step
-- (or whichever step you click) is expanded with materials have/need.
-- Click a step's tick box to skip it (and again to bring it back); gathering
-- steps get a button per zone that opens the world map there.
local NS = JohnnysProfessions
local Page = {}
NS.MainWindow:AddPage("Professions", Page, {
	order = 3, label = "Professions", icon = "Interface\\Icons\\Trade_BlackSmithing",
	title = "Professions", subtitle = "Level every gathering and crafting profession, step by step",
})

local GROUPS = {
	Gathering = { "Mining", "Herbalism", "Skinning", "Fishing" },
	Crafting = {
		"Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Inscription",
		"Jewelcrafting", "Leatherworking", "Tailoring", "Cooking", "First Aid",
	},
}
local GROUP_OF = {}
for group, list in pairs(GROUPS) do
	for _, key in ipairs(list) do
		GROUP_OF[key] = group
	end
end

local CHECK = "Interface\\Buttons\\UI-CheckBox-Check"
local CARD_H = 34
local CARD_GAP = 6
local HEADER_H = 88
local ROW_H = 36
local ROW_GAP = 4
local MAT_W = 150
local MAX_MATS = 10

local W, Skin
local holder, contentW
local groupButtons = {}
local profCards = {}
local header = {}
local scroll, content
local rows = {}
local group
local lastProf, expanded, lastCur
local HideZones

----------------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------------
local function SelectedProf()
	local prof = NS.db.profile.ui.guide
	if prof and NS.Guide:Has(prof) then
		return prof
	end
	local mine = NS.Guide:MyGuidedProfessions()
	if mine[1] then
		return mine[1]
	end
	return "Mining"
end

local function Skill(prof)
	return NS.Characters:Me().skills[prof]
end

local function Grey(text)
	return "|cff9e9e9e" .. text .. "|r"
end

local function StepIcon(step, prof)
	if step.zones or step.title then
		return NS.PROF_BY_KEY[prof].icon
	end
	local product = NS.Guide:Product(step)
	if product then
		return NS.ItemCache:Icon(product)
	end
	local spell = NS.Guide:SpellFor(step)
	local icon = spell and select(3, GetSpellInfo(spell))
	return icon or NS.PROF_BY_KEY[prof].icon
end

local function MatsSummary(step)
	local parts = {}
	for id, n in pairs(NS.Guide:Reagents(step)) do
		table.insert(parts, n .. "x " .. NS.ItemCache:Name(id))
	end
	table.sort(parts)
	return table.concat(parts, ", ")
end

local function SubText(step)
	if step.zones then
		return NS.Guide:ZoneText(step) or ""
	end
	return MatsSummary(step)
end

----------------------------------------------------------------------------
-- Profession cards
----------------------------------------------------------------------------
local function NewProfCard()
	local card = CreateFrame("Button", nil, holder)
	W:StyleCard(card)
	local hl = card:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 1, -1)
	hl:SetPoint("BOTTOMRIGHT", -1, 1)
	hl:SetTexture(Skin.WHITE)
	hl:SetVertexColor(1, 1, 1, 0.06)
	card.icon = W:CreateIcon(card, 24)
	card.icon:SetPoint("LEFT", 5, 0)
	card.name = W:Label(card, "GameFontHighlight")
	card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 7, 1)
	card.name:SetPoint("RIGHT", -4, 0)
	card.sub = W:Label(card)
	card.sub:SetPoint("BOTTOMLEFT", card.icon, "BOTTOMRIGHT", 7, -1)
	card.sub:SetPoint("RIGHT", -4, 0)
	card:SetScript("OnClick", function(self)
		NS.db.profile.ui.guide = self.prof
		Page:Refresh()
	end)
	return card
end

-- Lays out the cards for the current group; returns the height used.
local function LayoutProfCards(selected)
	local list = GROUPS[group]
	local perRow = math.min(#list, 5)
	local cardW = math.floor((contentW - (perRow - 1) * CARD_GAP) / perRow)
	for i, key in ipairs(list) do
		local card = profCards[i] or NewProfCard()
		profCards[i] = card
		local col = (i - 1) % perRow
		local rowIndex = math.floor((i - 1) / perRow)
		card:ClearAllPoints()
		card:SetPoint("TOPLEFT", col * (cardW + CARD_GAP), -28 - rowIndex * (CARD_H + CARD_GAP))
		card:SetSize(cardW, CARD_H)
		card.prof = key
		local s = Skill(key)
		card.icon:SetIcon(NS.PROF_BY_KEY[key].icon, not s)
		card.name:SetText(key)
		if s then
			card.name:SetTextColor(1, 1, 1)
			card.sub:SetText(string.format("%d / %d", s.rank, s.max))
			card.sub:SetTextColor(0.75, 0.75, 0.75)
		else
			card.name:SetTextColor(0.6, 0.6, 0.6)
			card.sub:SetText("Not learned")
			card.sub:SetTextColor(0.42, 0.42, 0.42)
		end
		W:StyleCard(card, key == selected)
		card:Show()
	end
	for i = #list + 1, #profCards do
		profCards[i]:Hide()
	end
	local numRows = math.ceil(#list / perRow)
	return 28 + numRows * CARD_H + (numRows - 1) * CARD_GAP
end

----------------------------------------------------------------------------
-- Header card
----------------------------------------------------------------------------
local function BuildHeader()
	local card = W:CreateCard(holder, contentW, HEADER_H)
	header.card = card
	header.icon = W:CreateIcon(card, 44)
	header.icon:SetPoint("TOPLEFT", 10, -10)

	header.name = W:Label(card, "GameFontNormalLarge")
	header.name:SetPoint("TOPLEFT", header.icon, "TOPRIGHT", 10, 0)
	header.name:SetTextColor(1, 1, 1)
	header.rankName = W:Label(card)
	header.rankName:SetPoint("BOTTOMLEFT", header.name, "BOTTOMRIGHT", 8, 1)
	header.rankName:SetTextColor(unpack(W.COLORS.muted))

	header.bar = W:CreateProgressBar(card, 220, 8)
	header.bar:SetPoint("TOPLEFT", header.name, "BOTTOMLEFT", 0, -6)
	header.barText = W:Label(card)
	header.barText:SetPoint("LEFT", header.bar, "RIGHT", 8, 0)

	header.now = W:Label(card)
	header.now:SetPoint("TOPLEFT", 10, -60)
	header.now:SetPoint("RIGHT", card, "RIGHT", -150, 0)
	header.hint = W:Label(card)
	header.hint:SetPoint("TOPLEFT", header.now, "BOTTOMLEFT", 0, -3)
	header.hint:SetPoint("RIGHT", card, "RIGHT", -150, 0)

	header.track = Skin:CreateButton(card, 126, 22, "Track mats")
	header.track:SetPoint("TOPRIGHT", -10, -10)
	header.track:SetScript("OnClick", function()
		local prof = SelectedProf()
		local n = NS.Tracker:TrackShoppingList(NS.Guide:ShoppingList({ prof }))
		NS:Print(string.format("Tracking %d item(s) for %s.", n, prof))
		NS.TrackerWindow:Show()
	end)
	header.mini = Skin:CreateButton(card, 126, 22, "Mini-guide")
	header.mini:SetPoint("TOPRIGHT", header.track, "BOTTOMRIGHT", 0, -4)
	header.mini:SetScript("OnClick", function()
		NS.MiniGuide:ShowFor(SelectedProf())
	end)
	header.cost = W:Label(card)
	header.cost:SetPoint("BOTTOMRIGHT", -10, 8)
	header.cost:SetJustifyH("RIGHT")
end

local function RefreshHeader(prof, steps, cur)
	local s = Skill(prof)
	local rank = s and s.rank or 0
	header.icon:SetIcon(NS.PROF_BY_KEY[prof].icon, not s)
	header.name:SetText(prof)
	if s then
		local _, r = NS:RankForCap(s.max)
		header.rankName:SetText(r and r.name or "")
		header.bar:SetProgress(rank, s.max)
		local gained, perHour = NS.StepAlerts:Rate(prof)
		local rate = ""
		if gained > 0 then
			rate = Grey(string.format("   +%d this session", gained))
			if perHour then
				rate = rate .. Grey(string.format(" (%d/hour)", math.floor(perHour + 0.5)))
			end
		end
		header.barText:SetText(string.format("%d / %d", rank, s.max) .. rate)
		header.hint:SetText(NS:TrainerHint(rank, s.max, UnitLevel("player"), prof) or "")
		header.track:Show()
	else
		header.rankName:SetText("Not learned")
		header.bar:SetProgress(0, 75)
		header.barText:SetText(Grey("0 / 75"))
		header.hint:SetText(Grey("Learn Apprentice " .. prof .. " from a trainer to start."))
		header.track:Hide()
	end

	local step = cur and steps[cur]
	if step then
		local sub = SubText(step)
		header.now:SetText("|cffffffffNow:|r " .. NS.Guide:StepName(step) .. (sub ~= "" and Grey(" - " .. sub) or ""))
	else
		header.now:SetText("|cffffffffGuide complete.|r")
	end

	-- Cost of everything still short for this profession.
	if s then
		local total, unknown = 0, 0
		for _, entry in ipairs(NS.Guide:ShoppingList({ prof })) do
			if entry.short > 0 then
				local each = NS.Prices:GetCost(entry.id)
				if each then
					total = total + each * entry.short
				else
					unknown = unknown + 1
				end
			end
		end
		local text = Grey("Still to buy: ") .. NS:FormatMoney(total)
		if unknown > 0 then
			text = text .. Grey(string.format(" (+%d unpriced)", unknown))
		end
		header.cost:SetText(text)
	else
		header.cost:SetText("")
	end
end

----------------------------------------------------------------------------
-- Step rows
----------------------------------------------------------------------------
local function MatOnEnter(self)
	if self.itemID then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink("item:" .. self.itemID)
		GameTooltip:Show()
	end
end

local function HideTooltip()
	GameTooltip:Hide()
end

local function NewMat(row)
	local m = CreateFrame("Frame", nil, row)
	m:SetSize(MAT_W - 6, 20)
	m:EnableMouse(true)
	m.icon = W:CreateIcon(m, 20)
	m.icon:SetPoint("LEFT")
	m.icon:EnableMouse(false)
	m.text = W:Label(m)
	m.text:SetPoint("LEFT", m.icon, "RIGHT", 4, 0)
	m.text:SetPoint("RIGHT")
	m:SetScript("OnEnter", MatOnEnter)
	m:SetScript("OnLeave", HideTooltip)
	return m
end

local function NewRow()
	local row = CreateFrame("Button", nil, content)
	W:StyleCard(row)
	local hl = row:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 1, -1)
	hl:SetPoint("BOTTOMRIGHT", -1, 1)
	hl:SetTexture(Skin.WHITE)
	hl:SetVertexColor(1, 1, 1, 0.05)

	row.tick = CreateFrame("Button", nil, row)
	row.tick:SetSize(14, 14)
	row.tick:SetScript("OnClick", function(self)
		NS.Guide:ToggleSkip(SelectedProf(), self:GetParent().index)
		Page:Refresh()
	end)
	row.tick:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if NS.Guide:IsSkipped(SelectedProf(), self:GetParent().index) then
			GameTooltip:AddLine("Skipped - click to bring this step back")
		else
			GameTooltip:AddLine("Click to skip this step")
		end
		GameTooltip:Show()
	end)
	row.tick:SetScript("OnLeave", function() GameTooltip:Hide() end)
	row.tick:SetBackdrop({ bgFile = Skin.WHITE, edgeFile = Skin.WHITE, edgeSize = 1 })
	row.tick:SetBackdropColor(0, 0, 0, 1)
	row.tick:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
	row.check = row.tick:CreateTexture(nil, "OVERLAY")
	row.check:SetSize(20, 20)
	row.check:SetPoint("CENTER", 1, 0)
	row.check:SetTexture(CHECK)
	row.check:SetDesaturated(true)

	row.icon = W:CreateIcon(row, 24)
	row.icon:EnableMouse(false)
	row.tag = W:Label(row, "GameFontNormalSmall")
	row.name = W:Label(row, "GameFontHighlight")
	row.sub = W:Label(row)
	row.sub:SetHeight(12)
	row.range = W:Label(row)
	row.range:SetJustifyH("RIGHT")
	row.range:SetPoint("TOPRIGHT", -10, -12)
	row.detail = W:Label(row)
	row.note = W:Label(row)
	row.note:SetJustifyV("TOP")
	row.mats = {}
	row.zones = {}

	row:SetScript("OnClick", function(self)
		if expanded == self.index then
			expanded = -1 -- everything collapsed until the step changes
		else
			expanded = self.index
		end
		Page:Refresh()
	end)
	return row
end

local function HideMats(row, from)
	for m = from, #row.mats do
		row.mats[m]:Hide()
	end
end

HideZones = function(row, from)
	for z = from, #row.zones do
		row.zones[z]:Hide()
	end
end

-- Buttons per map zone named in `text`, laid out from y down; returns the
-- height they took.
local function LayoutZones(row, text, y, width)
	local zones = NS.Guide:ZonesIn(text)
	local x, line = 0, 0
	for z, name in ipairs(zones) do
		local b = row.zones[z]
		if not b then
			b = Skin:CreateButton(row, 10, 18)
			b:SetScript("OnClick", function(self) NS.Guide:OpenMap(self.zone) end)
			row.zones[z] = b
		end
		b.zone = name
		b.text:SetText(name)
		local w = b.text:GetStringWidth() + 16
		b:SetWidth(w)
		if x > 0 and x + w > width then
			x, line = 0, line + 1
		end
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", 32 + x, -(y + line * 22))
		b:Show()
		x = x + w + 6
	end
	HideZones(row, #zones + 1)
	if #zones == 0 then
		return 0
	end
	return (line + 1) * 22 + 4
end

-- Fills a collapsed row; returns its height.
local function FillCollapsed(row, step, prof, done, skipped)
	row.tick:ClearAllPoints()
	row.tick:SetPoint("LEFT", 10, 0)
	row.icon:ClearAllPoints()
	row.icon:SetSize(24, 24)
	row.icon:SetPoint("LEFT", 32, 0)
	row.icon:SetIcon(StepIcon(step, prof), done)

	row.tag:Hide()
	row.detail:Hide()
	row.note:Hide()
	HideMats(row, 1)

	row.name:ClearAllPoints()
	row.name:SetPoint("TOPLEFT", 64, -5)
	row.name:SetPoint("RIGHT", row, "RIGHT", -90, 0)
	row.name:SetText(NS.Guide:StepName(step))
	row.sub:ClearAllPoints()
	row.sub:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
	row.sub:SetPoint("RIGHT", row, "RIGHT", -90, 0)
	row.sub:SetText(Grey(skipped and "Skipped" or SubText(step)))
	row.sub:Show()
	HideZones(row, 1)
	return ROW_H
end

-- Fills an expanded row (the current step or the one clicked); returns height.
local function FillExpanded(row, step, prof, rank, isCurrent, done, skipped)
	local width = contentW - 24
	row.tick:ClearAllPoints()
	row.tick:SetPoint("TOPLEFT", 10, -12)
	row.icon:ClearAllPoints()
	row.icon:SetSize(34, 34)
	row.icon:SetPoint("TOPLEFT", 32, -8)
	row.icon:SetIcon(StepIcon(step, prof), done)

	local tag = string.format("SKILL %d - %d", step.from, step.to)
	if isCurrent then
		tag = tag .. "   |cffffffffYOU ARE HERE|r"
	elseif done then
		tag = tag .. "   DONE"
	elseif skipped then
		tag = tag .. "   SKIPPED"
	end
	row.tag:ClearAllPoints()
	row.tag:SetPoint("TOPLEFT", 76, -8)
	row.tag:SetText(tag)
	row.tag:SetTextColor(unpack(W.COLORS.muted))
	row.tag:Show()

	row.name:ClearAllPoints()
	row.name:SetPoint("TOPLEFT", row.tag, "BOTTOMLEFT", 0, -3)
	row.name:SetPoint("RIGHT", row, "RIGHT", -90, 0)
	row.name:SetText(NS.Guide:StepName(step))
	row.sub:Hide()

	local y = 48 -- below the icon
	local detail
	if step.zones then
		detail = NS.Guide:ZoneText(step) or ""
	elseif step.count and step.count > 0 then
		local left = NS.Guide:CraftsLeft(step, rank)
		detail = string.format("Make about %d%s", left, done and "" or " more")
		local diff = NS.Guide:DifficultyText(step, rank)
		if diff then
			detail = detail .. "  -  currently " .. diff
		end
		local made = NS.Guide:Made(step)
		if made ~= 1 then
			detail = detail .. Grey(string.format("  (makes %s each)", made))
		end
	end
	if detail and detail ~= "" then
		row.detail:ClearAllPoints()
		row.detail:SetPoint("TOPLEFT", 32, -y)
		row.detail:SetWidth(width - 44)
		row.detail:SetText(detail)
		row.detail:Show()
		y = y + row.detail:GetStringHeight() + 6
	else
		row.detail:Hide()
	end
	if step.zones then
		y = y + LayoutZones(row, detail, y, width - 44)
	else
		HideZones(row, 1)
	end

	-- Materials still needed for this step, with what you hold.
	local n = 0
	if not step.zones then
		local mats = {}
		local need = NS.Guide:StepMats(step, done and step.from or rank)
		for id, count in pairs(need) do
			table.insert(mats, { id = id, need = count })
		end
		table.sort(mats, function(a, b) return a.id < b.id end)
		local perLine = math.max(1, math.floor((width - 44) / MAT_W))
		for i = 1, math.min(#mats, MAX_MATS) do
			n = i
			local e = mats[i]
			local m = row.mats[i] or NewMat(row)
			row.mats[i] = m
			local col = (i - 1) % perLine
			local line = math.floor((i - 1) / perLine)
			m:ClearAllPoints()
			m:SetPoint("TOPLEFT", 32 + col * MAT_W, -(y + line * 24))
			m.itemID = e.id
			m.icon:SetIcon(NS.ItemCache:Icon(e.id))
			local have = NS.Characters:MyCount(e.id)
			local color = have >= e.need and "|cff40ff40" or "|cffff6060"
			m.text:SetText(string.format("%s%d/%d|r %s", color, have, e.need, NS.ItemCache:Name(e.id)))
			m:Show()
		end
		if n > 0 then
			y = y + math.ceil(n / perLine) * 24 + 4
		end
	end
	HideMats(row, n + 1)

	if step.note then
		row.note:ClearAllPoints()
		row.note:SetPoint("TOPLEFT", 32, -y)
		row.note:SetWidth(width - 44)
		row.note:SetText(Grey(step.note))
		row.note:Show()
		y = y + row.note:GetStringHeight() + 4
	else
		row.note:Hide()
	end
	return math.max(56, y + 8)
end

local function RefreshSteps(prof, steps, cur, rank)
	local y = 0
	local curY
	for i, step in ipairs(steps) do
		local row = rows[i] or NewRow()
		rows[i] = row
		row.index = i
		local done = rank >= step.to
		local skipped = NS.Guide:IsSkipped(prof, i)
		local isCurrent = (i == cur)
		local h
		if i == expanded then
			h = FillExpanded(row, step, prof, rank, isCurrent, done, skipped)
		else
			h = FillCollapsed(row, step, prof, done, skipped)
		end
		if done or skipped then
			row.check:Show()
			row.check:SetAlpha(skipped and not done and 0.45 or 1)
		else
			row.check:Hide()
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, -y)
		row:SetSize(contentW - 24, h)
		W:StyleCard(row, isCurrent)
		row.range:SetText(string.format("%d - %d", step.from, step.to))
		row:SetAlpha(((done or skipped) and i ~= expanded) and 0.5 or 1)
		row:Show()
		if isCurrent then
			curY = y
		end
		y = y + h + ROW_GAP
	end
	for i = #steps + 1, #rows do
		rows[i]:Hide()
	end
	content:SetHeight(math.max(1, y))
	return curY
end

----------------------------------------------------------------------------
-- Page
----------------------------------------------------------------------------
function Page:Build(f)
	W, Skin = NS.Widgets, NS.Skin
	holder = f
	contentW = NS.MainWindow.CONTENT_W

	local x = 0
	for _, g in ipairs({ "Gathering", "Crafting" }) do
		local b = Skin:CreateButton(f, 100, 22, g)
		b:SetPoint("TOPLEFT", x, 0)
		b:SetScript("OnClick", function()
			group = g
			-- Switch to the first learned profession in that group, if any.
			local skills = NS.Characters:Me().skills
			local pick = GROUPS[g][1]
			for _, key in ipairs(GROUPS[g]) do
				if skills[key] then
					pick = key
					break
				end
			end
			if GROUP_OF[SelectedProf()] ~= g then
				NS.db.profile.ui.guide = pick
			end
			Page:Refresh()
		end)
		groupButtons[g] = b
		x = x + 104
	end
	local hint = W:Label(f)
	hint:SetPoint("TOPRIGHT", 0, -6)
	hint:SetJustifyH("RIGHT")
	hint:SetTextColor(unpack(W.COLORS.dim))
	hint:SetText("Click a step to open it - tick its box to skip it")

	BuildHeader()

	scroll = CreateFrame("ScrollFrame", "JohnnysProfessionsStepScroll", f, "UIPanelScrollFrameTemplate")
	content = CreateFrame("Frame", nil, scroll)
	content:SetSize(contentW - 24, 10)
	scroll:SetScrollChild(content)
end

function Page:Refresh()
	local prof = SelectedProf()
	if not group or GROUP_OF[prof] ~= group then
		group = GROUP_OF[prof] or "Crafting"
	end
	for g, b in pairs(groupButtons) do
		W:SetSelected(b, g == group)
	end

	local cardsH = LayoutProfCards(prof)
	header.card:ClearAllPoints()
	header.card:SetPoint("TOPLEFT", 0, -(cardsH + 8))
	scroll:ClearAllPoints()
	scroll:SetPoint("TOPLEFT", 0, -(cardsH + 8 + HEADER_H + 8))
	scroll:SetPoint("BOTTOMRIGHT", -24, 0)

	local s = Skill(prof)
	local rank = s and s.rank or 0
	local steps = NS.Guide:GetSteps(prof) or {}
	local cur = NS.Guide:CurrentIndex(steps, rank)

	-- New profession, or moved on to the next step: open the current one.
	if prof ~= lastProf or cur ~= lastCur then
		expanded = cur
	end
	lastCur = cur

	RefreshHeader(prof, steps, cur)
	local curY = RefreshSteps(prof, steps, cur, rank)

	-- Scroll the current step into view the first time a profession is shown.
	if prof ~= lastProf then
		lastProf = prof
		scroll:UpdateScrollChildRect()
		local target = math.max(0, (curY or 0) - ROW_H - ROW_GAP)
		scroll:SetVerticalScroll(math.min(target, scroll:GetVerticalScrollRange()))
	end
end
