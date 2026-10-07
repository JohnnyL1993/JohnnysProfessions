-- First Aid leveling route 1-450 (WotLK 3.3.5a).
-- Generated from the wow-professions.com WotLK guide; IDs resolved via Wowhead.
-- Reagents are per craft and are replaced by the live trade skill data once
-- you open the profession window.
JohnnysProfessions:RegisterGuide("First Aid", {
	-- Linen Bandage <- 1x Linen Cloth
	{ from = 1, to = 40, spell = 3275, item = 1251, count = 50, reagents = { [2589] = 1 } },
	-- Heavy Linen Bandage <- 2x Linen Cloth
	{ from = 40, to = 75, spell = 3276, item = 2581, count = 45, reagents = { [2589] = 2 } },
	-- Heavy Linen Bandage <- 2x Linen Cloth
	{ from = 75, to = 80, spell = 3276, item = 2581, count = 15, reagents = { [2589] = 2 } },
	-- Wool Bandage <- 1x Wool Cloth
	{ from = 80, to = 115, spell = 3277, item = 3530, count = 60, reagents = { [2592] = 1 } },
	-- Heavy Wool Bandage <- 2x Wool Cloth
	{ from = 115, to = 150, spell = 3278, item = 3531, count = 60, reagents = { [2592] = 2 } },
	-- Silk Bandage <- 1x Silk Cloth
	{ from = 150, to = 180, spell = 7928, item = 6450, count = 50, reagents = { [4306] = 1 } },
	-- Heavy Silk Bandage <- 2x Silk Cloth
	{ from = 180, to = 210, spell = 7929, item = 6451, count = 50, reagents = { [4306] = 2 } },
	-- Mageweave Bandage <- 1x Mageweave Cloth
	{ from = 210, to = 240, spell = 10840, item = 8544, count = 60, reagents = { [4338] = 1 } },
	-- Heavy Mageweave Bandage <- 2x Mageweave Cloth
	{ from = 240, to = 260, spell = 10841, item = 8545, count = 30, reagents = { [4338] = 2 } },
	-- Runecloth Bandage <- 1x Runecloth
	{ from = 260, to = 290, spell = 18629, item = 14529, count = 50, reagents = { [14047] = 1 } },
	-- Heavy Runecloth Bandage <- 2x Runecloth
	{ from = 290, to = 300, spell = 18630, item = 14530, count = 15, reagents = { [14047] = 2 } },
	-- Netherweave Bandage <- 1x Netherweave Cloth
	{ from = 300, to = 340, spell = 27032, item = 21990, count = 50, reagents = { [21877] = 1 } },
	-- Heavy Netherweave Bandage <- 2x Netherweave Cloth
	{ from = 340, to = 360, spell = 27033, item = 21991, count = 20, reagents = { [21877] = 2 } },
	-- Frostweave Bandage <- 1x Frostweave Cloth
	{ from = 360, to = 400, spell = 45545, item = 34721, count = 80, reagents = { [33470] = 1 } },
	-- Heavy Frostweave Bandage <- 2x Frostweave Cloth
	{ from = 400, to = 450, spell = 45546, item = 34722, count = 90, reagents = { [33470] = 2 } },
})
