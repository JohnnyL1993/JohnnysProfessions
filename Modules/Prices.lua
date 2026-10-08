-- Price lookups. AH prices come from TradeSkillMaster's AuctionDB or
-- Auctionator when either is installed (and the option is on), falling back
-- to this addon's own AH scans (see AuctionScan.lua); plus vendor prices.
local NS = JohnnysProfessions
NS.Prices = {}
local Prices = NS.Prices

local STALE_AFTER = 48 * 3600
local AH_CUT = 0.95

NS:RegisterOption("externalPrices", true, "Prices",
	"Use TSM or Auctionator prices",
	"Takes AH prices from TradeSkillMaster (AuctionDB market value) or Auctionator when installed. Items they don't know fall back to this addon's own scan.")

-- Raw scan record for an item, or nil if it has never been scanned.
function Prices:GetScan(itemID)
	return NS:RealmDB().prices[itemID]
end

----------------------------------------------------------------------------
-- Other addons' price data. Each returns copper or nil, and never errors
-- (their databases may not be loaded yet).
----------------------------------------------------------------------------
local function FromTSM(itemID)
	if not (TSMAPI and TSMAPI.GetItemValue) then
		return nil
	end
	local item = "item:" .. itemID
	local ok, v = pcall(TSMAPI.GetItemValue, TSMAPI, item, "DBMarket")
	if not (ok and type(v) == "number" and v > 0) then
		ok, v = pcall(TSMAPI.GetItemValue, TSMAPI, item, "DBMinBuyout")
	end
	return ok and type(v) == "number" and v > 0 and v or nil
end

-- Auctionator keys its data by item name, so the item must be cached.
local function FromAuctionator(itemID)
	if not (Atr_GetAuctionPrice and gAtr_ScanDB) then
		return nil
	end
	local name = GetItemInfo(itemID)
	if not name then
		return nil
	end
	local ok, v = pcall(Atr_GetAuctionPrice, name)
	return ok and type(v) == "number" and v > 0 and v or nil
end

local EXTERNAL = {
	{ name = "TSM", get = FromTSM, loaded = function() return TSMAPI and TSMAPI.GetItemValue end },
	{ name = "Auctionator", get = FromAuctionator, loaded = function() return Atr_GetAuctionPrice end },
}

-- Names of the installed price addons being used, e.g. "TSM, Auctionator",
-- or nil when none are (or the option is off).
function Prices:ExternalSourceName()
	if not NS:Option("externalPrices") then
		return nil
	end
	local names = {}
	for _, src in ipairs(EXTERNAL) do
		if src.loaded() then
			table.insert(names, src.name)
		end
	end
	return #names > 0 and table.concat(names, ", ") or nil
end

-- Returns (copper, isStale, sourceName) for the AH price, or nil if no
-- source knows the item. Other addons' data is never marked stale - they
-- keep their own history. For our own scan, `market` (the cost of buying a
-- realistic quantity) is preferred over the single cheapest listing.
function Prices:GetAH(itemID)
	if NS:Option("externalPrices") then
		for _, src in ipairs(EXTERNAL) do
			local v = src.get(itemID)
			if v then
				return v, false, src.name
			end
		end
	end
	local p = self:GetScan(itemID)
	if not p or not (p.market or p.min) then
		return nil
	end
	return p.market or p.min, (time() - (p.time or 0)) > STALE_AFTER, "JP scan"
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
-- Returns copper, source ("ah" / "vendor"), isStale, and for AH prices the
-- addon it came from ("TSM" / "Auctionator" / "JP scan").
function Prices:GetCost(itemID)
	local ah, stale, from = self:GetAH(itemID)
	local vendor = self:GetVendorBuy(itemID)
	if vendor and (not ah or vendor <= ah) then
		return vendor, "vendor", false
	end
	if ah then
		return ah, "ah", stale, from
	end
	return nil
end

-- What one sells for on the AH after the 5% cut, or nil if unknown.
function Prices:GetSellValue(itemID)
	local ah, stale, from = self:GetAH(itemID)
	if not ah then
		return nil
	end
	return math.floor(ah * AH_CUT), stale, from
end

-- Can this item never go on the AH? Binds on pickup, quest items and
-- account-bound items. Checked once per item from its tooltip; items the
-- client hasn't loaded yet count as tradable until it has.
local boundCache = {}
local boundTip
function Prices:IsBound(itemID)
	if boundCache[itemID] ~= nil then
		return boundCache[itemID]
	end
	local name, _, _, _, _, itemType = GetItemInfo(itemID)
	if not name then
		return false
	end
	local bound = itemType == "Quest"
	if not bound then
		if not boundTip then
			boundTip = CreateFrame("GameTooltip", "JohnnysProfessionsBoundScanTooltip", UIParent, "GameTooltipTemplate")
		end
		boundTip:SetOwner(UIParent, "ANCHOR_NONE")
		boundTip:SetHyperlink("item:" .. itemID)
		for i = 2, math.min(boundTip:NumLines(), 6) do
			local fs = _G["JohnnysProfessionsBoundScanTooltipTextLeft" .. i]
			local text = fs and fs:GetText()
			if text == ITEM_BIND_ON_PICKUP or text == ITEM_SOULBOUND or text == ITEM_BIND_QUEST
				or text == ITEM_BIND_TO_ACCOUNT then
				bound = true
				break
			end
		end
		boundTip:Hide()
	end
	boundCache[itemID] = bound
	return bound
end

-- What one held item is worth: its AH sell value, but never more than a
-- vendor would charge for it (Crystal Vials etc. get listed far above the
-- vendor price, and nobody pays that). nil if there's no AH price or the
-- item can't be auctioned (see IsBound).
-- Returns copper, isStale, source ("vendor" or the AH addon name).
function Prices:GetWorth(itemID)
	if self:IsBound(itemID) then
		return nil
	end
	local sell, stale, from = self:GetSellValue(itemID)
	if not sell then
		return nil
	end
	local vendor = self:GetVendorBuy(itemID)
	if vendor and vendor < sell then
		return vendor, false, "vendor"
	end
	return sell, stale, from
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
