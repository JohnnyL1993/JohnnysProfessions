-- Gold tab, two views:
--  * Recipes - for every recipe this character knows that makes an item, the
--    cost of its materials vs what the product sells for on the AH (after the
--    5% cut) and to a vendor. Click a recipe to select it in the open
--    profession window, Shift-click to track its materials.
--  * Loot in your bags - the loot advisor's verdict (VENDOR / DISENCHANT /
--    AUCTION) for every green+ weapon and armor piece in your bags.
-- Uses this addon's own AH scan prices.
local NS = JohnnysProfessions
local Page = {}
NS.MainWindow:AddPage("Gold", Page, {
	order = 6, label = "Gold", icon = "Interface\\Icons\\INV_Misc_Coin_01",
	title = "Gold", subtitle = function()
		if Page.mode == "loot" then
			return "Vendor, disenchant or auction - what your loot is worth"
		end
		return "What your recipes cost to make and what they sell for"
	end,
})
Page.mode = "recipes"

local COLUMNS = {
	{ x = 24, width = 230 },                     -- product
	{ x = 258, width = 100, justify = "RIGHT" }, -- cost
	{ x = 362, width = 100, justify = "RIGHT" }, -- AH value
	{ x = 466, width = 100, justify = "RIGHT" }, -- profit
	{ x = 566, width = 96, justify = "RIGHT" },  -- vendor
}

local LOOT_COLUMNS = {
	{ x = 24, width = 210 },                     -- item
	{ x = 238, width = 90 },                     -- verdict
	{ x = 330, width = 82, justify = "RIGHT" },  -- vendor
	{ x = 414, width = 82, justify = "RIGHT" },  -- disenchant
	{ x = 498, width = 82, justify = "RIGHT" },  -- auction
	{ x = 582, width = 80, justify = "RIGHT" },  -- gain
}

local filterButtons = {}
local modeButtons = {}
local list, head, lootList, lootHead, summaryText, emptyText, filter

local function CraftProfessions()
	local list = {}
	local recipes = NS.Characters:Me().recipes
	for _, p in ipairs(NS.PROFESSIONS) do
		if recipes[p.key] and next(recipes[p.key]) then
			table.insert(list, p.key)
		end
	end
	return list
end

-- One entry per known recipe that has a product item.
local function BuildRows(prof)
	local rows = {}
	local cache = NS.db.global.recipeCache
	for spellID in pairs(NS.Characters:Me().recipes[prof] or {}) do
		local r = cache[spellID]
		if r and r.item then
			local cost, missing = 0, false
			for id, n in pairs(r.reagents or {}) do
				local each = NS.Prices:GetCost(id)
				if each then
					cost = cost + each * n
				else
					missing = true
				end
			end
			local made = r.made or 1
			local value = NS.Prices:GetSellValue(r.item)
			value = value and value * made
			local vendor = NS.Prices:GetVendorSell(r.item)
			vendor = vendor and vendor > 0 and vendor * made or nil
			table.insert(rows, {
				spellID = spellID, prof = prof, item = r.item, made = made, reagents = r.reagents or {},
				cost = (not missing) and cost or nil, partialCost = cost,
				value = value,
				profit = (value and not missing) and (value - cost) or nil,
				vendor = vendor,
			})
		end
	end
	table.sort(rows, function(a, b)
		if (a.profit ~= nil) ~= (b.profit ~= nil) then
			return a.profit ~= nil
		end
		if a.profit and b.profit and a.profit ~= b.profit then
			return a.profit > b.profit
		end
		return (GetItemInfo(a.item) or "") < (GetItemInfo(b.item) or "")
	end)
	return rows
end

local function RowTooltip(row, tt)
	local r = row.data
	tt:AddLine(" ")
	tt:AddLine("Materials:", 0.85, 0.85, 0.85)
	for id, n in pairs(r.reagents) do
		tt:AddDoubleLine(n .. "x " .. NS.ItemCache:ColoredName(id), NS.Prices:FormatCost(id, n), 1, 1, 1, 1, 1, 1)
	end
	if r.made ~= 1 then
		tt:AddLine(string.format("Makes %s per craft", r.made), 0.7, 0.7, 0.7)
	end
	local scan = NS.Prices:GetScan(r.item)
	if scan and scan.none then
		tt:AddLine("None listed at the last scan.", 0.6, 0.6, 0.6)
	elseif scan and scan.available then
		tt:AddLine(string.format("%d on the AH at the last scan.", scan.available), 0.6, 0.6, 0.6)
	end
	tt:AddLine(" ")
	tt:AddLine("Click: select it in your profession window", 0.6, 0.6, 0.6)
	tt:AddLine("Shift-click: track its materials", 0.6, 0.6, 0.6)
end

-- Selects a recipe in the Blizzard profession window, if it's open on the
-- right profession and the recipe is visible under its current filters.
local function SelectInTradeWindow(r)
	local frameOpen = TradeSkillFrame and TradeSkillFrame:IsShown()
	if not frameOpen or GetTradeSkillLine() ~= r.prof then
		NS:Print("Open your " .. r.prof .. " window first, then click the recipe again.")
		return
	end
	for i = 1, GetNumTradeSkills() do
		if NS:SpellIDFromLink(GetTradeSkillRecipeLink(i)) == r.spellID then
			TradeSkillFrame_SetSelection(i)
			if TradeSkillListScrollFrame and TRADE_SKILL_HEIGHT then
				local offset = math.max(0, i - 1)
				FauxScrollFrame_SetOffset(TradeSkillListScrollFrame, offset)
				TradeSkillListScrollFrame:SetVerticalScroll(offset * TRADE_SKILL_HEIGHT)
			end
			TradeSkillFrame_Update()
			return
		end
	end
	NS:Print("That recipe is hidden by the profession window's filters or a collapsed category.")
end

local function TrackMats(r)
	for id, n in pairs(r.reagents) do
		NS.Tracker:Adjust(id, n)
	end
	NS:Print("Tracking materials for 1x " .. NS.ItemCache:ColoredName(r.item) .. ".")
end

local function RecipeOnClick(row)
	local r = row.data
	if IsShiftKeyDown() then
		TrackMats(r)
	else
		SelectInTradeWindow(r)
	end
end

local function BuildFilters(f, profs)
	for _, b in ipairs(filterButtons) do
		b:Hide()
	end
	for i, prof in ipairs(profs) do
		local b = filterButtons[i]
		if not b then
			b = NS.Skin:CreateButton(f, 110, 20)
			b:SetPoint("TOPLEFT", (i - 1) * 114, -28)
			filterButtons[i] = b
		end
		b.text:SetText(prof)
		b:SetScript("OnClick", function()
			filter = prof
			Page:Refresh()
		end)
		NS.Widgets:SetSelected(b, prof == filter)
		b:Show()
	end
end

function Page:Build(f)
	local W = NS.Widgets
	self.holder = f

	local modes = { { "recipes", "Recipes" }, { "loot", "Loot in your bags" } }
	for i, m in ipairs(modes) do
		local b = NS.Skin:CreateButton(f, 140, 22, m[2])
		b:SetPoint("TOPLEFT", (i - 1) * 144, 0)
		b:SetScript("OnClick", function()
			Page.mode = m[1]
			NS.MainWindow:Refresh()
		end)
		modeButtons[m[1]] = b
	end

	head = W:CreateHeader(f, COLUMNS, { "Product", "Mat cost", "AH (-5%)", "Profit", "Vendor" })
	head:SetPoint("TOPLEFT", 0, -56)
	head:SetPoint("RIGHT", -24, 0)
	list = W:CreateList(f, 18, COLUMNS, true)
	list.scroll:SetPoint("TOPLEFT", 0, -74)
	list.scroll:SetPoint("BOTTOMRIGHT", -24, 24)

	lootHead = W:CreateHeader(f, LOOT_COLUMNS, { "Item", "Best", "Vendor", "Disenchant", "AH (-5%)", "Gain" })
	lootHead:SetPoint("TOPLEFT", 0, -34)
	lootHead:SetPoint("RIGHT", -24, 0)
	lootList = W:CreateList(f, 18, LOOT_COLUMNS, true)
	lootList.scroll:SetPoint("TOPLEFT", 0, -52)
	lootList.scroll:SetPoint("BOTTOMRIGHT", -24, 24)

	emptyText = W:Label(f, "GameFontHighlight")
	emptyText:SetPoint("TOP", 0, -110)
	emptyText:SetWidth(520)
	emptyText:SetJustifyH("CENTER")

	summaryText = W:Label(f)
	summaryText:SetPoint("BOTTOMLEFT", 2, 4)
	summaryText:SetTextColor(unpack(W.COLORS.muted))
end

local function RefreshRecipes()
	local profs = CraftProfessions()
	local found = false
	for _, p in ipairs(profs) do
		if p == filter then
			found = true
		end
	end
	if not found then
		filter = profs[1]
	end
	BuildFilters(Page.holder, profs)

	local rows = filter and BuildRows(filter) or {}
	list:SetCount(#rows, function(row, i)
		local r = rows[i]
		row.data = r
		row.link = "item:" .. r.item
		row.tooltipFunc = RowTooltip
		row:SetScript("OnClick", RecipeOnClick)
		row.icon:SetTexture(NS.ItemCache:Icon(r.item))
		local c = row.cols
		c[1]:SetText(NS.ItemCache:ColoredName(r.item) .. (r.made ~= 1 and string.format(" |cffaaaaaax%s|r", r.made) or ""))
		c[2]:SetText(r.cost and NS:FormatMoney(r.cost) or "|cff808080?|r")
		c[3]:SetText(r.value and NS:FormatMoney(r.value) or "|cff808080?|r")
		c[4]:SetText(r.profit and NS:FormatMoney(r.profit) or "|cff808080?|r")
		c[5]:SetText(r.vendor and NS:FormatMoney(r.vendor) or "")
	end)

	if #profs == 0 then
		emptyText:SetText("No recipes recorded yet. Open each of your profession windows once so they can be read.")
		emptyText:Show()
	elseif #rows == 0 then
		emptyText:SetText("No item-making recipes recorded for " .. filter .. ".")
		emptyText:Show()
	else
		emptyText:Hide()
	end
end

local function LootTooltip(row, tt)
	local e = row.entry
	if e.bound then
		tt:AddLine("Soulbound - can't be auctioned.", 0.6, 0.6, 0.6)
	end
end

local function RefreshLoot()
	local items = NS.LootAdvisor:BagItems()
	lootList:SetCount(#items, function(row, i)
		local e = items[i]
		local r = e.eval
		row.entry = e
		row.link = "item:" .. e.id
		row.tooltipFunc = LootTooltip
		row.icon:SetTexture(NS.ItemCache:Icon(e.id))
		local c = row.cols
		c[1]:SetText(NS.ItemCache:ColoredName(e.id))
		c[2]:SetText(NS.LootAdvisor:VerdictText(r))
		c[3]:SetText(NS:FormatMoney(r.vendor or 0))
		if r.de then
			c[4]:SetText(NS:FormatMoney(r.de) .. (r.dePartial and " |cff808080+?|r" or ""))
		else
			c[4]:SetText(r.outcomes and "|cff808080?|r" or "|cff808080-|r")
		end
		if e.bound then
			c[5]:SetText("|cff808080bound|r")
		else
			c[5]:SetText(r.ah and NS:FormatMoney(r.ah) or "|cff808080?|r")
		end
		c[6]:SetText(r.margin and r.margin > 0 and ("+" .. NS:FormatMoney(r.margin)) or "")
	end)
	if #items == 0 then
		emptyText:SetText("No green, blue or purple weapons or armor in your bags.")
		emptyText:Show()
	else
		emptyText:Hide()
	end
end

function Page:Refresh()
	local loot = self.mode == "loot"
	for m, b in pairs(modeButtons) do
		NS.Widgets:SetSelected(b, m == self.mode)
	end
	if loot then
		head:Hide()
		list.scroll:Hide()
		for _, b in ipairs(filterButtons) do
			b:Hide()
		end
		lootHead:Show()
		lootList.scroll:Show()
		RefreshLoot()
	else
		lootHead:Hide()
		lootList.scroll:Hide()
		head:Show()
		list.scroll:Show()
		RefreshRecipes()
	end

	local count, oldest = NS.Prices:Summary()
	if oldest then
		summaryText:SetText(string.format("%d AH prices, oldest scanned %s ago. Scan again at the AH to update.",
			count, NS:FormatDuration(math.max(60, time() - oldest))))
	else
		summaryText:SetText("No AH prices yet - open the auction house and click \"JP: Scan prices\".")
	end
end
