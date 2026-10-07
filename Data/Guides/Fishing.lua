-- Fishing leveling route 1-450 (WotLK 3.3.5a): where to farm at each skill range.
-- Based on the wow-professions.com WotLK guide.
JohnnysProfessions:RegisterGuide("Fishing", {
	{ from = 1, to = 50, zones = { both = "Any starting zone or capital city" }, note = "Buy a Fishing Pole and learn Apprentice Fishing." },
	{ from = 50, to = 200, zones = { Horde = "Orgrimmar, The Barrens", Alliance = "Stormwind, Wetlands" }, note = "Learn Journeyman, and Expert at 125. Nightcrawlers help." },
	{ from = 200, to = 275, zones = { both = "Felwood, Feralas, The Hinterlands, Un'Goro Crater, Western Plaguelands" }, note = "Learn Artisan." },
	{ from = 275, to = 300, zones = { both = "Jademir Lake (Feralas), Eastern Plaguelands" }, note = "Use Bright Baubles." },
	{ from = 300, to = 375, zones = { both = "Zangarmarsh, Terokkar Forest (or Northrend coasts)" }, note = "Learn Master (needs Fishing 275)." },
	{ from = 375, to = 450, zones = { both = "Northrend: Borean Tundra, Dalaran fountain, Sholazar Basin" }, note = "Learn Grand Master at 350. Fishing dailies in Dalaran also give skill." },
})
