-- Small movable window with just the current guide step: what to craft, how
-- many, materials you have vs need, and the next trainer visit. Pops up on
-- its own while a profession window with a guide is open. Right-click it to
-- open the full Professions page. While the profession window is open it
-- also shows how many you can craft, warns when the guide's recipe has gone
-- grey, suggests the best recipe for a skill-up right now, and has Craft 1 /
-- Craft all buttons.
local NS = JohnnysProfessions
NS.MiniGuide = {}
local Mini = NS.MiniGuide

local WIDTH = 290
local MAX_MATS = 6

local frame, bar, body, craftOne, craftAll
local prof
local openedByTradeWindow = false
local craftTarget -- { spell=, numAvailable= } the Craft buttons act on

local function Craft(count)
	if not craftTarget then
		return
	end
	-- Look the index up again: filters or collapsed headers may have moved it.
	local index, available = NS.Guide:FindTradeIndex(craftTarget.spell)
	if not index or available < 1 then
		return
	end
	if TradeSkillFrame_SetSelection and TradeSkillFrame and TradeSkillFrame:IsShown() then
		TradeSkillFrame_SetSelection(index)
		TradeSkillFrame_Update()
	end
	DoTradeSkill(index, math.min(count or available, available))
end

local function Grey(text)
	return "|cff9e9e9e" .. text .. "|r"
end

local function Build()
	local W = NS.Widgets
	frame = W:CreateWindow("MiniGuide", "Guide", WIDTH, 120)
	frame:SetFrameStrata("MEDIUM")
	W:StyleCard(frame)

	bar = W:CreateProgressBar(frame, WIDTH - 20, 6)
	bar:SetPoint("TOPLEFT", 10, -30)

	body = W:Label(frame)
	body:SetPoint("TOPLEFT", 10, -44)
	body:SetWidth(WIDTH - 20)
	body:SetJustifyV("TOP")
	body:SetSpacing(3)

	craftOne = NS.Skin:CreateButton(frame, 80, 20, "Craft 1")
	craftOne:SetPoint("BOTTOMLEFT", 10, 8)
	craftOne:SetScript("OnClick", function() Craft(1) end)
	craftAll = NS.Skin:CreateButton(frame, 110, 20, "Craft all")
	craftAll:SetPoint("LEFT", craftOne, "RIGHT", 6, 0)
	craftAll:SetScript("OnClick", function() Craft(nil) end)

	frame:EnableMouse(true)
	frame:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then
			NS.MainWindow:ShowGuide(prof)
		end
	end)
end

local function Line(lines, text)
	table.insert(lines, text)
end

function Mini:Refresh()
	if not frame or not frame:IsShown() or not prof then
		return
	end
	local s = NS.Characters:Me().skills[prof]
	local rank = s and s.rank or 0
	frame.title:SetText(string.format("%s  %s", prof, Grey(string.format("%d / %d", rank, s and s.max or 0))))
	bar:SetProgress(rank, s and s.max or 75)

	local lines = {}
	craftTarget = nil
	local live = NS.Guide:TradeWindowIs(prof)
	local steps = NS.Guide:GetSteps(prof)
	local i = steps and NS.Guide:CurrentIndex(steps, rank)
	if not i then
		Line(lines, "|cffffffffGuide complete.|r")
	else
		local step = steps[i]
		Line(lines, Grey(string.format("SKILL %d - %d   STEP %d / %d", step.from, step.to, i, #steps)))
		if not step.zones then
			local left = NS.Guide:CraftsLeft(step, rank)
			local diff = NS.Guide:DifficultyText(step, rank)
			Line(lines, string.format("|cffffffff%s|r  x%d%s", NS.Guide:StepName(step), left, diff and ("  " .. diff) or ""))
			if live then
				local spell = NS.Guide:SpellFor(step)
				local index, available, difficulty = NS.Guide:FindTradeIndex(spell)
				if not spell then
					-- generic step ("any orange glyph"): rely on the best pick below
				elseif not index then
					Line(lines, Grey("You don't know this recipe yet - learn it first."))
				elseif difficulty == "trivial" then
					Line(lines, "|cff808080This recipe has gone grey - no more skill-ups. Move on.|r")
				else
					Line(lines, Grey(string.format("You can craft %d now.", available)))
					if available > 0 then
						craftTarget = { spell = spell, numAvailable = available }
					end
				end
				local best = NS.Guide:BestPick()
				if best and best.spell ~= spell then
					Line(lines, string.format("Best right now: |cffffffff%s|r  %s%s", best.name,
						NS.Guide:ColorWord(best.difficulty) or "",
						best.numAvailable > 0 and Grey(string.format("  (can craft %d)", best.numAvailable)) or ""))
					if not craftTarget and best.numAvailable > 0 then
						craftTarget = { spell = best.spell, numAvailable = best.numAvailable }
					end
				end
			end
			local mats = {}
			for id, n in pairs(NS.Guide:StepMats(step, rank)) do
				table.insert(mats, { id = id, need = n, have = NS.Characters:MyCount(id) })
			end
			table.sort(mats, function(a, b) return a.id < b.id end)
			for m = 1, math.min(#mats, MAX_MATS) do
				local e = mats[m]
				local color = e.have >= e.need and "|cff40ff40" or "|cffff6060"
				Line(lines, string.format("|T%s:16|t %s%d/%d|r  %s", NS.ItemCache:Icon(e.id), color, e.have, e.need, NS.ItemCache:Name(e.id)))
			end
		else
			Line(lines, "|cffffffff" .. (NS.Guide:ZoneText(step) or "") .. "|r")
		end
		if step.note then
			Line(lines, Grey(step.note))
		end
		local nextStep = steps[i + 1]
		if nextStep then
			Line(lines, "|cff6b6b6b" .. string.format("Next at %d: %s", nextStep.from, NS.Guide:StepName(nextStep)) .. "|r")
		end
	end
	if s then
		local hint = NS:TrainerHint(rank, s.max, UnitLevel("player"), prof)
		if hint then
			Line(lines, hint)
		end
	end

	body:SetText(table.concat(lines, "\n"))
	local h = body:GetStringHeight() + 56
	if craftTarget then
		craftOne:Show()
		craftAll:Show()
		craftAll.text:SetText(string.format("Craft all (%d)", craftTarget.numAvailable))
		h = h + 26
	else
		craftOne:Hide()
		craftAll:Hide()
	end
	frame:SetHeight(h)
end

function Mini:ShowFor(p)
	if not p or not NS.Guide:Has(p) then
		return
	end
	if not frame then
		Build()
	end
	prof = p
	frame:Show()
	self:Refresh()
end

function Mini:Toggle()
	if frame and frame:IsShown() then
		frame:Hide()
		return
	end
	self:ShowFor(prof or NS.db.profile.ui.guide or NS.Guide:MyGuidedProfessions()[1])
end

-- Trade skill window opened/closed.
function Mini:OnTradeSkillShow()
	if not NS.db.profile.ui.showMiniGuide then
		return
	end
	if IsTradeSkillLinked and IsTradeSkillLinked() then
		return
	end
	local line = GetTradeSkillLine()
	if line and NS.Guide:Has(line) then
		openedByTradeWindow = true
		self:ShowFor(line)
	end
end

function Mini:OnTradeSkillClose()
	if openedByTradeWindow and frame then
		frame:Hide()
	end
	openedByTradeWindow = false
end
