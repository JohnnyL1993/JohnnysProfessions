-- "Who in my guild can craft this?" Guild members running this addon answer
-- a query over the hidden addon channel with whichever of their characters
-- know the recipe. Answers are kept per realm, so crafters still show up
-- while they're offline, with when they last answered.
--
-- Protocol (prefix "JPRO", GUILD channel, one line per message):
--   query:  "Q\t<spellID>"
--   answer: "A\t<spellID>\t<char>:<skill>,<char>:<skill>,..."
local NS = JohnnysProfessions
NS.GuildCrafters = {}
local GC = NS.GuildCrafters

local PREFIX = "JPRO"
local MAX_LEN = 250
local QUERY_COOLDOWN = 30   -- per recipe
local QUERY_GAP = 2         -- between any two queries

local lastQuery = {}        -- [spellID] = GetTime()
local lastAny = 0
local online = {}           -- [name] = true, from the guild roster

local function Store()
	local r = NS:RealmDB()
	r.guildCrafters = r.guildCrafters or {}
	return r.guildCrafters
end

local function ProfOf(spellID)
	local r = NS.db.global.recipeCache[spellID]
	return r and r.prof
end

-- This account's characters that know a recipe: { { name=, skill=, class= } }.
function GC:MyCrafters(spellID)
	local list = {}
	for name, char in pairs(NS.Characters:All()) do
		for prof, known in pairs(char.recipes or {}) do
			if known[spellID] then
				local s = char.skills and char.skills[prof]
				table.insert(list, { name = name, skill = s and s.rank or 0, class = char.class })
				break
			end
		end
	end
	table.sort(list, function(a, b) return a.skill > b.skill end)
	return list
end

----------------------------------------------------------------------------
-- Guild roster (online status)
----------------------------------------------------------------------------
local function ReadRoster()
	wipe(online)
	if not IsInGuild() then
		return
	end
	for i = 1, GetNumGuildMembers(true) do
		local name, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
		if name and isOnline then
			online[name] = true
		end
	end
end

function GC:IsOnline(name)
	return online[name] == true
end

----------------------------------------------------------------------------
-- Sending / answering
----------------------------------------------------------------------------
-- Asks the guild. Returns false (and a reason) if throttled or not in a guild.
function GC:Query(spellID)
	if not IsInGuild() then
		return false, "You're not in a guild."
	end
	local now = GetTime()
	if lastQuery[spellID] and now - lastQuery[spellID] < QUERY_COOLDOWN then
		return false, "Already asked - answers are coming in."
	end
	if now - lastAny < QUERY_GAP then
		return false, "Wait a moment before asking again."
	end
	lastQuery[spellID], lastAny = now, now
	SendAddonMessage(PREFIX, "Q\t" .. spellID, "GUILD")
	GuildRoster()
	return true
end

local function Answer(spellID)
	local mine = GC:MyCrafters(spellID)
	if #mine == 0 then
		return
	end
	local msg = "A\t" .. spellID .. "\t"
	local first = true
	for _, c in ipairs(mine) do
		local part = c.name .. ":" .. c.skill
		if #msg + #part + 1 > MAX_LEN then
			break
		end
		msg = msg .. (first and "" or ",") .. part
		first = false
	end
	SendAddonMessage(PREFIX, msg, "GUILD")
end

local function OnAnswer(spellID, sender, list)
	local chars = {}
	for name, skill in list:gmatch("([^:,]+):(%d+)") do
		table.insert(chars, { name = name, skill = tonumber(skill) })
	end
	if #chars == 0 then
		return
	end
	local store = Store()
	store[spellID] = store[spellID] or {}
	store[spellID][sender] = { chars = chars, time = time() }
	NS:RequestRedraw()
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_ADDON")
events:RegisterEvent("GUILD_ROSTER_UPDATE")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, prefix, msg, channel, sender)
	if event == "GUILD_ROSTER_UPDATE" then
		ReadRoster()
		return
	elseif event == "PLAYER_LOGIN" then
		if IsInGuild() then
			GuildRoster()
		end
		return
	end
	if prefix ~= PREFIX or channel ~= "GUILD" or not NS.db then
		return
	end
	if sender == UnitName("player") then
		return -- our own message echoed back
	end
	local kind, id, rest = strsplit("\t", msg, 3)
	id = tonumber(id)
	if not id then
		return
	end
	if kind == "Q" then
		Answer(id)
	elseif kind == "A" and rest then
		OnAnswer(id, sender, rest)
	end
end)

----------------------------------------------------------------------------
-- Results for the Crafters page
----------------------------------------------------------------------------
-- Array of { player=, chars={ {name=, skill=} }, time=, online=, whisper=,
-- mine= } - your own characters first, then guild answers, online first.
function GC:Results(spellID)
	local results = {}
	local mine = self:MyCrafters(spellID)
	if #mine > 0 then
		table.insert(results, { player = UnitName("player"), chars = mine, mine = true, online = true })
	end
	for sender, info in pairs(Store()[spellID] or {}) do
		local whisper
		if online[sender] then
			whisper = sender
		else
			for _, c in ipairs(info.chars) do
				if online[c.name] then
					whisper = c.name
					break
				end
			end
		end
		table.insert(results, {
			player = sender, chars = info.chars, time = info.time,
			online = whisper ~= nil, whisper = whisper or sender,
		})
	end
	table.sort(results, function(a, b)
		if a.mine ~= b.mine then
			return a.mine == true
		end
		if a.online ~= b.online then
			return a.online
		end
		return (a.time or 0) > (b.time or 0)
	end)
	return results
end

function GC:ProfessionOf(spellID)
	return ProfOf(spellID)
end
