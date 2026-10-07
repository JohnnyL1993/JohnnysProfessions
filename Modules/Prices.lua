-- Price lookups. Everything comes from this addon's own AH scans (see
-- AuctionScan.lua) or the vendor price table - no other addon is consulted.
local NS = JohnnysProfessions
NS.Prices = {}
local Prices = NS.Prices

local STALE_AFTER = 48 * 3600
local AH_CUT = 0.95

-- Raw scan record for an item, or nil if it has never been scanned.
function Prices:GetScan(itemID)
	return NS:RealmDB().prices[itemID]
end

-- Returns (copper, isStale) for the AH price, or nil if the item has never
-- been seen on the AH. `market` (the cost of buying a realistic quantity) is
-- preferred over the single cheapest listing.
function Prices:GetAH(itemID)
	local p = self:GetScan(itemID)
	if not p or not (p.market or p.min) then
		return nil
	end
	return p.market or p.min, (time() - (p.time or 0)) > STALE_AFTER
end

----------------------------------------------------------------------------
-- Vendor prices: what a merchant actually charged you (learned from the
-- merchant window, so reputation discounts are included) beats the static
-- table in Data\VendorPrices.lua.
----------------------------------------------------------------------------
local function Learned()
	local g = NS.db.global
	g.vendorPrices = g.vendorPrices or {}
	return g.vendorPrices
end

function Prices:GetVendorBuy(itemID)
	return Learned()[itemID] or NS.VENDOR_PRICES[itemID]
end

-- Items worth remembering a merchant price for: anything in the static
-- table, any reagent of a known recipe or guide step, and trade goods.
local reagentSet
local function IsReagent(id)
	if not reagentSet then
		reagentSet = {}
		for _, r in pairs(NS.db.global.recipeCache) do
			for rid in pairs(r.reagents or {}) do
				reagentSet[rid] = true
			end
		end
		for _, steps in pairs(NS.Guides) do
			for _, step in ipairs(steps) do
				for rid in pairs(step.reagents or {}) do
					reagentSet[rid] = true
				end
			end
		end
	end
	return reagentSet[id]
end

local function ScanMerchant()
	local learned = Learned()
	for i = 1, GetMerchantNumItems() do
		local _, _, price, quantity, numAvailable, _, extendedCost = GetMerchantItemInfo(i)
		local id = NS:ItemIDFromLink(GetMerchantItemLink(i))
		-- Unlimited stock only (limited items are recipes/rares, not staples),
		-- and gold-only prices (no honor/token costs).
		if id and price and price > 0 and not extendedCost and numAvailable == -1 then
			local itemType = select(6, GetItemInfo(id))
			if NS.VENDOR_PRICES[id] or IsReagent(id) or itemType == "Trade Goods" then
				learned[id] = math.floor(price / math.max(quantity or 1, 1) + 0.5)
			end
		end
	end
	NS:RequestRedraw()
end

local merchantEvents = CreateFrame("Frame")
merchantEvents:RegisterEvent("MERCHANT_SHOW")
merchantEvents:RegisterEvent("MERCHANT_UPDATE")
merchantEvents:SetScript("OnEvent", function(_, event)
	if event == "MERCHANT_SHOW" then
		reagentSet = nil -- new recipes may have been learned since last time
	end
	ScanMerchant()
end)

-- What it costs to obtain one: the cheaper of the AH and a vendor.
-- Returns copper, source ("ah" / "vendor"), isStale.
function Prices:GetCost(itemID)
	local ah, stale = self:GetAH(itemID)
	local vendor = self:GetVendorBuy(itemID)
	if vendor and (not ah or vendor <= ah) then
		return vendor, "vendor", false
	end
	if ah then
		return ah, "ah", stale
	end
	return nil
end

-- What one sells for on the AH after the 5% cut, or nil if unknown.
function Prices:GetSellValue(itemID)
	local ah, stale = self:GetAH(itemID)
	if not ah then
		return nil
	end
	return math.floor(ah * AH_CUT), stale
end

-- What a vendor pays for one.
function Prices:GetVendorSell(itemID)
	local sell = select(11, GetItemInfo(itemID))
	return sell
end

-- Formats a cost for display, greyed out if stale, "?" if unknown.
function Prices:FormatCost(itemID, quantity)
	local each, _, stale = self:GetCost(itemID)
	if not each then
		return "|cff808080?|r"
	end
	local text = NS:FormatMoney(each * (quantity or 1))
	if stale then
		text = "|cff909090(old)|r " .. text
	end
	return text
end

-- Summary for UI headers: number of scanned items and age of the oldest scan.
function Prices:Summary()
	local n, oldest = 0, nil
	for _, p in pairs(NS:RealmDB().prices) do
		n = n + 1
		if p.time and (not oldest or p.time < oldest) then
			oldest = p.time
		end
	end
	return n, oldest
end
