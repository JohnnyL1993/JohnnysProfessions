-- Inscription leveling route 1-450 (WotLK 3.3.5a).
-- Generated from the wow-professions.com WotLK guide; IDs resolved via Wowhead.
-- Reagents are per craft and are replaced by the live trade skill data once
-- you open the profession window.
JohnnysProfessions:RegisterGuide("Inscription", {
	-- Ivory Ink <- 1x Alabaster Pigment
	{ from = 1, to = 18, spell = 52738, item = 37101, count = 17, reagents = { [39151] = 1 } },
	-- Scroll of Stamina <- 1x Ivory Ink, 1x Light Parchment
	{ from = 18, to = 35, spell = 45382, item = 1180, count = 17, reagents = { [37101] = 1, [39354] = 1 } },
	-- Moonglow Ink <- 2x Alabaster Pigment
	{ from = 35, to = 53, spell = 52843, item = 39469, count = 22, reagents = { [39151] = 2 } },
	-- Armor Vellum <- 2x Light Parchment, 1x Moonglow Ink
	{ from = 53, to = 75, spell = 52739, item = 38682, count = 22, reagents = { [39354] = 2, [39469] = 1 } },
	-- Midnight Ink <- 2x Dusky Pigment
	{ from = 75, to = 80, spell = 53462, item = 39774, count = 21, reagents = { [39334] = 2 } },
	-- Any orange Glyph <- 1x Light Parchment, 1x Midnight Ink
	{ from = 80, to = 100, title = "Any orange Glyph", count = 20, reagents = { [39354] = 1, [39774] = 1 }, note = "Make whichever glyph is orange; they turn yellow after ~10 points, then learn new ones." },
	-- Lion's Ink <- 2x Golden Pigment
	{ from = 100, to = 105, spell = 57704, item = 43116, count = 40, reagents = { [39338] = 2 } },
	-- Any orange Glyph <- 1x Common Parchment, 1x Lion's Ink
	{ from = 105, to = 125, title = "Any orange Glyph", count = 20, reagents = { [10648] = 1, [43116] = 1 }, note = "Glyphs turn yellow after 5 points - keep learning new ones." },
	-- Any orange Glyph <- 1x Common Parchment, 1x Lion's Ink
	{ from = 125, to = 150, title = "Any orange Glyph", count = 25, reagents = { [10648] = 1, [43116] = 1 }, note = "Turn Burnt Pigment into Dawnstar Ink at 125 if you have any; Strange Tarot works for 147-150." },
	-- Jadefire Ink <- 2x Emerald Pigment
	{ from = 150, to = 155, spell = 57707, item = 43118, count = 47, reagents = { [39339] = 2 } },
	-- Any orange Glyph <- 1x Common Parchment, 1x Jadefire Ink
	{ from = 155, to = 200, title = "Any orange Glyph", count = 47, reagents = { [10648] = 1, [43118] = 1 }, note = "Learn new glyphs every 5 points. Turn Indigo Pigment into Royal Ink at 175 if you have any." },
	-- Celestial Ink <- 2x Violet Pigment
	{ from = 200, to = 205, spell = 57709, item = 43120, count = 55, reagents = { [39340] = 2 } },
	-- Any orange Glyph <- 1x Heavy Parchment, 1x Celestial Ink
	{ from = 205, to = 245, title = "Any orange Glyph", count = 40, reagents = { [39501] = 1, [43120] = 1 }, note = "Turn Ruby Pigment into Fiery Ink at 225 - you need 5 for the next step." },
	-- Weapon Vellum II <- 2x Heavy Parchment, 1x Celestial Ink, 1x Fiery Ink
	{ from = 245, to = 250, spell = 59488, item = 39350, count = 5, reagents = { [39501] = 2, [43120] = 1, [43121] = 1 } },
	-- Shimmering Ink <- 2x Silvery Pigment
	{ from = 250, to = 255, spell = 57711, item = 43122, count = 35, reagents = { [39341] = 2 }, note = "20-35 needed; keep the extra ink." },
	-- Scroll of Spirit V <- 2x Heavy Parchment, 1x Shimmering Ink
	{ from = 255, to = 260, spell = 50608, item = 27501, count = 5, reagents = { [39501] = 2, [43122] = 1 } },
	-- Any orange Glyph <- 2x Heavy Parchment, 2x Shimmering Ink
	{ from = 260, to = 275, title = "Any orange Glyph", count = 15, reagents = { [39501] = 2, [43122] = 2 } },
	-- Ink of the Sky <- 1x Sapphire Pigment
	{ from = 275, to = 290, spell = 57712, item = 43123, count = 15, reagents = { [43107] = 1 } },
	-- Ethereal Ink <- 2x Nether Pigment
	{ from = 290, to = 305, spell = 57713, item = 43124, count = 45, reagents = { [39342] = 2 } },
	-- Any orange Glyph <- 1x Resilient Parchment, 1x Ethereal Ink
	{ from = 305, to = 350, title = "Any orange Glyph", count = 45, reagents = { [39502] = 1, [43124] = 1 }, note = "Make glyphs until they turn yellow, then learn new ones." },
	-- Ink of the Sea <- 2x Azure Pigment
	{ from = 350, to = 355, spell = 57715, item = 43126, count = 90, reagents = { [39343] = 2 } },
	-- Scroll of Spirit VII <- 2x Resilient Parchment, 1x Ink of the Sea
	{ from = 355, to = 360, spell = 50610, item = 37097, count = 5, reagents = { [39502] = 2, [43126] = 1 } },
	-- Scroll of Intellect VII <- 2x Resilient Parchment, 1x Ink of the Sea
	{ from = 360, to = 365, spell = 50603, item = 37091, count = 5, reagents = { [39502] = 2, [43126] = 1 } },
	-- Scroll of Strength VII <- 2x Resilient Parchment, 1x Ink of the Sea
	{ from = 365, to = 370, spell = 58490, item = 43465, count = 5, reagents = { [39502] = 2, [43126] = 1 } },
	-- Scroll of Agility VII <- 2x Resilient Parchment, 1x Ink of the Sea
	{ from = 370, to = 375, spell = 58482, item = 43463, count = 5, reagents = { [39502] = 2, [43126] = 1 } },
	-- Snowfall Ink <- 2x Icy Pigment
	{ from = 375, to = 380, spell = 57716, item = 43127, count = 5, reagents = { [43109] = 2 }, note = "Use your Icy Pigment. Keep spare Snowfall Ink for Northrend Inscription Research." },
	-- Glyph of Focus <- 1x Resilient Parchment, 1x Ink of the Sea
	{ from = 380, to = 385, spell = 62162, item = 44928, count = 7, reagents = { [39502] = 1, [43126] = 1 } },
	-- Any discovered Major Glyph <- 1x Resilient Parchment, 1x Ink of the Sea
	{ from = 386, to = 400, title = "Any discovered Major Glyph", count = 25, reagents = { [39502] = 1, [43126] = 1 } },
	-- Scroll of Stamina VIII <- 2x Resilient Parchment, 1x Ink of the Sea
	{ from = 400, to = 405, spell = 50620, item = 37094, count = 5, reagents = { [39502] = 2, [43126] = 1 } },
	-- Scroll of Spirit VIII <- 2x Resilient Parchment, 1x Ink of the Sea
	{ from = 405, to = 410, spell = 50611, item = 37098, count = 5, reagents = { [39502] = 2, [43126] = 1 } },
	-- Scroll of Intellect VIII <- 2x Resilient Parchment, 1x Ink of the Sea
	{ from = 410, to = 415, spell = 50604, item = 37092, count = 5, reagents = { [39502] = 2, [43126] = 1 } },
	-- Scroll of Strength VIII <- 2x Resilient Parchment, 1x Ink of the Sea
	{ from = 415, to = 420, spell = 58491, item = 43466, count = 5, reagents = { [39502] = 2, [43126] = 1 } },
	-- Scroll of Agility VIII <- 2x Resilient Parchment, 1x Ink of the Sea
	{ from = 420, to = 430, spell = 58483, item = 43464, count = 13, reagents = { [39502] = 2, [43126] = 1 } },
	-- Northrend Inscription Research <- 5x Resilient Parchment, 3x Ink of the Sea, 1x Snowfall Ink
	{ from = 430, to = 450, spell = 61177, count = 20, reagents = { [39502] = 5, [43126] = 3, [43127] = 1 }, note = "Easiest from here: do the research cooldown daily and make new glyphs as you discover them." },
})
