-- Watches profession ranks while you play: counts skill-ups this session
-- (shown as skill-ups per hour on the Professions page) and pops up a toast
-- when you finish a guide step or get within a few points of your cap.
-- Toasts go through NS.Toast (Modules\TradeWatch.lua); chat if it's missing.
local NS = JohnnysProfessions
NS.StepAlerts = {}
local Alerts = NS.StepAlerts

local CAP_WARNING = 5

NS:RegisterOption("stepToasts", true, "Professions",
	"Pop-up when a guide step is done",
	"Shows what's next when your skill passes the end of the current guide step.")
NS:RegisterOption("capToasts", true, "Professions",
	"Pop-up when a profession is about to cap",
	"Warns a few points before your skill cap, with the rank to train next and the level it needs.")

local lastRank       -- [prof] = rank seen last (nil until the first scan)
local session = {}   -- [prof] = { start = rank, startTime = GetTime(), gained = n }
local capWarned = {} -- [prof .. max] = true once warned this session

local function Toast(icon, title, text, onClick)
	if NS.Toast then
		NS.Toast:Show({ icon = icon, title = title, text = text, onClick = onClick })
	else
		NS:Print(title .. (text and (" - " .. text) or ""))
	end
end

-- Skill-ups this session and the hourly rate (nil until a few minutes in).
function Alerts:Rate(prof)
	local s = session[prof]
	if not s or s.gained <= 0 then
		return 0, nil
	end
	local hours = (GetTime() - s.startTime) / 3600
	if hours < 2 / 60 then
		return s.gained, nil
	end
	return s.gained, s.gained / hours
end

local function StepDone(prof, old, new)
	local steps = NS.Guide:GetSteps(prof)
	if not steps then
		return
	end
	for i, step in ipairs(steps) do
		if old < step.to and new >= step.to and not NS.Guide:IsSkipped(prof, i) then
			local nextIndex = NS.Guide:CurrentIndex(steps, new)
			local nextStep = nextIndex and steps[nextIndex]
			local text
			if nextStep then
				text = string.format("Next (%d-%d): %s", nextStep.from, nextStep.to, NS.Guide:StepName(nextStep))
			else
				text = "That was the last step of the guide."
			end
			Toast(NS.PROF_BY_KEY[prof].icon,
				string.format("%s step done: %s", prof, NS.Guide:StepName(step)), text,
				function() NS.MainWindow:ShowGuide(prof) end)
			return -- one toast per skill-up is plenty
		end
	end
end

local function NearCap(prof, rank, max)
	if rank < max - CAP_WARNING or rank >= max then
		return
	end
	local key = prof .. max
	if capWarned[key] then
		return
	end
	capWarned[key] = true
	local hint = NS:TrainerHint(rank, max, UnitLevel("player"), prof)
	local i = NS:RankForCap(max)
	local nextRank = i and NS.RANKS[i + 1]
	if not nextRank then
		return
	end
	Toast(NS.PROF_BY_KEY[prof].icon,
		string.format("%s is almost capped (%d / %d)", prof, rank, max),
		hint or string.format("Train %s next.", nextRank.name),
		function() NS.MainWindow:ShowGuide(prof) end)
end

local function OnSkills()
	local me = NS.Characters:Me()
	if not me then
		return
	end
	local first = lastRank == nil
	lastRank = lastRank or {}
	for prof, s in pairs(me.skills) do
		local old = lastRank[prof]
		if not session[prof] then
			session[prof] = { start = s.rank, startTime = GetTime(), gained = 0 }
		end
		if old and s.rank > old and not first then
			session[prof].gained = session[prof].gained + (s.rank - old)
			if NS:Option("stepToasts") then
				StepDone(prof, old, s.rank)
			end
			if NS:Option("capToasts") then
				NearCap(prof, s.rank, s.max)
			end
		end
		lastRank[prof] = s.rank
	end
end

-- Characters notifies after every skill / trade window scan.
NS.Characters:OnChange(function(what)
	if what == "skills" or what == "recipes" then
		OnSkills()
	end
end)
