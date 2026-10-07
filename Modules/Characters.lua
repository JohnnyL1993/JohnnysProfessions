-- Collects everything the rest of the addon reads about each character:
-- profession ranks, known recipes, item counts (bags / bank / mail), gold and
-- trade skill cooldowns. Stored realm-wide in db.global so alts can see each
-- other. Bank and mail counts can only be refreshed while those frames are
-- open, so they're kept from the last visit.
local NS = JohnnysProfessions
NS.Characters = {}
local Chars = NS.Characters

local me
local bankOpen = false
local scanningSkills = false

-- Fired (via NS:SendMessage-style callbacks) whenever stored data changes, so
-- open windows can redraw. Kept dead simple: a list of functions.
local listeners = {}
function Chars:OnChange(fn)
	table.insert(listeners, fn)
end
local function Notify(what)
	for _, fn in ipairs(listeners) do
		fn(what)
	end
end

function Chars:Init()
	local name = UnitName("player")
	local chars = NS:RealmDB().chars
	me = chars[name] or {}
	chars[name] = me
	me.skills = me.skills or {}
	me.recipes = me.recipes or {}
	me.bags = me.bags or {}
	me.bank = me.bank or {}
	me.mail = me.mail or {}
	me.cooldowns = me.cooldowns or {}
	self.name = name
	self:UpdateBasics()
end

function Chars:Me()
	return me
end

function Chars:All()
	return NS:RealmDB().chars
end

function Chars:UpdateBasics()
	me.class = select(2, UnitClass("player"))
	me.level = UnitLevel("player")
	me.faction = UnitFactionGroup("player")
	me.money = GetMoney()
	me.lastSeen = time()
end

----------------------------------------------------------------------------
-- Skills
----------------------------------------------------------------------------
function Chars:ScanSkills()
	if scanningSkills then
		return
	end
	scanningSkills = true

	-- Collapsed headers hide their skills from GetSkillLineInfo, so expand
	-- any collapsed ones, read, then collapse them again (walking backwards
	-- so expanding doesn't shift indexes we haven't visited yet).
	local collapsed = {}
	local touched = false
	for i = GetNumSkillLines(), 1, -1 do
		local name, isHeader, isExpanded = GetSkillLineInfo(i)
		if isHeader and not isExpanded then
			collapsed[name] = true
			touched = true
			ExpandSkillHeader(i)
		end
	end

	local skills = {}
	for i = 1, GetNumSkillLines() do
		local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
		if not isHeader and NS.PROF_BY_KEY[name] then
			skills[name] = { rank = rank, max = maxRank }
		end
	end

	for i = GetNumSkillLines(), 1, -1 do
		local name, isHeader, isExpanded = GetSkillLineInfo(i)
		if isHeader and isExpanded and collapsed[name] then
			CollapseSkillHeader(i)
		end
	end

	-- Expanding/collapsing fires SKILL_LINES_CHANGED itself; ignore those
	-- echoes or every scan would schedule another one.
	if touched then
		self.ignoreSkillEventsUntil = GetTime() + 1
	end

	me.skills = skills
	-- Drop recipe lists for professions this character has unlearned.
	for prof in pairs(me.recipes) do
		if not skills[prof] then
			me.recipes[prof] = nil
		end
	end
	scanningSkills = false
	Notify("skills")
end

----------------------------------------------------------------------------
-- Trade skill window: known recipes, live reagents, cooldowns
----------------------------------------------------------------------------
-- Session-only: the colour the trade window currently shows for each recipe
-- ("optimal" = orange, "medium" = yellow, "easy" = green, "trivial" = grey).
Chars.difficulty = {}

function Chars:ScanTradeSkill()
	if IsTradeSkillLinked and IsTradeSkillLinked() then
		return
	end
	local line, rank, maxRank = GetTradeSkillLine()
	if not line or not NS.PROF_BY_KEY[line] then
		return
	end
	if rank and maxRank and maxRank > 0 then
		me.skills[line] = { rank = rank, max = maxRank }
	end

	local known = me.recipes[line] or {}
	me.recipes[line] = known
	local cache = NS.db.global.recipeCache
	local cdSpells = NS.db.global.cooldownSpells
	local now = time()

	-- Only recipes visible under the window's current filters can be read;
	-- recipes are merged in rather than replaced so a filtered view never
	-- "forgets" anything.
	for i = 1, GetNumTradeSkills() do
		local name, skillType = GetTradeSkillInfo(i)
		if name and skillType ~= "header" then
			local spellID = NS:SpellIDFromLink(GetTradeSkillRecipeLink(i))
			if spellID then
				known[spellID] = true
				self.difficulty[spellID] = skillType

				local entry = cache[spellID] or {}
				entry.prof = line
				entry.item = NS:ItemIDFromLink(GetTradeSkillItemLink(i))
				local minMade, maxMade = GetTradeSkillNumMade(i)
				entry.made = ((minMade or 1) + (maxMade or minMade or 1)) / 2
				local reagents = {}
				local complete = true
				for r = 1, GetTradeSkillNumReagents(i) do
					local _, _, count = GetTradeSkillReagentInfo(i, r)
					local id = NS:ItemIDFromLink(GetTradeSkillReagentItemLink(i, r))
					if id and count then
						reagents[id] = count
					else
						complete = false
					end
				end
				if complete then
					entry.reagents = reagents
				end
				cache[spellID] = entry

				local cd = GetTradeSkillCooldown(i)
				if cd and cd > 0 then
					cdSpells[spellID] = true
					me.cooldowns[spellID] = now + cd
				elseif me.cooldowns[spellID] then
					me.cooldowns[spellID] = now
				end
			end
		end
	end
	Notify("recipes")
end

----------------------------------------------------------------------------
-- Items
----------------------------------------------------------------------------
local function CountContainer(counts, bag)
	for slot = 1, GetContainerNumSlots(bag) do
		local id = NS:ItemIDFromLink(GetContainerItemLink(bag, slot))
		if id then
			local _, count = GetContainerItemInfo(bag, slot)
			counts[id] = (counts[id] or 0) + (count or 1)
		end
	end
end

function Chars:ScanBags()
	local counts = {}
	for bag = 0, NUM_BAG_SLOTS do
		CountContainer(counts, bag)
	end
	me.bags = counts
	Notify("items")
end

function Chars:ScanBank()
	if not bankOpen then
		return
	end
	local counts = {}
	CountContainer(counts, BANK_CONTAINER)
	for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
		CountContainer(counts, bag)
	end
	me.bank = counts
	Notify("items")
end

function Chars:ScanMail()
	local counts = {}
	for i = 1, GetInboxNumItems() do
		for a = 1, ATTACHMENTS_MAX_RECEIVE do
			local id = NS:ItemIDFromLink(GetInboxItemLink(i, a))
			if id then
				local _, _, count = GetInboxItem(i, a)
				counts[id] = (counts[id] or 0) + (count or 1)
			end
		end
	end
	me.mail = counts
	Notify("items")
end

function Chars:SetBankOpen(open)
	bankOpen = open
	if open then
		self:ScanBank()
	end
end

function Chars:IsBankOpen()
	return bankOpen
end

-- How many of `itemID` a character has across bags, bank and mail.
function Chars:Count(char, itemID)
	return (char.bags[itemID] or 0) + (char.bank[itemID] or 0) + (char.mail[itemID] or 0)
end

function Chars:MyCount(itemID)
	return self:Count(me, itemID)
end

-- Returns total held by alts, plus a { {name=, count=}, ... } breakdown.
function Chars:AltCounts(itemID)
	local total, list = 0, {}
	for name, char in pairs(self:All()) do
		if char ~= me and char.bags then
			local n = self:Count(char, itemID)
			if n > 0 then
				total = total + n
				table.insert(list, { name = name, class = char.class, count = n })
			end
		end
	end
	table.sort(list, function(a, b) return a.count > b.count end)
	return total, list
end

----------------------------------------------------------------------------
-- Throttled rescans (BAG_UPDATE can fire dozens of times a second)
----------------------------------------------------------------------------
local dirty = {}
local throttle = CreateFrame("Frame")
throttle:Hide()
local wait = 0
throttle:SetScript("OnUpdate", function(self, elapsed)
	wait = wait - elapsed
	if wait > 0 then
		return
	end
	self:Hide()
	-- Copy then clear first, so anything a scan schedules (e.g. the skill
	-- scan's own SKILL_LINES_CHANGED) isn't wiped before it runs.
	local todo = {}
	for k in pairs(dirty) do
		todo[k] = true
	end
	wipe(dirty)
	if todo.bags then Chars:ScanBags() end
	if todo.bank then Chars:ScanBank() end
	if todo.mail then Chars:ScanMail() end
	if todo.trade then Chars:ScanTradeSkill() end
	if todo.skills then Chars:ScanSkills() end
end)

function Chars:Schedule(what, delay)
	dirty[what] = true
	if not throttle:IsShown() then
		wait = delay or 0.5
		throttle:Show()
	end
end
