-- Leatherworking leveling route 1-450 (WotLK 3.3.5a).
-- Generated from the wow-professions.com WotLK guide; IDs resolved via Wowhead.
-- Reagents are per craft and are replaced by the live trade skill data once
-- you open the profession window.
JohnnysProfessions:RegisterGuide("Leatherworking", {
	-- Light Leather <- 3x Ruined Leather Scraps
	{ from = 1, to = 20, spell = 2881, item = 2318, count = 19, reagents = { [2934] = 3 }, note = "Or: Light Armor Kit. Make the next recipe if you don't have Ruined Leather Scraps." },
	-- Light Armor Kit <- 1x Light Leather
	{ from = 20, to = 45, spell = 2152, item = 2304, count = 40, reagents = { [2318] = 1 } },
	-- Handstitched Leather Cloak <- 2x Light Leather, 1x Coarse Thread
	{ from = 45, to = 55, spell = 9058, item = 7276, count = 20, reagents = { [2318] = 2, [2320] = 1 } },
	-- Embossed Leather Gloves <- 3x Light Leather, 2x Coarse Thread
	{ from = 55, to = 100, spell = 3756, item = 4239, count = 50, reagents = { [2318] = 3, [2320] = 2 } },
	-- Fine Leather Belt <- 6x Light Leather, 2x Coarse Thread
	{ from = 100, to = 120, spell = 3763, item = 4246, count = 25, reagents = { [2318] = 6, [2320] = 2 }, note = "Check the Auction house and if 1x Medium Hide is cheaper than 4x Medium Leather then buy up to 25 of them." },
	-- Dark Leather Boots <- 4x Medium Leather, 2x Fine Thread, 1x Gray Dye
	{ from = 120, to = 135, spell = 2167, item = 2315, count = 20, reagents = { [2319] = 4, [2321] = 2, [4340] = 1 }, note = "Alternative recipe If you made Cured Medium Hide, make as many Dark Leather Belt as you can instead of the boots. (you should stop making them at 150)" },
	-- Dark Leather Pants <- 12x Medium Leather, 1x Fine Thread, 1x Gray Dye
	{ from = 135, to = 150, spell = 7135, item = 5961, count = 25, reagents = { [2319] = 12, [2321] = 1, [4340] = 1 } },
	-- Heavy Leather <- 5x Medium Leather
	{ from = 150, to = 155, spell = 20649, item = 4234, count = 7, reagents = { [2319] = 5 }, note = "Or: Heavy Leather Ball. You can also make the following recipe: The pattern is sold by these NPCs." },
	-- Cured Heavy Hide <- 1x Heavy Hide, 3x Salt
	{ from = 155, to = 165, spell = 3818, item = 4236, count = 20, reagents = { [4235] = 1, [4289] = 3 }, note = "You will need the Cured Heavy Hides later. Alternative recipes" },
	-- Heavy Armor Kit <- 1x Fine Thread, 5x Heavy Leather
	{ from = 165, to = 180, spell = 3780, item = 4265, count = 15, reagents = { [2321] = 1, [4234] = 5 } },
	-- Barbaric Shoulders <- 2x Fine Thread, 8x Heavy Leather, 1x Cured Heavy Hide
	{ from = 180, to = 190, spell = 7151, item = 5964, count = 10, reagents = { [2321] = 2, [4234] = 8, [4236] = 1 } },
	-- Guardian Gloves <- 4x Heavy Leather, 1x Cured Heavy Hide, 1x Silken Thread
	{ from = 190, to = 200, spell = 7156, item = 5966, count = 10, reagents = { [4234] = 4, [4236] = 1, [4291] = 1 } },
	-- Thick Armor Kit <- 1x Silken Thread, 5x Thick Leather
	{ from = 200, to = 205, spell = 10487, item = 8173, count = 7, reagents = { [4291] = 1, [4304] = 5 } },
	-- Nightscape Headband <- 2x Silken Thread, 5x Thick Leather
	{ from = 205, to = 235, spell = 10507, item = 8176, count = 40, reagents = { [4291] = 2, [4304] = 5 }, note = "You need a bit more Silken Thread to make these than the Thick Armor kits, but you can sell the Headbands to the vendor for a lot more, so they are cheaper..." },
	-- Nightscape Pants <- 4x Silken Thread, 14x Thick Leather
	{ from = 235, to = 250, spell = 10548, item = 8193, count = 15, reagents = { [4291] = 4, [4304] = 14 } },
	-- Rugged Armor Kit <- 5x Rugged Leather
	{ from = 250, to = 265, spell = 19058, item = 15564, count = 25, reagents = { [8170] = 5 } },
	-- Wicked Leather Bracers <- 1x Black Dye, 8x Rugged Leather, 1x Rune Thread
	{ from = 265, to = 290, spell = 19052, item = 15084, count = 28, reagents = { [2325] = 1, [8170] = 8, [14341] = 1 } },
	-- Wicked Leather Headband <- 1x Black Dye, 12x Rugged Leather, 1x Rune Thread
	{ from = 290, to = 300, spell = 19071, item = 15086, count = 10, reagents = { [2325] = 1, [8170] = 12, [14341] = 1 } },
	-- Knothide Armor Kit <- 4x Knothide Leather
	{ from = 300, to = 325, spell = 32456, item = 25650, count = 30, reagents = { [21887] = 4 }, note = "The recipe will be yellow, so you might have to make a few more. Alternative recipe:" },
	-- Heavy Knothide Leather <- 5x Knothide Leather
	{ from = 325, to = 335, spell = 32455, item = 23793, count = 66, reagents = { [21887] = 5 } },
	-- Thick Draenic Vest <- 3x Rune Thread, 3x Heavy Knothide Leather
	{ from = 335, to = 350, spell = 32473, item = 25671, count = 22, reagents = { [14341] = 3, [23793] = 3 }, note = "Or: Scaled Draenic Boots. It will be yellow for 10 points, so you might have to make a few more to reach 350." },
	-- Borean Armor Kit <- 4x Borean Leather
	{ from = 350, to = 380, spell = 50962, item = 38375, count = 35, reagents = { [33568] = 4 } },
	-- Arctic Boots <- 8x Borean Leather
	{ from = 380, to = 386, spell = 50948, item = 38404, count = 6, reagents = { [33568] = 8 } },
	-- Arctic Gloves <- 10x Borean Leather
	{ from = 386, to = 390, spell = 50947, item = 38403, count = 4, reagents = { [33568] = 10 } },
	-- Heavy Borean Leather <- 6x Borean Leather
	{ from = 390, to = 405, spell = 50936, item = 38425, count = 300, reagents = { [33568] = 6 } },
	-- Arctic Wristguards <- 12x Borean Leather
	{ from = 405, to = 410, spell = 51571, item = 38433, count = 10, reagents = { [33568] = 12 }, note = "You might have to make more than 10 because this recipe is yellow." },
	-- Dark Frostscale Leggings <- 5x Crystallized Water, 4x Heavy Borean Leather
	{ from = 410, to = 420, spell = 60601, item = 44436, count = 13, reagents = { [37705] = 5, [38425] = 4 }, note = "Or: Dark Iceborne Leggings. Both will be yellow, so you might have to make more." },
	-- Overcast Bracers <- 1x Eternal Water, 8x Heavy Borean Leather
	{ from = 420, to = 425, spell = 60720, item = 43264, count = 5, reagents = { [35622] = 1, [38425] = 8 }, note = "Pattern: Overcast Bracers is sold by Braeg Stoutbeard. (He is in front of the building where the Leatherworking trainer is)" },
	-- Overcast Handwraps <- 1x Eternal Water, 10x Heavy Borean Leather
	{ from = 425, to = 435, spell = 60721, item = 43265, count = 13, reagents = { [35622] = 1, [38425] = 10 }, note = "Pattern: Overcast Handwraps recipe is sold by Braeg Stoutbeard." },
	-- Frosthide Leg Armor <- 2x Nerubian Chitin, 1x Frozen Orb, 2x Arctic Fur
	{ from = 435, to = 440, spell = 50965, item = 38373, count = 5, reagents = { [38558] = 2, [43102] = 1, [44128] = 2 }, note = "Or: Icescale Leg Armor." },
	-- Trollwoven Girdle <- 5x Eternal Shadow, 5x Eternal Fire, 10x Heavy Borean Leather, 1x Frozen Orb
	{ from = 440, to = 450, spell = 60759, item = 43484, count = 10, reagents = { [35627] = 5, [36860] = 5, [38425] = 10, [43102] = 1 }, note = "Pattern: Trollwoven Girdle is sold by Braeg Stoutbeard for 2 Arctic Fur." },
})
