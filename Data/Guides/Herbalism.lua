-- Herbalism leveling route 1-450 (WotLK 3.3.5a): where to farm at each skill range.
-- Based on the wow-professions.com WotLK guide.
JohnnysProfessions:RegisterGuide("Herbalism", {
	{ from = 1, to = 70, zones = { both = "Any starting zone: Durotar, Mulgore, Tirisfal Glades, Elwynn Forest, Teldrassil, Dun Morogh" }, note = "Peacebloom, Silverleaf, Earthroot. Turn on Find Herbs." },
	{ from = 70, to = 115, zones = { Horde = "The Barrens", Alliance = "Loch Modan, Darkshore" }, note = "Mageroyal, Briarthorn, Stranglekelp (85). Learn Journeyman at 50." },
	{ from = 115, to = 170, zones = { both = "Hillsbrad Foothills, Wetlands, Stonetalon Mountains" }, note = "Bruiseweed, Wild Steelbloom, Grave Moss. Learn Expert at 125." },
	{ from = 170, to = 205, zones = { both = "Stranglethorn Vale, Arathi Highlands" }, note = "Kingsblood, Liferoot, Fadeleaf, Goldthorn, Khadgar's Whisker (185)." },
	{ from = 205, to = 230, zones = { both = "Tanaris, Searing Gorge" }, note = "Purple Lotus, Firebloom. Learn Artisan at 200 (level 25)." },
	{ from = 230, to = 270, zones = { both = "The Hinterlands" }, note = "Sungrass, Purple Lotus, Ghost Mushroom, Golden Sansam." },
	{ from = 270, to = 300, zones = { both = "Felwood" }, note = "Golden Sansam, Dreamfoil, Mountain Silversage, Gromsblood." },
	{ from = 300, to = 315, zones = { both = "Hellfire Peninsula" }, note = "Felweed. Learn Master in Hellfire Peninsula (level 40)." },
	{ from = 315, to = 325, zones = { both = "Blade's Edge Mountains, Nagrand" }, note = "Felweed, Dreaming Glory." },
	{ from = 325, to = 350, zones = { both = "Terokkar Forest" }, note = "Felweed, Dreaming Glory, Terocone." },
	{ from = 350, to = 400, zones = { both = "Howling Fjord, Borean Tundra, Grizzly Hills" }, note = "Goldclover, Tiger Lily (375). Learn Grand Master (level 55)." },
	{ from = 400, to = 435, zones = { both = "Sholazar Basin" }, note = "Adder's Tongue, Goldclover, Tiger Lily." },
	{ from = 435, to = 450, zones = { both = "The Storm Peaks" }, note = "Lichbloom, Icethorn." },
})
