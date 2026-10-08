-- Materials page: every item all your characters hold (bags, bank, mail)
-- added up, with what it's worth on the AH after the 5% cut. Shows trade
-- goods and gems by default; "All items" shows everything. Hover a row for
-- who holds how many and where.
local NS = JohnnysProfessions
local Page = {}
NS.MainWindow:AddPage("Materials", Page, {
	order = 5.5, label = "Materials", icon = "Interface\\Icons\\INV_Fabric_Netherweave_Bolt",
	title = "Materials", subtitle = "Everything your characters hold, and what it's worth",
})

local COLUMNS = {
	{ x = 24, width = 220 },                     -- item
	{ x = 250, width = 50, justify = "RIGHT" },  -- count
	{ x = 306, width = 100, justify = "RIGHT" }, -- each
	{ x = 412, width = 110, justify = "RIGHT" }, -- total
	{ x = 534, width = 106 },                    -- held by
}

-- Item types counted as materials in the default view.
local MAT_TYPES = { ["Trade Goods"] = true, ["Gem"] = true }

local SORTS = {
	{ label = "Value", fn = function(a, b)
		if (a.total or -1) ~= (b.total or -1) then
			return (a.total or -1) > (b.total or -1)
		end
		return a.name < b.name
	end },
	{ label = "Count", fn = function(a, b)
		if a.count ~= b.count then
			return a.count > b.count
		end
		return a.name < b.name
	end },
	{ label = "Name", fn = function(a, b) return a.name < b.name end },
}

local sortIndex = 1
local showAll = false
local sortButtons = {}
local matsButton, allButton
local list, totalText, emptyText, scanButton

local function ShortName(name)
	return #name > 6 and name:sub(1, 6) or name
end

-- { id=, name=, count=, each=, total=, holders = { {name=, class=, bags=, bank=, mail=, count=} } }
local function Entries()
	local byID = {}
	for charName, char in pairs(NS.Characters:All()) do
		for _, where in ipairs({ "bags", "bank", "mail" }) do
			for id, n in pairs(char[where] or {}) do
				local e = byID[id]
				if not e then
					e = { id = id, count = 0, holders = {}, byChar = {} }
					byID[id] = e
				end
				local h = e.byChar[charName]
				if not h then
					h = { name = charName, class = char.class, bags = 0, bank = 0, mail = 0, count = 0 }
					e.byChar[charName] = h
					table.insert(e.holders, h)
				end
				h[where] = h[where] + n
				h.count = h.count + n
				e.count = e.count + n
			end
		end
	end
	local entries = {}
	for id, e in pairs(byID) do
		local name, _, _, _, _, itemType = GetItemInfo(id)
		if not name then
			NS.ItemCache:Request(id)
		end
		if showAll or (itemType and MAT_TYPES[itemType]) then
			e.name = name or ("item #" .. id)
			e.each = NS.Prices:GetWorth(id)
			e.total = e.each and e.each * e.count
			table.sort(e.holders, function(a, b) return a.count > b.count end)
			table.insert(entries, e)
		end
	end
	table.sort(entries, SORTS[sortIndex].fn)
	return entries
end

local function RowTooltip(row, tt)
	local e = row.entry
	tt:AddLine(" ")
	tt:AddDoubleLine("Total held", e.count, 1, 0.82, 0, 1, 1, 1)
	for _, h in ipairs(e.holders) do
		local parts = {}
		for _, where in ipairs({ "bags", "bank", "mail" }) do
			if h[where] > 0 then
				table.insert(parts, h[where] .. " " .. where)
			end
		end
		tt:AddDoubleLine("  " .. NS:ClassColoredName(h.name, h.class), table.concat(parts, ", "), 1, 1, 1, 0.8, 0.8, 0.8)
	end
	if e.each then
		local _, stale, from = NS.Prices:GetWorth(e.id)
		if from == "vendor" then
			tt:AddDoubleLine("Worth each (vendor price - AH is higher)", NS:FormatMoney(e.each), 1, 0.82, 0, 1, 1, 1)
		else
			tt:AddDoubleLine("AH each, after cut (" .. (from or "AH") .. (stale and ", old" or "") .. ")",
				NS:FormatMoney(e.each), 1, 0.82, 0, 1, 1, 1)
		end
	elseif NS.Prices:IsBound(e.id) then
		tt:AddLine("Bound or quest item - can't be auctioned, not counted.", 0.6, 0.6, 0.6)
	else
		tt:AddLine("No AH price yet - scan at the auction house.", 0.6, 0.6, 0.6)
	end
	local vendor = NS.Prices:GetVendorSell(e.id)
	if vendor and vendor > 0 then
		tt:AddDoubleLine("Vendor each", NS:FormatMoney(vendor), 1, 0.82, 0, 1, 1, 1)
	end
end

function Page:Build(f)
	local W = NS.Widgets
	matsButton = NS.Skin:CreateButton(f, 96, 20, "Materials")
	matsButton:SetPoint("TOPLEFT", 0, 0)
	matsButton:SetScript("OnClick", function()
		showAll = false
		Page:Refresh()
	end)
	allButton = NS.Skin:CreateButton(f, 96, 20, "All items")
	allButton:SetPoint("TOPLEFT", 100, 0)
	allButton:SetScript("OnClick", function()
		showAll = true
		Page:Refresh()
	end)
	for i, s in ipairs(SORTS) do
		local b = NS.Skin:CreateButton(f, 64, 20, s.label)
		b:SetPoint("TOPRIGHT", -24 - (#SORTS - i) * 68, 0)
		b:SetScript("OnClick", function()
			sortIndex = i
			Page:Refresh()
		end)
		sortButtons[i] = b
	end

	local head = W:CreateHeader(f, COLUMNS, { "Item", "Count", "AH each", "Total", "Held by" })
	head:SetPoint("TOPLEFT", 0, -28)
	head:SetPoint("RIGHT", -24, 0)

	list = W:CreateList(f, 18, COLUMNS, true)
	list.scroll:SetPoint("TOPLEFT", 0, -46)
	list.scroll:SetPoint("BOTTOMRIGHT", -24, 30)

	emptyText = W:Label(f, "GameFontHighlight")
	emptyText:SetPoint("TOP", 0, -90)
	emptyText:SetWidth(500)
	emptyText:SetJustifyH("CENTER")

	scanButton = NS.Skin:CreateButton(f, 150, 22, "Scan AH prices")
	scanButton:SetPoint("BOTTOMLEFT", 0, 0)
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
end

function Page:Refresh()
	NS.Widgets:SetSelected(matsButton, not showAll)
	NS.Widgets:SetSelected(allButton, showAll)
	for i, b in ipairs(sortButtons) do
		NS.Widgets:SetSelected(b, i == sortIndex)
	end

	local entries = Entries()
	local total, unknown = 0, 0
	list:SetCount(#entries, function(row, i)
		local e = entries[i]
		row.entry = e
		row.link = "item:" .. e.id
		row.tooltipFunc = RowTooltip
		row.bg:SetVertexColor(1, 1, 1, (i % 2 == 0) and 0.03 or 0)
		row.icon:SetTexture(NS.ItemCache:Icon(e.id))
		local c = row.cols
		c[1]:SetText(NS.ItemCache:ColoredName(e.id))
		c[2]:SetText(e.count)
		if e.each then
			c[3]:SetText(NS:FormatMoney(e.each))
			c[4]:SetText(NS:FormatMoney(e.total))
			total = total + e.total
		elseif NS.Prices:IsBound(e.id) then
			c[3]:SetText("|cff808080bound|r")
			c[4]:SetText("|cff808080-|r")
		else
			c[3]:SetText("|cff808080?|r")
			c[4]:SetText("|cff808080?|r")
			unknown = unknown + 1
		end
		local holders = {}
		for h = 1, math.min(2, #e.holders) do
			table.insert(holders, NS:ClassColoredName(ShortName(e.holders[h].name), e.holders[h].class))
		end
		if #e.holders > 2 then
			table.insert(holders, "|cff808080+" .. (#e.holders - 2) .. "|r")
		end
		c[5]:SetText(table.concat(holders, " "))
	end)

	if #entries == 0 then
		emptyText:SetText(showAll and "No items recorded yet. Log in on each character and open your bank and mailbox once."
			or "No materials recorded yet. Log in on each character and open your bank and mailbox once.")
		emptyText:Show()
	else
		emptyText:Hide()
	end

	local text = string.format("%d items, worth %s", #entries, NS:FormatMoney(total))
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
