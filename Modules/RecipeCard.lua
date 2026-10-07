-- A card next to Blizzard's profession window for the selected recipe: its
-- skill-up colours, the guide step it belongs to, materials you're short on
-- (with bank and alt counts and a Track button), what it costs and sells
-- for, and which of your other characters know it. Also adds a "JP" button
-- to the profession window: left-click opens the guide, right-click toggles
-- the mini-guide.
local NS = JohnnysProfessions
NS.RecipeCard = {}
local Card = NS.RecipeCard

local WIDTH = 250

NS:RegisterOption("recipeCard", true, "Profession window",
	"Recipe card in the profession window",
	"Shows skill-up colours, guide step, missing materials and profit next to the selected recipe.")

local frame, body, trackBtn, jpButton
local shortList = {} -- { {id=, need=}, ... } for the Track button
local hooked = false

local function Grey(text)
	return "|cff9e9e9e" .. text .. "|r"
end

local function CurrentProf()
	if IsTradeSkillLinked and IsTradeSkillLinked() then
		return nil
	end
	local line = GetTradeSkillLine()
	return line and NS.PROF_BY_KEY[line] and line
end

-- The guide step (index, step, steps) a recipe belongs to, if any.
local function GuideStepFor(prof, spell)
	local steps = NS.Guide:GetSteps(prof)
	if not steps then
		return nil
	end
	for i, step in ipairs(steps) do
		if not step.zones and NS.Guide:SpellFor(step) == spell then
			return i, step, steps
		end
	end
	return nil
end

local function Build()
	local W = NS.Widgets
	frame = W:CreateCard(TradeSkillFrame, WIDTH, 100)
	frame:SetPoint("TOPLEFT", TradeSkillFrame, "TOPRIGHT", -32, -14)
	frame:SetFrameStrata(TradeSkillFrame:GetFrameStrata())

	frame.icon = W:CreateIcon(frame, 28)
	frame.icon:SetPoint("TOPLEFT", 10, -10)
	frame.name = W:Label(frame, "GameFontHighlight")
	frame.name:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 8, -1)
	frame.name:SetPoint("RIGHT", -10, 0)
	frame.color = W:Label(frame)
	frame.color:SetPoint("TOPLEFT", frame.name, "BOTTOMLEFT", 0, -3)

	body = W:Label(frame)
	body:SetPoint("TOPLEFT", 10, -46)
	body:SetWidth(WIDTH - 20)
	body:SetJustifyV("TOP")
	body:SetSpacing(3)

	trackBtn = NS.Skin:CreateButton(frame, 120, 20, "Track missing")
	trackBtn:SetPoint("BOTTOMLEFT", 10, 8)
	trackBtn:SetScript("OnClick", function()
		local goals = NS.Tracker:Goals()
		for _, e in ipairs(shortList) do
			NS.Tracker:Set(e.id, math.max(goals[e.id] or 0, e.need))
		end
		NS:Print(string.format("Tracking %d item(s).", #shortList))
		NS.TrackerWindow:Show()
	end)
end

function Card:Update(index)
	if not TradeSkillFrame or not TradeSkillFrame:IsShown() then
		return
	end
	local prof = CurrentProf()
	index = index or GetTradeSkillSelectionIndex()
	local name, skillType
	if index and index > 0 then
		name, skillType = GetTradeSkillInfo(index)
	end
	if not NS:Option("recipeCard") or not prof or not name or skillType == "header" then
		if frame then
			frame:Hide()
		end
		return
	end
	if not frame then
		Build()
	end

	local spell = NS:SpellIDFromLink(GetTradeSkillRecipeLink(index))
	local itemLink = GetTradeSkillItemLink(index)
	local product = NS:ItemIDFromLink(itemLink)
	local s = NS.Characters:Me().skills[prof]
	local rank = s and s.rank or 0

	frame.icon:SetIcon(GetTradeSkillIcon(index))
	frame.name:SetText(name)
	local now = NS.Guide:ColorWord(skillType)
	frame.color:SetText(now and ("Now " .. now) or "")

	local lines = {}
	local range = NS.Guide:RangeText(spell)
	if range then
		table.insert(lines, Grey("Skill-up colours: ") .. range)
	end

	-- Guide step
	local crafts = 1
	local i, step, steps = GuideStepFor(prof, spell)
	if step then
		local cur = NS.Guide:CurrentIndex(steps, rank)
		local text = string.format("Guide step %d  (%d - %d)", i, step.from, step.to)
		if rank >= step.to then
			text = text .. Grey("  - done")
		else
			crafts = math.max(1, NS.Guide:CraftsLeft(step, rank))
			text = text .. string.format("  - about %d left", crafts)
			if i == cur then
				text = text .. "  |cffffffffYOU ARE HERE|r"
			end
		end
		table.insert(lines, text)
	else
		table.insert(lines, Grey("Not part of the guide."))
	end

	-- Materials for the crafts still to do (one craft if not in the guide).
	table.insert(lines, " ")
	table.insert(lines, Grey(crafts > 1 and string.format("MATERIALS FOR %d CRAFTS", crafts) or "MATERIALS"))
	wipe(shortList)
	local cost, costKnown = 0, true
	for r = 1, GetTradeSkillNumReagents(index) do
		local rName, rTex, count = GetTradeSkillReagentInfo(index, r)
		local id = NS:ItemIDFromLink(GetTradeSkillReagentItemLink(index, r))
		if id and count then
			local need = count * crafts
			local have = NS.Characters:MyCount(id)
			local alts = NS.Characters:AltCounts(id)
			local color = have >= need and "|cff40ff40" or "|cffff6060"
			local line = string.format("|T%s:14|t %s%d/%d|r %s", rTex or NS.ItemCache:Icon(id), color, have, need, rName or NS.ItemCache:Name(id))
			if alts > 0 then
				line = line .. Grey(string.format("  (+%d on alts)", alts))
			end
			table.insert(lines, line)
			if have < need then
				table.insert(shortList, { id = id, need = need })
			end
			local each = NS.Prices:GetCost(id)
			if each then
				cost = cost + each * count
			else
				costKnown = false
			end
		end
	end

	-- Money
	local minMade, maxMade = GetTradeSkillNumMade(index)
	local made = ((minMade or 1) + (maxMade or minMade or 1)) / 2
	local value = product and NS.Prices:GetSellValue(product)
	table.insert(lines, " ")
	table.insert(lines, Grey("Cost ") .. (costKnown and NS:FormatMoney(cost) or "|cff808080?|r")
		.. Grey("   Sells ") .. (value and NS:FormatMoney(value * made) or "|cff808080?|r"))
	if value and costKnown then
		table.insert(lines, Grey("Profit ") .. NS:FormatMoney(value * made - cost))
	end

	-- Your other characters who know it.
	local knownBy = {}
	for charName, char in pairs(NS.Characters:All()) do
		if charName ~= NS.Characters.name and char.recipes and char.recipes[prof] and char.recipes[prof][spell] then
			table.insert(knownBy, NS:ClassColoredName(charName, char.class))
		end
	end
	if #knownBy > 0 then
		table.sort(knownBy)
		table.insert(lines, Grey("Also known by: ") .. table.concat(knownBy, ", "))
	end

	body:SetText(table.concat(lines, "\n"))
	local h = 46 + body:GetStringHeight() + 12
	if #shortList > 0 then
		trackBtn:Show()
		h = h + 26
	else
		trackBtn:Hide()
	end
	frame:SetHeight(h)
	frame:Show()
end

----------------------------------------------------------------------------
-- JP button on the profession window
----------------------------------------------------------------------------
local function BuildJPButton()
	jpButton = NS.Skin:CreateButton(TradeSkillFrame, 28, 18, "JP")
	if TradeSkillLinkButton then
		jpButton:SetPoint("RIGHT", TradeSkillLinkButton, "LEFT", -4, 0)
	else
		jpButton:SetPoint("TOPRIGHT", TradeSkillFrame, "TOPRIGHT", -70, -16)
	end
	jpButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	jpButton:SetScript("OnClick", function(_, button)
		local prof = CurrentProf()
		if button == "RightButton" then
			if prof and NS.Guide:Has(prof) then
				NS.MiniGuide:ShowFor(prof)
			else
				NS.MiniGuide:Toggle()
			end
		elseif prof then
			NS.MainWindow:ShowGuide(prof)
		else
			NS.MainWindow:Toggle()
		end
	end)
	jpButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Johnny's Professions")
		GameTooltip:AddLine("Left-click: open this profession's guide", 1, 1, 1)
		GameTooltip:AddLine("Right-click: mini-guide", 1, 1, 1)
		GameTooltip:Show()
	end)
	jpButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Hook()
	if hooked or not TradeSkillFrame then
		return
	end
	hooked = true
	BuildJPButton()
	hooksecurefunc("TradeSkillFrame_SetSelection", function(id)
		Card:Update(id)
	end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("TRADE_SKILL_SHOW")
events:RegisterEvent("TRADE_SKILL_UPDATE")
events:RegisterEvent("BAG_UPDATE")
events:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == "Blizzard_TradeSkillUI" then
			Hook()
		end
		return
	end
	Hook()
	if frame or NS:Option("recipeCard") then
		Card:Update()
	end
end)
