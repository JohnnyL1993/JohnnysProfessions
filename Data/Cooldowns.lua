-- Profession recipes with a cooldown. The actual time left is read straight
-- from the trade skill window (GetTradeSkillCooldown), so durations don't
-- need to be listed here and any cooldown recipe missing from this list is
-- still picked up the first time it's seen on cooldown. This list only lets
-- the Cooldowns tab show "Ready" for recipes before you've used them once.
--
-- `group` merges recipes that share one cooldown (all transmutes).
local NS = JohnnysProfessions

NS.COOLDOWNS = {
	-- Alchemy
	[60893] = { prof = "Alchemy", group = "Northrend Alchemy Research" },
	[60350] = { prof = "Alchemy", group = "Transmute" }, -- Titanium
	[57427] = { prof = "Alchemy", group = "Transmute" }, -- Earthsiege Diamond
	[57425] = { prof = "Alchemy", group = "Transmute" }, -- Skyflare Diamond
	[17187] = { prof = "Alchemy", group = "Transmute" }, -- Arcanite
	[29688] = { prof = "Alchemy", group = "Transmute" }, -- Primal Might
	-- Blacksmithing / Mining
	[55208] = { prof = "Mining", group = "Smelt Titansteel" },
	-- Jewelcrafting
	[62242] = { prof = "Jewelcrafting", group = "Icy Prism" },
	-- Inscription
	[61288] = { prof = "Inscription", group = "Minor Inscription Research" },
	[61177] = { prof = "Inscription", group = "Northrend Inscription Research" },
	-- Tailoring
	[56001] = { prof = "Tailoring", group = "Moonshroud" },
	[56002] = { prof = "Tailoring", group = "Ebonweave" },
	[56003] = { prof = "Tailoring", group = "Spellweave" },
	[56005] = { prof = "Tailoring", group = "Glacial Bag" },
	[18560] = { prof = "Tailoring", group = "Mooncloth" },
}
