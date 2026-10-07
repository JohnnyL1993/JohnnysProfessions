-- Skinning leveling route 1-450 (WotLK 3.3.5a): where to farm at each skill range.
-- Based on the wow-professions.com WotLK guide.
JohnnysProfessions:RegisterGuide("Skinning", {
	{ from = 1, to = 75, zones = { Horde = "Durotar, Mulgore, Tirisfal Glades", Alliance = "Elwynn Forest, Dun Morogh, Teldrassil" }, note = "Skin every beast you kill. Buy a Skinning Knife." },
	{ from = 75, to = 155, zones = { Horde = "The Barrens", Alliance = "Loch Modan, Wetlands" }, note = "Learn Journeyman at 50 and Expert at 125." },
	{ from = 155, to = 205, zones = { Horde = "Thousand Needles", Alliance = "Arathi Highlands" }, note = "Raptors and other beasts." },
	{ from = 205, to = 300, zones = { both = "Feralas, Un'Goro Crater" }, note = "Learn Artisan at 200." },
	{ from = 300, to = 330, zones = { both = "Hellfire Peninsula, Zangarmarsh" }, note = "Learn Master in Hellfire Peninsula or Shattrath." },
	{ from = 330, to = 350, zones = { both = "Nagrand" }, note = "Talbuks and Clefthoofs." },
	{ from = 350, to = 395, zones = { both = "Borean Tundra (north of Warsong Hold)" }, note = "Learn Grand Master in Northrend or Dalaran." },
	{ from = 395, to = 450, zones = { both = "Sholazar Basin" }, note = "Rhinos, gorillas and crocolisks." },
})
