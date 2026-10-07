-- Item tooltip additions: how many of the item each of your characters owns,
-- which recipes use it, who of your characters knows / can learn a recipe
-- item (Pattern:, Plans:, ...), and the loot advisor's verdict for gear.
-- Each part is a Settings toggle; "short tooltips" mode hides the details
-- until Shift is held.
local NS = JohnnysProfessions
NS.Tooltip = {}
local TT = NS.Tooltip

NS:RegisterOption("tooltipCounts", true, "Tooltips", "Item counts on your characters",
	"How many of the item each of your characters has in bags, bank and mail.")
NS:RegisterOption("tooltipReagent", true, "Tooltips", "Recipes that use the item",
	"Lists known and guide recipes that need the item as a material.")
NS:RegisterOption("tooltipRecipe", true, "Tooltips", "Who knows a recipe item",
	"On patterns, plans, formulas and the like: which of your characters know it, can learn it, or need more skill.")
NS:RegisterOption("tooltipLoot", true, "Tooltips", "Loot advice on gear",
	"VENDOR, DISENCHANT or AUCTION on green, blue and purple weapons and armor.")
NS:RegisterOption("tooltipShort", false, "Tooltips", "Short tooltips - hold Shift for details",
	"Shows one summary line per section until you hold Shift.")

local MAX_RECIPES = 5
local RECIPE_PREFIXES = {
	"Pattern", "Plans", "Schematic", "Formula", "Recipe", "Design", "Manual", "Technique",
}

local HEADER = { 0.85, 0.85, 0.85 }
local MUTED = { 0.62, 0.62, 0.62 }

----------------------------------------------------------------------------
-- Indexes over recipeCache + guide data, rebuilt at most every few seconds
----------------------------------------------------------------------------
local INDEX_TTL = 10
local indexTime = 0
local usedBy    -- [reagentItemID] = { [spellID] = prof }
local spellByName -- [recipe name] = spellID

local function AddRecipe(spellID, prof, reagents)
	for id in pairs(reagents or {}) do
		local t = usedBy[id]
		if not t then
			t = {}
			usedBy[id] = t
		end
		t[spellID] = t[spellID] or prof
	end
	local name = GetSpellInfo(spellID)
	if name then
		spellByName[name] = spellID
	end
end

local function Index()
	if usedBy and GetTime() - indexTime < INDEX_TTL then
		return
	end
	usedBy, spellByName = {}, {}
	indexTime = GetTime()
	for spellID, r in pairs(NS.db.global.recipeCache) do
		AddRecipe(spellID, r.prof, r.reagents)
	end
	for prof, steps in pairs(NS.Guides) do
		for _, step in ipairs(steps) do
			if step.spell then
				AddRecipe(step.spell, prof, NS.db.global.recipeCache[step.spell] and NS.db.global.recipeCache[step.spell].reagents or step.reagents)
			end
		end
	end
end

-- Does any of your characters know this recipe?
local function KnownBy(spellID, prof)
	for _, char in pairs(NS.Characters:All()) do
		local known = char.recipes and char.recipes[prof]
		if known and known[spellID] then
			return true
		end
	end
	return false
end

----------------------------------------------------------------------------
-- Sections
----------------------------------------------------------------------------
local function AddCounts(tt, itemID, detail)
	local rows, total = {}, 0
	for name, char in pairs(NS.Characters:All()) do
		if char.bags then
			local bags, bank, mail = char.bags[itemID] or 0, char.bank[itemID] or 0, char.mail[itemID] or 0
			local n = bags + bank + mail
			if n > 0 then
				total = total + n
				table.insert(rows, { name = name, class = char.class, n = n, bags = bags, bank = bank, mail = mail })
			end
		end
	end
	if total == 0 then
		return false
	end
	if not detail then
		tt:AddDoubleLine("Your characters", total, MUTED[1], MUTED[2], MUTED[3], 1, 1, 1)
		return true
	end
	table.sort(rows, function(a, b) return a.n > b.n end)
	for _, r in ipairs(rows) do
		local parts = {}
		if r.bags > 0 then table.insert(parts, "bags " .. r.bags) end
		if r.bank > 0 then table.insert(parts, "bank " .. r.bank) end
		if r.mail > 0 then table.insert(parts, "mail " .. r.mail) end
		tt:AddDoubleLine(NS:ClassColoredName(r.name, r.class) .. " |cff9e9e9e(" .. table.concat(parts, ", ") .. ")|r",
			r.n, 1, 1, 1, 1, 1, 1)
	end
	if #rows > 1 then
		tt:AddDoubleLine("Total", total, MUTED[1], MUTED[2], MUTED[3], 1, 1, 1)
	end
	return true
end

local function AddReagentFor(tt, itemID, detail)
	Index()
	local users = usedBy[itemID]
	if not users then
		return false
	end
	local list = {}
	for spellID, prof in pairs(users) do
		local name = GetSpellInfo(spellID)
		if name then
			table.insert(list, { name = name, prof = prof, known = KnownBy(spellID, prof) })
		end
	end
	if #list == 0 then
		return false
	end
	table.sort(list, function(a, b)
		if a.known ~= b.known then
			return a.known
		end
		return a.name < b.name
	end)
	if not detail then
		tt:AddDoubleLine("Used in recipes", #list, MUTED[1], MUTED[2], MUTED[3], 1, 1, 1)
		return true
	end
	tt:AddLine("Used in:", HEADER[1], HEADER[2], HEADER[3])
	for i = 1, math.min(#list, MAX_RECIPES) do
		local e = list[i]
		local shade = e.known and 1 or 0.55
		tt:AddDoubleLine("  " .. e.name, e.prof, shade, shade, shade, MUTED[1], MUTED[2], MUTED[3])
	end
	if #list > MAX_RECIPES then
		tt:AddLine(string.format("  +%d more", #list - MAX_RECIPES), MUTED[1], MUTED[2], MUTED[3])
	end
	return true
end

-- "Requires Tailoring (300)" from the tooltip's own lines.
local function RequiredSkill(tt)
	local name = tt:GetName()
	for i = 2, tt:NumLines() do
		local fs = _G[name .. "TextLeft" .. i]
		local text = fs and fs:GetText()
		if text then
			local prof, skill = text:match("^Requires ([%a ]+) %((%d+)%)$")
			if prof and NS.PROF_BY_KEY[prof] then
				return prof, tonumber(skill)
			end
		end
	end
end

local function AddRecipeItem(tt, itemName, detail)
	local taught
	for _, prefix in ipairs(RECIPE_PREFIXES) do
		taught = itemName:match("^" .. prefix .. ": (.+)$")
		if taught then
			break
		end
	end
	if not taught then
		return false
	end
	local prof, need = RequiredSkill(tt)
	if not prof then
		return false
	end
	Index()
	local spellID = spellByName[taught]

	local rows, knowN, learnN = {}, 0, 0
	for name, char in pairs(NS.Characters:All()) do
		local s = char.skills and char.skills[prof]
		if s then
			local known = spellID and char.recipes and char.recipes[prof] and char.recipes[prof][spellID]
			local status
			if known then
				status = "|cff40ff40knows it|r"
				knowN = knowN + 1
			elseif s.rank >= need then
				status = spellID and "|cffffff00can learn|r" or "|cffffff00can learn (if not known)|r"
				learnN = learnN + 1
			else
				status = string.format("|cffff6060needs %d (has %d)|r", need, s.rank)
			end
			table.insert(rows, { name = name, class = char.class, status = status })
		end
	end
	if #rows == 0 then
		return false
	end
	if not detail then
		tt:AddLine(string.format("%s: %d know it, %d can learn", prof, knowN, learnN), MUTED[1], MUTED[2], MUTED[3])
		return true
	end
	table.sort(rows, function(a, b) return a.name < b.name end)
	for _, r in ipairs(rows) do
		tt:AddDoubleLine(NS:ClassColoredName(r.name, r.class), r.status)
	end
	return true
end

local function IsBoundTooltip(tt)
	local name = tt:GetName()
	for i = 2, math.min(tt:NumLines(), 6) do
		local fs = _G[name .. "TextLeft" .. i]
		local text = fs and fs:GetText()
		if text == ITEM_SOULBOUND or text == ITEM_BIND_ON_PICKUP then
			return true
		end
	end
	return false
end

local function AddLoot(tt, itemID, detail)
	local r = NS.LootAdvisor:Evaluate(itemID, IsBoundTooltip(tt))
	if not r then
		return false
	end
	local LA = NS.LootAdvisor
	local headline = "Loot advice: " .. LA:VerdictText(r)
	if r.margin and r.margin > 0 then
		headline = headline .. " |cff9e9e9e(+" .. NS:FormatMoney(r.margin) .. " over " .. strlower(r.second) .. ")|r"
	end
	tt:AddLine(headline, HEADER[1], HEADER[2], HEADER[3])
	if not detail then
		return true
	end
	tt:AddDoubleLine("  Vendor", NS:FormatMoney(r.vendor or 0), MUTED[1], MUTED[2], MUTED[3], 1, 1, 1)
	if r.outcomes then
		local de = r.de and NS:FormatMoney(r.de) or "|cff808080no prices|r"
		if r.de and r.dePartial then
			de = de .. " |cff808080+?|r"
		end
		tt:AddDoubleLine("  Disenchant (avg)", de, MUTED[1], MUTED[2], MUTED[3], 1, 1, 1)
		for _, o in ipairs(r.outcomes) do
			local qty = o.min == o.max and tostring(o.min) or (o.min .. "-" .. o.max)
			tt:AddDoubleLine(string.format("    %s %s", qty, NS.ItemCache:Name(o.id)),
				string.format("%d%%", math.floor(o.chance * 100 + 0.5)), 0.75, 0.75, 0.75, MUTED[1], MUTED[2], MUTED[3])
		end
		if r.disenchanters then
			if #r.disenchanters == 0 then
				tt:AddLine(string.format("    Needs Enchanting %d - none of your characters has it", r.skill), MUTED[1], MUTED[2], MUTED[3])
			else
				local names = {}
				for i = 1, math.min(#r.disenchanters, 3) do
					names[i] = NS:ClassColoredName(r.disenchanters[i].name, r.disenchanters[i].class)
				end
				tt:AddLine("    Can disenchant: " .. table.concat(names, ", "), MUTED[1], MUTED[2], MUTED[3])
			end
		end
	end
	if r.ah then
		tt:AddDoubleLine("  Auction (-5%)", NS:FormatMoney(r.ah), MUTED[1], MUTED[2], MUTED[3], 1, 1, 1)
	end
	return true
end

----------------------------------------------------------------------------
-- Hooks
----------------------------------------------------------------------------
local function OnSetItem(tt)
	if tt.jpDone or not NS.db then
		return
	end
	local name, link = tt:GetItem()
	local itemID = NS:ItemIDFromLink(link)
	if not itemID then
		return
	end
	tt.jpDone = true
	local detail = not NS:Option("tooltipShort") or IsShiftKeyDown()

	-- Each section is wrapped so a bad record can't break the whole tooltip.
	local sections = {
		{ "tooltipLoot", function() return AddLoot(tt, itemID, detail) end },
		{ "tooltipRecipe", function() return AddRecipeItem(tt, name or "", detail) end },
		{ "tooltipReagent", function() return AddReagentFor(tt, itemID, detail) end },
		{ "tooltipCounts", function() return AddCounts(tt, itemID, detail) end },
	}
	local lines = tt:NumLines()
	for _, s in ipairs(sections) do
		if NS:Option(s[1]) then
			pcall(s[2])
		end
	end
	-- Resize the tooltip to fit the added lines.
	if tt:NumLines() > lines then
		tt:Show()
	end
end

local function OnCleared(tt)
	tt.jpDone = nil
end

local function Hook(tt)
	if not tt or tt.jpHooked then
		return
	end
	tt.jpHooked = true
	tt:HookScript("OnTooltipSetItem", OnSetItem)
	if tt:HasScript("OnTooltipCleared") then
		tt:HookScript("OnTooltipCleared", OnCleared)
	else
		tt:HookScript("OnHide", OnCleared)
	end
end

Hook(GameTooltip)
Hook(ItemRefTooltip)

-- Redraw a hovered item's tooltip when Shift is pressed/released in short mode.
local mod = CreateFrame("Frame")
mod:RegisterEvent("MODIFIER_STATE_CHANGED")
mod:SetScript("OnEvent", function(_, _, key)
	if not NS.db or not NS:Option("tooltipShort") then
		return
	end
	if (key == "LSHIFT" or key == "RSHIFT") and GameTooltip:IsShown() and GameTooltip:GetItem() then
		local owner = GameTooltip:GetOwner()
		if owner and owner:GetScript("OnEnter") then
			owner:GetScript("OnEnter")(owner)
		end
	end
end)
