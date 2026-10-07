-- Trade chat customer alerts: when someone in the Trade channel asks for
-- (LF / WTB / need / "can anyone craft") something one of your characters
-- can make, a toast says so and clicking it opens a whisper to them.
--
-- Also home to NS.Toast, the small pop-up used by other modules (cooldowns
-- ready, etc.): NS.Toast:Show({ icon=, title=, text=, onClick= }).
local NS = JohnnysProfessions
NS.TradeWatch = {}
local TW = NS.TradeWatch

NS:RegisterOption("tradeWatch", true, "Trade chat",
	"Alert me about crafting customers in Trade",
	"Pops up when someone in Trade asks for something one of your characters can craft. Click it to whisper them.")

local THROTTLE = 600     -- seconds before the same person/item can alert again
local MIN_NAME_LEN = 6   -- plain-text name matches shorter than this are too noisy

----------------------------------------------------------------------------
-- Toasts
----------------------------------------------------------------------------
NS.Toast = {}
local Toast = NS.Toast

local TOAST_W, TOAST_H = 320, 50
local TOAST_LIFE = 15
local MAX_TOASTS = 3
local toasts = {}  -- pooled frames, index 1 = top

local function Layout()
	local y = -120
	for _, t in ipairs(toasts) do
		if t:IsShown() then
			t:ClearAllPoints()
			t:SetPoint("TOP", UIParent, "TOP", 0, y)
			y = y - TOAST_H - 6
		end
	end
end

local function NewToast()
	local W = NS.Widgets
	local t = CreateFrame("Button", nil, UIParent)
	t:SetSize(TOAST_W, TOAST_H)
	t:SetFrameStrata("DIALOG")
	t:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	W:StyleCard(t, true)
	t.icon = W:CreateIcon(t, 32, nil, false)
	t.icon:SetPoint("LEFT", 9, 0)
	t.title = W:Label(t, "GameFontHighlight")
	t.title:SetPoint("TOPLEFT", t.icon, "TOPRIGHT", 10, 0)
	t.title:SetPoint("RIGHT", -10, 0)
	t.text = W:Label(t)
	t.text:SetPoint("BOTTOMLEFT", t.icon, "BOTTOMRIGHT", 10, 0)
	t.text:SetPoint("RIGHT", -10, 0)
	t.text:SetTextColor(unpack(W.COLORS.muted))
	t:SetScript("OnClick", function(self, button)
		if button == "LeftButton" and self.onClick then
			self.onClick()
		end
		self:Hide()
		Layout()
	end)
	t:SetScript("OnUpdate", function(self, elapsed)
		self.life = self.life - elapsed
		if self.life <= 0 then
			self:Hide()
			Layout()
		elseif self.life < 1 then
			self:SetAlpha(self.life)
		end
	end)
	t:SetScript("OnEnter", function(self)
		self.life = math.max(self.life, TOAST_LIFE)
		self:SetAlpha(1)
	end)
	t:Hide()
	return t
end

-- info: { icon=, title=, text=, onClick= }. Left-click runs onClick, right-
-- click just dismisses. Oldest toast is reused once MAX_TOASTS are showing.
function Toast:Show(info)
	if not NS.Widgets then
		return
	end
	local t
	for _, f in ipairs(toasts) do
		if not f:IsShown() then
			t = f
			break
		end
	end
	if not t then
		if #toasts < MAX_TOASTS then
			t = NewToast()
		else
			t = table.remove(toasts, #toasts)
		end
	else
		for i, f in ipairs(toasts) do
			if f == t then
				table.remove(toasts, i)
				break
			end
		end
	end
	table.insert(toasts, 1, t)
	t.icon:SetIcon(info.icon or "Interface\\Icons\\INV_Misc_Note_01", false)
	t.title:SetText(info.title or "")
	t.text:SetText(info.text or "")
	t.onClick = info.onClick
	t.life = TOAST_LIFE
	t:SetAlpha(1)
	t:Show()
	Layout()
	PlaySound("TellMessage")
end

----------------------------------------------------------------------------
-- What your characters can craft
----------------------------------------------------------------------------
-- byItem[itemID] = { name=, chars={...} }, byName[lowercase name] = entry,
-- bySpell[spellID] = entry. Rebuilt whenever a trade skill scan adds recipes.
local byItem, byName, bySpell

NS.Characters:OnChange(function(what)
	if what == "recipes" then
		byItem = nil
	end
end)

local function AddChar(entry, charName)
	for _, n in ipairs(entry.chars) do
		if n == charName then
			return
		end
	end
	table.insert(entry.chars, charName)
end

local function Build()
	byItem, byName, bySpell = {}, {}, {}
	local cache = NS.db.global.recipeCache
	for charName, char in pairs(NS.Characters:All()) do
		for _, known in pairs(char.recipes or {}) do
			for spellID in pairs(known) do
				local r = cache[spellID]
				if r and r.item then
					local entry = byItem[r.item]
					if not entry then
						local name = GetItemInfo(r.item)
						entry = { item = r.item, name = name, chars = {} }
						byItem[r.item] = entry
						if name and #name >= MIN_NAME_LEN then
							byName[strlower(name)] = entry
						end
					end
					AddChar(entry, charName)
					bySpell[spellID] = entry
				elseif r then
					-- Enchants make no item: match on the part after " - "
					-- ("Enchant Weapon - Crusader" -> "crusader") or the link.
					local spellName = GetSpellInfo(spellID)
					if spellName then
						local entry = bySpell[spellID]
						if not entry then
							entry = { spell = spellID, name = spellName, chars = {} }
							bySpell[spellID] = entry
							local short = spellName:match("%- (.+)$") or spellName
							if #short >= MIN_NAME_LEN then
								byName[strlower(short)] = entry
							end
						end
						AddChar(entry, charName)
					end
				end
			end
		end
	end
end

----------------------------------------------------------------------------
-- Chat parsing
----------------------------------------------------------------------------
local REQUEST_WORDS = { "lf", "lfw", "wtb", "need", "needs", "looking", "anyone", "anybody", "craft", "crafter", "maker", "make", "who can" }
local SELL_WORDS = { "wts", "selling", "lfm", "lfg" }

local function HasWord(text, words)
	for _, w in ipairs(words) do
		if (" " .. text .. " "):find("[^%a]" .. w .. "[^%a]") then
			return true
		end
	end
	return false
end

local recent = {} -- [sender .. key] = time

local function Alert(sender, entry)
	local key = sender .. ":" .. (entry.item or entry.spell or entry.name)
	local now = time()
	if recent[key] and now - recent[key] < THROTTLE then
		return
	end
	recent[key] = now
	local crafter = entry.chars[1]
	if #entry.chars > 1 then
		crafter = crafter .. string.format(" (+%d)", #entry.chars - 1)
	end
	local itemText = entry.item and NS.ItemCache:ColoredName(entry.item) or entry.name
	local icon = entry.item and NS.ItemCache:Icon(entry.item) or select(3, GetSpellInfo(entry.spell))
	NS:Print(string.format("%s in Trade wants %s - %s can craft it.", sender, itemText, crafter))
	NS.Toast:Show({
		icon = icon,
		title = sender .. " wants " .. (entry.name or itemText),
		text = crafter .. " can craft it - click to whisper.",
		onClick = function()
			ChatFrame_OpenChat("/w " .. sender .. " ")
		end,
	})
end

function TW:OnMessage(msg, sender, channelName)
	if not NS:Option("tradeWatch") or not msg or not sender then
		return
	end
	if not (channelName and channelName:find("Trade")) then
		return
	end
	if sender == UnitName("player") then
		return
	end
	local lower = strlower(msg)
	if HasWord(lower, SELL_WORDS) or not HasWord(lower, REQUEST_WORDS) then
		return
	end
	if not byItem then
		Build()
	end

	-- Links first: item links and enchant/spell links.
	for id in msg:gmatch("|Hitem:(%d+)") do
		local entry = byItem[tonumber(id)]
		if entry then
			Alert(sender, entry)
			return
		end
	end
	for id in msg:gmatch("|H%a+:(%d+)") do
		local entry = bySpell[tonumber(id)]
		if entry then
			Alert(sender, entry)
			return
		end
	end
	-- Then plain-text names (links stripped so "[Item]" text isn't matched twice).
	local plain = lower:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|h.-|h", ""):gsub("|r", "")
	for name, entry in pairs(byName) do
		if plain:find(name, 1, true) then
			Alert(sender, entry)
			return
		end
	end
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_CHANNEL")
events:SetScript("OnEvent", function(_, _, msg, sender, _, channelString, _, _, _, _, channelName)
	if not NS.db then
		return
	end
	TW:OnMessage(msg, sender, channelName or channelString)
end)
