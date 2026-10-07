-- Profession cooldowns for every character on the realm. Expiry times are
-- recorded by Characters:ScanTradeSkill whenever a profession window is open.
local NS = JohnnysProfessions
NS.Cooldowns = {}
local Cooldowns = NS.Cooldowns

local function GroupFor(spellID)
	local info = NS.COOLDOWNS[spellID]
	if info then
		return info.group
	end
	local name = GetSpellInfo(spellID)
	if name and name:find("^Transmute") then
		return "Transmute"
	end
	return name or ("spell #" .. spellID)
end

local function IsCooldownSpell(spellID)
	return NS.COOLDOWNS[spellID] or NS.db.global.cooldownSpells[spellID]
end

-- Array of { name=, class=, group=, prof=, expires=, used= } for one character,
-- one row per cooldown group they know.
function Cooldowns:ForChar(name, char)
	local byGroup = {}
	for prof, known in pairs(char.recipes or {}) do
		for spellID in pairs(known) do
			if IsCooldownSpell(spellID) then
				local group = GroupFor(spellID)
				local row = byGroup[group]
				if not row then
					row = { name = name, class = char.class, group = group, prof = prof, expires = 0, used = false }
					byGroup[group] = row
				end
				local exp = char.cooldowns and char.cooldowns[spellID]
				if exp then
					row.used = true
					if exp > row.expires then
						row.expires = exp
					end
				end
			end
		end
	end
	local list = {}
	for _, row in pairs(byGroup) do
		table.insert(list, row)
	end
	table.sort(list, function(a, b) return a.group < b.group end)
	return list
end

-- Every character's cooldowns, soonest-ready first.
function Cooldowns:All()
	local list = {}
	for name, char in pairs(NS.Characters:All()) do
		for _, row in ipairs(self:ForChar(name, char)) do
			table.insert(list, row)
		end
	end
	table.sort(list, function(a, b)
		if a.expires ~= b.expires then
			return a.expires < b.expires
		end
		return a.name < b.name
	end)
	return list
end

-- On login: list this character's cooldowns that are ready again (only ones
-- used at least once, so a never-used recipe doesn't nag every login).
function Cooldowns:AnnounceReady()
	if not NS.db.profile.ui.cooldownAlerts then
		return
	end
	local now = time()
	local ready = {}
	for _, row in ipairs(self:ForChar(NS.Characters.name, NS.Characters:Me())) do
		if row.used and row.expires <= now then
			table.insert(ready, row.group)
		end
	end
	if #ready > 0 then
		NS:Print("Cooldowns ready: |cff40ff40" .. table.concat(ready, ", ") .. "|r")
	end
end

----------------------------------------------------------------------------
-- Durations and in-session "ready" alerts
----------------------------------------------------------------------------
NS:RegisterOption("cooldownReadyAlert", true, "Cooldowns",
	"Alert when a cooldown becomes ready",
	"While you play, a chat line and a pop-up when any character's profession cooldown comes off cooldown.")

local CHECK_EVERY = 30
local FALLBACK_DURATION = 20 * 3600

-- Full length of each cooldown group, learned from what we observe: the
-- longest time-left ever seen for a group is (close to) its real duration.
local function Durations()
	local g = NS.db.global
	g.cooldownDurations = g.cooldownDurations or {}
	return g.cooldownDurations
end

function Cooldowns:Duration(group)
	return Durations()[group] or FALLBACK_DURATION
end

local function LearnDurations(rows, now)
	local d = Durations()
	for _, row in ipairs(rows) do
		local left = row.expires - now
		if left > 0 and left > (d[row.group] or 0) then
			d[row.group] = left
		end
	end
end

-- Progress toward ready, 0 (just used) .. 1 (ready).
function Cooldowns:Progress(row, now)
	local left = row.expires - (now or time())
	if not row.used or left <= 0 then
		return 1
	end
	return math.max(0, 1 - left / self:Duration(row.group))
end

-- [name .. group] = true while known to be on cooldown, so the moment it
-- turns ready can be spotted. Seeded at login so already-ready cooldowns
-- don't alert (the login message covers those).
local waiting

local function Check()
	if not NS.db then
		return
	end
	local now = time()
	local rows = Cooldowns:All()
	LearnDurations(rows, now)
	local first = waiting == nil
	waiting = waiting or {}
	for _, row in ipairs(rows) do
		local key = row.name .. ":" .. row.group
		if row.used and row.expires > now then
			waiting[key] = true
		elseif waiting[key] then
			waiting[key] = nil
			if not first and NS:Option("cooldownReadyAlert") then
				local who = NS:ClassColoredName(row.name, row.class)
				NS:Print(string.format("%s is ready on %s.", row.group, who))
				if NS.Toast then
					NS.Toast:Show({
						icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
						title = row.group .. " is ready",
						text = "On " .. row.name .. " (" .. row.prof .. ").",
						onClick = function()
							NS.MainWindow:ShowTab("Cooldowns")
						end,
					})
				end
			end
		end
	end
end

local ticker = CreateFrame("Frame")
local wait = 5
ticker:SetScript("OnUpdate", function(_, elapsed)
	wait = wait - elapsed
	if wait <= 0 then
		wait = CHECK_EVERY
		Check()
	end
end)
