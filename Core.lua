JohnnysProfessions = LibStub("AceAddon-3.0"):NewAddon("JohnnysProfessions", "AceConsole-3.0", "AceEvent-3.0")
local NS = JohnnysProfessions

-- Guide data files (Data\Guides\*.lua) register themselves here via
-- NS:RegisterGuide as they load, before any module runs.
NS.Guides = {}

local defaults = {
	-- Realm-wide data shared by every character on the account: each
	-- character's skills/recipes/item counts/cooldowns, plus the AH prices
	-- this addon has scanned. Lives in `global` (not `profile`) so an alt can
	-- see what the others have.
	global = {
		realms = {},
		-- [spellID] = { prof=, item=, made=, reagents={[itemID]=n} }, read
		-- live from the trade skill window - overrides the guide data's
		-- reagent lists, so a typo in a guide file fixes itself once you've
		-- opened that profession.
		recipeCache = {},
		-- [spellID] = true for every recipe ever seen with a cooldown.
		cooldownSpells = {},
	},
	profile = {
		-- Per-window scale/opacity (see Modules\WindowSettings.lua).
		windowSettings = {},
		-- [itemID] = target count
		trackerGoals = {},
		-- Values for NS:RegisterOption toggles (see below).
		options = {},
		ui = {
			tab = "Home",
			guide = nil,
			showMiniGuide = true,
			cooldownAlerts = true,
			positions = {},
		},
	},
}

function JohnnysProfessions:OnInitialize()
	-- Per-character profile (no `true` third arg - see the note in
	-- JohnnysGearAdvisor's Core.lua), realm data lives in `global`.
	self.db = LibStub("AceDB-3.0"):New("JohnnysProfessionsDB", defaults)

	self:RegisterChatCommand("jp", "OnSlashCommand")
	self:RegisterChatCommand("johnnysprofessions", "OnSlashCommand")
end

local TAB_COMMANDS = {
	home = "Home",
	guide = "Professions", guides = "Professions", prof = "Professions", professions = "Professions",
	spec = "Specializations", specs = "Specializations",
	settings = "Settings", config = "Settings",
	shop = "Shopping", shopping = "Shopping",
	gold = "Gold",
	cd = "Cooldowns", cooldowns = "Cooldowns",
	alts = "Alts",
}

-- Extra slash commands registered by feature modules:
--   NS:RegisterSlash("farm", function(rest) ... end, "/jp farm - start/stop the farming tracker")
-- `rest` is whatever followed the command word (original case).
local extraCommands, extraHelp = {}, {}
function JohnnysProfessions:RegisterSlash(word, handler, help)
	extraCommands[strlower(word)] = handler
	if help then
		table.insert(extraHelp, help)
	end
end

function JohnnysProfessions:OnSlashCommand(input)
	input = strtrim(input or "")
	local word, rest = input:match("^(%S*)%s*(.-)$")
	local cmd = strlower(word or "")
	if cmd == "" then
		self.MainWindow:Toggle()
	elseif TAB_COMMANDS[cmd] then
		self.MainWindow:ShowTab(TAB_COMMANDS[cmd])
	elseif extraCommands[cmd] then
		extraCommands[cmd](rest or "")
	elseif cmd == "track" then
		self.TrackerWindow:Toggle()
	elseif cmd == "mini" then
		self.MiniGuide:Toggle()
	elseif cmd == "scan" then
		self.AuctionScan:Start()
	elseif cmd == "debug" then
		self.Guide:ReportInvalidData()
	else
		self:Print("Commands:")
		self:Print("  /jp - show or hide the main window")
		self:Print("  /jp home | guides | spec | shop | gold | cd | alts | settings - open a page")
		self:Print("  /jp track - show or hide the item tracker")
		self:Print("  /jp mini - show or hide the mini-guide")
		self:Print("  /jp scan - scan AH prices (auction house must be open)")
		self:Print("  /jp debug - list guide entries with bad spell IDs")
		for _, help in ipairs(extraHelp) do
			self:Print("  " .. help)
		end
	end
end

----------------------------------------------------------------------------
-- Options registry. Feature modules declare their toggles at load time and
-- the Settings page lists them by section:
--   NS:RegisterOption("autoRepair", true, "Everyday", "Auto repair", "Repairs at vendors ...")
--   if NS:Option("autoRepair") then ... end
-- Values live in db.profile.options; unset options fall back to the default.
----------------------------------------------------------------------------
JohnnysProfessions.optionList = {}
local optionDefaults = {}

function JohnnysProfessions:RegisterOption(key, default, section, label, desc)
	optionDefaults[key] = default
	table.insert(self.optionList, { key = key, section = section or "General", label = label or key, desc = desc })
end

function JohnnysProfessions:Option(key)
	local opts = self.db and self.db.profile.options
	local v = opts and opts[key]
	if v == nil then
		return optionDefaults[key]
	end
	return v
end

function JohnnysProfessions:SetOption(key, value)
	self.db.profile.options[key] = value
end

function JohnnysProfessions:Toggle()
	self.MainWindow:Toggle()
end

function JohnnysProfessions:RegisterGuide(key, steps)
	self.Guides[key] = steps
end

-- This realm's shared table: { chars = { [name] = {...} }, prices = { [itemID] = {...} } }
function JohnnysProfessions:RealmDB()
	local realms = self.db.global.realms
	local realm = GetRealmName()
	local r = realms[realm]
	if not r then
		r = { chars = {}, prices = {} }
		realms[realm] = r
	end
	return r
end

----------------------------------------------------------------------------
-- Small shared helpers
----------------------------------------------------------------------------
function JohnnysProfessions:ItemIDFromLink(link)
	if not link then
		return nil
	end
	local id = link:match("item:(%d+)")
	return id and tonumber(id)
end

function JohnnysProfessions:SpellIDFromLink(link)
	if not link then
		return nil
	end
	local id = link:match("enchant:(%d+)")
	return id and tonumber(id)
end

-- "12g 3s 40c" with coloured unit letters; nil/0 handled by the caller.
function JohnnysProfessions:FormatMoney(copper)
	if not copper then
		return "|cff808080-|r"
	end
	local neg = copper < 0
	copper = math.floor(math.abs(copper) + 0.5)
	local g = math.floor(copper / 10000)
	local s = math.floor((copper % 10000) / 100)
	local c = copper % 100
	local text
	if g > 0 then
		text = string.format("%d|cffffd700g|r %d|cffc7c7cfs|r", g, s)
	elseif s > 0 then
		text = string.format("%d|cffc7c7cfs|r %d|cffeda55fc|r", s, c)
	else
		text = string.format("%d|cffeda55fc|r", c)
	end
	if neg then
		text = "|cffff4040-|r" .. text
	end
	return text
end

function JohnnysProfessions:FormatDuration(seconds)
	if seconds <= 0 then
		return "|cff40ff40Ready|r"
	end
	local d = math.floor(seconds / 86400)
	local h = math.floor((seconds % 86400) / 3600)
	local m = math.floor((seconds % 3600) / 60)
	if d > 0 then
		return string.format("%dd %dh", d, h)
	elseif h > 0 then
		return string.format("%dh %dm", h, m)
	end
	return string.format("%dm", math.max(m, 1))
end

function JohnnysProfessions:ClassColoredName(name, classFile)
	local c = classFile and RAID_CLASS_COLORS[classFile]
	if not c then
		return name
	end
	return string.format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, name)
end
