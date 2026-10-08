-- Short "you might want to..." hints for the Home page: junk to sell, bags
-- filling up, gear needing repair, a trainer visit, cooldowns ready, tracked
-- goals done, old AH prices. Each check is cheap enough to run on every
-- Home page refresh.
local NS = JohnnysProfessions
NS.Suggestions = {}
local Sug = NS.Suggestions

local STALE_AFTER = 48 * 3600

-- Total vendor value of grey items in the bags, plus how many stacks.
function Sug:JunkValue()
	local value, stacks = 0, 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link then
				local _, _, quality, _, _, _, _, _, _, _, sell = GetItemInfo(link)
				if quality == 0 and sell and sell > 0 then
					local _, count = GetContainerItemInfo(bag, slot)
					value = value + sell * (count or 1)
					stacks = stacks + 1
				end
			end
		end
	end
	return value, stacks
end

-- Free / total slots in normal bags (profession bags left out of "free").
function Sug:BagSpace()
	local free, total = 0, 0
	for bag = 0, NUM_BAG_SLOTS do
		local slots = GetContainerNumSlots(bag)
		total = total + slots
		local n, bagType = GetContainerNumFreeSlots(bag)
		if (bagType or 0) == 0 then
			free = free + (n or 0)
		end
	end
	return free, total
end

-- Lowest and average durability (0-100) over equipped items, nil if nothing
-- equipped has durability.
function Sug:Durability()
	local lowest, sum, n = nil, 0, 0
	for slot = 1, 18 do
		local cur, max = GetInventoryItemDurability(slot)
		if cur and max and max > 0 then
			local pct = cur / max * 100
			sum = sum + pct
			n = n + 1
			if not lowest or pct < lowest then
				lowest = pct
			end
		end
	end
	if n == 0 then
		return nil
	end
	return lowest, sum / n
end

local function StripColors(text)
	return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

----------------------------------------------------------------------------
-- Hiding: right-click a suggestion on Home to hide it until your next level.
-- Stored as hiddenSuggestions[id] = the level it was hidden at.
----------------------------------------------------------------------------
local function Hidden()
	local p = NS.db.profile
	p.hiddenSuggestions = p.hiddenSuggestions or {}
	return p.hiddenSuggestions
end

function Sug:Hide(id)
	if id then
		Hidden()[id] = UnitLevel("player")
	end
end

function Sug:IsHidden(id)
	local level = id and Hidden()[id]
	return level ~= nil and level >= UnitLevel("player")
end

function Sug:UnhideAll()
	wipe(Hidden())
end

----------------------------------------------------------------------------
-- Class trainer: remembered whenever you open a (non-profession) trainer,
-- so the "new spells" reminder goes away once you've been.
----------------------------------------------------------------------------
local trainerEvents = CreateFrame("Frame")
trainerEvents:RegisterEvent("TRAINER_SHOW")
trainerEvents:SetScript("OnEvent", function()
	if NS.db and not (IsTradeskillTrainer and IsTradeskillTrainer()) then
		NS.db.profile.classTrainerLevel = UnitLevel("player")
	end
end)

local function MaxLevel()
	return (MAX_PLAYER_LEVEL_TABLE and MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel()]) or 80
end

-- Every current suggestion. Hidden ones are left out unless includeHidden.
-- Entries: { id=, icon=, title=, text=, onClick=, hidden= }.
function Sug:Get(includeHidden)
	local list = {}
	local function Add(id, icon, title, text, onClick)
		local hidden = self:IsHidden(id)
		if includeHidden or not hidden then
			table.insert(list, { id = id, icon = icon, title = title, text = text, onClick = onClick, hidden = hidden })
		end
	end

	local level = UnitLevel("player")
	if level < MaxLevel() then
		local rested, max = GetXPExhaustion(), UnitXPMax("player")
		if rested and max > 0 and rested >= max * 0.5 then
			Add("rested", "Interface\\Icons\\Spell_Nature_Sleep",
				string.format("%d%% of a level in rested XP", math.floor(rested / max * 100)),
				"Kills give double experience until it runs out - a good time to quest.")
		end
		local trained = NS.db.profile.classTrainerLevel or 0
		if level >= 10 and level % 2 == 0 and trained < level then
			Add("classTrainer", "Interface\\Icons\\INV_Misc_Book_09", "New spells at your class trainer",
				string.format("You reached level %d - your class trainer has new ranks to learn.", level))
		end
	end

	local _, quests = GetNumQuestLogEntries()
	local maxQuests = MAX_QUESTLOG_QUESTS or 25
	if quests and quests >= maxQuests - 1 then
		Add("questLog", "Interface\\Icons\\INV_Misc_Book_08",
			quests >= maxQuests and "Your quest log is full" or "Your quest log is almost full",
			string.format("%d / %d quests - abandon or turn some in before picking up more.", quests, maxQuests))
	end

	local junk, stacks = self:JunkValue()
	if stacks > 0 then
		Add("junk", "Interface\\Icons\\INV_Misc_Coin_01",
			string.format("Sell %d junk item%s", stacks, stacks == 1 and "" or "s"),
			"Grey items in your bags are worth " .. NS:FormatMoney(junk) .. " at any vendor.")
	end

	local lowest = self:Durability()
	if lowest and lowest < 30 then
		Add("repair", "Interface\\Icons\\Trade_BlackSmithing",
			string.format("Repair your gear (%d%%)", math.floor(lowest)),
			"Something you're wearing is close to breaking.")
	end

	local free = self:BagSpace()
	if free <= 3 then
		Add("bags", "Interface\\Icons\\INV_Misc_Bag_08", "Running low on bag space",
			string.format("%d free slot%s left.", free, free == 1 and "" or "s"))
	end

	local me = NS.Characters:Me()
	local level = UnitLevel("player")
	for _, p in ipairs(NS.PROFESSIONS) do
		local s = me.skills[p.key]
		if s then
			local hint = NS:TrainerHint(s.rank, s.max, level, p.key)
			if hint and hint:find("Visit a trainer") then
				local prof = p.key
				Add("trainer:" .. prof, p.icon, "Visit your " .. prof .. " trainer", StripColors(hint), function()
					NS.MainWindow:ShowGuide(prof)
				end)
			end
		end
	end

	local now, ready = time(), {}
	for _, row in ipairs(NS.Cooldowns:ForChar(NS.Characters.name, me)) do
		if row.used and row.expires <= now then
			table.insert(ready, row.group)
		end
	end
	if #ready > 0 then
		Add("cooldowns", "Interface\\Icons\\INV_Misc_PocketWatch_01", "Cooldowns ready", table.concat(ready, ", "), function()
			NS.MainWindow:ShowTab("Cooldowns")
		end)
	end

	local goals = NS.Tracker:List()
	if #goals > 0 then
		local done = true
		for _, g in ipairs(goals) do
			if g.count < g.target then
				done = false
				break
			end
		end
		if done then
			Add("tracker", "Interface\\Icons\\INV_Misc_Note_01", "All tracked items collected",
				"Every goal in the item tracker is met.", function()
				NS.TrackerWindow:Show()
			end)
		end
	end

	local _, oldest = NS.Prices:Summary()
	if not NS.Prices:ExternalSourceName() and (not oldest or time() - oldest > STALE_AFTER) then
		local unpriced = 0
		for _, e in ipairs(NS.Guide:ShoppingList(NS.Guide:MyGuidedProfessions())) do
			if e.short > 0 and not NS.Prices:GetCost(e.id) then
				unpriced = unpriced + 1
			end
		end
		if unpriced > 0 or oldest then
			Add("ahPrices", "Interface\\Icons\\INV_Misc_Coin_02",
				oldest and "AH prices are out of date" or "Scan auction house prices",
				"Open the auction house and click \"JP: Scan prices\" to price your shopping list.", function()
				NS.MainWindow:ShowTab("Shopping")
			end)
		end
	end

	return list
end
