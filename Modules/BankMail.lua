-- Bank and mailbox helpers.
--   * "Grab guide mats" on the bank frame moves what your guides (and item
--     tracker goals) still need from the bank into your bags.
--   * "Mats for alt" on the Send Mail tab picks one of your characters,
--     fills in their name and attaches the materials their guides still need
--     (minus what they already hold) - you check it and press Send.
-- Item moves go one per tick: the server locks a slot until it confirms each
-- move, so firing them all in one frame would mostly fail.
local NS = JohnnysProfessions
NS.BankMail = {}
local BM = NS.BankMail

local TICK = 0.3
local RESERVE_FOR = 1.5 -- seconds a just-filled empty slot is treated as taken
local BANK_BAGS = { -1, 5, 6, 7, 8, 9, 10, 11 }

----------------------------------------------------------------------------
-- Shared step driver
----------------------------------------------------------------------------
local job       -- function() -> true when finished
local onFinish  -- function(reason)
local driver = CreateFrame("Frame")
driver:Hide()
local wait = 0
driver:SetScript("OnUpdate", function(self, elapsed)
	wait = wait - elapsed
	if wait > 0 then
		return
	end
	wait = TICK
	if CursorHasItem() then
		-- Something didn't land last tick (e.g. a soulbound item refused by
		-- the mail); drop it back where it came from.
		ClearCursor()
		return
	end
	local done, reason = job()
	if done then
		self:Hide()
		job = nil
		if onFinish then
			onFinish(reason)
		end
	end
end)

local function Run(stepFn, finishFn)
	job, onFinish = stepFn, finishFn
	wait = 0
	driver:Show()
end

local function Abort(reason)
	if job then
		driver:Hide()
		job = nil
		if onFinish then
			onFinish(reason)
		end
	end
end

local function SortedIDs(t)
	local ids = {}
	for id, n in pairs(t) do
		if n > 0 then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids
end

local function Summary(moved)
	local parts = {}
	for _, id in ipairs(SortedIDs(moved)) do
		table.insert(parts, moved[id] .. "x " .. NS.ItemCache:ColoredName(id))
	end
	return table.concat(parts, ", ")
end

----------------------------------------------------------------------------
-- Bag helpers
----------------------------------------------------------------------------
local reserved = {} -- ["bag:slot"] = GetTime() it was filled

-- An empty slot in your bags (0-4) that can hold this item, honouring
-- special bags (herb, mining, ...).
local function FreeBagSlot(itemID)
	local family = GetItemFamily(itemID) or 0
	local now = GetTime()
	for bag = 0, NUM_BAG_SLOTS do
		local free, bagType = GetContainerNumFreeSlots(bag)
		if free and free > 0 and (bagType == 0 or bit.band(family, bagType) > 0) then
			for slot = 1, GetContainerNumSlots(bag) do
				local key = bag .. ":" .. slot
				if not GetContainerItemLink(bag, slot) and now - (reserved[key] or 0) > RESERVE_FOR then
					reserved[key] = now
					return bag, slot
				end
			end
		end
	end
end

-- First unlocked stack of itemID in the given containers.
-- Returns bag, slot, count - or nil, plus true if only locked stacks exist.
local function FindStack(containers, itemID)
	local sawLocked = false
	for _, bag in ipairs(containers) do
		for slot = 1, GetContainerNumSlots(bag) do
			if NS:ItemIDFromLink(GetContainerItemLink(bag, slot)) == itemID then
				local _, count, locked = GetContainerItemInfo(bag, slot)
				if locked then
					sawLocked = true
				else
					return bag, slot, count or 1
				end
			end
		end
	end
	return nil, sawLocked
end

local MY_BAGS = { 0, 1, 2, 3, 4 }

----------------------------------------------------------------------------
-- Grab guide mats at the bank
----------------------------------------------------------------------------
local bankButton

-- What should come out of the bank: guide needs and tracker goals, minus
-- what's already in your bags.
local function BankWants()
	local want = {}
	for _, e in ipairs(NS.Guide:ShoppingList(NS.Guide:MyGuidedProfessions())) do
		want[e.id] = math.max(want[e.id] or 0, e.need)
	end
	for id, target in pairs(NS.Tracker:Goals()) do
		want[id] = math.max(want[id] or 0, target)
	end
	for id, n in pairs(want) do
		want[id] = n - GetItemCount(id)
	end
	return want
end

function BM:GrabFromBank()
	if job then
		return
	end
	if not NS.Characters:IsBankOpen() then
		NS:Print("Open your bank first.")
		return
	end
	local want = BankWants()
	local moved = {}
	local ids = SortedIDs(want)
	if #ids == 0 then
		NS:Print("Your bags already hold everything your guides and tracker need.")
		return
	end
	local i = 1
	if bankButton then
		bankButton.text:SetText("Moving...")
	end
	Run(function()
		while ids[i] do
			local id = ids[i]
			if want[id] <= 0 then
				i = i + 1
			else
				local bag, slot, count = FindStack(BANK_BAGS, id)
				if not bag then
					if slot then
						return false -- only locked stacks right now: wait a tick
					end
					i = i + 1 -- none of this in the bank
				else
					local take = math.min(count, want[id])
					local fb, fs = FreeBagSlot(id)
					if not fb then
						return true, "full"
					end
					if take >= count then
						PickupContainerItem(bag, slot)
					else
						SplitContainerItem(bag, slot, take)
					end
					PickupContainerItem(fb, fs)
					want[id] = want[id] - take
					moved[id] = (moved[id] or 0) + take
					return false
				end
			end
		end
		return true, "done"
	end, function(reason)
		if bankButton then
			bankButton.text:SetText("Grab guide mats")
		end
		local text = Summary(moved)
		if text == "" then
			NS:Print("Nothing in your bank that your guides or tracker need.")
		else
			NS:Print("Took from the bank: " .. text)
		end
		if reason == "full" then
			NS:Print("Your bags are full - stopped early.")
		elseif reason == "closed" then
			NS:Print("Bank closed - stopped early.")
		end
	end)
end

local function EnsureBankButton()
	if bankButton or not BankFrame then
		return
	end
	bankButton = NS.Skin:CreateButton(BankFrame, 130, 22, "Grab guide mats")
	bankButton:SetPoint("BOTTOMRIGHT", BankFrame, "TOPRIGHT", -40, -12)
	bankButton:SetScript("OnClick", function() BM:GrabFromBank() end)
	bankButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Grab guide mats", 1, 1, 1)
		GameTooltip:AddLine("Moves what your profession guides and tracked items still need from the bank into your bags.", 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	bankButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

----------------------------------------------------------------------------
-- Mats for an alt at the mailbox
----------------------------------------------------------------------------
local mailButton, picker
local pickerRows = {}

-- What an alt's guides still need, minus what they already hold.
function BM:AltNeeds(alt)
	local need = {}
	for prof, s in pairs(alt.skills or {}) do
		if NS.Guide:Has(prof) then
			for id, n in pairs(NS.Guide:RemainingMats(prof, s.rank)) do
				need[id] = (need[id] or 0) + n
			end
		end
	end
	for id, n in pairs(need) do
		local left = n - NS.Characters:Count(alt, id)
		need[id] = left > 0 and left or nil
	end
	return need
end

local function FreeAttachment()
	for i = 1, ATTACHMENTS_MAX_SEND or 12 do
		if not GetSendMailItem(i) then
			return i
		end
	end
end

function BM:AttachForAlt(name)
	if job then
		return
	end
	local alt = NS.Characters:All()[name]
	if not alt then
		return
	end
	SendMailNameEditBox:SetText(name)
	if (SendMailSubjectEditBox:GetText() or "") == "" then
		SendMailSubjectEditBox:SetText("Profession materials")
	end

	-- Only what you actually carry in your bags can be attached.
	local want = {}
	for id, n in pairs(self:AltNeeds(alt)) do
		local have = GetItemCount(id)
		if have > 0 then
			want[id] = math.min(n, have)
		end
	end
	local ids = SortedIDs(want)
	if #ids == 0 then
		NS:Print(string.format("You aren't carrying anything %s's guides need. Visit the bank first (\"Grab guide mats\" only grabs for this character).", name))
		return
	end
	local attached = {}
	local i = 1
	Run(function()
		while ids[i] do
			local id = ids[i]
			if want[id] <= 0 then
				i = i + 1
			else
				local index = FreeAttachment()
				if not index then
					return true, "full"
				end
				local bag, slot, count = FindStack(MY_BAGS, id)
				if not bag then
					i = i + 1 -- the rest is locked (already attached) or gone
				else
					local take = math.min(count, want[id])
					if take >= count then
						PickupContainerItem(bag, slot)
					else
						SplitContainerItem(bag, slot, take)
					end
					ClickSendMailItemButton(index)
					want[id] = want[id] - take
					attached[id] = (attached[id] or 0) + take
					return false
				end
			end
		end
		return true, "done"
	end, function(reason)
		local text = Summary(attached)
		if text ~= "" then
			NS:Print(string.format("Attached for %s: %s. Check it and press Send.", name, text))
		end
		if reason == "full" then
			NS:Print("All 12 attachment slots are used - send this one, then click \"Mats for alt\" again for the rest.")
		elseif reason == "closed" then
			NS:Print("Mailbox closed - stopped early.")
		end
	end)
end

local function ShowPicker()
	local W = NS.Widgets
	if not picker then
		picker = W:CreateCard(SendMailFrame, 260, 40)
		picker:SetPoint("TOPLEFT", mailButton, "BOTTOMLEFT", 0, -2)
		picker:SetFrameStrata("DIALOG")
		picker.title = W:SectionTitle(picker, "Send materials to")
		picker.title:SetPoint("TOPLEFT", 8, -8)
		picker.empty = W:Label(picker)
		picker.empty:SetPoint("TOPLEFT", 8, -26)
		picker.empty:SetWidth(244)
		picker:Hide()
	end
	if picker:IsShown() then
		picker:Hide()
		return
	end

	local me = NS.Characters:Me()
	local alts = {}
	for name, char in pairs(NS.Characters:All()) do
		if char ~= me and (not char.faction or char.faction == me.faction) then
			local need = BM:AltNeeds(char)
			local count = 0
			for _ in pairs(need) do
				count = count + 1
			end
			if count > 0 then
				local profs = {}
				for prof, s in pairs(char.skills or {}) do
					if NS.Guide:Has(prof) and s.rank < 450 then
						table.insert(profs, prof .. " " .. s.rank)
					end
				end
				table.sort(profs)
				table.insert(alts, { name = name, class = char.class, profs = table.concat(profs, ", "), items = count })
			end
		end
	end
	table.sort(alts, function(a, b) return a.name < b.name end)

	for _, b in ipairs(pickerRows) do
		b:Hide()
	end
	for i, a in ipairs(alts) do
		local b = pickerRows[i]
		if not b then
			b = CreateFrame("Button", nil, picker)
			b:SetHeight(32)
			b:SetPoint("TOPLEFT", 4, -24 - (i - 1) * 34)
			b:SetPoint("RIGHT", -4, 0)
			local hl = b:CreateTexture(nil, "HIGHLIGHT")
			hl:SetAllPoints()
			hl:SetTexture(NS.Skin.WHITE)
			hl:SetVertexColor(1, 1, 1, 0.08)
			b.name = W:Label(b, "GameFontHighlight")
			b.name:SetPoint("TOPLEFT", 6, -3)
			b.sub = W:Label(b)
			b.sub:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -2)
			b.sub:SetPoint("RIGHT", -6, 0)
			b.sub:SetTextColor(unpack(W.COLORS.muted))
			b:SetScript("OnClick", function(self)
				picker:Hide()
				BM:AttachForAlt(self.altName)
			end)
			pickerRows[i] = b
		end
		b.altName = a.name
		b.name:SetText(NS:ClassColoredName(a.name, a.class))
		b.sub:SetText(string.format("%s - %d item%s needed", a.profs, a.items, a.items == 1 and "" or "s"))
		b:Show()
	end
	if #alts == 0 then
		picker.empty:SetText("None of your other characters on this realm and faction need guide materials right now. (Log into each alt once so its professions are known.)")
		picker.empty:Show()
		picker:SetHeight(32 + picker.empty:GetStringHeight())
	else
		picker.empty:Hide()
		picker:SetHeight(28 + #alts * 34)
	end
	picker:Show()
end

local function EnsureMailButton()
	if mailButton or not SendMailFrame then
		return
	end
	mailButton = NS.Skin:CreateButton(SendMailFrame, 120, 22, "Mats for alt")
	mailButton:SetPoint("BOTTOMRIGHT", MailFrame, "TOPRIGHT", -40, -12)
	mailButton:SetScript("OnClick", ShowPicker)
	mailButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Mats for alt", 1, 1, 1)
		GameTooltip:AddLine("Pick one of your characters: their name is filled in and the materials their profession guides still need are attached from your bags.", 0.8, 0.8, 0.8, true)
		GameTooltip:Show()
	end)
	mailButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
	SendMailFrame:HookScript("OnHide", function()
		if picker then
			picker:Hide()
		end
	end)
end

----------------------------------------------------------------------------
-- Events
----------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("BANKFRAME_OPENED")
events:RegisterEvent("BANKFRAME_CLOSED")
events:RegisterEvent("MAIL_SHOW")
events:RegisterEvent("MAIL_CLOSED")
events:SetScript("OnEvent", function(_, event)
	if event == "BANKFRAME_OPENED" then
		EnsureBankButton()
	elseif event == "MAIL_SHOW" then
		EnsureMailButton()
	else
		Abort("closed")
		if picker then
			picker:Hide()
		end
	end
end)
