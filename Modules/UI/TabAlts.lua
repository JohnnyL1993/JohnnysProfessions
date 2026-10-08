-- Alts page: every character on this realm as a card (sortable, hideable),
-- a table of everyone's professions, materials one character holds that
-- another one's guides need, and what the account is worth (gold plus
-- materials at AH prices). Shift-right-click a card to forget a deleted
-- character.
local NS = JohnnysProfessions
local Page = {}
NS.MainWindow:AddPage("Alts", Page, {
	order = 2, label = "Alts", icon = "Interface\\Icons\\INV_Misc_GroupNeedMore",
	title = "Alts", subtitle = "Every character on this realm",
})

local CARD_H = 112
local CARD_GAP = 8
local TABLE_ROW = 20
local TABLE_NAME_W = 140
local TABLE_COL_W = 62
local SHARE_ROW = 20
local MAX_SHARE = 40

local TABLE_ICON = 16

local function HighestSkill(char)
	local best = 0
	for _, s in pairs(char.skills or {}) do
		if s.rank > best then
			best = s.rank
		end
	end
	return best
end

local SORTS = {
	{ label = "Name", fn = function(a, b) return a.name < b.name end },
	{ label = "Level", fn = function(a, b)
		if (a.char.level or 0) ~= (b.char.level or 0) then
			return (a.char.level or 0) > (b.char.level or 0)
		end
		return a.name < b.name
	end },
	{ label = "Gold", fn = function(a, b) return (a.char.money or 0) > (b.char.money or 0) end },
	{ label = "Skill", fn = function(a, b)
		local sa, sb = HighestSkill(a.char), HighestSkill(b.char)
		if sa ~= sb then
			return sa > sb
		end
		return a.name < b.name
	end },
}

local sortIndex = 1
local showHidden = false
local sortButtons = {}
local hiddenButton, worthText
local scroll, content
local cards, tableRows, tableHeads, shareRows = {}, {}, {}, {}
local titles = {}

local function Hidden()
	local r = NS:RealmDB()
	r.hiddenChars = r.hiddenChars or {}
	return r.hiddenChars
end

----------------------------------------------------------------------------
-- Data
----------------------------------------------------------------------------
local function Characters()
	local list = {}
	local hidden = Hidden()
	for name, char in pairs(NS.Characters:All()) do
		if showHidden or not hidden[name] then
			table.insert(list, { name = name, char = char, hidden = hidden[name] })
		end
	end
	table.sort(list, SORTS[sortIndex].fn)
	return list
end

-- What this character's guides still need: raw[itemID] = total, short[itemID]
-- = total minus own stock (only when > 0), forProf[itemID] = profession.
local function Needs(char)
	local raw, short, forProf = {}, {}, {}
	for prof, s in pairs(char.skills or {}) do
		if NS.Guide:Has(prof) then
			for id, n in pairs(NS.Guide:RemainingMats(prof, s.rank)) do
				raw[id] = (raw[id] or 0) + n
				forProf[id] = forProf[id] or prof
			end
		end
	end
	for id, n in pairs(raw) do
		local missing = n - NS.Characters:Count(char, id)
		if missing > 0 then
			short[id] = missing
		end
	end
	return raw, short, forProf
end

-- { holder=, needer=, id=, count=, prof= } - stock one character has spare
-- (beyond their own guides) that another character's guides need.
local function ShareList(chars)
	local raws, needs, profs, spare = {}, {}, {}, {}
	for _, c in ipairs(chars) do
		raws[c.name], needs[c.name], profs[c.name] = Needs(c.char)
	end
	local list = {}
	for _, needer in ipairs(chars) do
		for id, short in pairs(needs[needer.name]) do
			for _, holder in ipairs(chars) do
				if short <= 0 or #list >= MAX_SHARE then
					break
				end
				if holder ~= needer then
					local key = holder.name .. ":" .. id
					if spare[key] == nil then
						-- Spare = what they hold minus what their own guides use.
						local own = raws[holder.name][id] or 0
						spare[key] = math.max(0, NS.Characters:Count(holder.char, id) - own)
					end
					local give = math.min(short, spare[key])
					if give > 0 then
						spare[key] = spare[key] - give
						short = short - give
						table.insert(list, { holder = holder, needer = needer, id = id, count = give, prof = profs[needer.name][id] })
					end
				end
			end
		end
	end
	table.sort(list, function(a, b)
		if a.needer.name ~= b.needer.name then
			return a.needer.name < b.needer.name
		end
		return a.id < b.id
	end)
	return list
end

local function AccountWorth()
	local gold, mats = 0, 0
	for _, char in pairs(NS.Characters:All()) do
		gold = gold + (char.money or 0)
		for _, store in ipairs({ char.bags, char.bank, char.mail }) do
			for id, n in pairs(store or {}) do
				local each = NS.Prices:GetWorth(id)
				if each then
					mats = mats + each * n
				end
			end
		end
	end
	return gold + mats, gold, mats
end

----------------------------------------------------------------------------
-- Cards
----------------------------------------------------------------------------
local function CardTooltip(card)
	local char = card.char
	GameTooltip:SetOwner(card, "ANCHOR_RIGHT")
	GameTooltip:AddLine(NS:ClassColoredName(card.name, char.class))
	GameTooltip:AddLine(string.format("Level %d %s", char.level or 0, char.faction or ""), 0.8, 0.8, 0.8)
	for _, p in ipairs(NS.PROFESSIONS) do
		local s = char.skills and char.skills[p.key]
		if s then
			GameTooltip:AddDoubleLine(p.key, string.format("%d / %d", s.rank, s.max), 1, 1, 1, 0.8, 0.8, 0.8)
		end
	end
	if char.lastSeen then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Last seen " .. date("%d %b %Y", char.lastSeen), 0.6, 0.6, 0.6)
	end
	if card.name ~= NS.Characters.name then
		GameTooltip:AddLine("Shift-right-click to forget this character.", 0.6, 0.6, 0.6)
	end
	GameTooltip:Show()
end

local function NewCard()
	local W = NS.Widgets
	local card = CreateFrame("Button", nil, content)
	W:StyleCard(card)
	card:SetHeight(CARD_H)
	card:RegisterForClicks("RightButtonUp")
	card.nameText = W:Label(card, "GameFontNormalLarge")
	card.nameText:SetPoint("TOPLEFT", 10, -8)
	card.info = W:Label(card)
	card.info:SetPoint("TOPLEFT", card.nameText, "BOTTOMLEFT", 0, -2)
	card.info:SetTextColor(unpack(W.COLORS.muted))
	card.gold = W:Label(card)
	card.gold:SetPoint("TOPRIGHT", -10, -10)
	card.gold:SetJustifyH("RIGHT")
	card.profs = {}
	for i = 1, 2 do
		local line = CreateFrame("Frame", nil, card)
		line:SetHeight(16)
		line:SetPoint("TOPLEFT", 10, -46 - (i - 1) * 19)
		line:SetPoint("RIGHT", -10, 0)
		line.icon = W:CreateIcon(line, 14, nil, false)
		line.icon:SetPoint("LEFT", 0, 0)
		line.name = W:Label(line)
		line.name:SetPoint("LEFT", 20, 0)
		line.name:SetWidth(100)
		line.bar = W:CreateProgressBar(line, 110, 6)
		line.bar:SetPoint("LEFT", 124, 0)
		line.rank = W:Label(line)
		line.rank:SetPoint("RIGHT", 0, 0)
		line.rank:SetJustifyH("RIGHT")
		card.profs[i] = line
	end
	card.divider = card:CreateTexture(nil, "ARTWORK")
	card.divider:SetTexture(NS.Skin.WHITE)
	card.divider:SetVertexColor(0.2, 0.2, 0.2, 1)
	card.divider:SetPoint("TOPLEFT", 10, -84)
	card.divider:SetPoint("TOPRIGHT", -10, -84)
	card.divider:SetHeight(1)
	-- Secondary skills: icon + rank, side by side (names are in the tooltip).
	card.secondary = {}
	for i = 1, 3 do
		local s = CreateFrame("Frame", nil, card)
		s:SetSize(64, 16)
		s:SetPoint("BOTTOMLEFT", 10 + (i - 1) * 70, 7)
		s.icon = W:CreateIcon(s, 16, nil, false)
		s.icon:SetPoint("LEFT", 0, 0)
		s.rank = W:Label(s)
		s.rank:SetPoint("LEFT", s.icon, "RIGHT", 5, 0)
		s.rank:SetTextColor(0.82, 0.82, 0.82)
		card.secondary[i] = s
	end
	card.hide = NS.Skin:CreateButton(card, 50, 16, "Hide")
	card.hide:SetPoint("BOTTOMRIGHT", -8, 6)
	card.hide:SetScript("OnClick", function(self)
		local c = self:GetParent()
		Hidden()[c.name] = (not Hidden()[c.name]) or nil
		Page:Refresh()
	end)
	card:SetScript("OnEnter", CardTooltip)
	card:SetScript("OnLeave", GameTooltip_Hide)
	card:SetScript("OnClick", function(self)
		if IsShiftKeyDown() and self.name ~= NS.Characters.name then
			NS.Characters:All()[self.name] = nil
			Hidden()[self.name] = nil
			NS:Print("Forgot " .. self.name .. ".")
			Page:Refresh()
		end
	end)
	return card
end

local function FillCard(card, entry)
	local char = entry.char
	card.name, card.char = entry.name, char
	NS.Widgets:StyleCard(card, entry.name == NS.Characters.name)
	card.nameText:SetText(NS:ClassColoredName(entry.name, char.class))
	card.info:SetText(string.format("Level %d %s", char.level or 0, char.faction or ""))
	card.gold:SetText(NS:FormatMoney(char.money or 0))
	local primaries, secondary = {}, {}
	for _, p in ipairs(NS.PROFESSIONS) do
		local s = char.skills and char.skills[p.key]
		if s then
			if p.secondary then
				table.insert(secondary, { p = p, s = s })
			else
				table.insert(primaries, { p = p, s = s })
			end
		end
	end
	for i, line in ipairs(card.profs) do
		local e = primaries[i]
		if e then
			line.icon:SetIcon(e.p.icon, false)
			line.name:SetText(e.p.key)
			line.bar:SetProgress(e.s.rank, e.s.max)
			line.rank:SetText(string.format("%d / %d", e.s.rank, e.s.max))
			line:Show()
		elseif i == 1 then
			line.icon:SetIcon(nil, true)
			line.name:SetText("|cff808080No professions|r")
			line.bar:SetProgress(0, 1)
			line.rank:SetText("")
			line:Show()
		else
			line:Hide()
		end
	end
	for i, slot in ipairs(card.secondary) do
		local e = secondary[i]
		if e then
			slot.icon:SetIcon(e.p.icon, false)
			slot.rank:SetText(e.s.rank)
			slot:Show()
		else
			slot:Hide()
		end
	end
	card.hide.text:SetText(entry.hidden and "Show" or "Hide")
	card:SetAlpha(entry.hidden and 0.55 or 1)
end

----------------------------------------------------------------------------
-- Build
----------------------------------------------------------------------------
local function Title(i, text, y)
	local fs = titles[i]
	if not fs then
		fs = NS.Widgets:SectionTitle(content, text)
		titles[i] = fs
	end
	fs:SetText(strupper(text))
	fs:ClearAllPoints()
	fs:SetPoint("TOPLEFT", 2, y)
	fs:Show()
	return y - 18
end

function Page:Build(f)
	local W = NS.Widgets
	for i, s in ipairs(SORTS) do
		local b = NS.Skin:CreateButton(f, 64, 20, s.label)
		b:SetPoint("TOPLEFT", (i - 1) * 68, 0)
		b:SetScript("OnClick", function()
			sortIndex = i
			Page:Refresh()
		end)
		sortButtons[i] = b
	end
	hiddenButton = NS.Skin:CreateButton(f, 96, 20, "Show hidden")
	hiddenButton:SetPoint("TOPLEFT", #SORTS * 68 + 8, 0)
	hiddenButton:SetScript("OnClick", function()
		showHidden = not showHidden
		Page:Refresh()
	end)
	worthText = W:Label(f)
	worthText:SetPoint("TOPLEFT", 2, -28)
	worthText:SetPoint("RIGHT", -2, 0)
	worthText:SetJustifyH("LEFT")

	scroll = CreateFrame("ScrollFrame", "JohnnysProfessionsAltsScroll", f, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 0, -48)
	scroll:SetPoint("BOTTOMRIGHT", -24, 0)
	content = CreateFrame("Frame", nil, scroll)
	content:SetSize(NS.MainWindow.CONTENT_W - 26, 10)
	scroll:SetScrollChild(content)
end

----------------------------------------------------------------------------
-- Refresh
----------------------------------------------------------------------------
-- Column sizes change with how many professions are shown, so cells are
-- re-placed on every refresh.
local function TableCell(row, i, nameW, colW)
	row.cells = row.cells or {}
	local fs = row.cells[i]
	if not fs then
		fs = NS.Widgets:Label(row)
		fs:SetJustifyH("CENTER")
		row.cells[i] = fs
	end
	fs:ClearAllPoints()
	fs:SetPoint("LEFT", nameW + (i - 1) * colW, 0)
	fs:SetWidth(colW - 4)
	return fs
end

-- Header cell: the profession's icon, its name in a tooltip.
local function HeadIcon(row, i, nameW, colW, p)
	row.icons = row.icons or {}
	local b = row.icons[i]
	if not b then
		b = CreateFrame("Button", nil, row)
		b:SetSize(TABLE_ICON, TABLE_ICON)
		b.tex = b:CreateTexture(nil, "ARTWORK")
		b.tex:SetAllPoints()
		b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(self.prof)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", GameTooltip_Hide)
		row.icons[i] = b
	end
	b:ClearAllPoints()
	b:SetPoint("CENTER", row, "LEFT", nameW + (i - 1) * colW + (colW - 4) / 2, 0)
	b.tex:SetTexture(p.icon)
	b.prof = p.key
	b:Show()
	return b
end

local function TableRow(i)
	local row = tableRows[i]
	if not row then
		row = CreateFrame("Frame", nil, content)
		row:SetHeight(TABLE_ROW)
		row.bg = row:CreateTexture(nil, "BACKGROUND")
		row.bg:SetAllPoints()
		row.bg:SetTexture(NS.Skin.WHITE)
		row.name = NS.Widgets:Label(row)
		row.name:SetPoint("LEFT", 6, 0)
		row.name:SetWidth(TABLE_NAME_W - 10)
		tableRows[i] = row
	end
	return row
end

local function ShareRow(i)
	local row = shareRows[i]
	if not row then
		local W = NS.Widgets
		row = CreateFrame("Button", nil, content)
		row:SetHeight(SHARE_ROW)
		row.icon = W:CreateIcon(row, 16, nil, false)
		row.icon:SetPoint("LEFT", 4, 0)
		row.text = W:Label(row)
		row.text:SetPoint("LEFT", 26, 0)
		row.text:SetPoint("RIGHT", -4, 0)
		row:SetScript("OnEnter", function(self)
			if self.itemID then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetHyperlink("item:" .. self.itemID)
				GameTooltip:Show()
			end
		end)
		row:SetScript("OnLeave", GameTooltip_Hide)
		shareRows[i] = row
	end
	return row
end

function Page:Refresh()
	if not content then
		return
	end
	for i, b in ipairs(sortButtons) do
		NS.Widgets:SetSelected(b, i == sortIndex)
	end
	NS.Widgets:SetSelected(hiddenButton, showHidden)
	local total, gold, mats = AccountWorth()
	worthText:SetText(string.format("Account worth %s  |cff9e9e9e(gold %s + mats %s)|r",
		NS:FormatMoney(total), NS:FormatMoney(gold), NS:FormatMoney(mats)))

	local chars = Characters()
	local width = content:GetWidth()
	local cardW = (width - CARD_GAP) / 2
	local y = 0

	-- Cards, two per row.
	y = Title(1, "Characters", y)
	for i, entry in ipairs(chars) do
		local card = cards[i] or NewCard()
		cards[i] = card
		local col = (i - 1) % 2
		local line = math.floor((i - 1) / 2)
		card:ClearAllPoints()
		card:SetPoint("TOPLEFT", col * (cardW + CARD_GAP), y - line * (CARD_H + CARD_GAP))
		card:SetWidth(cardW)
		FillCard(card, entry)
		card:Show()
	end
	for i = #chars + 1, #cards do
		cards[i]:Hide()
	end
	y = y - math.ceil(#chars / 2) * (CARD_H + CARD_GAP) - 6

	-- Professions table: one column per profession anyone has.
	local cols = {}
	for _, p in ipairs(NS.PROFESSIONS) do
		for _, entry in ipairs(chars) do
			if entry.char.skills and entry.char.skills[p.key] then
				table.insert(cols, p)
				break
			end
		end
	end
	-- Icon headers are narrow, so columns just shrink until every profession fits.
	local nameW = TABLE_NAME_W
	local colW = TABLE_COL_W
	if #cols > 0 then
		colW = math.min(TABLE_COL_W, math.floor((width - nameW) / #cols))
	end
	y = Title(2, "Professions", y)
	local head = TableRow(1)
	head:ClearAllPoints()
	head:SetPoint("TOPLEFT", 0, y)
	head:SetWidth(width)
	head.bg:SetVertexColor(1, 1, 1, 0.08)
	head.name:SetText("|cff9e9e9eCharacter|r")
	for c, p in ipairs(cols) do
		HeadIcon(head, c, nameW, colW, p)
	end
	for c = #cols + 1, #(head.icons or {}) do
		head.icons[c]:Hide()
	end
	head:Show()
	for i, entry in ipairs(chars) do
		local row = TableRow(i + 1)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, y - i * TABLE_ROW)
		row:SetWidth(width)
		row.bg:SetVertexColor(1, 1, 1, (i % 2 == 0) and 0.03 or 0)
		row.name:SetText(NS:ClassColoredName(entry.name, entry.char.class))
		for c, p in ipairs(cols) do
			local s = entry.char.skills and entry.char.skills[p.key]
			local cell = TableCell(row, c, nameW, colW)
			if s then
				local color = s.rank >= 450 and "|cffffffff" or (s.rank >= s.max and "|cffffd200" or "|cffc8c8c8")
				cell:SetText(color .. s.rank .. "|r")
			else
				cell:SetText("|cff505050-|r")
			end
		end
		row:Show()
	end
	for _, row in ipairs(tableRows) do
		for c = #cols + 1, #(row.cells or {}) do
			row.cells[c]:SetText("")
		end
	end
	for i = #chars + 2, #tableRows do
		tableRows[i]:Hide()
	end
	y = y - (#chars + 1) * TABLE_ROW - 12

	-- Materials to share.
	y = Title(3, "Materials your characters can share", y)
	local shares = ShareList(chars)
	for i, s in ipairs(shares) do
		local row = ShareRow(i)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, y - (i - 1) * SHARE_ROW)
		row:SetWidth(width)
		row.itemID = s.id
		row.icon:SetIcon(NS.ItemCache:Icon(s.id), false)
		row.text:SetText(string.format("%s  ->  %s:  %dx %s  |cff9e9e9e(%s)|r",
			NS:ClassColoredName(s.holder.name, s.holder.char.class),
			NS:ClassColoredName(s.needer.name, s.needer.char.class),
			s.count, NS.ItemCache:ColoredName(s.id), s.prof or ""))
		row:Show()
	end
	for i = #shares + 1, #shareRows do
		shareRows[i]:Hide()
	end
	local emptyShare = titles.emptyShare
	if not emptyShare then
		emptyShare = NS.Widgets:Label(content)
		emptyShare:SetTextColor(unpack(NS.Widgets.COLORS.muted))
		titles.emptyShare = emptyShare
	end
	if #shares == 0 then
		emptyShare:ClearAllPoints()
		emptyShare:SetPoint("TOPLEFT", 4, y)
		emptyShare:SetText("Nothing to swap - no character holds spare materials another one's guides need.")
		emptyShare:Show()
		y = y - SHARE_ROW
	else
		emptyShare:Hide()
		y = y - #shares * SHARE_ROW
	end

	content:SetHeight(math.max(1, -y + 8))
end
