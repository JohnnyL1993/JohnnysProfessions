-- Mining leveling route 1-450 (WotLK 3.3.5a): where to farm at each skill range.
-- Based on the wow-professions.com WotLK guide.
JohnnysProfessions:RegisterGuide("Mining", {
	{ from = 1, to = 65, zones = { both = "Any starting zone: Durotar, Mulgore, Tirisfal Glades, Elwynn Forest, Dun Morogh, Darkshore" }, note = "Copper Ore. Buy a Mining Pick and turn on Find Minerals." },
	{ from = 65, to = 125, zones = { Horde = "Hillsbrad Foothills, The Barrens", Alliance = "Redridge Mountains, Ashenvale, Hillsbrad Foothills" }, note = "Tin, Copper and Silver. Learn Journeyman at 50." },
	{ from = 125, to = 175, zones = { both = "Arathi Highlands, Desolace, Thousand Needles" }, note = "Iron, Tin and Gold. Learn Expert at 125." },
	{ from = 175, to = 245, zones = { both = "The Hinterlands, Tanaris" }, note = "Mithril and Truesilver. Learn Artisan at 200 (level 25)." },
	{ from = 245, to = 275, zones = { both = "Un'Goro Crater, Blasted Lands, Felwood" }, note = "Mithril, Truesilver, Thorium." },
	{ from = 275, to = 300, zones = { both = "Un'Goro Crater, Eastern Plaguelands, Winterspring, Burning Steppes" }, note = "Thorium (Rich Thorium too)." },
	{ from = 300, to = 325, zones = { both = "Hellfire Peninsula" }, note = "Fel Iron. Learn Master in Hellfire Peninsula or Shattrath (level 40)." },
	{ from = 325, to = 350, zones = { both = "Zangarmarsh, Terokkar Forest" }, note = "Fel Iron and Adamantite." },
	{ from = 350, to = 400, zones = { both = "Borean Tundra, Howling Fjord" }, note = "Cobalt. Learn Grand Master in Northrend or Dalaran (level 55)." },
	{ from = 400, to = 450, zones = { both = "Sholazar Basin (or The Storm Peaks)" }, note = "Saronite." },
})
