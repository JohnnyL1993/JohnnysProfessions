-- Specializations page: profession buttons along the top, an intro card, then
-- one card per specialization with its numbered quest steps (giver, location,
-- what to bring). Data lives in Data\Specializations.lua. Each profession's
-- cards are built once and kept, so switching back and forth is free; only
-- texts that can change (item names, "Your specialization" tag) are updated
-- on refresh.
local NS = JohnnysProfessions
local Page = {}
NS.MainWindow:AddPage("Specializations", Page, {
	order = 4, label = "Specializations", icon = "Interface\\Icons\\INV_Misc_Book_11",
	title = "Specializations",
	subtitle = "Armorsmith or Weaponsmith, Gnomish or Goblin, Dragonscale, Elemental or Tribal - how to get them",
})

local PAD = 12
local STEP_INDENT = 34
local ITEM_H = 18

local holder, scroll, introCard, introIcon, introText
local profButtons = {}
local built = {}   -- prof -> { content = Frame, cards = { {frame=, tag=, spec=, items = {...}} } }
local selected

local function SpecData(prof)
	for _, entry in ipairs(NS.SPECIALIZATIONS) do
		if entry.prof == prof then
			return entry
		end
	end
end

----------------------------------------------------------------------------
-- Which specialization does this character have?
----------------------------------------------------------------------------
-- Specialization passives are listed in the spellbook (General tab), so
-- collect every spellbook spell name; IsSpellKnown is used as well where the
-- client has it.
local function KnownSpellNames()
	local known = {}
	for tab = 1, GetNumSpellTabs() do
		local _, _, offset, numSpells = GetSpellTabInfo(tab)
		for i = offset + 1, offset + numSpells do
			local name = GetSpellName(i, BOOKTYPE_SPELL)
			if name then
				known[name] = true
			end
		end
	end
	return known
end

local function HasSpec(spec, known)
	for _, id in ipairs(spec.spells or {}) do
		if IsSpellKnown and IsSpellKnown(id) then
			return true
		end
		local name = GetSpellInfo(id)
		if name and known[name] then
			return true
		end
	end
	return false
end

local function SpecIcon(spec)
	for _, id in ipairs(spec.spells or {}) do
		local _, _, icon = GetSpellInfo(id)
		if icon then
			return icon
		end
	end
end

----------------------------------------------------------------------------
-- Building one profession's cards
----------------------------------------------------------------------------
local function ItemLine(parent, item, x, y, width)
	local line = CreateFrame("Button", nil, parent)
	line:SetPoint("TOPLEFT", x, y)
	line:SetSize(width, ITEM_H)
	local icon = line:CreateTexture(nil, "ARTWORK")
	icon:SetSize(14, 14)
	icon:SetPoint("LEFT", 0, 0)
	icon:SetTexture(NS.ItemCache:Icon(item.id))
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	line.name = NS.Widgets:Label(line)
	line.name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
	line.name:SetWidth(width * 0.55)
	line.source = NS.Widgets:Label(line)
	line.source:SetPoint("RIGHT", 0, 0)
	line.source:SetWidth(width * 0.42)
	line.source:SetJustifyH("RIGHT")
	line.source:SetTextColor(unpack(NS.Widgets.COLORS.muted))
	line.source:SetText(item.source or "")
	line.item = item
	line:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink("item:" .. self.item.id)
		GameTooltip:Show()
	end)
	line:SetScript("OnLeave", function() GameTooltip:Hide() end)
	return line
end

local function SetItemText(line)
	local item = line.item
	local prefix = (item.count and item.count > 1) and (item.count .. "x ") or ""
	line.name:SetText(prefix .. NS.ItemCache:ColoredName(item.id))
end

-- Adds a wrapped font string at y; returns it and the y below it.
local function Text(parent, template, x, y, width, text, color)
	local fs = NS.Widgets:Label(parent, template)
	fs:SetPoint("TOPLEFT", x, y)
	fs:SetWidth(width)
	if color then
		fs:SetTextColor(unpack(color))
	end
	fs:SetText(text)
	return fs, y - fs:GetStringHeight()
end

local function BuildStep(card, step, number, y, width)
	local W = NS.Widgets
	local C = W.COLORS
	local numBox = W:CreateCard(card, 18, 18)
	numBox:SetPoint("TOPLEFT", PAD, y)
	local num = numBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	num:SetPoint("CENTER")
	num:SetText(number)

	local x = STEP_INDENT
	local w = width - x - PAD
	local title = W:Label(card, "GameFontHighlight")
	title:SetPoint("TOPLEFT", x, y - 2)
	title:SetText(step.title)
	local meta = {}
	if step.level then
		table.insert(meta, "level " .. step.level)
	end
	if step.req then
		table.insert(meta, step.req)
	end
	local metaText = W:Label(card)
	metaText:SetPoint("LEFT", title, "RIGHT", 8, 0)
	metaText:SetTextColor(unpack(C.muted))
	metaText:SetText(table.concat(meta, ", "))
	y = y - 20

	if step.npc then
		local where = "From |cffffffff" .. step.npc .. "|r"
		if step.zone then
			where = where .. " - " .. step.zone
		end
		if step.coords then
			where = where .. " (" .. step.coords .. ")"
		end
		local _, ny = Text(card, "GameFontHighlightSmall", x, y, w, where, C.muted)
		y = ny - 3
	end
	if step.text then
		local _, ny = Text(card, "GameFontHighlightSmall", x, y, w, step.text, { 0.85, 0.85, 0.85 })
		y = ny - 4
	end

	local lines = {}
	for _, item in ipairs(step.items or {}) do
		local line = ItemLine(card, item, x, y, w)
		table.insert(lines, line)
		y = y - ITEM_H
	end
	if step.reward then
		local line = ItemLine(card, { id = step.reward, count = 1, source = "Reward" }, x, y, w)
		table.insert(lines, line)
		y = y - ITEM_H
	end
	return y - 8, lines
end

local function BuildCard(content, spec, y, width, faction)
	local W = NS.Widgets
	local card = W:CreateCard(content)
	card:SetPoint("TOPLEFT", 0, y)
	card:SetWidth(width)

	local icon = W:CreateIcon(card, 32, SpecIcon(spec))
	icon:SetPoint("TOPLEFT", PAD, -PAD)
	local name = W:Label(card, "GameFontNormalLarge")
	name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -1)
	name:SetTextColor(1, 1, 1)
	name:SetText(spec.name)
	local summary = W:Label(card)
	summary:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
	summary:SetWidth(width - 2 * PAD - 42 - 130)
	summary:SetTextColor(unpack(W.COLORS.muted))
	summary:SetText(spec.summary or "")

	-- "Your specialization" tag, shown on refresh if this character has it.
	local tag = W:CreateCard(card, 124, 18, true)
	tag:SetPoint("TOPRIGHT", -PAD, -PAD)
	local tagText = tag:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	tagText:SetPoint("CENTER")
	tagText:SetText("Your specialization")
	tag:Hide()

	local cy = -PAD - 32 - math.max(0, summary:GetStringHeight() - 12) - 10
	local divider = card:CreateTexture(nil, "ARTWORK")
	divider:SetTexture(NS.Skin.WHITE)
	divider:SetVertexColor(0.2, 0.2, 0.2, 1)
	divider:SetPoint("TOPLEFT", PAD, cy)
	divider:SetPoint("TOPRIGHT", -PAD, cy)
	divider:SetHeight(1)
	cy = cy - 10

	local items = {}
	local n = 0
	for _, step in ipairs(spec.steps or {}) do
		if not step.faction or step.faction == faction then
			n = n + 1
			local lines
			cy, lines = BuildStep(card, step, n, cy, width)
			for _, l in ipairs(lines) do
				table.insert(items, l)
			end
		end
	end

	local height = -cy + 2
	card:SetHeight(height)
	return { frame = card, tag = tag, spec = spec, items = items }, height
end

local function BuildProfession(prof)
	local data = SpecData(prof)
	local content = CreateFrame("Frame", nil, scroll)
	local width = scroll:GetWidth()
	if not width or width < 200 then
		width = NS.MainWindow.CONTENT_W - 24
	end
	content:SetWidth(width)
	local faction = UnitFactionGroup("player")
	local cards = {}
	local y = 0
	for _, spec in ipairs(data.specs) do
		local card, h = BuildCard(content, spec, y, width, faction)
		table.insert(cards, card)
		y = y - h - 10
	end
	content:SetHeight(math.max(1, -y))
	content:Hide()
	built[prof] = { content = content, cards = cards }
	return built[prof]
end

----------------------------------------------------------------------------
-- Page
----------------------------------------------------------------------------
local function DefaultProf()
	local skills = NS.Characters:Me().skills
	for _, entry in ipairs(NS.SPECIALIZATIONS) do
		if skills[entry.prof] then
			return entry.prof
		end
	end
	return NS.SPECIALIZATIONS[1].prof
end

function Page:Build(f)
	local W = NS.Widgets
	holder = f

	for i, entry in ipairs(NS.SPECIALIZATIONS) do
		local b = NS.Skin:CreateButton(f, 124, 22, entry.prof)
		b:SetPoint("TOPLEFT", (i - 1) * 130, 0)
		b:SetScript("OnClick", function()
			selected = entry.prof
			Page:Refresh()
		end)
		profButtons[entry.prof] = b
	end

	introCard = W:CreateCard(f)
	introCard:SetPoint("TOPLEFT", 0, -32)
	introCard:SetPoint("RIGHT", 0, 0)
	introCard:SetHeight(56)
	introIcon = W:CreateIcon(introCard, 32)
	introIcon:SetPoint("LEFT", PAD, 0)
	introText = W:Label(introCard)
	introText:SetPoint("LEFT", introIcon, "RIGHT", 12, 0)
	introText:SetTextColor(0.85, 0.85, 0.85)

	scroll = CreateFrame("ScrollFrame", "JohnnysProfessionsSpecScroll", f, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 0, -98)
	scroll:SetPoint("BOTTOMRIGHT", -24, 0)
end

function Page:Refresh()
	if not selected or not SpecData(selected) then
		selected = DefaultProf()
	end
	for prof, b in pairs(profButtons) do
		NS.Widgets:SetSelected(b, prof == selected)
	end

	local data = SpecData(selected)
	local p = NS.PROF_BY_KEY[selected]
	introIcon:SetIcon(p and p.icon)
	-- Explicit width so the text wraps (anchor-only width stays one line).
	local cardW = introCard:GetWidth()
	if not cardW or cardW < 200 then
		cardW = NS.MainWindow.CONTENT_W - 24
	end
	introText:SetWidth(cardW - PAD - 32 - 12 - PAD)
	introText:SetText(data.intro or "")
	introCard:SetHeight(math.max(56, introText:GetStringHeight() + 2 * PAD))
	scroll:ClearAllPoints()
	scroll:SetPoint("TOPLEFT", 0, -32 - introCard:GetHeight() - 10)
	scroll:SetPoint("BOTTOMRIGHT", -24, 0)

	local view = built[selected] or BuildProfession(selected)
	for prof, v in pairs(built) do
		if prof ~= selected then
			v.content:Hide()
		end
	end
	if scroll:GetScrollChild() ~= view.content then
		scroll:SetScrollChild(view.content)
		scroll:SetVerticalScroll(0)
	end
	view.content:Show()
	scroll:UpdateScrollChildRect()

	local known = KnownSpellNames()
	for _, card in ipairs(view.cards) do
		local has = HasSpec(card.spec, known)
		if has then
			card.tag:Show()
		else
			card.tag:Hide()
		end
		NS.Widgets:StyleCard(card.frame, has)
		for _, line in ipairs(card.items) do
			SetItemText(line)
		end
	end
end
