-- Building blocks shared by every window: a movable skinned window with a
-- saved position, and a scrolling list of column rows. Plain CreateFrame (no
-- AceGUI), same as Johnny's other addons.
local NS = JohnnysProfessions
NS.Widgets = {}
local W = NS.Widgets
local Skin = NS.Skin

local function Positions()
	return NS.db.profile.ui.positions
end

function W:CreateWindow(key, label, width, height)
	local f = CreateFrame("Frame", "JohnnysProfessions" .. key .. "Window", UIParent)
	f:SetSize(width, height)
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, rel, x, y = self:GetPoint()
		Positions()[key] = { point = point, rel = rel, x = x, y = y }
	end)
	local pos = Positions()[key]
	if pos then
		f:SetPoint(pos.point, UIParent, pos.rel, pos.x, pos.y)
	else
		f:SetPoint("CENTER")
	end
	Skin:StylePanel(f)

	f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.title:SetPoint("TOPLEFT", 10, -9)
	f.title:SetTextColor(1, 1, 1)
	f.title:SetText(label)

	local close = Skin:CreateButton(f, 20, 20, "X")
	close:SetPoint("TOPRIGHT", -4, -4)
	close:SetScript("OnClick", function() f:Hide() end)

	NS.WindowSettings:Register(f, key, label)
	NS.WindowSettings:AttachButton(f)
	table.insert(UISpecialFrames, f:GetName())
	f:Hide()
	return f
end

-- A "selected" look for tab/filter buttons built with Skin:CreateButton:
-- bright white border + text when selected, dimmed grey otherwise.
function W:SetSelected(btn, selected)
	if selected then
		btn:SetBackdropColor(0.16, 0.16, 0.16, 0.95)
		btn:SetBackdropBorderColor(0.9, 0.9, 0.9, 1)
		btn.text:SetTextColor(1, 1, 1)
	else
		btn:SetBackdropColor(0.06, 0.06, 0.06, 0.95)
		btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
		btn.text:SetTextColor(0.7, 0.7, 0.7)
	end
end

function W:Label(parent, template)
	local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
	fs:SetJustifyH("LEFT")
	return fs
end

----------------------------------------------------------------------------
-- Theme pieces for the sidebar layout (black/white, no gold art)
----------------------------------------------------------------------------
W.COLORS = {
	text = { 1, 1, 1 },
	muted = { 0.62, 0.62, 0.62 },
	dim = { 0.42, 0.42, 0.42 },
	card = { 0.075, 0.075, 0.075, 0.95 },
	cardBorder = { 0.22, 0.22, 0.22, 1 },
	highlight = { 0.9, 0.9, 0.9, 1 },
}

-- A slightly lighter rounded-off panel used for every content block.
function W:StyleCard(frame, highlighted)
	local c = self.COLORS
	frame:SetBackdrop({ bgFile = Skin.WHITE, edgeFile = Skin.WHITE, edgeSize = 1 })
	frame:SetBackdropColor(unpack(c.card))
	if highlighted then
		frame:SetBackdropBorderColor(unpack(c.highlight))
	else
		frame:SetBackdropBorderColor(unpack(c.cardBorder))
	end
end

function W:CreateCard(parent, width, height, highlighted)
	local f = CreateFrame("Frame", nil, parent)
	if width then
		f:SetSize(width, height)
	end
	self:StyleCard(f, highlighted)
	return f
end

-- Small caps-style grey heading ("PROFESSIONS", "SUGGESTIONS").
function W:SectionTitle(parent, text)
	local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	fs:SetJustifyH("LEFT")
	fs:SetTextColor(unpack(self.COLORS.muted))
	fs:SetText(strupper(text or ""))
	return fs
end

-- An icon with a thin border. `desaturate` greys it out to fit the theme.
function W:CreateIcon(parent, size, texture, desaturate)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetSize(size, size)
	holder:SetBackdrop({ bgFile = Skin.WHITE, edgeFile = Skin.WHITE, edgeSize = 1 })
	holder:SetBackdropColor(0, 0, 0, 1)
	holder:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
	local tex = holder:CreateTexture(nil, "ARTWORK")
	tex:SetPoint("TOPLEFT", 1, -1)
	tex:SetPoint("BOTTOMRIGHT", -1, 1)
	tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	holder.texture = tex
	function holder:SetIcon(path, grey)
		tex:SetTexture(path or "Interface\\Icons\\INV_Misc_QuestionMark")
		tex:SetDesaturated(grey and true or false)
	end
	holder:SetIcon(texture, desaturate)
	return holder
end

-- Horizontal progress bar. bar:SetProgress(cur, max[, text]) - text defaults
-- to "cur / max" on the right.
function W:CreateProgressBar(parent, width, height)
	local bar = CreateFrame("Frame", nil, parent)
	bar:SetSize(width, height)
	bar:SetBackdrop({ bgFile = Skin.WHITE, edgeFile = Skin.WHITE, edgeSize = 1 })
	bar:SetBackdropColor(0.12, 0.12, 0.12, 1)
	bar:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	local fill = bar:CreateTexture(nil, "ARTWORK")
	fill:SetTexture(Skin.WHITE)
	fill:SetVertexColor(0.85, 0.85, 0.85, 1)
	fill:SetPoint("TOPLEFT", 1, -1)
	fill:SetPoint("BOTTOMLEFT", 1, 1)
	bar.fill = fill
	function bar:SetProgress(cur, max)
		local pct = (max and max > 0) and math.min(1, math.max(0, cur / max)) or 0
		local inner = self:GetWidth() - 2
		if pct <= 0 then
			fill:Hide()
		else
			fill:Show()
			fill:SetWidth(math.max(1, inner * pct))
		end
	end
	function bar:SetFillColor(r, g, b, a)
		fill:SetVertexColor(r, g, b, a or 1)
	end
	return bar
end

-- Sidebar navigation entry: greyed icon + label, white bar on the left and
-- a lighter background when selected.
function W:CreateNavButton(parent, width, label, icon)
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(width, 28)
	local bg = btn:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture(Skin.WHITE)
	bg:SetVertexColor(1, 1, 1, 0)
	btn.bg = bg
	local hl = btn:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetTexture(Skin.WHITE)
	hl:SetVertexColor(1, 1, 1, 0.06)
	local bar = btn:CreateTexture(nil, "ARTWORK")
	bar:SetTexture(Skin.WHITE)
	bar:SetVertexColor(1, 1, 1, 1)
	bar:SetPoint("TOPLEFT")
	bar:SetPoint("BOTTOMLEFT")
	bar:SetWidth(2)
	bar:Hide()
	btn.bar = bar
	local tex = btn:CreateTexture(nil, "ARTWORK")
	tex:SetSize(18, 18)
	tex:SetPoint("LEFT", 12, 0)
	tex:SetTexture(icon)
	tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	btn.icon = tex
	local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	fs:SetPoint("LEFT", tex, "RIGHT", 10, 0)
	fs:SetText(label)
	btn.text = fs
	function btn:SetSelected(selected)
		if selected then
			bg:SetVertexColor(1, 1, 1, 0.1)
			bar:Show()
			tex:SetDesaturated(false)
			fs:SetTextColor(1, 1, 1)
		else
			bg:SetVertexColor(1, 1, 1, 0)
			bar:Hide()
			tex:SetDesaturated(true)
			fs:SetTextColor(0.65, 0.65, 0.65)
		end
	end
	btn:SetSelected(false)
	return btn
end

----------------------------------------------------------------------------
-- Scrolling list
----------------------------------------------------------------------------
-- columns: { { x = 24, width = 200, justify = "LEFT" }, ... } - each becomes
-- row.cols[i]. `icon = true` adds a 16px row.icon at the left.
-- Rows show an item/spell tooltip on hover when row.link is set
-- ("item:1234" / "enchant:2963"), or call row.tooltipFunc(row) if set.
local listCount = 0

local function RowOnEnter(row)
	if row.link or row.tooltipFunc then
		GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
		if row.link then
			GameTooltip:SetHyperlink(row.link)
		end
		if row.tooltipFunc then
			row.tooltipFunc(row, GameTooltip)
		end
		GameTooltip:Show()
	end
end

local function RowOnLeave()
	GameTooltip:Hide()
end

function W:CreateList(parent, rowHeight, columns, icon)
	listCount = listCount + 1
	local scroll = CreateFrame("ScrollFrame", "JohnnysProfessionsList" .. listCount, parent, "UIPanelScrollFrameTemplate")
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(10, 10)
	scroll:SetScrollChild(content)

	local list = { scroll = scroll, content = content, rows = {} }

	local function NewRow()
		local row = CreateFrame("Button", nil, content)
		row:SetHeight(rowHeight)
		local hl = row:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetTexture(Skin.WHITE)
		hl:SetVertexColor(1, 1, 1, 0.08)
		row.bg = row:CreateTexture(nil, "BACKGROUND")
		row.bg:SetAllPoints()
		row.bg:SetTexture(Skin.WHITE)
		row.bg:SetVertexColor(1, 1, 1, 0)
		if icon then
			row.icon = row:CreateTexture(nil, "ARTWORK")
			row.icon:SetSize(rowHeight - 4, rowHeight - 4)
			row.icon:SetPoint("LEFT", 2, 0)
		end
		row.cols = {}
		for i, c in ipairs(columns) do
			local fs = row:CreateFontString(nil, "OVERLAY", c.font or "GameFontHighlightSmall")
			fs:SetPoint("LEFT", c.x, 0)
			fs:SetWidth(c.width)
			fs:SetHeight(rowHeight)
			fs:SetJustifyH(c.justify or "LEFT")
			row.cols[i] = fs
		end
		row:SetScript("OnEnter", RowOnEnter)
		row:SetScript("OnLeave", RowOnLeave)
		return row
	end

	-- Shows `n` rows, calling fill(row, i) for each.
	function list:SetCount(n, fill)
		local width = self.scroll:GetWidth()
		self.content:SetWidth(width)
		for i = 1, n do
			local row = self.rows[i]
			if not row then
				row = NewRow()
				row:SetPoint("TOPLEFT", 0, -(i - 1) * rowHeight)
				self.rows[i] = row
			end
			row:SetWidth(width)
			row.link, row.tooltipFunc = nil, nil
			row.bg:SetVertexColor(1, 1, 1, 0)
			row:SetScript("OnClick", nil)
			fill(row, i)
			row:Show()
		end
		for i = n + 1, #self.rows do
			self.rows[i]:Hide()
		end
		self.content:SetHeight(math.max(1, n * rowHeight))
	end

	return list
end

-- A row of column header labels matching a list's columns.
function W:CreateHeader(parent, columns, labels)
	local holder = CreateFrame("Frame", nil, parent)
	holder:SetHeight(16)
	for i, c in ipairs(columns) do
		if labels[i] then
			local fs = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			fs:SetPoint("LEFT", c.x, 0)
			fs:SetWidth(c.width)
			fs:SetJustifyH(c.justify or "LEFT")
			fs:SetText(labels[i])
		end
	end
	return holder
end
