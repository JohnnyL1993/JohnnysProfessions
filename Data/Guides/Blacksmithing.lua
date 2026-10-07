-- Blacksmithing leveling route 1-450 (WotLK 3.3.5a).
-- Generated from the wow-professions.com WotLK guide; IDs resolved via Wowhead.
-- Reagents are per craft and are replaced by the live trade skill data once
-- you open the profession window.
JohnnysProfessions:RegisterGuide("Blacksmithing", {
	-- Rough Sharpening Stone <- 1x Rough Stone
	{ from = 1, to = 30, spell = 2660, item = 2862, count = 40, reagents = { [2835] = 1 } },
	-- Rough Grinding Stone <- 2x Rough Stone
	{ from = 30, to = 65, spell = 3320, item = 3470, count = 55, reagents = { [2835] = 2 } },
	-- Coarse Sharpening Stone <- 1x Coarse Stone
	{ from = 65, to = 75, spell = 2665, item = 2863, count = 25, reagents = { [2836] = 1 } },
	-- Coarse Grinding Stone <- 2x Coarse Stone
	{ from = 75, to = 90, spell = 3326, item = 3478, count = 35, reagents = { [2836] = 2 }, note = "If you didn't reach 90 by making these, you could continue to the next step, but you will need more Copper Bars or make a few more Coarse Grinding Stones." },
	-- Runed Copper Belt <- 10x Copper Bar
	{ from = 90, to = 100, spell = 2666, item = 2857, count = 10, reagents = { [2840] = 10 } },
	-- Silver Rod <- 1x Silver Bar, 2x Rough Grinding Stone
	{ from = 100, to = 105, spell = 7818, item = 6338, count = 5, reagents = { [2842] = 1, [3470] = 2 } },
	-- Runed Copper Belt <- 10x Copper Bar
	{ from = 105, to = 110, spell = 2666, item = 2857, count = 5, reagents = { [2840] = 10 } },
	-- Rough Bronze Leggings <- 6x Bronze Bar
	{ from = 110, to = 125, spell = 2668, item = 2865, count = 15, reagents = { [2841] = 6 } },
	-- Heavy Grinding Stone <- 3x Heavy Stone
	{ from = 125, to = 140, spell = 3337, item = 3486, count = 35, reagents = { [2838] = 3 }, note = "Keep the Heavy Grinding Stones. Make this one up to 150 if Heavy Stone is cheap." },
	-- Patterned Bronze Bracers <- 5x Bronze Bar, 2x Coarse Grinding Stone
	{ from = 140, to = 150, spell = 2672, item = 2868, count = 10, reagents = { [2841] = 5, [3478] = 2 } },
	-- Golden Rod <- 2x Coarse Grinding Stone, 1x Gold Bar
	{ from = 150, to = 155, spell = 14379, item = 11128, count = 5, reagents = { [3478] = 2, [3577] = 1 }, note = "Green Dye is sold by Tailoring and Leatherworking supply vendors." },
	-- Green Iron Leggings <- 1x Green Dye, 1x Heavy Grinding Stone, 8x Iron Bar
	{ from = 155, to = 165, spell = 3506, item = 3842, count = 10, reagents = { [2605] = 1, [3486] = 1, [3575] = 8 } },
	-- Green Iron Bracers <- 1x Green Dye, 6x Iron Bar
	{ from = 165, to = 190, spell = 3501, item = 3835, count = 25, reagents = { [2605] = 1, [3575] = 6 } },
	-- Golden Scale Bracers <- 2x Heavy Grinding Stone, 5x Steel Bar
	{ from = 190, to = 200, spell = 7223, item = 6040, count = 10, reagents = { [3486] = 2, [3859] = 5 } },
	-- Solid Grinding Stone <- 4x Solid Stone
	{ from = 200, to = 210, spell = 9920, item = 7966, count = 30, reagents = { [7912] = 4 }, note = "Keep at least 10 of these for the 225-235 part. Keep all of them if you bought the Plans: Mithril Spurs, and you will also have to make another 40." },
	-- Heavy Mithril Gauntlet <- 6x Mithril Bar, 4x Mageweave Cloth
	{ from = 210, to = 225, spell = 9928, item = 7919, count = 15, reagents = { [3860] = 6, [4338] = 4 }, note = "At Blacksmithing skill 200 and character level 40, you can specialize in Armorsmithing or Weaponsmithing. Choosing one is optional." },
	-- Steel Plate Helm <- 14x Steel Bar, 1x Citrine, 1x Solid Grinding Stone
	{ from = 225, to = 235, spell = 9935, item = 7922, count = 10, reagents = { [3859] = 14, [3864] = 1, [7966] = 1 } },
	-- Mithril Spurs <- 4x Mithril Bar, 3x Solid Grinding Stone
	{ from = 235, to = 250, spell = 9964, item = 7969, count = 15, reagents = { [3860] = 4, [7966] = 3 }, note = "Alternative recipe:15x Mithril Coif - 150 Mithril Bar, 90 Mageweave Cloth" },
	-- Dense Sharpening Stone <- 1x Dense Stone
	{ from = 250, to = 260, spell = 16641, item = 12404, count = 20, reagents = { [12365] = 1 } },
	-- Thorium Belt <- 8x Thorium Bar
	{ from = 260, to = 270, spell = 16643, item = 12406, count = 10, reagents = { [12359] = 8 } },
	-- Thorium Bracers <- 8x Thorium Bar
	{ from = 270, to = 275, spell = 16644, item = 12408, count = 5, reagents = { [12359] = 8 } },
	-- Imperial Plate Bracers <- 12x Thorium Bar
	{ from = 275, to = 290, spell = 16649, item = 12425, count = 15, reagents = { [12359] = 12 } },
	-- Thorium Boots <- 8x Rugged Leather, 12x Thorium Bar
	{ from = 290, to = 300, spell = 16652, item = 12409, count = 10, reagents = { [8170] = 8, [12359] = 12 }, note = "Or: Thorium Helm." },
	-- Fel Weightstone <- 1x Netherweave Cloth, 1x Fel Iron Bar
	{ from = 300, to = 305, spell = 34607, item = 28420, count = 7, reagents = { [21877] = 1, [23445] = 1 }, note = "You might need to make more of these because you won't gain a skill point for every craft." },
	-- Fel Iron Plate Belt <- 4x Fel Iron Bar
	{ from = 305, to = 316, spell = 29547, item = 23484, count = 11, reagents = { [23445] = 4 }, note = "Make 16x Thorium Leggings up to 321 if 190x Thorium Bar is cheaper than 69x Fel Iron Bar." },
	-- Fel Iron Chain Gloves <- 5x Fel Iron Bar
	{ from = 316, to = 321, spell = 29552, item = 23491, count = 5, reagents = { [23445] = 5 } },
	-- Fel Iron Plate Boots <- 6x Fel Iron Bar
	{ from = 321, to = 325, spell = 29548, item = 23487, count = 4, reagents = { [23445] = 6 } },
	-- Lesser Rune of Warding <- 1x Adamantite Bar
	{ from = 325, to = 335, spell = 32284, item = 23559, count = 45, reagents = { [23446] = 1 }, note = "It's green for the last 5 points, so 45 is an approximate number. You might need to make more." },
	-- Fel Iron Chain Tunic <- 9x Fel Iron Bar
	{ from = 335, to = 340, spell = 29556, item = 23490, count = 7, reagents = { [23445] = 9 }, note = "You might need to make more because the recipe is yellow." },
	-- Lesser Ward of Shielding <- 1x Adamantite Bar
	{ from = 340, to = 350, spell = 29728, item = 23575, count = 45, reagents = { [23446] = 1 }, note = "It's green for the last 5 points, so 45 is an approximate number. You might need to make more or fewer." },
	-- Cobalt Boots <- 4x Cobalt Bar
	{ from = 350, to = 360, spell = 52569, item = 39088, count = 10, reagents = { [36916] = 4 } },
	-- Cobalt Triangle Shield <- 4x Cobalt Bar
	{ from = 360, to = 370, spell = 54550, item = 40668, count = 10, reagents = { [36916] = 4 } },
	-- Cobalt Legplates <- 5x Cobalt Bar
	{ from = 370, to = 375, spell = 52567, item = 39086, count = 5, reagents = { [36916] = 5 } },
	-- Cobalt Gauntlets <- 5x Cobalt Bar
	{ from = 375, to = 380, spell = 55835, item = 41975, count = 5, reagents = { [36916] = 5 } },
	-- Spiked Cobalt Boots <- 7x Cobalt Bar
	{ from = 380, to = 385, spell = 54918, item = 40949, count = 5, reagents = { [36916] = 7 } },
	-- Spiked Cobalt Shoulders <- 7x Cobalt Bar
	{ from = 385, to = 390, spell = 54941, item = 40950, count = 5, reagents = { [36916] = 7 } },
	-- Notched Cobalt War Axe <- 10x Cobalt Bar
	{ from = 390, to = 395, spell = 55204, item = 41243, count = 5, reagents = { [36916] = 10 } },
	-- Brilliant Saronite Belt <- 5x Saronite Bar, 6x Cobalt Bar
	{ from = 395, to = 400, spell = 59436, item = 43860, count = 5, reagents = { [36913] = 5, [36916] = 6 } },
	-- Horned Cobalt Helm <- 8x Cobalt Bar
	{ from = 400, to = 405, spell = 54949, item = 40955, count = 5, reagents = { [36916] = 8 } },
	-- Deadly Saronite Dirk <- 7x Saronite Bar, 2x Crystallized Air
	{ from = 405, to = 416, spell = 55206, item = 41245, count = 11, reagents = { [36913] = 7, [37700] = 2 } },
	-- Eternal Belt Buckle <- 1x Eternal Water, 1x Eternal Earth, 1x Eternal Shadow, 4x Saronite Bar
	{ from = 416, to = 425, spell = 55656, item = 41611, count = 13, reagents = { [35622] = 1, [35624] = 1, [35627] = 1, [36913] = 4 }, note = "There are cheaper alternative recipes that you can make, but Eternal Belt Buckle is a very useful item, so you can sell all of them and get most of your..." },
	-- Titanium Weapon Chain <- 2x Saronite Bar, 1x Titanium Bar
	{ from = 425, to = 430, spell = 55839, item = 41976, count = 7, reagents = { [36913] = 2, [41163] = 1 }, note = "The recipe will be yellow, so you might have to make more." },
	-- Daunting Legplates <- 1x Eternal Earth, 14x Saronite Bar
	{ from = 430, to = 445, spell = 55303, item = 41345, count = 23, reagents = { [35624] = 1, [36913] = 14 } },
	-- Daunting Legplates <- 1x Eternal Earth, 14x Saronite Bar
	{ from = 445, to = 450, spell = 55303, item = 41345, count = 17, reagents = { [35624] = 1, [36913] = 14 }, note = "Alternative recipes" },
})
