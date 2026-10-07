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
	local each, source, stale = NS.Prices:GetCost(e.id)
	if each then
		tt:AddDoubleLine("Price each (" .. (source == "vendor" and "vendor" or "AH") .. (stale and ", old" or "") .. ")",
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
	local head = W:CreateHeader(f, COLUMNS, { "Item", "Need", "You", "Alts", "Short", "Cost of short" })
	head:SetPoint("TOPLEFT", 0, -28)
	head:SetPoint("RIGHT", -24, 0)

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

	totalText = W:Label(f)
	totalText:SetPoint("BOTTOMRIGHT", -2, 6)
	totalText:SetJustifyH("RIGHT")

	self.filterHolder = f
end

function Page:Refresh()
	BuildFilters(self.filterHolder)
	local entries = NS.Guide:ShoppingList(Professions())
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

	if #entries == 0 then
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
