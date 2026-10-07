-- Leveling guide engine. Guide data lives in Data\Guides\<Profession>.lua as
-- an ordered list of steps:
--
--   crafting:  { from = 1, to = 50, spell = 2963, count = 60,
--                reagents = { [2589] = 2 }, item = 2996, made = 1, note = "..." }
--   generic:   { from = 80, to = 100, title = "Any orange Glyph", count = 20, reagents = {...} }
--   gathering: { from = 1, to = 65, zones = { Alliance = "...", Horde = "..." },
--                note = "..." }        -- zones may also be one string
--
-- A crafting step may name only the product `item` (no `spell`); its recipe
-- is then looked up from the trade skill data once you've opened the window.
--
-- `count` is how many crafts the step takes (an estimate - recipes turn
-- yellow/green at different points). `faction` on a step limits it to
-- "Alliance" or "Horde". Reagents/product/made are read live from the trade
-- skill window once you've opened it (Characters.lua's recipeCache) and that
-- beats whatever the data file says.
local NS = JohnnysProfessions
NS.Guide = {}
local Guide = NS.Guide

function Guide:Has(prof)
	return NS.Guides[prof] ~= nil
end

-- Steps that apply to this character's faction. The list remembers which
-- profession it's for (steps.prof) so skipped steps can be looked up.
function Guide:GetSteps(prof)
	local all = NS.Guides[prof]
	if not all then
		return nil
	end
	local faction = UnitFactionGroup("player")
	local steps = { prof = prof }
	for _, step in ipairs(all) do
		if not step.faction or step.faction == faction then
			table.insert(steps, step)
		end
	end
	return steps
end

----------------------------------------------------------------------------
-- Skipped steps: ticking a step's box on the Professions page skips it, so
-- it no longer counts as the current step or towards the shopping list.
-- Stored per character, per profession, by index into GetSteps(prof).
----------------------------------------------------------------------------
local function Skipped(prof, create)
	local all = NS.db.profile.skippedSteps
	if not all then
		if not create then
			return nil
		end
		all = {}
		NS.db.profile.skippedSteps = all
	end
	if not all[prof] and create then
		all[prof] = {}
	end
	return all[prof]
end

function Guide:IsSkipped(prof, index)
	local t = prof and Skipped(prof)
	return t and t[index] or false
end

function Guide:ToggleSkip(prof, index)
	local t = Skipped(prof, true)
	t[index] = (not t[index]) or nil
end

-- Index of the step you're on: the first one you haven't finished or
-- skipped. nil once you're past the end of the guide.
function Guide:CurrentIndex(steps, rank)
	for i, step in ipairs(steps) do
		if rank < step.to and not self:IsSkipped(steps.prof, i) then
			return i
		end
	end
	return nil
end


function Guide:IsGathering(step)
	return step.zones ~= nil
end

-- product itemID -> recipe spellID, built from recipeCache on demand and
-- dropped whenever a trade skill scan adds recipes.
local spellByItem
NS.Characters:OnChange(function(what)
	if what == "recipes" then
		spellByItem = nil
	end
end)

function Guide:SpellFor(step)
	if step.spell then
		return step.spell
	end
	if not step.item then
		return nil
	end
	if not spellByItem then
		spellByItem = {}
		for spellID, r in pairs(NS.db.global.recipeCache) do
			if r.item then
				spellByItem[r.item] = spellID
			end
		end
	end
	return spellByItem[step.item]
end

local function Cached(step)
	local spell = Guide:SpellFor(step)
	return spell and NS.db.global.recipeCache[spell]
end

function Guide:Reagents(step)
	local c = Cached(step)
	return (c and c.reagents) or step.reagents or {}
end

function Guide:Product(step)
	local c = Cached(step)
	return step.item or (c and c.item)
end

function Guide:Made(step)
	local c = Cached(step)
	return step.made or (c and c.made) or 1
end

-- Some realms (Icecrown) give 3 skill points per skill-up instead of 1, so
-- every step takes a third of the crafts. On by default on those realms.
local TRIPLE_SKILLUP_REALMS = { "Icecrown" }
local function IsTripleRealm()
	local realm = GetRealmName() or ""
	for _, name in ipairs(TRIPLE_SKILLUP_REALMS) do
		if realm:find(name, 1, true) then
			return true
		end
	end
	return false
end
NS:RegisterOption("tripleSkillUps", IsTripleRealm(), "Professions",
	"3 skill points per skill-up",
	"For realms like Icecrown where each skill-up gives 3 points: guide craft counts and materials are divided by 3. On by default on Icecrown.")

function Guide:SkillPerCraft()
	return NS:Option("tripleSkillUps") and 3 or 1
end

-- Crafts still to do on this step at the given rank (scaled down linearly
-- once you're part-way through it, and by the realm's skill-up rate).
function Guide:CraftsLeft(step, rank)
	local count = (step.count or 0) / self:SkillPerCraft()
	if rank >= step.to then
		return 0
	elseif rank <= step.from then
		return math.ceil(count)
	end
	return math.ceil(count * (step.to - rank) / (step.to - step.from))
end

function Guide:StepName(step)
	if step.title then
		return step.title
	end
	if step.zones then
		return self:ZoneText(step) or "Gather"
	end
	local spell = self:SpellFor(step)
	local name = spell and GetSpellInfo(spell)
	if name then
		return name
	end
	if step.item then
		return NS.ItemCache:Name(step.item)
	end
	if spell then
		return "spell #" .. spell
	end
	return "Gather"
end

function Guide:ZoneText(step)
	if type(step.zones) == "string" then
		return step.zones
	elseif type(step.zones) == "table" then
		return step.zones[UnitFactionGroup("player")] or step.zones.both
	end
end

----------------------------------------------------------------------------
-- Skill-up colours
----------------------------------------------------------------------------
local DIFFICULTY_COLORS = {
	optimal = { "ff8040", "orange" },
	medium = { "ffff00", "yellow" },
	easy = { "40c040", "green" },
	trivial = { "808080", "grey" },
}
Guide.DIFFICULTY_COLORS = DIFFICULTY_COLORS

-- { orange, yellow, green, grey } skill thresholds from Data\SkillUps.lua.
function Guide:SkillRange(spell)
	return spell and NS.SKILLUPS and NS.SKILLUPS[spell]
end

-- Difficulty ("optimal"/"medium"/"easy"/"trivial") a recipe has at `rank`
-- according to the skill-up data, or nil if unknown.
function Guide:DifficultyAt(spell, rank)
	local r = self:SkillRange(spell)
	if not r or not rank then
		return nil
	end
	if rank >= r[4] then
		return "trivial"
	elseif rank >= r[3] then
		return "easy"
	elseif rank >= r[2] then
		return "medium"
	end
	return "optimal"
end

function Guide:ColorWord(difficulty)
	local c = DIFFICULTY_COLORS[difficulty]
	return c and ("|cff" .. c[1] .. c[2] .. "|r")
end

-- The four thresholds coloured: orange yellow green grey.
function Guide:RangeText(spell)
	local r = self:SkillRange(spell)
	if not r then
		return nil
	end
	local order = { "optimal", "medium", "easy", "trivial" }
	local parts = {}
	for i = 1, 4 do
		table.insert(parts, "|cff" .. DIFFICULTY_COLORS[order[i]][1] .. r[i] .. "|r")
	end
	return table.concat(parts, "  ")
end

-- Skill-up colour of a step's recipe: as the trade window last showed it,
-- else estimated from the skill-up data at `rank` (when given).
function Guide:DifficultyText(step, rank)
	local spell = self:SpellFor(step)
	local d = spell and NS.Characters.difficulty[spell]
	if not d and rank then
		d = self:DifficultyAt(spell, rank)
	end
	return d and self:ColorWord(d)
end

----------------------------------------------------------------------------
-- Live trade skill window helpers (only meaningful while it's open)
----------------------------------------------------------------------------
-- True when the open trade skill window is this character's own `prof`.
function Guide:TradeWindowIs(prof)
	if IsTradeSkillLinked and IsTradeSkillLinked() then
		return false
	end
	return GetTradeSkillLine() == prof
end

-- index, numAvailable, difficulty of a recipe in the open window.
function Guide:FindTradeIndex(spell)
	if not spell then
		return nil
	end
	for i = 1, GetNumTradeSkills() do
		local _, skillType, numAvailable = GetTradeSkillInfo(i)
		if skillType ~= "header" and NS:SpellIDFromLink(GetTradeSkillRecipeLink(i)) == spell then
			return i, numAvailable or 0, skillType
		end
	end
	return nil
end

local function RecipeCost(spell)
	local r = NS.db.global.recipeCache[spell]
	if not r or not r.reagents then
		return math.huge
	end
	local total = 0
	for id, n in pairs(r.reagents) do
		local each = NS.Prices:GetCost(id)
		if not each then
			return math.huge
		end
		total = total + each * n
	end
	return total
end

-- The recipe in the open window most likely to give a skill-up right now:
-- orange before yellow, craftable-now before not, then cheapest mats.
-- Returns { index=, spell=, name=, difficulty=, numAvailable= } or nil.
function Guide:BestPick()
	local best, bestKey
	for i = 1, GetNumTradeSkills() do
		local name, skillType, numAvailable = GetTradeSkillInfo(i)
		if skillType == "optimal" or skillType == "medium" then
			local spell = NS:SpellIDFromLink(GetTradeSkillRecipeLink(i))
			if spell then
				local key = (skillType == "optimal" and 0 or 2) + ((numAvailable or 0) > 0 and 0 or 1)
				local cost = RecipeCost(spell)
				if not best or key < bestKey or (key == bestKey and cost < best.cost) then
					best = {
						index = i, spell = spell, name = name, difficulty = skillType,
						numAvailable = numAvailable or 0, cost = cost,
					}
					bestKey = key
				end
			end
		end
	end
	return best
end

----------------------------------------------------------------------------
-- World map zones (zone buttons on gathering steps)
----------------------------------------------------------------------------
local zoneLookup -- [zone name] = { continent, index }; "X City" also as "X"
local function ZoneLookup()
	if zoneLookup then
		return zoneLookup
	end
	zoneLookup = {}
	for c = 1, 4 do
		local zones = { GetMapZones(c) }
		for i, name in ipairs(zones) do
			zoneLookup[name] = { c, i }
			local short = name:match("^(.-) City$")
			if short and not zoneLookup[short] then
				zoneLookup[short] = { c, i }
			end
		end
	end
	return zoneLookup
end

-- Map zones named anywhere in `text`, in the order they appear.
function Guide:ZonesIn(text)
	local found = {}
	if not text or text == "" then
		return found
	end
	for name in pairs(ZoneLookup()) do
		local pos = string.find(text, name, 1, true)
		if pos then
			table.insert(found, { name = name, pos = pos, len = #name })
		end
	end
	-- Drop matches inside a longer one ("Stormwind" in "Stormwind City").
	table.sort(found, function(a, b)
		if a.pos ~= b.pos then
			return a.pos < b.pos
		end
		return a.len > b.len
	end)
	local list, lastEnd = {}, 0
	for _, f in ipairs(found) do
		if f.pos > lastEnd then
			table.insert(list, f.name)
			lastEnd = f.pos + f.len - 1
		end
	end
	return list
end

-- Opens the world map on a zone from ZonesIn.
function Guide:OpenMap(zone)
	local z = ZoneLookup()[zone]
	if not z then
		return
	end
	ShowUIPanel(WorldMapFrame)
	SetMapZoom(z[1], z[2])
end


----------------------------------------------------------------------------
-- Materials
----------------------------------------------------------------------------
-- Net materials still needed to finish the guide from `rank`: reagents of
-- the current step's remaining crafts and every later step, minus whatever
-- earlier steps in that range produce (so a "make 40 bolts" step covers the
-- bolts later steps use, instead of being counted twice).
-- Returns { [itemID] = count }.
function Guide:RemainingMats(prof, rank, steps)
	steps = steps or self:GetSteps(prof)
	local need = {}
	if not steps then
		return need
	end
	local start = self:CurrentIndex(steps, rank)
	if not start then
		return need
	end
	local produced = {}
	for i = start, #steps do
		local step = steps[i]
		local crafts = self:CraftsLeft(step, rank)
		if crafts > 0 and not step.zones and not self:IsSkipped(steps.prof, i) then
			for id, n in pairs(self:Reagents(step)) do
				local want = n * crafts
				local fromEarlier = math.min(produced[id] or 0, want)
				produced[id] = (produced[id] or 0) - fromEarlier
				want = want - fromEarlier
				if want > 0 then
					need[id] = (need[id] or 0) + want
				end
			end
			local product = self:Product(step)
			if product then
				produced[product] = (produced[product] or 0) + math.floor(crafts * self:Made(step))
			end
		end
	end
	return need
end

-- Materials for just the current step's remaining crafts.
function Guide:StepMats(step, rank)
	local mats = {}
	local crafts = self:CraftsLeft(step, rank)
	for id, n in pairs(self:Reagents(step)) do
		mats[id] = n * crafts
	end
	return mats
end

-- Shopping list across several professions. Returns a sorted array of
--   { id=, need=, mine=, alts=, altList=, short= }
-- where `short` is what's left to buy/farm after your own and your alts'
-- stock.
function Guide:ShoppingList(profs)
	local Chars = NS.Characters
	local skills = Chars:Me().skills
	local total = {}
	for _, prof in ipairs(profs) do
		local s = skills[prof]
		if s and self:Has(prof) then
			for id, n in pairs(self:RemainingMats(prof, s.rank)) do
				total[id] = (total[id] or 0) + n
			end
		end
	end
	local list = {}
	for id, need in pairs(total) do
		local mine = Chars:MyCount(id)
		local alts, altList = Chars:AltCounts(id)
		table.insert(list, {
			id = id, need = need, mine = mine, alts = alts, altList = altList,
			short = math.max(0, need - mine - alts),
		})
	end
	table.sort(list, function(a, b)
		if (a.short > 0) ~= (b.short > 0) then
			return a.short > 0
		end
		return a.id < b.id
	end)
	return list
end

-- Guided professions this character has learned, in NS.PROFESSIONS order.
function Guide:MyGuidedProfessions()
	local skills = NS.Characters:Me().skills
	local list = {}
	for _, p in ipairs(NS.PROFESSIONS) do
		if skills[p.key] and self:Has(p.key) then
			table.insert(list, p.key)
		end
	end
	return list
end

----------------------------------------------------------------------------
-- Data validation (/jp debug)
----------------------------------------------------------------------------
-- Spell IDs can be checked against the client's own spell data. Item IDs
-- can't be checked reliably (GetItemInfo is nil for anything not cached
-- yet), so only spells and step ordering are reported.
function Guide:ReportInvalidData()
	local bad, total = 0, 0
	for prof, steps in pairs(NS.Guides) do
		local prevTo = 0
		for i, step in ipairs(steps) do
			total = total + 1
			if step.spell and not GetSpellInfo(step.spell) then
				bad = bad + 1
				NS:Print(string.format("%s step %d (%d-%d): unknown spell %d", prof, i, step.from, step.to, step.spell))
			end
			if step.to <= step.from then
				bad = bad + 1
				NS:Print(string.format("%s step %d: 'to' (%d) is not above 'from' (%d)", prof, i, step.to, step.from))
			end
			if not step.faction and step.to <= prevTo then
				NS:Print(string.format("%s step %d (%d-%d) is fully covered by the step before it", prof, i, step.from, step.to))
			end
			if not step.faction then
				prevTo = step.to
			end
		end
	end
	NS:Print(string.format("Checked %d guide steps: %d problem(s).", total, bad))
end
