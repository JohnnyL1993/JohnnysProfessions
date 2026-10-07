-- Farming sessions and gathering reminders.
--
-- /jp farm starts/stops a session: a small window counts what you loot, what
-- it's worth (AH price after the cut, else the vendor price), gold per hour
-- and the skill-ups you've made since it started.
--
-- Reminders (each can be turned off in Settings): Find Minerals / Find Herbs
-- is off while you're out in the world, you have Mining/Skinning but no pick
-- or knife, and you're fishing without a lure while you carry one.
local NS = JohnnysProfessions
NS.Farm = {}
local Farm = NS.Farm

NS:RegisterOption("farmRemindTracking", true, "Gathering",
	"Remind me when Find Minerals / Find Herbs is off",
	"Once per zone, when you're out in the world with the tracking for your gathering profession turned off.")
NS:RegisterOption("farmRemindTools", true, "Gathering",
	"Remind me about a missing Mining Pick / Skinning Knife",
	"Once per session, if you have the profession but not the tool in your bags.")
NS:RegisterOption("farmRemindLure", true, "Gathering",
	"Suggest a fishing lure",
	"When you fish without a lure on your pole and carry one your skill can use.")

NS:RegisterSlash("farm", function() Farm:Toggle() end, "/jp farm - start/stop a farming session (gold per hour)")

local WIDTH = 270
local MAX_ROWS = 8
local LURE_NAG = 600

local session          -- { start=, stop=, items={[id]=n}, skills={[prof]=rank} }
local frame, summary, rows, toggleBtn
local lastLureNag = 0
local remindedZones, remindedTools = {}, {}

----------------------------------------------------------------------------
-- Loot parsing
----------------------------------------------------------------------------
-- Turns a GlobalStrings format ("You receive loot: %sx%d.") into a Lua
-- pattern capturing the link and count.
local function ToPattern(fmt)
	fmt = fmt:gsub("([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
	fmt = fmt:gsub("%%s", "(.+)")
	fmt = fmt:gsub("%%d", "(%%d+)")
	return "^" .. fmt .. "$"
end

local LOOT_PATTERNS = {}
local function BuildPatterns()
	-- Multiple-item formats first, so "x5" isn't swallowed by the link capture.
	for _, key in ipairs({ "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_SELF", "LOOT_ITEM_PUSHED_SELF" }) do
		local fmt = _G[key]
		if fmt then
			table.insert(LOOT_PATTERNS, ToPattern(fmt))
		end
	end
end

local function ParseLoot(msg)
	for _, pattern in ipairs(LOOT_PATTERNS) do
		local link, count = msg:match(pattern)
		if link then
			return NS:ItemIDFromLink(link), tonumber(count) or 1
		end
	end
end

----------------------------------------------------------------------------
-- Session
----------------------------------------------------------------------------
local function Ranks()
	local ranks = {}
	for prof, s in pairs(NS.Characters:Me().skills) do
		ranks[prof] = s.rank
	end
	return ranks
end

local function ItemValue(id)
	local v = NS.Prices:GetSellValue(id)
	if v then
		return v, "ah"
	end
	v = NS.Prices:GetVendorSell(id)
	if v and v > 0 then
		return v, "vendor"
	end
	return 0
end

function Farm:IsRunning()
	return session and not session.stop
end

function Farm:Start()
	session = { start = time(), items = {}, skills = Ranks() }
	NS:Print("Farming session started - /jp farm again to stop.")
	self:Show()
end

function Farm:Stop()
	if not self:IsRunning() then
		return
	end
	session.stop = time()
	local total, elapsed = self:Totals()
	NS:Print(string.format("Farming session stopped: %s in %s (%s per hour).",
		NS:FormatMoney(total), NS:FormatDuration(math.max(60, elapsed)), NS:FormatMoney(self:PerHour())))
	self:Refresh()
end

function Farm:Toggle()
	if self:IsRunning() then
		self:Stop()
	else
		self:Start()
	end
end

-- Total value looted and seconds elapsed.
function Farm:Totals()
	if not session then
		return 0, 0
	end
	local total = 0
	for id, n in pairs(session.items) do
		total = total + ItemValue(id) * n
	end
	return total, (session.stop or time()) - session.start
end

function Farm:PerHour()
	local total, elapsed = self:Totals()
	if elapsed < 60 then
		return 0
	end
	return total * 3600 / elapsed
end

----------------------------------------------------------------------------
-- Window
----------------------------------------------------------------------------
local function Build()
	local W = NS.Widgets
	frame = W:CreateWindow("Farm", "Farming", WIDTH, 96 + MAX_ROWS * 18)
	frame:SetFrameStrata("MEDIUM")

	summary = W:Label(frame)
	summary:SetPoint("TOPLEFT", 10, -32)
	summary:SetWidth(WIDTH - 20)
	summary:SetJustifyV("TOP")

	rows = {}
	for i = 1, MAX_ROWS do
		local row = CreateFrame("Frame", nil, frame)
		row:SetSize(WIDTH - 20, 18)
		row:SetPoint("TOPLEFT", 10, -86 - (i - 1) * 18)
		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(14, 14)
		row.icon:SetPoint("LEFT")
		row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		row.name = W:Label(row)
		row.name:SetPoint("LEFT", 20, 0)
		row.name:SetWidth(150)
		row.value = W:Label(row)
		row.value:SetPoint("RIGHT")
		row.value:SetJustifyH("RIGHT")
		rows[i] = row
	end

	toggleBtn = NS.Skin:CreateButton(frame, 70, 20, "Stop")
	toggleBtn:SetPoint("TOPRIGHT", -72, -4)
	toggleBtn:SetScript("OnClick", function() Farm:Toggle() end)

	local elapsedSince = 0
	frame:SetScript("OnUpdate", function(_, elapsed)
		elapsedSince = elapsedSince + elapsed
		if elapsedSince >= 1 then
			elapsedSince = 0
			Farm:Refresh()
		end
	end)
end

function Farm:Refresh()
	if not frame or not frame:IsShown() then
		return
	end
	toggleBtn.text:SetText(self:IsRunning() and "Stop" or "Start")
	if not session then
		summary:SetText("No session yet - click Start.")
		for _, row in ipairs(rows) do
			row:Hide()
		end
		return
	end

	local total, elapsed = self:Totals()
	local skillText = {}
	for prof, rank in pairs(Ranks()) do
		local gained = rank - (session.skills[prof] or rank)
		if gained > 0 then
			table.insert(skillText, string.format("%s +%d", prof, gained))
		end
	end
	local muted = "|cff9e9e9e"
	summary:SetText(string.format("%sTime|r  %s%s\n%sLooted|r  %s   %sPer hour|r  %s\n%sSkill-ups|r  %s",
		muted, NS:FormatDuration(math.max(60, elapsed)), self:IsRunning() and "" or "  |cff808080(stopped)|r",
		muted, NS:FormatMoney(total), muted, NS:FormatMoney(self:PerHour()),
		muted, #skillText > 0 and table.concat(skillText, ", ") or "none yet"))

	local list = {}
	for id, n in pairs(session.items) do
		table.insert(list, { id = id, n = n, value = ItemValue(id) * n })
	end
	table.sort(list, function(a, b) return a.value > b.value end)
	for i, row in ipairs(rows) do
		local e = list[i]
		if e then
			row.icon:SetTexture(NS.ItemCache:Icon(e.id))
			row.name:SetText(NS.ItemCache:ColoredName(e.id) .. " |cffaaaaaax" .. e.n .. "|r")
			row.value:SetText(e.value > 0 and NS:FormatMoney(e.value) or "")
			row:Show()
		else
			row:Hide()
		end
	end
end

function Farm:Show()
	if not frame then
		Build()
	end
	frame:Show()
	self:Refresh()
end

----------------------------------------------------------------------------
-- Reminders
----------------------------------------------------------------------------
local function Notify(icon, title, text, onClick)
	if NS.Toast then
		NS.Toast:Show({ icon = icon, title = title, text = text, onClick = onClick })
	end
	NS:Print(title .. " - " .. text)
end

local function OutInTheWorld()
	return not IsInInstance() and not IsResting() and not UnitOnTaxi("player")
		and not UnitAffectingCombat("player") and not UnitIsDeadOrGhost("player")
end

local TRACKING_ICON = { Mining = "Interface\\Icons\\Spell_Nature_Earthquake", Herbalism = "Interface\\Icons\\INV_Misc_Flower_02" }

function Farm:CheckTracking()
	if not NS:Option("farmRemindTracking") or not OutInTheWorld() then
		return
	end
	local zone = GetRealZoneText() or ""
	if remindedZones[zone] then
		return
	end
	local skills = NS.Characters:Me().skills
	local missing
	for _, prof in ipairs({ "Mining", "Herbalism" }) do
		if skills[prof] then
			local index, active = NS.Nodes:TrackingFor(prof)
			if active then
				return -- one gathering tracking is already on; that's enough
			end
			if index and not missing then
				missing = { prof = prof, index = index }
			end
		end
	end
	if not missing then
		return
	end
	remindedZones[zone] = true
	local spellName = GetSpellInfo(missing.prof == "Mining" and 2580 or 2383) or "Tracking"
	Notify(TRACKING_ICON[missing.prof], spellName .. " is off",
		"Click to turn it on, so " .. strlower(missing.prof == "Mining" and "ore veins" or "herbs") .. " show on your minimap.",
		function()
			SetTracking(missing.index)
		end)
end

local function HasAny(list)
	for _, id in ipairs(list) do
		if GetItemCount(id) > 0 then
			return true
		end
		for _, slot in ipairs({ 16, 17 }) do
			if NS:ItemIDFromLink(GetInventoryItemLink("player", slot)) == id then
				return true
			end
		end
	end
	return false
end

function Farm:CheckTools()
	if not NS:Option("farmRemindTools") then
		return
	end
	local skills = NS.Characters:Me().skills
	if skills.Mining and not remindedTools.Mining and not HasAny(NS.MINING_TOOLS) then
		remindedTools.Mining = true
		Notify(GetItemIcon(2901), "No Mining Pick",
			"You need a Mining Pick in your bags to mine. Trade supply vendors sell them.")
	end
	if skills.Skinning and not remindedTools.Skinning and not HasAny(NS.SKINNING_TOOLS) then
		remindedTools.Skinning = true
		Notify(GetItemIcon(7005), "No Skinning Knife",
			"You need a Skinning Knife in your bags to skin. Trade supply vendors sell them.")
	end
end

-- Best lure you carry that your Fishing skill allows, or nil.
local function BestLure()
	local s = NS.Characters:Me().skills.Fishing
	local rank = s and s.rank or 0
	local best
	for _, lure in ipairs(NS.FISHING_LURES) do
		if lure.req <= rank and GetItemCount(lure.id) > 0 and (not best or lure.bonus >= best.bonus) then
			best = lure
		end
	end
	return best
end

function Farm:CheckLure()
	if not NS:Option("farmRemindLure") or GetTime() - lastLureNag < LURE_NAG then
		return
	end
	local hasMainHandEnchant = GetWeaponEnchantInfo()
	if hasMainHandEnchant then
		return
	end
	local lure = BestLure()
	if not lure then
		return
	end
	lastLureNag = GetTime()
	Notify(GetItemIcon(lure.id), "Fishing without a lure",
		string.format("Use %s (+%d Fishing) on your pole for more catches.", NS.ItemCache:Name(lure.id), lure.bonus))
end

----------------------------------------------------------------------------
-- Events
----------------------------------------------------------------------------
local FISHING -- localized cast name

local delayed = CreateFrame("Frame")
delayed:Hide()
local delayLeft = 0
delayed:SetScript("OnUpdate", function(self, elapsed)
	delayLeft = delayLeft - elapsed
	if delayLeft <= 0 then
		self:Hide()
		Farm:CheckTracking()
		Farm:CheckTools()
	end
end)
local function CheckSoon(seconds)
	delayLeft = seconds
	delayed:Show()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("CHAT_MSG_LOOT")
events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
events:SetScript("OnEvent", function(_, event, arg1, arg2)
	if event == "PLAYER_LOGIN" then
		BuildPatterns()
		FISHING = GetSpellInfo(7620)
	elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
		-- Give tracking/bag state a few seconds to settle after loading.
		CheckSoon(event == "PLAYER_ENTERING_WORLD" and 8 or 3)
	elseif event == "CHAT_MSG_LOOT" then
		if Farm:IsRunning() then
			local id, count = ParseLoot(arg1 or "")
			if id then
				session.items[id] = (session.items[id] or 0) + count
				Farm:Refresh()
			end
		end
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		if arg1 == "player" and FISHING and arg2 == FISHING then
			Farm:CheckLure()
		end
	end
end)
