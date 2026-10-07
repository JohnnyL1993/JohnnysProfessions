-- Item goals ("collect 120 Copper Ore"). Counts are this character's bags +
-- bank + mail, plus anything bought on the AH that's on its way to the
-- mailbox. A chat message and sound play the first time a goal is met.
local NS = JohnnysProfessions
NS.Tracker = {}
local Tracker = NS.Tracker

local reached = {} -- session-only: [itemID] = true once announced
local listeners = {}

function Tracker:OnChange(fn)
	table.insert(listeners, fn)
end
local function Notify()
	for _, fn in ipairs(listeners) do
		fn()
	end
end

local function Goals()
	return NS.db.profile.trackerGoals
end

function Tracker:Goals()
	return Goals()
end

----------------------------------------------------------------------------
-- AH purchases waiting in the mailbox. Bought items go straight to the mail,
-- which this addon can only read while the mailbox is open, so buyouts are
-- remembered here until the next mailbox visit counts them for real.
----------------------------------------------------------------------------
local function Pending()
	local p = NS.db.profile
	p.pendingMail = p.pendingMail or {}
	return p.pendingMail
end

-- Items of this ID bought since the last mailbox visit.
function Tracker:PendingCount(id)
	return Pending()[id] or 0
end

-- Items of this ID in the mailbox: last-seen mail plus pending buyouts.
function Tracker:MailCount(id)
	local me = NS.Characters:Me()
	return ((me and me.mail[id]) or 0) + self:PendingCount(id)
end

function Tracker:Count(id)
	return NS.Characters:MyCount(id) + self:PendingCount(id)
end

hooksecurefunc("PlaceAuctionBid", function(listType, index, bid)
	local _, _, count, _, _, _, _, _, buyout = GetAuctionItemInfo(listType, index)
	local id = NS:ItemIDFromLink(GetAuctionItemLink(listType, index))
	if not id or not buyout or buyout <= 0 or not bid or bid < buyout then
		return -- a bid, not a buyout: nothing is won yet
	end
	count = count or 1
	Pending()[id] = (Pending()[id] or 0) + count
	if Goals()[id] then
		NS:Print(string.format("Bought %dx %s - waiting in your mailbox.", count, NS.ItemCache:ColoredName(id)))
	end
	Tracker:CheckGoals()
end)

local mailEvents = CreateFrame("Frame")
mailEvents:RegisterEvent("MAIL_INBOX_UPDATE")
mailEvents:SetScript("OnEvent", function()
	-- The inbox is readable now, so Characters' mail counts include the
	-- purchases; stop counting them twice.
	if next(Pending()) then
		wipe(Pending())
		Notify()
	end
end)

----------------------------------------------------------------------------
-- Goals
----------------------------------------------------------------------------
function Tracker:Set(id, target)
	if target and target > 0 then
		Goals()[id] = target
		reached[id] = self:Count(id) >= target or nil
	else
		Goals()[id] = nil
		reached[id] = nil
	end
	Notify()
end

function Tracker:Adjust(id, delta)
	self:Set(id, math.max(0, (Goals()[id] or 0) + delta))
end

function Tracker:Remove(id)
	self:Set(id, nil)
end

function Tracker:Clear()
	wipe(Goals())
	wipe(reached)
	Notify()
end

-- Adds a goal for every item a shopping list is short on. The goal is the
-- full amount needed, so it counts down as you gather/buy and mail to self.
function Tracker:TrackShoppingList(list)
	local added = 0
	for _, entry in ipairs(list) do
		if entry.short > 0 then
			Goals()[entry.id] = math.max(Goals()[entry.id] or 0, entry.need)
			added = added + 1
		end
	end
	Notify()
	return added
end

-- Which of your professions an item is for: the first guided profession
-- whose remaining route uses it, else a known recipe that uses it, else nil.
local function GroupMap()
	local map = {}
	local me = NS.Characters:Me()
	for _, prof in ipairs(NS.Guide:MyGuidedProfessions()) do
		local s = me.skills[prof]
		for id in pairs(NS.Guide:RemainingMats(prof, s and s.rank or 0)) do
			map[id] = map[id] or prof
		end
	end
	local cache = NS.db.global.recipeCache
	for prof, known in pairs(me.recipes) do
		for spellID in pairs(known) do
			local r = cache[spellID]
			if r then
				for id in pairs(r.reagents or {}) do
					map[id] = map[id] or prof
				end
			end
		end
	end
	return map
end

-- Sorted array of { id=, target=, count=, mail=, group= } for display,
-- grouped by profession ("Other" last), unfinished goals first in a group.
function Tracker:List()
	local groups = GroupMap()
	local list = {}
	for id, target in pairs(Goals()) do
		table.insert(list, {
			id = id, target = target, count = self:Count(id),
			mail = self:MailCount(id), group = groups[id] or "Other",
		})
	end
	table.sort(list, function(a, b)
		if a.group ~= b.group then
			if a.group == "Other" or b.group == "Other" then
				return b.group == "Other"
			end
			return a.group < b.group
		end
		local doneA, doneB = a.count >= a.target, b.count >= b.target
		if doneA ~= doneB then
			return doneB
		end
		return a.id < b.id
	end)
	return list
end

-- Called whenever item counts change.
function Tracker:CheckGoals()
	for id, target in pairs(Goals()) do
		local count = self:Count(id)
		if count >= target then
			if not reached[id] then
				reached[id] = true
				NS:Print(string.format("Goal reached: %s %d/%d", NS.ItemCache:ColoredName(id), count, target))
				PlaySound("ReadyCheck")
			end
		else
			reached[id] = nil
		end
	end
	Notify()
end

-- Marks goals already met at login as announced, so logging in doesn't spam.
function Tracker:Init()
	for id, target in pairs(Goals()) do
		if self:Count(id) >= target then
			reached[id] = true
		end
	end
end

----------------------------------------------------------------------------
-- Finding items by name. Only items the client has cached have names, so
-- the search covers what this addon knows about: guide materials/products,
-- recorded recipes, tracked items, and what's in your bags and bank.
----------------------------------------------------------------------------
local nameIndex, indexBuilt = nil, 0

local function BuildIndex()
	local ids = {}
	for _, steps in pairs(NS.Guides) do
		for _, step in ipairs(steps) do
			if step.item then
				ids[step.item] = true
			end
			for id in pairs(step.reagents or {}) do
				ids[id] = true
			end
		end
	end
	for _, r in pairs(NS.db.global.recipeCache) do
		if r.item then
			ids[r.item] = true
		end
		for id in pairs(r.reagents or {}) do
			ids[id] = true
		end
	end
	for id in pairs(Goals()) do
		ids[id] = true
	end
	local me = NS.Characters:Me()
	for id in pairs(me.bags) do
		ids[id] = true
	end
	for id in pairs(me.bank) do
		ids[id] = true
	end
	nameIndex = {}
	for id in pairs(ids) do
		local name = GetItemInfo(id)
		if name then
			table.insert(nameIndex, { id = id, name = name, lower = strlower(name) })
		else
			NS.ItemCache:Request(id)
		end
	end
	table.sort(nameIndex, function(a, b) return a.name < b.name end)
	indexBuilt = GetTime()
end

-- Up to `limit` item IDs whose name matches `query`: exact match first,
-- then names starting with it, then names containing it.
function Tracker:FindItems(query, limit)
	query = strlower(strtrim(query or ""))
	if query == "" then
		return {}
	end
	-- Rebuild now and then so newly cached names become searchable.
	if not nameIndex or GetTime() - indexBuilt > 30 then
		BuildIndex()
	end
	local exact, starts, contains = {}, {}, {}
	for _, e in ipairs(nameIndex) do
		if e.lower == query then
			table.insert(exact, e.id)
		elseif e.lower:sub(1, #query) == query then
			table.insert(starts, e.id)
		elseif e.lower:find(query, 1, true) then
			table.insert(contains, e.id)
		end
	end
	local out = {}
	for _, group in ipairs({ exact, starts, contains }) do
		for _, id in ipairs(group) do
			if #out >= (limit or 8) then
				return out
			end
			table.insert(out, id)
		end
	end
	return out
end

-- Item ID for a typed name, link or ID, or nil.
function Tracker:Resolve(text)
	text = strtrim(text or "")
	local id = NS:ItemIDFromLink(text) or tonumber(text)
	if id then
		return id
	end
	local found = self:FindItems(text, 1)
	if found[1] then
		return found[1]
	end
	-- GetItemInfo accepts a name for anything cached this session.
	local _, link = GetItemInfo(text)
	return NS:ItemIDFromLink(link)
end

----------------------------------------------------------------------------
-- /jp track [count] [item name or link] [count]
----------------------------------------------------------------------------
local DEFAULT_GOAL = 20

NS:RegisterSlash("track", function(rest)
	rest = strtrim(rest or "")
	if rest == "" then
		NS.TrackerWindow:Toggle()
		return
	end
	local id = NS:ItemIDFromLink(rest)
	local text = rest:gsub("|c%x+|Hitem:[^|]+|h[^|]*|h|r", " ")
	local count
	text = text:gsub("^%s*(%d+)%s+", function(n) count = tonumber(n) return "" end)
	text = text:gsub("%s+(%d+)%s*$", function(n) count = count or tonumber(n) return "" end)
	text = strtrim(text)
	if not id and text:match("^%d+$") then
		-- "/jp track 20" alone is a count with no item
		text = ""
	end
	if not id and text ~= "" then
		id = Tracker:Resolve(text)
	end
	if not id then
		NS:Print(text ~= "" and ("Couldn't find an item called \"" .. text .. "\". Shift-click it into the command, or open the tracker and search there.")
			or "Usage: /jp track 20 Copper Ore  (or Shift-click an item link)")
		return
	end
	count = count or DEFAULT_GOAL
	Tracker:Set(id, count)
	NS:Print(string.format("Tracking %dx %s.", count, NS.ItemCache:ColoredName(id)))
	NS.TrackerWindow:Show()
end, "/jp track [count] <item> - show/hide the tracker, or track an item (name or Shift-clicked link)")
