-- Jewelcrafting leveling route 1-450 (WotLK 3.3.5a).
-- Generated from the wow-professions.com WotLK guide; IDs resolved via Wowhead.
-- Reagents are per craft and are replaced by the live trade skill data once
-- you open the profession window.
JohnnysProfessions:RegisterGuide("Jewelcrafting", {
	-- Delicate Copper Wire <- 2x Copper Bar
	{ from = 1, to = 35, spell = 25255, item = 20816, count = 55, reagents = { [2840] = 2 }, note = "Keep these because you will need them later. But you can stop making them when you reach 35 and only make more if you need it." },
	-- Tigerseye Band <- 1x Tigerseye, 1x Delicate Copper Wire
	{ from = 35, to = 50, spell = 32179, item = 25439, count = 15, reagents = { [818] = 1, [20816] = 1 } },
	-- Bronze Setting <- 2x Bronze Bar
	{ from = 50, to = 80, spell = 25278, item = 20817, count = 50, reagents = { [2841] = 2 }, note = "Save these. You will need some of them later." },
	-- Gloom Band <- 2x Shadowgem, 2x Delicate Copper Wire, 1x Bronze Setting
	{ from = 80, to = 100, spell = 25287, item = 20823, count = 20, reagents = { [1210] = 2, [20816] = 2, [20817] = 1 }, note = "Or: Simple Pearl Ring, Ring of Silver Might. Alternative recipes:" },
	-- Ring of Twilight Shadows <- 2x Shadowgem, 2x Bronze Bar
	{ from = 100, to = 110, spell = 25318, item = 20828, count = 10, reagents = { [1210] = 2, [2841] = 2 } },
	-- Heavy Stone Statue <- 8x Heavy Stone
	{ from = 110, to = 120, spell = 32807, item = 25881, count = 10, reagents = { [2838] = 8 }, note = "If Heavy Stone is cheap, then you can make this one up to 130." },
	-- Pendant of the Agate Shield <- 1x Moss Agate, 1x Bronze Setting
	{ from = 120, to = 150, spell = 25610, item = 20950, count = 30, reagents = { [1206] = 1, [20817] = 1 }, note = "Alternative recipes: Make Amulet of the Moon if 2x Lesser Moonstone is cheaper than one Moss Agate." },
	-- Mithril Filigree <- 2x Mithril Bar
	{ from = 150, to = 180, spell = 25615, item = 20963, count = 40, reagents = { [3860] = 2 }, note = "Keep these. You will need some of them later." },
	-- Solid Stone Statue <- 10x Solid Stone
	{ from = 180, to = 185, spell = 32808, item = 25882, count = 9, reagents = { [7912] = 10 }, note = "If you can get cheap Solid Stones, then you could make this one up to 190. Alternative recipes:" },
	-- Engraved Truesilver Ring <- 1x Truesilver Bar, 2x Mithril Filigree
	{ from = 185, to = 210, spell = 25620, item = 20960, count = 28, reagents = { [6037] = 1, [20963] = 2 }, note = "Or: Citrine Ring of Rapid Healing. This recipe will be yellow for the last few points, so you might have to make a few more. Alternative recipes:" },
	-- Aquamarine Signet <- 3x Aquamarine, 4x Flask of Mojo
	{ from = 210, to = 220, spell = 26874, item = 20964, count = 10, reagents = { [7909] = 3, [8151] = 4 } },
	-- Aquamarine Pendant of the Warrior <- 1x Aquamarine, 3x Mithril Filigree
	{ from = 220, to = 225, spell = 26876, item = 21755, count = 5, reagents = { [7909] = 1, [20963] = 3 } },
	-- Thorium Setting <- 1x Thorium Bar
	{ from = 225, to = 250, spell = 26880, item = 21752, count = 56, reagents = { [12359] = 1 }, note = "Stop making these at 250 and only make more if you need them. (you will need around 56)" },
	-- Ruby Pendant of Fire <- 1x Star Ruby, 1x Thorium Setting
	{ from = 250, to = 260, spell = 26883, item = 21764, count = 10, reagents = { [7910] = 1, [21752] = 1 } },
	-- Simple Opal Ring <- 1x Large Opal, 1x Thorium Setting
	{ from = 260, to = 281, spell = 26902, item = 21767, count = 21, reagents = { [12799] = 1, [21752] = 1 }, note = "Alternative recipe:" },
	-- Diamond Focus Ring <- 1x Azerothian Diamond, 1x Thorium Setting
	{ from = 281, to = 295, spell = 36526, item = 30422, count = 20, reagents = { [12800] = 1, [21752] = 1 } },
	-- Emerald Lion Ring <- 2x Huge Emerald, 1x Thorium Setting
	{ from = 295, to = 300, spell = 34961, item = 29160, count = 5, reagents = { [12364] = 2, [21752] = 1 }, note = "Or: Onslaught Ring, Sapphire Pendant of Winter Night, Glowing Thorium Band." },
	-- Brilliant Golden Draenite <- 1x Golden Draenite
	{ from = 300, to = 320, spell = 28938, item = 23113, count = 30, reagents = { [23112] = 1 }, note = "Any green Outland gem cut works (Glowing Shadow Draenite, Inscribed Flame Spessarite, ...)." },
	-- Glinting Flame Spessarite <- 1x Flame Spessarite
	{ from = 320, to = 325, spell = 28914, item = 23100, count = 6, reagents = { [21929] = 1 } },
	-- Mercurial Adamantite <- 1x Primal Earth, 4x Adamantite Powder
	{ from = 325, to = 335, spell = 38068, item = 31079, count = 12, reagents = { [22452] = 1, [24243] = 4 }, note = "Save the 12x Mercurial Adamantite. You will need them at 340." },
	-- Sovereign Shadow Draenite <- 1x Shadow Draenite
	{ from = 335, to = 340, spell = 28936, item = 23111, count = 8, reagents = { [23107] = 1 }, note = "Any Outland gem cut that is still orange/yellow works." },
	-- Heavy Adamantite Ring <- 1x Adamantite Bar, 1x Mercurial Adamantite
	{ from = 340, to = 350, spell = 31052, item = 24078, count = 12, reagents = { [23446] = 1, [31079] = 1 } },
	-- Cut any uncommon Northrend gem
	{ from = 350, to = 395, title = "Cut any uncommon Northrend gem", count = 60, reagents = {}, note = "Learn cuts for the gems you have: Bloodstone, Chalcedony, Dark Jade, Huge Citrine, Shadow Crystal, Sun Crystal. ~60 cuts." },
	-- Bloodstone Band <- 1x Bloodstone, 2x Crystallized Earth
	{ from = 395, to = 400, spell = 56193, item = 42336, count = 5, reagents = { [36917] = 1, [37701] = 2 }, note = "Or: Crystal Chalcedony Amulet, Crystal Citrine Necklace, Sun Rock Ring. These are all yellow recipes, so you might have to make more than 5." },
	-- Stoneguard Band <- 2x Eternal Earth
	{ from = 400, to = 420, spell = 58145, item = 43248, count = 23, reagents = { [35624] = 2 }, note = "Or: Shadowmight Ring." },
	-- Persistent Earthsiege Diamond <- 1x Earthsiege Diamond
	{ from = 420, to = 440, spell = 55402, item = 41381, count = 20, reagents = { [41334] = 1 }, note = "Or: Powerful Earthsiege Diamond, Swift Skyflare Diamond, Tireless Skyflare Diamond, Dream Signet." },
	-- Icy Prism <- 1x Chalcedony, 1x Shadow Crystal, 1x Dark Jade, 1x Frozen Orb
	{ from = 440, to = 450, spell = 62242, item = 44943, count = 10, reagents = { [36923] = 1, [36926] = 1, [36932] = 1, [43102] = 1 }, note = "Daily cooldown that gives skill up to 450, or keep cutting meta gems if you want 450 quickly." },
})
