-- Crafters page: search a recipe, ask the guild who can craft it
-- (Modules\GuildCrafters.lua), and whisper them. Your own characters are
-- always listed; guild answers are remembered while their senders are offline.
local NS = JohnnysProfessions
local Page = {}
NS.MainWindow:AddPage("Crafters", Page, {
	order = 8, label = "Crafters", icon = "Interface\\Icons\\INV_Misc_Note_02",
	title = "Guild crafters", subtitle = "Who in your guild can craft it",
})

local LEFT_W = 250
local MAX_MATCHES = 60
local RECIPE_COLUMNS = {
	{ x = 24, width = 150 },                     -- recipe
	{ x = 176, width = 46, justify = "RIGHT" },  -- profession (short)
}
local CRAFTER_COLUMNS = {
	{ x = 8, width = 150 },                      -- player + online
	{ x = 160, width = 160 },                    -- characters (widened to fit on refresh)
}

local search, recipeList, hintText
local header, profText, askButton, statusText, crafterList, emptyText
local selected
local matches = {}

----------------------------------------------------------------------------
-- Recipe name index: every recipe this addon has seen (trade skill scans of
-- any character) plus every guide step's recipe.
----------------------------------------------------------------------------
local index, indexBuilt = nil, 0

local function BuildIndex()
	local seen = {}
	index = {}
	local function Add(spellID, prof)
		if not spellID or seen[spellID] then
			return
		end
		local name, _, icon = GetSpellInfo(spellID)
		if name then
			seen[spellID] = true
			table.insert(index, { id = spellID, name = name, lower = strlower(name), prof = prof, icon = icon })
		end
	end
	for spellID, r in pairs(NS.db.global.recipeCache) do
		Add(spellID, r.prof)
	end
	for prof, steps in pairs(NS.Guides) do
		for _, step in ipairs(steps) do
			if step.spell then
				Add(step.spell, prof)
			end
		end
	end
	table.sort(index, function(a, b) return a.name < b.name end)
	indexBuilt = GetTime()
end

local function Find(query)
	if not index or GetTime() - indexBuilt > 60 then
		BuildIndex()
	end
	wipe(matches)
	query = strlower(strtrim(query or ""))
	if query == "" then
		-- Nothing typed: recipes the guild has answered about before.
		local asked = NS:RealmDB().guildCrafters or {}
		for _, e in ipairs(index) do
			if asked[e.id] then
				table.insert(matches, e)
			end
		end
		return
	end
	for _, e in ipairs(index) do
		if e.lower:find(query, 1, true) then
			table.insert(matches, e)
			if #matches >= MAX_MATCHES then
				return
			end
		end
	end
end

local function Ago(t)
	if not t then
		return ""
	end
	return NS:FormatDuration(math.max(60, time() - t)) .. " ago"
end

----------------------------------------------------------------------------
-- Build
----------------------------------------------------------------------------
local function Select(entry)
	selected = entry
	if entry then
		local ok, reason = NS.GuildCrafters:Query(entry.id)
		statusText:SetText(ok and "Asked your guild - answers appear as they arrive." or (reason or ""))
	end
	Page:Refresh()
end

local function AddWhisper(row)
	row.whisper = NS.Skin:CreateButton(row, 70, 20, "Whisper")
	row.whisper:SetPoint("RIGHT", -6, 0)
	row.whisper:SetScript("OnClick", function(self)
		local name = self:GetParent().whisperTo
		if name then
			ChatFrame_OpenChat("/w " .. name .. " ")
		end
	end)
end

function Page:Build(f)
	local W = NS.Widgets

	-- Left: search + matching recipes
	local left = W:CreateCard(f)
	left:SetPoint("TOPLEFT", 0, 0)
	left:SetPoint("BOTTOMLEFT", 0, 0)
	left:SetWidth(LEFT_W)
	local title = W:SectionTitle(left, "Find a recipe")
	title:SetPoint("TOPLEFT", 10, -8)
	search = NS.Skin:CreateEditBox(left, LEFT_W - 20, 22)
	search:SetPoint("TOPLEFT", 10, -24)
	search.editBox:SetScript("OnTextChanged", function() Page:Refresh() end)
	hintText = W:Label(left)
	hintText:SetPoint("TOPLEFT", 12, -54)
	hintText:SetWidth(LEFT_W - 24)
	hintText:SetTextColor(unpack(W.COLORS.muted))

	recipeList = W:CreateList(left, 20, RECIPE_COLUMNS, true)
	recipeList.scroll:SetPoint("TOPLEFT", 6, -52)
	recipeList.scroll:SetPoint("BOTTOMRIGHT", -26, 6)

	-- Right: selected recipe + crafters
	local right = CreateFrame("Frame", nil, f)
	right:SetPoint("TOPLEFT", LEFT_W + 10, 0)
	right:SetPoint("BOTTOMRIGHT", 0, 0)

	local head = W:CreateCard(right)
	head:SetPoint("TOPLEFT", 0, 0)
	head:SetPoint("RIGHT", 0, 0)
	head:SetHeight(64)
	head.icon = W:CreateIcon(head, 36, nil, false)
	head.icon:SetPoint("TOPLEFT", 10, -10)
	header = W:Label(head, "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", head.icon, "TOPRIGHT", 10, 0)
	header:SetPoint("RIGHT", -110, 0)
	header:SetTextColor(1, 1, 1)
	profText = W:Label(head)
	profText:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
	profText:SetTextColor(unpack(W.COLORS.muted))
	askButton = NS.Skin:CreateButton(head, 96, 22, "Ask guild")
	askButton:SetPoint("TOPRIGHT", -10, -10)
	askButton:SetScript("OnClick", function()
		if selected then
			local ok, reason = NS.GuildCrafters:Query(selected.id)
			statusText:SetText(ok and "Asked your guild - answers appear as they arrive." or (reason or ""))
		end
	end)
	statusText = W:Label(head)
	statusText:SetPoint("BOTTOMRIGHT", -10, 8)
	statusText:SetJustifyH("RIGHT")
	statusText:SetTextColor(unpack(W.COLORS.muted))

	local sub = W:SectionTitle(right, "Crafters")
	sub:SetPoint("TOPLEFT", 2, -74)
	crafterList = W:CreateList(right, 40, CRAFTER_COLUMNS)
	crafterList.scroll:SetPoint("TOPLEFT", 0, -90)
	crafterList.scroll:SetPoint("BOTTOMRIGHT", -24, 0)

	emptyText = W:Label(right, "GameFontHighlight")
	emptyText:SetPoint("TOP", 0, -120)
	emptyText:SetWidth(380)
	emptyText:SetJustifyH("CENTER")

	self.head = head
end

----------------------------------------------------------------------------
-- Refresh
----------------------------------------------------------------------------
local function RefreshRecipes()
	Find(search.editBox:GetText())
	local typed = strtrim(search.editBox:GetText() or "") ~= ""
	if #matches == 0 then
		hintText:SetText(typed and "No recipe matches. Open your profession windows so their recipes are known."
			or "Type part of a recipe name. Recipes you've asked about before show here.")
		hintText:Show()
	else
		hintText:Hide()
	end
	recipeList:SetCount(#matches, function(row, i)
		local e = matches[i]
		row.icon:SetTexture(e.icon)
		row.cols[1]:SetText(e.name)
		row.cols[2]:SetText("|cff9e9e9e" .. (e.prof or ""):sub(1, 6) .. "|r")
		row.link = "enchant:" .. e.id
		if selected and selected.id == e.id then
			row.bg:SetVertexColor(1, 1, 1, 0.12)
		end
		row:SetScript("OnClick", function() Select(e) end)
	end)
end

local function RefreshCrafters()
	if not selected then
		header:SetText("Pick a recipe")
		profText:SetText("Search on the left, then click a recipe to ask your guild.")
		Page.head.icon:SetIcon(nil, true)
		askButton:Disable()
		crafterList:SetCount(0)
		emptyText:Hide()
		return
	end
	askButton:Enable()
	header:SetText(selected.name)
	profText:SetText(selected.prof or NS.GuildCrafters:ProfessionOf(selected.id) or "")
	Page.head.icon:SetIcon(selected.icon, false)

	local results = NS.GuildCrafters:Results(selected.id)
	crafterList:SetCount(#results, function(row, i)
		local r = results[i]
		if not row.whisper then
			AddWhisper(row)
		end
		local who = r.mine and "|cffffffffYour characters|r"
			or (r.player .. (r.online and "  |cff40ff40online|r" or "  |cff808080offline|r"))
		row.cols[1]:SetText(who)
		local parts = {}
		for _, c in ipairs(r.chars) do
			table.insert(parts, string.format("%s (%d)", c.class and NS:ClassColoredName(c.name, c.class) or c.name, c.skill or 0))
		end
		local line = table.concat(parts, ", ")
		if r.time then
			line = line .. "\n|cff808080answered " .. Ago(r.time) .. "|r"
		end
		row.cols[2]:SetText(line)
		row.cols[2]:SetWidth(math.max(120, row:GetWidth() - 160 - 84))
		row.whisperTo = r.whisper
		if r.mine or not r.online then
			row.whisper:Hide()
		else
			row.whisper:Show()
		end
	end)
	if #results == 0 then
		emptyText:SetText(IsInGuild() and "No answers yet. Guild members need Johnny's Professions installed to answer."
			or "You're not in a guild - only your own characters can be listed.")
		emptyText:Show()
	else
		emptyText:Hide()
	end
end

function Page:Refresh()
	if not search then
		return
	end
	RefreshRecipes()
	RefreshCrafters()
end
