-- Loot advisor: for a green/blue/purple weapon or armor piece, compares what
-- a vendor pays, the expected value of disenchanting it (Data\Disenchant.lua
-- outcomes x this addon's AH prices) and its own AH price, and gives a
-- verdict - VENDOR / DISENCHANT / AUCTION - with how much more the best
-- option pays than the next one.
local NS = JohnnysProfessions
NS.LootAdvisor = {}
local LA = NS.LootAdvisor

-- Shirts and tabards are armor but can't be disenchanted.
local NOT_DISENCHANTABLE = { INVTYPE_BODY = true, INVTYPE_TABARD = true }

local scanTip

local function FindBracket(list, ilvl)
	for _, b in ipairs(list) do
		if ilvl >= b.min and ilvl <= b.max then
			return b
		end
	end
end

-- Basic facts about an item, or nil if it's not a weapon/armor piece of
-- green quality or better. Returns a table { quality=, ilvl=, weapon=, sell= }.
function LA:Info(itemID)
	local name, _, quality, ilvl, _, itemType, _, _, equipLoc, _, sell = GetItemInfo(itemID)
	if not name or not quality or quality < 2 or quality > 4 then
		return nil
	end
	if itemType ~= "Weapon" and itemType ~= "Armor" then
		return nil
	end
	if not equipLoc or equipLoc == "" or NOT_DISENCHANTABLE[equipLoc] then
		return nil
	end
	return { quality = quality, ilvl = ilvl or 0, weapon = itemType == "Weapon", sell = sell or 0 }
end

-- Possible disenchant results: array of { id=, qty= (average), chance= } and
-- the Enchanting skill needed, or nil if the bracket isn't in the table.
function LA:Outcomes(itemID)
	local info = self:Info(itemID)
	if not info then
		return nil
	end
	local DE = NS.DISENCHANT
	if info.quality == 2 then
		local b = FindBracket(DE.uncommon, info.ilvl)
		if not b then
			return nil
		end
		local chances = DE.GREEN_CHANCES[b.era][info.weapon and "weapon" or "armor"]
		local list = {}
		local parts = { b.dust, b.essence, b.shard }
		for i = 1, 3 do
			local p = parts[i]
			if p and chances[i] > 0 then
				table.insert(list, { id = p[1], qty = (p[2] + p[3]) / 2, min = p[2], max = p[3], chance = chances[i] })
			end
		end
		return list, b.skill
	end
	local b = FindBracket(info.quality == 3 and DE.rare or DE.epic, info.ilvl)
	if not b then
		return nil
	end
	local list = {}
	for _, o in ipairs(b) do
		table.insert(list, { id = o[1], qty = (o[2] + o[3]) / 2, min = o[2], max = o[3], chance = o[4] })
	end
	return list, b.skill
end

-- Expected AH value of disenchanting one: copper, or nil if no outcome has a
-- price yet. `partial` is true when some outcomes are unpriced.
function LA:DisenchantValue(itemID)
	local outcomes, skill = self:Outcomes(itemID)
	if not outcomes then
		return nil
	end
	local value, priced, partial = 0, false, false
	for _, o in ipairs(outcomes) do
		local each = NS.Prices:GetSellValue(o.id)
		if each then
			value = value + o.chance * o.qty * each
			priced = true
		else
			partial = true
		end
	end
	return priced and math.floor(value) or nil, partial, outcomes, skill
end

-- Names (with class) of every character whose Enchanting is high enough.
function LA:Disenchanters(skill)
	local list = {}
	for name, char in pairs(NS.Characters:All()) do
		local s = char.skills and char.skills.Enchanting
		if s and s.rank >= (skill or 1) then
			table.insert(list, { name = name, class = char.class })
		end
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

-- Full evaluation. `bound` = soulbound / bind-on-pickup (can't be auctioned).
-- Returns nil for items the advisor doesn't cover, else
-- { vendor=, de=, dePartial=, ah=, verdict=, best=, margin=, skill=, outcomes=, disenchanters= }
function LA:Evaluate(itemID, bound)
	local info = self:Info(itemID)
	if not info then
		return nil
	end
	local r = { vendor = info.sell, quality = info.quality, ilvl = info.ilvl }
	r.de, r.dePartial, r.outcomes, r.skill = self:DisenchantValue(itemID)
	if r.skill then
		r.disenchanters = self:Disenchanters(r.skill)
	end
	if not bound then
		r.ah = NS.Prices:GetSellValue(itemID)
	end

	local options = { { "VENDOR", r.vendor or 0 } }
	if r.de then
		table.insert(options, { "DISENCHANT", r.de })
	end
	if r.ah then
		table.insert(options, { "AUCTION", r.ah })
	end
	table.sort(options, function(a, b) return a[2] > b[2] end)
	r.verdict, r.best = options[1][1], options[1][2]
	r.margin = options[2] and (options[1][2] - options[2][2]) or nil
	r.second = options[2] and options[2][1]
	return r
end

local VERDICT_COLORS = { VENDOR = "|cffbbbbbb", DISENCHANT = "|cffa335ee", AUCTION = "|cff40c0ff" }
function LA:VerdictText(r)
	return (VERDICT_COLORS[r.verdict] or "|cffffffff") .. r.verdict .. "|r"
end

----------------------------------------------------------------------------
-- Bags
----------------------------------------------------------------------------
local function IsBound(bag, slot)
	if not scanTip then
		scanTip = CreateFrame("GameTooltip", "JohnnysProfessionsLootScanTooltip", UIParent, "GameTooltipTemplate")
	end
	scanTip:SetOwner(UIParent, "ANCHOR_NONE")
	scanTip:SetBagItem(bag, slot)
	for i = 2, math.min(scanTip:NumLines(), 6) do
		local fs = _G["JohnnysProfessionsLootScanTooltipTextLeft" .. i]
		local text = fs and fs:GetText()
		if text == ITEM_SOULBOUND or text == ITEM_BIND_ON_PICKUP then
			scanTip:Hide()
			return true
		end
	end
	scanTip:Hide()
	return false
end

-- Every green+ weapon/armor piece in this character's bags, evaluated, best
-- value first. Array of { id=, bag=, slot=, count=, bound=, eval= }.
function LA:BagItems()
	local list = {}
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local id = NS:ItemIDFromLink(GetContainerItemLink(bag, slot))
			if id and self:Info(id) then
				local bound = IsBound(bag, slot)
				local eval = self:Evaluate(id, bound)
				if eval then
					table.insert(list, { id = id, bag = bag, slot = slot, bound = bound, eval = eval })
				end
			end
		end
	end
	table.sort(list, function(a, b)
		if a.eval.best ~= b.eval.best then
			return a.eval.best > b.eval.best
		end
		return a.id < b.id
	end)
	return list
end
