-- Home page: the character at a glance. A rotatable 3D model on the left;
-- name, experience, gold/durability/bags/time played, profession ranks and
-- suggestions (Modules\Suggestions.lua) on the right.
local NS = JohnnysProfessions
local Page = {}
NS.MainWindow:AddPage("Home", Page, {
	order = 1, label = "Home", icon = "Interface\\Icons\\INV_Misc_Map_01",
	title = "Welcome back", subtitle = "Your character at a glance",
})

local MODEL_W = 220
local RIGHT_X = MODEL_W + 12
local RIGHT_W = 458
local MAX_PROF_ROWS = 6
local MAX_SUGGESTIONS = 3

local model
local nameText, infoText, guildText, xpLabel, xpBar, restedText
local stats = {}
local profRows, profEmpty = {}, nil
local sugRows, sugEmpty = {}, nil

----------------------------------------------------------------------------
-- Time played: asked for once per session, without printing it to chat
----------------------------------------------------------------------------
local played, playedAt
local requested = false
local mutedFrames = {}

local function RestoreChat()
	for _, cf in ipairs(mutedFrames) do
		cf:RegisterEvent("TIME_PLAYED_MSG")
	end
	wipe(mutedFrames)
end

local function RequestPlayed()
	if requested then
		return
	end
	requested = true
	for i = 1, NUM_CHAT_WINDOWS do
		local cf = _G["ChatFrame" .. i]
		if cf and cf.IsEventRegistered and cf:IsEventRegistered("TIME_PLAYED_MSG") then
			cf:UnregisterEvent("TIME_PLAYED_MSG")
			table.insert(mutedFrames, cf)
		end
	end
	RequestTimePlayed()
end

----------------------------------------------------------------------------
-- Events (only acted on while the Home page is showing)
----------------------------------------------------------------------------
local events = CreateFrame("Frame")
-- Safety net: give chat its /played output back even if the reply never comes.
local restoreWait = 0
events:SetScript("OnUpdate", function(self, elapsed)
	if #mutedFrames == 0 then
		return
	end
	restoreWait = restoreWait + elapsed
	if restoreWait > 10 then
		restoreWait = 0
		RestoreChat()
	end
end)
for _, e in ipairs({ "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION", "UPDATE_INVENTORY_DURABILITY", "BAG_UPDATE",
	"PLAYER_MONEY", "TIME_PLAYED_MSG", "ZONE_CHANGED_NEW_AREA", "PLAYER_GUILD_UPDATE", "PLAYER_LEVEL_UP" }) do
	events:RegisterEvent(e)
end
events:SetScript("OnEvent", function(_, event, total)
	if event == "TIME_PLAYED_MSG" then
		played, playedAt = total, GetTime()
		RestoreChat()
	end
	if NS.MainWindow:IsShown() and NS.MainWindow:Current() == "Home" then
		NS:RequestRedraw()
	end
end)

----------------------------------------------------------------------------
-- Build
----------------------------------------------------------------------------
local function BuildModel(f)
	local W = NS.Widgets
	local card = W:CreateCard(f, MODEL_W, 462)
	card:SetPoint("TOPLEFT", 0, 0)

	model = CreateFrame("PlayerModel", nil, card)
	model:SetPoint("TOPLEFT", 1, -1)
	model:SetPoint("BOTTOMRIGHT", -1, 24)
	model:EnableMouse(true)
	local dragging, lastX = false, 0
	model:SetScript("OnMouseDown", function(self)
		dragging = true
		lastX = GetCursorPosition()
	end)
	model:SetScript("OnMouseUp", function()
		dragging = false
	end)
	model:SetScript("OnUpdate", function(self)
		if dragging then
			local x = GetCursorPosition()
			self:SetFacing(self:GetFacing() + (x - lastX) * 0.02)
			lastX = x
		end
	end)

	local hint = W:Label(card)
	hint:SetPoint("BOTTOM", 0, 8)
	hint:SetTextColor(unpack(W.COLORS.dim))
	hint:SetText("Drag to rotate")
end

local function BuildStat(f, x, y, icon, caption)
	local W = NS.Widgets
	local card = W:CreateCard(f, 225, 46)
	card:SetPoint("TOPLEFT", x, y)
	local ic = W:CreateIcon(card, 30, icon, true)
	ic:SetPoint("LEFT", 8, 0)
	local cap = W:SectionTitle(card, caption)
	cap:SetPoint("TOPLEFT", ic, "TOPRIGHT", 10, 0)
	local value = W:Label(card, "GameFontHighlight")
	value:SetPoint("BOTTOMLEFT", ic, "BOTTOMRIGHT", 10, 0)
	return value
end

-- Suggestion rows (Home card and the "View all" popup): left-click acts,
-- right-click hides the suggestion until your next level.
local function SuggestionClick(self, button)
	if button == "RightButton" then
		if self.id then
			NS.Suggestions:Hide(self.id)
			NS:RequestRedraw()
			Page:RefreshPopup()
		end
	elseif self.onClick then
		self.onClick()
	end
end

local function SuggestionEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(self.title:GetText() or "", 1, 1, 1)
	if self.onClick then
		GameTooltip:AddLine("Click to open.", 0.7, 0.7, 0.7)
	end
	GameTooltip:AddLine("Right-click to hide until your next level.", 0.7, 0.7, 0.7)
	GameTooltip:Show()
end

local function RowButton(parent, height)
	local b = CreateFrame("Button", nil, parent)
	b:SetHeight(height)
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetTexture(NS.Skin.WHITE)
	hl:SetVertexColor(1, 1, 1, 0.06)
	return b
end

function Page:Build(f)
	local W = NS.Widgets
	BuildModel(f)

	local right = CreateFrame("Frame", nil, f)
	right:SetPoint("TOPLEFT", RIGHT_X, 0)
	right:SetSize(RIGHT_W, 462)

	nameText = W:Label(right, "GameFontNormalLarge")
	nameText:SetPoint("TOPLEFT", 0, 0)
	infoText = W:Label(right, "GameFontHighlight")
	infoText:SetPoint("TOPLEFT", 0, -22)
	guildText = W:Label(right)
	guildText:SetPoint("TOPLEFT", 0, -40)
	guildText:SetTextColor(unpack(W.COLORS.muted))

	local xpTitle = W:SectionTitle(right, "Experience")
	xpTitle:SetPoint("TOPLEFT", 0, -60)
	xpLabel = W:Label(right)
	xpLabel:SetPoint("TOPRIGHT", 0, -60)
	xpLabel:SetJustifyH("RIGHT")
	xpBar = W:CreateProgressBar(right, RIGHT_W, 12)
	xpBar:SetPoint("TOPLEFT", 0, -74)
	restedText = W:Label(xpBar)
	restedText:SetPoint("CENTER")
	restedText:SetTextColor(0.3, 0.3, 0.3)

	stats.gold = BuildStat(right, 0, -96, "Interface\\Icons\\INV_Misc_Coin_02", "Gold")
	stats.durability = BuildStat(right, 233, -96, "Interface\\Icons\\Trade_BlackSmithing", "Durability")
	stats.bags = BuildStat(right, 0, -150, "Interface\\Icons\\INV_Misc_Bag_08", "Bag space")
	stats.played = BuildStat(right, 233, -150, "Interface\\Icons\\INV_Misc_PocketWatch_01", "Time played")

	-- Professions: two columns of rows.
	local profCard = W:CreateCard(right, RIGHT_W, 104)
	profCard:SetPoint("TOPLEFT", 0, -206)
	local profTitle = W:SectionTitle(profCard, "Professions")
	profTitle:SetPoint("TOPLEFT", 10, -8)
	-- Row layout: icon | name | bar | rank, with fixed widths so the rank
	-- text ("450 / 450") never draws over the bar.
	local ROW_W = RIGHT_W / 2 - 14
	local RANK_W = 56
	local BAR_X = 112
	local BAR_W = ROW_W - BAR_X - RANK_W - 2 - 8
	for i = 1, MAX_PROF_ROWS do
		local col = (i - 1) % 2
		local line = math.floor((i - 1) / 2)
		local row = RowButton(profCard, 24)
		row:SetWidth(ROW_W)
		row:SetPoint("TOPLEFT", 8 + col * (RIGHT_W / 2), -24 - line * 25)
		row.icon = W:CreateIcon(row, 18, nil, false)
		row.icon:SetPoint("LEFT", 2, 0)
		row.name = W:Label(row)
		row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
		row.name:SetWidth(BAR_X - 26 - 4)
		row.bar = W:CreateProgressBar(row, BAR_W, 6)
		row.bar:SetPoint("LEFT", BAR_X, 0)
		row.rank = W:Label(row)
		row.rank:SetWidth(RANK_W)
		row.rank:SetPoint("RIGHT", -2, 0)
		row.rank:SetJustifyH("RIGHT")
		row:SetScript("OnClick", function(self)
			if self.prof then
				NS.MainWindow:ShowGuide(self.prof)
			end
		end)
		profRows[i] = row
	end
	profEmpty = W:Label(profCard)
	profEmpty:SetPoint("TOPLEFT", 10, -30)
	profEmpty:SetTextColor(unpack(W.COLORS.muted))
	profEmpty:SetText("No professions learned yet - visit a trainer in any capital city.")

	-- Suggestions
	local sugCard = W:CreateCard(right, RIGHT_W, 144)
	sugCard:SetPoint("TOPLEFT", 0, -318)
	local sugTitle = W:SectionTitle(sugCard, "Suggestions")
	sugTitle:SetPoint("TOPLEFT", 10, -8)
	for i = 1, MAX_SUGGESTIONS do
		local row = RowButton(sugCard, 36)
		row:SetPoint("TOPLEFT", 6, -24 - (i - 1) * 38)
		row:SetPoint("RIGHT", -6, 0)
		row.icon = W:CreateIcon(row, 26, nil, false)
		row.icon:SetPoint("LEFT", 4, 0)
		row.title = W:Label(row, "GameFontHighlight")
		row.title:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 10, 1)
		row.title:SetPoint("RIGHT", -20, 0)
		row.text = W:Label(row)
		row.text:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 10, -1)
		row.text:SetPoint("RIGHT", -20, 0)
		row.text:SetTextColor(unpack(W.COLORS.muted))
		row.arrow = W:Label(row, "GameFontHighlight")
		row.arrow:SetPoint("RIGHT", -6, 0)
		row.arrow:SetText(">")
		row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		row:SetScript("OnClick", SuggestionClick)
		row:SetScript("OnEnter", SuggestionEnter)
		row:SetScript("OnLeave", GameTooltip_Hide)
		sugRows[i] = row
	end
	local viewAll = NS.Skin:CreateButton(sugCard, 70, 18, "View all")
	viewAll:SetPoint("TOPRIGHT", -8, -5)
	viewAll:SetScript("OnClick", function() Page:ToggleAllSuggestions() end)
	sugEmpty = W:Label(sugCard)
	sugEmpty:SetPoint("TOPLEFT", 10, -30)
	sugEmpty:SetTextColor(unpack(W.COLORS.muted))
	sugEmpty:SetText("Nothing to do right now.")

	-- SetUnit only takes once the model is visible, and re-applying it resets
	-- the camera, so it's done on show rather than on every refresh.
	f:SetScript("OnShow", function()
		model:SetUnit("player")
		model:SetFacing(0)
		RequestPlayed()
	end)
end

----------------------------------------------------------------------------
-- Refresh
----------------------------------------------------------------------------
local function RefreshHeader()
	local W = NS.Widgets
	local _, classFile = UnitClass("player")
	nameText:SetText(NS:ClassColoredName(UnitName("player"), classFile))
	infoText:SetText(string.format("Level %d %s %s", UnitLevel("player"), UnitRace("player") or "", UnitClass("player")))
	local guild = GetGuildInfo("player")
	local zone = GetRealZoneText() or ""
	guildText:SetText((guild and ("<" .. guild .. ">  ") or "") .. zone)

	local maxLevel = (MAX_PLAYER_LEVEL_TABLE and MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel()]) or 80
	if UnitLevel("player") >= maxLevel then
		xpBar:SetProgress(1, 1)
		xpLabel:SetText("Max level")
		restedText:SetText("")
		return
	end
	local cur, max = UnitXP("player"), UnitXPMax("player")
	xpBar:SetProgress(cur, max)
	local pct = max > 0 and math.floor(cur / max * 100) or 0
	xpLabel:SetText(string.format("%d%%   %d / %d", pct, cur, max))
	local rested = GetXPExhaustion()
	if rested and max > 0 then
		restedText:SetText(string.format("rested %d%%", math.floor(rested / max * 100)))
	else
		restedText:SetText("")
	end
end

local function RefreshStats()
	local Sug = NS.Suggestions
	stats.gold:SetText(NS:FormatMoney(GetMoney()))

	local lowest, avg = Sug:Durability()
	if lowest then
		local color = lowest < 30 and "|cffff6060" or "|cffffffff"
		stats.durability:SetText(string.format("%s%d%%|r |cff9e9e9e(lowest %d%%)|r", color, math.floor(avg + 0.5), math.floor(lowest + 0.5)))
	else
		stats.durability:SetText("-")
	end

	local free, total = Sug:BagSpace()
	stats.bags:SetText(string.format("%s%d|r / %d free", free <= 3 and "|cffff6060" or "|cffffffff", free, total))

	if played then
		stats.played:SetText(NS:FormatDuration(played + (GetTime() - playedAt)))
	else
		stats.played:SetText("|cff9e9e9e...|r")
	end
end

local function RefreshProfessions()
	local skills = NS.Characters:Me().skills
	local n = 0
	for _, p in ipairs(NS.PROFESSIONS) do
		local s = skills[p.key]
		if s and n < MAX_PROF_ROWS then
			n = n + 1
			local row = profRows[n]
			row.prof = NS.Guide:Has(p.key) and p.key or nil
			row.icon:SetIcon(p.icon, false)
			row.name:SetText(p.key)
			row.bar:SetProgress(s.rank, s.max)
			row.rank:SetText(string.format("%d / %d", s.rank, s.max))
			row:Show()
		end
	end
	for i = n + 1, MAX_PROF_ROWS do
		profRows[i]:Hide()
	end
	if n == 0 then
		profEmpty:Show()
	else
		profEmpty:Hide()
	end
end

local function RefreshSuggestions()
	local list = NS.Suggestions:Get()
	for i = 1, MAX_SUGGESTIONS do
		local row, s = sugRows[i], list[i]
		if s then
			row.id = s.id
			row.icon:SetIcon(s.icon, false)
			row.title:SetText(s.title)
			row.text:SetText(s.text or "")
			row.onClick = s.onClick
			if s.onClick then
				row.arrow:Show()
			else
				row.arrow:Hide()
			end
			row:Show()
		else
			row:Hide()
		end
	end
	if #list == 0 then
		sugEmpty:Show()
	else
		sugEmpty:Hide()
	end
end

----------------------------------------------------------------------------
-- "View all" popup: every suggestion, hidden ones dimmed (right-click any
-- row to hide it, "Unhide all" brings them back).
----------------------------------------------------------------------------
local ALL_W, ALL_ROW = 400, 40
local allFrame, allRows, allEmpty, unhideButton = nil, {}, nil, nil
local RefreshAll -- defined below; BuildAll's button needs it

local function BuildAll()
	local W = NS.Widgets
	allFrame = W:CreateWindow("Suggestions", "All suggestions", ALL_W, 120)
	allFrame:SetFrameStrata("DIALOG")
	allEmpty = W:Label(allFrame)
	allEmpty:SetPoint("TOPLEFT", 12, -40)
	allEmpty:SetTextColor(unpack(W.COLORS.muted))
	allEmpty:SetText("Nothing to do right now.")
	unhideButton = NS.Skin:CreateButton(allFrame, 100, 20, "Unhide all")
	unhideButton:SetPoint("BOTTOMRIGHT", -10, 8)
	unhideButton:SetScript("OnClick", function()
		NS.Suggestions:UnhideAll()
		NS:RequestRedraw()
		RefreshAll()
	end)
end

local function AllRow(i)
	local row = allRows[i]
	if row then
		return row
	end
	local W = NS.Widgets
	row = RowButton(allFrame, ALL_ROW - 2)
	row:SetPoint("TOPLEFT", 8, -32 - (i - 1) * ALL_ROW)
	row:SetPoint("RIGHT", -8, 0)
	row.icon = W:CreateIcon(row, 28, nil, false)
	row.icon:SetPoint("LEFT", 4, 0)
	row.title = W:Label(row, "GameFontHighlight")
	row.title:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 10, 1)
	row.title:SetPoint("RIGHT", -6, 0)
	row.text = W:Label(row)
	row.text:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 10, -1)
	row.text:SetPoint("RIGHT", -6, 0)
	row.text:SetTextColor(unpack(W.COLORS.muted))
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	row:SetScript("OnClick", SuggestionClick)
	row:SetScript("OnEnter", SuggestionEnter)
	row:SetScript("OnLeave", GameTooltip_Hide)
	allRows[i] = row
	return row
end

RefreshAll = function()
	if not allFrame or not allFrame:IsShown() then
		return
	end
	local list = NS.Suggestions:Get(true)
	local anyHidden = false
	for i, s in ipairs(list) do
		local row = AllRow(i)
		row.id, row.onClick = s.id, s.onClick
		row.icon:SetIcon(s.icon, s.hidden)
		row.title:SetText(s.title .. (s.hidden and "  |cff808080(hidden until next level)|r" or ""))
		row.text:SetText(s.text or "")
		row:SetAlpha(s.hidden and 0.5 or 1)
		row:Show()
		anyHidden = anyHidden or s.hidden
	end
	for i = #list + 1, #allRows do
		allRows[i]:Hide()
	end
	if #list == 0 then
		allEmpty:Show()
	else
		allEmpty:Hide()
	end
	if anyHidden then
		unhideButton:Show()
	else
		unhideButton:Hide()
	end
	allFrame:SetHeight(32 + math.max(#list, 1) * ALL_ROW + 36)
end

function Page:RefreshPopup()
	RefreshAll()
end

function Page:ToggleAllSuggestions()
	if not allFrame then
		BuildAll()
	end
	if allFrame:IsShown() then
		allFrame:Hide()
	else
		allFrame:Show()
		RefreshAll()
	end
end

function Page:Refresh()
	RefreshAll()
	if not nameText then
		return
	end
	RefreshHeader()
	RefreshStats()
	RefreshProfessions()
	RefreshSuggestions()
end
