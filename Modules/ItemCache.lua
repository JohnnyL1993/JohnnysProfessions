-- 3.3.5a's GetItemInfo returns nil for any item the client hasn't seen yet,
-- and there's no "item info received" event. Guides name hundreds of items
-- you may never have looked at, so this asks the server about them through a
-- hidden tooltip - a few per frame so it never floods the connection - and
-- tells listeners when a batch has arrived so lists can redraw with names.
local NS = JohnnysProfessions
NS.ItemCache = {}
local Cache = NS.ItemCache

local PER_TICK = 4
local TICK = 0.15

local tooltip = CreateFrame("GameTooltip", "JohnnysProfessionsScanTooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

local queue, queued = {}, {}
-- Times each item has been asked for. Capped so an ID the server doesn't
-- know (a typo in a guide) can't keep the request/redraw cycle going forever.
local tries = {}
local MAX_TRIES = 2
local listeners = {}
local pendingNotify = false

function Cache:OnUpdate(fn)
	table.insert(listeners, fn)
end

local notifier = CreateFrame("Frame")
notifier:Hide()
local notifyWait = 0
notifier:SetScript("OnUpdate", function(self, elapsed)
	notifyWait = notifyWait + elapsed
	if notifyWait > 1 then
		self:Hide()
		for _, fn in ipairs(listeners) do
			fn()
		end
	end
end)

local ticker = CreateFrame("Frame")
ticker:Hide()
local elapsedSince = 0
ticker:SetScript("OnUpdate", function(self, elapsed)
	elapsedSince = elapsedSince + elapsed
	if elapsedSince < TICK then
		return
	end
	elapsedSince = 0
	for _ = 1, PER_TICK do
		local id = table.remove(queue, 1)
		if not id then
			break
		end
		queued[id] = nil
		if not GetItemInfo(id) then
			tooltip:SetOwner(UIParent, "ANCHOR_NONE")
			tooltip:SetHyperlink("item:" .. id)
			tooltip:Hide()
			pendingNotify = true
		end
	end
	if #queue == 0 then
		self:Hide()
		if pendingNotify then
			pendingNotify = false
			-- Give the server a moment to answer the last few before redrawing.
			notifyWait = 0
			notifier:Show()
		end
	end
end)

function Cache:Request(id)
	if not id or queued[id] or (tries[id] or 0) >= MAX_TRIES or GetItemInfo(id) then
		return
	end
	tries[id] = (tries[id] or 0) + 1
	queued[id] = true
	table.insert(queue, id)
	ticker:Show()
end

-- Name of an item, requesting it from the server if needed.
function Cache:Name(id)
	local name = GetItemInfo(id)
	if name then
		return name
	end
	self:Request(id)
	return "item #" .. id
end

-- Quality-coloured name.
function Cache:ColoredName(id)
	local name, _, quality = GetItemInfo(id)
	if not name then
		self:Request(id)
		return "|cff808080item #" .. id .. "|r"
	end
	local color = ITEM_QUALITY_COLORS[quality]
	return (color and color.hex or "|cffffffff") .. name .. "|r"
end

function Cache:Icon(id)
	return GetItemIcon(id) or "Interface\\Icons\\INV_Misc_QuestionMark"
end
