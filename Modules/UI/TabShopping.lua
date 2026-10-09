-- Shopping tab: everything still needed to finish the guides for your
-- professions, what you and your alts already hold, and what the rest costs.
local NS = JohnnysProfessions
local Page = {}
NS.MainWindow:AddPage("Shopping", Page, {
	order = 5, label = "Shopping", icon = "Interface\\Icons\\INV_Misc_Bag_10",
	title = "Shopping list", subtitle = "Everything still needed to finish your guides",
})

local COLUMNS = {
	{ x = 24, width = 220 },                     -- item
	{ x = 250, width = 60, justify = "RIGHT" },  -- need
	{ x = 316, width = 60, justify = "RIGHT" },  -- you
	{ x = 382, width = 60, justify = "RIGHT" },  -- alts
	{ x = 448, width = 60, justify = "RIGHT" },  -- short
	{ x = 514, width = 150, justify = "RIGHT" }, -- cost of short
}

local filterButtons = {}
local list, totalText, emptyText, scanButton, filter
local head, hideButton

-- Column sorting: click a header to sort by it (largest first, names A-Z),
-- again to reverse, a third time to go back to the default order (items
-- you're still short of first). `sortColumn` is an index into COLUMNS.
local sortColumn, sortReversed = nil, false
local HEADER_LABELS = { "Item", "Need", "You", "Alts", "Short", "Cost of short" }

local function HideOwned()
	return NS.db.profile.ui.shoppingHideOwned == true
end

local function SortValue(e, column)
	if column == 1 then
		return string.lower(GetItemInfo(e.id) or "")
	elseif column == 2 then
		return e.need
	elseif column == 3 then
		return e.mine
	elseif column == 4 then
		return e.alts
	elseif column == 5 then
		return e.short
	end
	local each = NS.Prices:GetCost(e.id)
	return (each or 0) * e.short
end

local function SortEntries(entries)
	if not sortColumn then
		return
	end
	local column, reversed = sortColumn, sortReversed
	table.sort(entries, function(a, b)
		local av, bv = SortValue(a, column), SortValue(b, column)
		if av == bv then
			return a.id < b.id
		end
		-- Names read A-Z first; every number column reads largest first.
		local ascending = (column == 1)
		if reversed then
			ascending = not ascending
		end
		if ascending then
			return av < bv
		end
		return av > bv
	end)
end

local function RefreshHeader()
	if not head or not head.labels then
		return
	end
	local C = NS.Skin.C
	for i, fs in pairs(head.labels) do
		local label = strupper(HEADER_LABELS[i])
		if i == sortColumn then
			local descending = (i ~= 1)
			if sortReversed then
				descending = not descending
			end
			fs:SetText(label .. (descending and " v" or " ^"))
			fs:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
		else
			fs:SetText(label)
			fs:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
		end
	end
end

local function Professions()
	if filter then
		return { filter }
	end
	return NS.Guide:MyGuidedProfessions()
end

local function RowTooltip(row, tt)
	local e = row.entry
	tt:AddLine(" ")
	tt:AddDoubleLine("Needed for guides", e.need, 1, 0.82, 0, 1, 1, 1)
	tt:AddDoubleLine("You (bags/bank/mail)", e.mine, 1, 0.82, 0, 1, 1, 1)
	for _, alt in ipairs(e.altList) do
		tt:AddDoubleLine("  " .. NS:ClassColoredName(alt.name, alt.class), alt.count, 1, 1, 1, 1, 1, 1)
	end
	local each, source, stale, from = NS.Prices:GetCost(e.id)
	if each then
		tt:AddDoubleLine("Price each (" .. (source == "vendor" and "vendor" or ("AH, " .. from)) .. (stale and ", old" or "") .. ")",
			NS:FormatMoney(each), 1, 0.82, 0, 1, 1, 1)
	else
		tt:AddLine("No price yet - scan at the auction house.", 0.6, 0.6, 0.6)
	end
end

local function BuildFilters(f)
	for _, b in ipairs(filterButtons) do
		b:Hide()
	end
	local profs = NS.Guide:MyGuidedProfessions()
	local labels = { "All" }
	for _, p in ipairs(profs) do
		table.insert(labels, p)
	end
	if filter and not NS.Guide:Has(filter) then
		filter = nil
	end
	for i, label in ipairs(labels) do
		local b = filterButtons[i]
		if not b then
			b = NS.Skin:CreateButton(f, 96, 20)
			b:SetPoint("TOPLEFT", (i - 1) * 100, 0)
			filterButtons[i] = b
		end
		b.text:SetText(label)
		b:SetScript("OnClick", function()
			filter = (label ~= "All") and label or nil
			Page:Refresh()
		end)
		NS.Widgets:SetSelected(b, (filter or "All") == label)
		b:Show()
	end
end

function Page:Build(f)
	local W = NS.Widgets
	head = W:CreateHeader(f, COLUMNS, HEADER_LABELS)
	head:SetPoint("TOPLEFT", 0, -28)
	head:SetPoint("RIGHT", -24, 0)
	-- An invisible button over each column label makes the header sortable.
	for i, c in ipairs(COLUMNS) do
		local b = CreateFrame("Button", nil, head)
		b:SetPoint("LEFT", head, "LEFT", c.x, 0)
		b:SetSize(c.width, 16)
		b:SetScript("OnClick", function()
			if sortColumn ~= i then
				sortColumn, sortReversed = i, false
			elseif not sortReversed then
				sortReversed = true
			else
				sortColumn, sortReversed = nil, false
			end
			Page:Refresh()
		end)
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("Sort by " .. string.lower(HEADER_LABELS[i]), 1, 1, 1)
			GameTooltip:AddLine("Click again to reverse, a third time for the default order.", nil, nil, nil, true)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end

	list = W:CreateList(f, 18, COLUMNS, true)
	list.scroll:SetPoint("TOPLEFT", 0, -46)
	list.scroll:SetPoint("BOTTOMRIGHT", -24, 30)

	emptyText = W:Label(f, "GameFontHighlight")
	emptyText:SetPoint("TOP", 0, -90)
	emptyText:SetWidth(500)
	emptyText:SetJustifyH("CENTER")

	local track = NS.Skin:CreateButton(f, 150, 22, "Track short items")
	track:SetPoint("BOTTOMLEFT", 0, 0)
	track:SetScript("OnClick", function()
		local n = NS.Tracker:TrackShoppingList(NS.Guide:ShoppingList(Professions()))
		NS:Print(string.format("Tracking %d item(s).", n))
		NS.TrackerWindow:Show()
	end)

	scanButton = NS.Skin:CreateButton(f, 150, 22, "Scan AH prices")
	scanButton:SetPoint("LEFT", track, "RIGHT", 6, 0)
	scanButton:SetScript("OnClick", function()
		if NS.AuctionScan:IsRunning() then
			NS.AuctionScan:Stop()
		else
			NS.AuctionScan:Start()
		end
	end)

	hideButton = NS.Skin:CreateButton(f, 140, 22, "Hide what I have")
	hideButton:SetPoint("LEFT", scanButton, "RIGHT", 6, 0)
	hideButton:SetScript("OnClick", function()
		NS.db.profile.ui.shoppingHideOwned = not HideOwned()
		Page:Refresh()
	end)
	hideButton:SetScript("OnMouseUp", function(self) W:SetSelected(self, HideOwned()) end)

	totalText = W:Label(f)
	totalText:SetPoint("BOTTOMRIGHT", -2, 6)
	totalText:SetJustifyH("RIGHT")

	self.filterHolder = f
end

function Page:Refresh()
	BuildFilters(self.filterHolder)
	local entries = NS.Guide:ShoppingList(Professions())
	local allCount = #entries
	if HideOwned() then
		local short = {}
		for _, e in ipairs(entries) do
			if e.short > 0 then
				table.insert(short, e)
			end
		end
		entries = short
	end
	SortEntries(entries)
	RefreshHeader()
	NS.Widgets:SetSelected(hideButton, HideOwned())
	local total, unknown = 0, 0
	list:SetCount(#entries, function(row, i)
		local e = entries[i]
		row.entry = e
		row.link = "item:" .. e.id
		row.tooltipFunc = RowTooltip
		row.icon:SetTexture(NS.ItemCache:Icon(e.id))
		local c = row.cols
		c[1]:SetText(NS.ItemCache:ColoredName(e.id))
		c[2]:SetText(e.need)
		c[3]:SetText(e.mine > 0 and e.mine or "|cff808080-|r")
		c[4]:SetText(e.alts > 0 and e.alts or "|cff808080-|r")
		if e.short > 0 then
			c[5]:SetText("|cffff8040" .. e.short .. "|r")
			local each = NS.Prices:GetCost(e.id)
			if each then
				total = total + each * e.short
			else
				unknown = unknown + 1
			end
			c[6]:SetText(NS.Prices:FormatCost(e.id, e.short))
		else
			c[5]:SetText("|cff40ff40done|r")
			c[6]:SetText("")
		end
	end)

	if #entries == 0 and allCount > 0 then
		emptyText:SetText("You or your alts already hold everything the guides still need. Turn off \"Hide what I have\" to see the full list.")
		emptyText:Show()
	elseif #entries == 0 then
		emptyText:SetText("Nothing to buy. Learn a profession that has a guide, or you've finished the guides for yours.")
		emptyText:Show()
	else
		emptyText:Hide()
	end

	local text = "Total: " .. NS:FormatMoney(total)
	if unknown > 0 then
		text = text .. string.format(" |cff808080(+%d unpriced)|r", unknown)
	end
	totalText:SetText(text)

	if NS.AuctionScan:IsRunning() then
		scanButton.text:SetText("Stop scan")
		scanButton:Enable()
	elseif NS.AuctionScan:IsAHOpen() then
		scanButton.text:SetText("Scan AH prices")
		scanButton:Enable()
	else
		scanButton.text:SetText("Open AH to scan")
		scanButton:Disable()
	end
end
