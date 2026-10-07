-- This addon's own AH scanner. Instead of a full "getAll" dump (throttled to
-- once every 15 minutes and prone to disconnects on Warmane) it searches only
-- the items this addon cares about: guide materials you still need, tracked
-- items, and the reagents/products of recipes you know.
--
-- 3.3.5a's QueryAuctionItems has no exact-match flag, so a search for "Linen
-- Cloth" also returns "Bolt of Linen Cloth"; every listing is filtered by
-- item ID. Results land in the Browse tab like a normal search would.
local NS = JohnnysProfessions
NS.AuctionScan = {}
local Scan = NS.AuctionScan

local PAGE_SIZE = NUM_AUCTION_ITEMS_PER_PAGE or 50
local MAX_PAGES = 8
local DEFAULT_NEED = 20
-- Pause after a result page arrives before reading it, so owner/link data on
-- the page has filled in.
local SETTLE = 0.25

local ahOpen = false
local running = false
local items = {}     -- array of { id=, name=, need= }
local index = 0
local page = 0
local listings = {}  -- for the current item: { {unit=, count=}, ... }
local awaiting = false
local readAt = nil
local skipped = 0
local listeners = {}

function Scan:OnChange(fn)
	table.insert(listeners, fn)
end
local function Notify()
	for _, fn in ipairs(listeners) do
		fn()
	end
end

function Scan:IsAHOpen()
	return ahOpen
end

function Scan:IsRunning()
	return running
end

function Scan:Progress()
	local cur = items[index]
	return index, #items, cur and cur.name
end

----------------------------------------------------------------------------
-- What to scan
----------------------------------------------------------------------------
function Scan:BuildList()
	local need = {}
	local function Add(id, n)
		if id then
			need[id] = math.max(need[id] or 0, n or DEFAULT_NEED)
		end
	end

	for _, entry in ipairs(NS.Guide:ShoppingList(NS.Guide:MyGuidedProfessions())) do
		Add(entry.id, entry.need)
	end
	for id, target in pairs(NS.db.profile.trackerGoals) do
		Add(id, target)
	end
	local cache = NS.db.global.recipeCache
	for _, known in pairs(NS.Characters:Me().recipes) do
		for spellID in pairs(known) do
			local r = cache[spellID]
			if r then
				Add(r.item, 1)
				for id, n in pairs(r.reagents or {}) do
					Add(id, n)
				end
			end
		end
	end

	-- Vendor-only reagents (threads, vials, flux) are never worth searching.
	local list = {}
	skipped = 0
	for id, n in pairs(need) do
		if not NS.Prices:GetVendorBuy(id) then
			local name = GetItemInfo(id)
			if name then
				table.insert(list, { id = id, name = name, need = n })
			else
				NS.ItemCache:Request(id)
				skipped = skipped + 1
			end
		end
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

----------------------------------------------------------------------------
-- Running a scan
----------------------------------------------------------------------------
local driver = CreateFrame("Frame")
driver:Hide()

local function FinishItem()
	local item = items[index]
	table.sort(listings, function(a, b) return a.unit < b.unit end)
	local prices = NS:RealmDB().prices
	if #listings == 0 then
		prices[item.id] = { none = true, time = time() }
	else
		-- "market": average unit price of the cheapest listings that cover
		-- the quantity you need, so one cheap single doesn't set the price.
		local want = math.max(item.need or 1, 1)
		local bought, spent, available = 0, 0, 0
		for _, l in ipairs(listings) do
			available = available + l.count
			if bought < want then
				local take = math.min(l.count, want - bought)
				bought = bought + take
				spent = spent + take * l.unit
			end
		end
		prices[item.id] = {
			min = math.floor(listings[1].unit),
			market = math.floor(spent / bought),
			available = available,
			time = time(),
		}
	end
	wipe(listings)
	page = 0
	index = index + 1
	Notify()
end

local function ReadPage()
	local item = items[index]
	local numBatch, total = GetNumAuctionItems("list")
	for i = 1, numBatch do
		local _, _, count, _, _, _, _, _, buyout = GetAuctionItemInfo("list", i)
		local id = NS:ItemIDFromLink(GetAuctionItemLink("list", i))
		if id == item.id and buyout and buyout > 0 and count and count > 0 then
			table.insert(listings, { unit = buyout / count, count = count })
		end
	end
	if (page + 1) * PAGE_SIZE < total and page + 1 < MAX_PAGES then
		page = page + 1
	else
		FinishItem()
	end
end

local function Stop(message)
	running = false
	awaiting = false
	readAt = nil
	driver:Hide()
	wipe(listings)
	if message then
		NS:Print(message)
	end
	Notify()
end

driver:SetScript("OnUpdate", function()
	if not ahOpen then
		Stop("Scan stopped - auction house closed.")
		return
	end
	if readAt then
		if GetTime() >= readAt then
			readAt = nil
			ReadPage()
		end
		return
	end
	if awaiting then
		return
	end
	if index > #items then
		local n = #items
		Stop(string.format("Scan finished: %d item%s priced.", n, n == 1 and "" or "s"))
		return
	end
	if CanSendAuctionQuery() then
		awaiting = true
		-- isUsable/quality must be nil, not 0: 0 is truthy in Lua and would
		-- limit the search to items this character can use.
		QueryAuctionItems(items[index].name, nil, nil, 0, 0, 0, page, nil, nil)
	end
end)

function Scan:OnListUpdate()
	if running and awaiting then
		awaiting = false
		readAt = GetTime() + SETTLE
	end
end

function Scan:Start()
	if running then
		return
	end
	if not ahOpen then
		NS:Print("Open the auction house first, then scan.")
		return
	end
	items = self:BuildList()
	if #items == 0 then
		NS:Print(skipped > 0
			and "Item info is still loading from the server - try again in a few seconds."
			or "Nothing to scan: no guide materials, tracked items or known recipes yet. Open your profession windows first.")
		return
	end
	if skipped > 0 then
		NS:Print(string.format("%d item(s) skipped while their info loads from the server - scan again afterwards to include them.", skipped))
	end
	index, page = 1, 0
	wipe(listings)
	awaiting, readAt = false, nil
	running = true
	driver:Show()
	Notify()
end

function Scan:Stop()
	if running then
		Stop("Scan stopped.")
	end
end

-- Runs a normal Browse-tab search for one item (used by the item tracker).
-- Returns true if the search was started.
function Scan:SearchFor(itemID)
	if not ahOpen or running or not BrowseName or not AuctionFrameBrowse_Search then
		return false
	end
	local name = GetItemInfo(itemID)
	if not name then
		NS.ItemCache:Request(itemID)
		return false
	end
	if AuctionFrame.selectedTab ~= 1 and AuctionFrameTab1 then
		AuctionFrameTab_OnClick(AuctionFrameTab1)
	end
	BrowseName:SetText(name)
	AuctionFrameBrowse_Search()
	return true
end

----------------------------------------------------------------------------
-- AH frame button
----------------------------------------------------------------------------
local button, status

local function UpdateButton()
	if not button then
		return
	end
	if running then
		local i, n, name = Scan:Progress()
		button.text:SetText("Stop scan")
		status:SetText(string.format("JP: %d/%d %s", math.min(i, n), n, name or ""))
	else
		button.text:SetText("JP: Scan prices")
		local count, oldest = NS.Prices:Summary()
		if oldest then
			status:SetText(string.format("%d prices, oldest %s ago", count, NS:FormatDuration(math.max(60, time() - oldest))))
		else
			status:SetText("No prices scanned yet")
		end
	end
end

function Scan:OnAuctionHouseShow()
	ahOpen = true
	if not button and AuctionFrame then
		local Skin = NS.Skin
		button = Skin:CreateButton(AuctionFrame, 120, 20, "JP: Scan prices")
		button:SetPoint("BOTTOMRIGHT", AuctionFrame, "TOPRIGHT", -10, 2)
		button:SetScript("OnClick", function()
			if running then
				Scan:Stop()
			else
				Scan:Start()
			end
		end)
		status = AuctionFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		status:SetPoint("RIGHT", button, "LEFT", -8, 0)
		self:OnChange(UpdateButton)
	end
	UpdateButton()
	Notify()
end

function Scan:OnAuctionHouseClosed()
	ahOpen = false
	if running then
		Stop("Scan stopped - auction house closed.")
	end
	Notify()
end
