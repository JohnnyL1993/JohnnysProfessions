-- Item tracker window: goals grouped by the profession that needs them, each
-- with a progress bar and +/- buttons (Shift for 10). Add items by searching
-- by name, Shift-clicking a link into the box, typing an ID, or dragging an
-- item from your bags onto the window. At the auction house, clicking an
-- item searches for it, and the window opens by itself when you have goals.
local NS = JohnnysProfessions
NS.TrackerWindow = {}
local TW = NS.TrackerWindow

NS:RegisterOption("trackerAutoOpenAH", true, "Item tracker",
	"Open the tracker at the auction house",
	"Shows the item tracker whenever you open the auction house and have tracked items.")

local WIDTH, HEIGHT = 300, 360
local ROW_H = 22
local MAX_SUGGEST = 6
local MAIL_COLOR = "|cff6cb4ff"
local COLUMNS = {
	{ x = 24, width = 128 },                    -- name
	{ x = 154, width = 50, justify = "RIGHT" }, -- count/target
}

local frame, list, emptyText, ahHint, edit, qtyBox, suggestBox
local suggestRows = {}
local openedByAH = false

local function GoalQty()
	return math.max(1, tonumber(qtyBox.editBox:GetText()) or 20)
end

local function Track(id)
	if not id then
		return
	end
	NS.Tracker:Set(id, math.max(NS.Tracker:Goals()[id] or 0, GoalQty()))
end

-- Adds whatever item is on the cursor (dragged from a bag).
local function AcceptCursor()
	local kind, id = GetCursorInfo()
	if kind ~= "item" or not id then
		return false
	end
	ClearCursor()
	Track(id)
	return true
end

local function RowTooltip(row, tt)
	if row.isHeader then
		return
	end
	local mail = NS.Tracker:MailCount(row.itemID)
	if mail > 0 then
		tt:AddLine(" ")
		tt:AddLine(string.format("%s%d waiting in the mailbox|r", MAIL_COLOR, mail))
	end
	if NS.AuctionScan:IsAHOpen() then
		tt:AddLine("Click to search the auction house.", 0.6, 0.6, 0.6)
	end
end

local function AddButtons(row)
	local Skin = NS.Skin
	row.bar = row:CreateTexture(nil, "BORDER")
	row.bar:SetTexture(Skin.WHITE)
	row.bar:SetPoint("BOTTOMLEFT", 22, 1)
	row.bar:SetHeight(2)

	row.minus = Skin:CreateButton(row, 16, 16, "-")
	row.minus:SetPoint("LEFT", 208, 0)
	row.plus = Skin:CreateButton(row, 16, 16, "+")
	row.plus:SetPoint("LEFT", row.minus, "RIGHT", 2, 0)
	row.remove = Skin:CreateButton(row, 16, 16, "x")
	row.remove:SetPoint("LEFT", row.plus, "RIGHT", 2, 0)

	row.minus:SetScript("OnClick", function(self)
		NS.Tracker:Adjust(self:GetParent().itemID, IsShiftKeyDown() and -10 or -1)
	end)
	row.plus:SetScript("OnClick", function(self)
		NS.Tracker:Adjust(self:GetParent().itemID, IsShiftKeyDown() and 10 or 1)
	end)
	row.remove:SetScript("OnClick", function(self)
		NS.Tracker:Remove(self:GetParent().itemID)
	end)
	-- Rows sit on top of the window, so they have to accept drops too.
	row:SetScript("OnReceiveDrag", AcceptCursor)
end

local function SetItemWidgetsShown(row, shown)
	for _, w in ipairs({ row.icon, row.bar, row.minus, row.plus, row.remove }) do
		if shown then
			w:Show()
		else
			w:Hide()
		end
	end
end

----------------------------------------------------------------------------
-- Name search suggestions
----------------------------------------------------------------------------
local function HideSuggestions()
	if suggestBox then
		suggestBox:Hide()
	end
end

local function ShowSuggestions(text)
	if not text or text == "" or text:find("|H") or tonumber(text) then
		HideSuggestions()
		return
	end
	local ids = NS.Tracker:FindItems(text, MAX_SUGGEST)
	if #ids == 0 then
		HideSuggestions()
		return
	end
	for i = 1, MAX_SUGGEST do
		local b = suggestRows[i]
		local id = ids[i]
		if id then
			b.itemID = id
			b.icon:SetTexture(NS.ItemCache:Icon(id))
			b.text:SetText(NS.ItemCache:ColoredName(id))
			b:Show()
		else
			b:Hide()
		end
	end
	suggestBox:SetHeight(#ids * 18 + 6)
	suggestBox:Show()
end

local function BuildSuggestions(anchor)
	local W = NS.Widgets
	suggestBox = W:CreateCard(frame, 200, 20)
	suggestBox:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
	suggestBox:SetFrameLevel(frame:GetFrameLevel() + 20)
	suggestBox:Hide()
	for i = 1, MAX_SUGGEST do
		local b = CreateFrame("Button", nil, suggestBox)
		b:SetHeight(18)
		b:SetPoint("TOPLEFT", 3, -3 - (i - 1) * 18)
		b:SetPoint("RIGHT", -3, 0)
		local hl = b:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetTexture(NS.Skin.WHITE)
		hl:SetVertexColor(1, 1, 1, 0.1)
		b.icon = b:CreateTexture(nil, "ARTWORK")
		b.icon:SetSize(14, 14)
		b.icon:SetPoint("LEFT", 2, 0)
		b.text = W:Label(b)
		b.text:SetPoint("LEFT", b.icon, "RIGHT", 5, 0)
		b.text:SetPoint("RIGHT", -2, 0)
		b:SetScript("OnClick", function(self)
			Track(self.itemID)
			edit:SetText("")
			edit:ClearFocus()
			HideSuggestions()
		end)
		suggestRows[i] = b
	end
end

----------------------------------------------------------------------------
-- Window
----------------------------------------------------------------------------
local function Build()
	local W = NS.Widgets
	frame = W:CreateWindow("Tracker", "Tracked items", WIDTH, HEIGHT)
	frame:SetFrameStrata("MEDIUM")
	frame:SetScript("OnReceiveDrag", AcceptCursor)
	frame:SetScript("OnMouseUp", AcceptCursor)

	list = W:CreateList(frame, ROW_H, COLUMNS, true)
	list.scroll:SetPoint("TOPLEFT", 6, -30)
	list.scroll:SetPoint("BOTTOMRIGHT", -28, 56)
	list.scroll:SetScript("OnReceiveDrag", AcceptCursor)

	emptyText = W:Label(frame)
	emptyText:SetPoint("TOP", 0, -60)
	emptyText:SetWidth(WIDTH - 30)
	emptyText:SetJustifyH("CENTER")
	emptyText:SetText("Nothing tracked yet.\n\nDrag an item from your bags onto this window, search for one below, or use \"Track mats\" on the Professions page.")

	ahHint = W:Label(frame)
	ahHint:SetPoint("BOTTOMLEFT", 10, 36)
	ahHint:SetTextColor(unpack(W.COLORS.muted))

	-- Search by name, Shift-click a link in, or type an item ID.
	local add = NS.Skin:CreateEditBox(frame, 170, 20)
	add:SetPoint("BOTTOMLEFT", 8, 8)
	edit = add.editBox
	qtyBox = NS.Skin:CreateEditBox(frame, 40, 20)
	qtyBox:SetPoint("LEFT", add, "RIGHT", 4, 0)
	qtyBox.editBox:SetNumeric(true)
	qtyBox.editBox:SetText("20")
	local addBtn = NS.Skin:CreateButton(frame, 52, 20, "Add")
	addBtn:SetPoint("LEFT", qtyBox, "RIGHT", 4, 0)

	local placeholder = add:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	placeholder:SetPoint("LEFT", 6, 0)
	placeholder:SetText("Search or Shift-click an item")

	BuildSuggestions(add)

	local function AddItem()
		local id = NS.Tracker:Resolve(edit:GetText())
		if id then
			Track(id)
			edit:SetText("")
		elseif strtrim(edit:GetText() or "") ~= "" then
			NS:Print("No item found with that name. Items your client hasn't seen yet can't be found by name - Shift-click or drag them in instead.")
		end
		edit:ClearFocus()
		HideSuggestions()
	end
	addBtn:SetScript("OnClick", AddItem)
	edit:SetScript("OnEnterPressed", AddItem)
	edit:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		HideSuggestions()
	end)
	edit:SetScript("OnTextChanged", function(self, userInput)
		local text = self:GetText() or ""
		if text == "" then
			placeholder:Show()
		else
			placeholder:Hide()
		end
		if userInput then
			ShowSuggestions(text)
		end
	end)
	edit:SetScript("OnEditFocusGained", function() placeholder:Hide() end)
	edit:SetScript("OnEditFocusLost", function(self)
		if (self:GetText() or "") == "" then
			placeholder:Show()
		end
	end)

	-- Shift-clicking an item while the box has focus inserts its link.
	hooksecurefunc("ChatEdit_InsertLink", function(link)
		if edit:HasFocus() and link then
			edit:SetText(link)
			HideSuggestions()
		end
	end)

	frame:SetScript("OnHide", HideSuggestions)
end

local function RowClick(row)
	if row.isHeader then
		return
	end
	if CursorHasItem() then
		AcceptCursor()
	elseif NS.AuctionScan:IsAHOpen() then
		NS.AuctionScan:SearchFor(row.itemID)
	end
end

function TW:Refresh()
	if not frame or not frame:IsShown() then
		return
	end
	local entries = NS.Tracker:List()
	-- Flatten into header + item rows.
	local rows, lastGroup = {}, nil
	for _, e in ipairs(entries) do
		if e.group ~= lastGroup then
			lastGroup = e.group
			table.insert(rows, { header = e.group })
		end
		table.insert(rows, e)
	end

	list:SetCount(#rows, function(row, i)
		local e = rows[i]
		if not row.minus then
			AddButtons(row)
		end
		row:SetScript("OnClick", RowClick)
		if e.header then
			row.isHeader = true
			row.itemID = nil
			SetItemWidgetsShown(row, false)
			row.cols[1]:SetText("|cff9e9e9e" .. strupper(e.header) .. "|r")
			row.cols[2]:SetText("")
			return
		end
		row.isHeader = false
		SetItemWidgetsShown(row, true)
		row.itemID = e.id
		row.link = "item:" .. e.id
		row.tooltipFunc = RowTooltip
		row.icon:SetTexture(NS.ItemCache:Icon(e.id))
		local done = e.count >= e.target
		local name = NS.ItemCache:ColoredName(e.id)
		if e.mail > 0 then
			name = name .. " " .. MAIL_COLOR .. "+" .. e.mail .. "|r"
		end
		row.cols[1]:SetText(name)
		local color = done and "|cff40ff40" or (e.mail > 0 and MAIL_COLOR or "|cffffffff")
		row.cols[2]:SetText(string.format("%s%d/%d|r", color, e.count, e.target))
		local pct = math.min(1, e.count / e.target)
		row.bar:SetWidth(math.max(1, 182 * pct))
		if done then
			row.bar:SetVertexColor(0.25, 1, 0.25, 0.8)
		else
			row.bar:SetVertexColor(0.85, 0.85, 0.85, 0.8)
		end
	end)
	if #entries == 0 then
		emptyText:Show()
	else
		emptyText:Hide()
	end
	if NS.AuctionScan:IsAHOpen() and #entries > 0 then
		ahHint:SetText("Click an item to search the auction house.")
	else
		ahHint:SetText(#entries > 0 and (MAIL_COLOR .. "+N|r = waiting in the mailbox") or "")
	end
end

function TW:Show()
	if not frame then
		Build()
	end
	frame:Show()
	self:Refresh()
end

function TW:Hide()
	if frame then
		frame:Hide()
	end
end

function TW:IsShown()
	return frame and frame:IsShown()
end

function TW:Toggle()
	if frame and frame:IsShown() then
		frame:Hide()
	else
		self:Show()
	end
end

-- Auto-open at the auction house (and close again when it closes, if we
-- were the ones who opened it).
local ahEvents = CreateFrame("Frame")
ahEvents:RegisterEvent("AUCTION_HOUSE_SHOW")
ahEvents:RegisterEvent("AUCTION_HOUSE_CLOSED")
ahEvents:SetScript("OnEvent", function(_, event)
	if event == "AUCTION_HOUSE_SHOW" then
		if NS:Option("trackerAutoOpenAH") and next(NS.Tracker:Goals()) and not TW:IsShown() then
			openedByAH = true
			TW:Show()
		end
	else
		if openedByAH then
			TW:Hide()
		end
		openedByAH = false
	end
	NS:RequestRedraw()
end)
