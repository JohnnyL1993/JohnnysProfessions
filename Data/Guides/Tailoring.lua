-- Tailoring leveling route 1-450 (WotLK 3.3.5a).
-- Generated from the wow-professions.com WotLK guide; IDs resolved via Wowhead.
-- Reagents are per craft and are replaced by the live trade skill data once
-- you open the profession window.
JohnnysProfessions:RegisterGuide("Tailoring", {
	-- Bolt of Linen Cloth <- 2x Linen Cloth
	{ from = 1, to = 45, spell = 2963, item = 2996, count = 102, reagents = { [2589] = 2 }, note = "Stop making these if you reach 45 and only make more if you need them." },
	-- Linen Belt <- 1x Coarse Thread, 1x Bolt of Linen Cloth
	{ from = 40, to = 67, spell = 8776, item = 7026, count = 35, reagents = { [2320] = 1, [2996] = 1 } },
	-- Reinforced Linen Cape <- 3x Coarse Thread, 2x Bolt of Linen Cloth
	{ from = 67, to = 75, spell = 2397, item = 2580, count = 8, reagents = { [2320] = 3, [2996] = 2 }, note = "You will need around 33x Fine Thread for the 75-125 part. You can vendor any remaining Coarse Thread, you won't need them." },
	-- Bolt of Woolen Cloth <- 3x Wool Cloth
	{ from = 75, to = 100, spell = 2964, item = 2997, count = 45, reagents = { [2592] = 3 } },
	-- Simple Kilt <- 1x Fine Thread, 4x Bolt of Linen Cloth
	{ from = 100, to = 110, spell = 12046, item = 10047, count = 13, reagents = { [2321] = 1, [2996] = 4 } },
	-- Double-stitched Woolen Shoulders <- 2x Fine Thread, 3x Bolt of Woolen Cloth
	{ from = 110, to = 125, spell = 3848, item = 4314, count = 15, reagents = { [2321] = 2, [2997] = 3 }, note = "You will need 36x Blue Dye, 83x Fine Thread, 10x Bleach, 40x Red Dye for the 125-205 part." },
	-- Bolt of Silk Cloth <- 4x Silk Cloth
	{ from = 125, to = 145, spell = 3839, item = 4305, count = 201, reagents = { [4306] = 4 } },
	-- Azure Silk Hood <- 1x Fine Thread, 2x Bolt of Silk Cloth, 2x Blue Dye
	{ from = 145, to = 160, spell = 8760, item = 7048, count = 18, reagents = { [2321] = 1, [4305] = 2, [6260] = 2 } },
	-- Silk Headband <- 2x Fine Thread, 3x Bolt of Silk Cloth
	{ from = 160, to = 170, spell = 8762, item = 7050, count = 10, reagents = { [2321] = 2, [4305] = 3 } },
	-- Formal White Shirt <- 1x Fine Thread, 2x Bleach, 3x Bolt of Silk Cloth
	{ from = 170, to = 175, spell = 3871, item = 4334, count = 5, reagents = { [2321] = 1, [2324] = 2, [4305] = 3 } },
	-- Bolt of Mageweave <- 4x Mageweave Cloth
	{ from = 175, to = 185, spell = 3865, item = 4339, count = 94, reagents = { [4338] = 4 } },
	-- Crimson Silk Vest <- 2x Fine Thread, 2x Red Dye, 4x Bolt of Silk Cloth
	{ from = 185, to = 205, spell = 8791, item = 7058, count = 20, reagents = { [2321] = 2, [2604] = 2, [4305] = 4 }, note = "You will need 20x Silken Thread, 71x Heavy Silken Thread, 20x Red Dye, 5x Orange Dye and 75x Rune Thread for the 205-300 part." },
	-- Crimson Silk Pantaloons <- 2x Red Dye, 2x Silken Thread, 4x Bolt of Silk Cloth
	{ from = 205, to = 215, spell = 8799, item = 7062, count = 10, reagents = { [2604] = 2, [4291] = 2, [4305] = 4 } },
	-- Orange Mageweave Shirt <- 1x Bolt of Mageweave, 1x Orange Dye, 1x Heavy Silken Thread
	{ from = 215, to = 220, spell = 12061, item = 10056, count = 5, reagents = { [4339] = 1, [6261] = 1, [8343] = 1 } },
	-- Black Mageweave Gloves <- 2x Bolt of Mageweave, 2x Heavy Silken Thread
	{ from = 220, to = 230, spell = 12053, item = 10003, count = 10, reagents = { [4339] = 2, [8343] = 2 } },
	-- Black Mageweave Headband <- 3x Bolt of Mageweave, 2x Heavy Silken Thread
	{ from = 230, to = 250, spell = 12072, item = 10024, count = 23, reagents = { [4339] = 3, [8343] = 2 } },
	-- Bolt of Runecloth <- 4x Runecloth
	{ from = 250, to = 260, spell = 18401, item = 14048, count = 200, reagents = { [14047] = 4 } },
	-- Runecloth Belt <- 3x Bolt of Runecloth, 1x Rune Thread
	{ from = 260, to = 280, spell = 18402, item = 13856, count = 25, reagents = { [14048] = 3, [14341] = 1 }, note = "The recipe goes yellow at 270, you might have to make a few more." },
	-- Runecloth Gloves <- 5x Bolt of Runecloth, 2x Rune Thread
	{ from = 280, to = 300, spell = 18417, item = 13863, count = 25, reagents = { [14048] = 5, [14341] = 2 }, note = "The recipes will be yellow at 290, so you might have to make a few more. Rune Threads are sold by your trainer." },
	-- Bolt of Netherweave <- 5x Netherweave Cloth
	{ from = 300, to = 325, spell = 26745, item = 21840, count = 140, reagents = { [21877] = 5 } },
	-- Bolt of Imbued Netherweave <- 3x Bolt of Netherweave, 2x Arcane Dust
	{ from = 325, to = 331, spell = 26747, item = 21842, count = 6, reagents = { [21840] = 3, [22445] = 2 }, note = "The Pattern: Bolt of Imbued Netherweave is sold by Eiin in Shattrath City." },
	-- Netherweave Pants <- 1x Rune Thread, 6x Bolt of Netherweave
	{ from = 331, to = 336, spell = 26771, item = 21852, count = 5, reagents = { [14341] = 1, [21840] = 6 }, note = "This recipe is taught by your trainer, so you have to go back." },
	-- Netherweave Boots <- 1x Rune Thread, 6x Bolt of Netherweave, 2x Knothide Leather
	{ from = 336, to = 346, spell = 26772, item = 21853, count = 10, reagents = { [14341] = 1, [21840] = 6, [21887] = 2 } },
	-- Netherweave Tunic <- 2x Rune Thread, 8x Bolt of Netherweave
	{ from = 346, to = 350, spell = 26774, item = 21855, count = 4, reagents = { [14341] = 2, [21840] = 8 }, note = "The recipe is sold by Eiin in Shattrath City." },
	-- Bolt of Frostweave <- 5x Frostweave Cloth
	{ from = 350, to = 375, spell = 55899, item = 41510, count = 50, reagents = { [33470] = 5 }, note = "Crafting around 50 should get you to 375, but in total, you will need more than 600 to reach 440. (3000x Frostweave Cloth)." },
	-- Frostwoven Belt <- 1x Eternium Thread, 3x Bolt of Frostweave
	{ from = 375, to = 380, spell = 55908, item = 41522, count = 5, reagents = { [38426] = 1, [41510] = 3 } },
	-- Frostwoven Boots <- 1x Eternium Thread, 4x Bolt of Frostweave
	{ from = 380, to = 385, spell = 55906, item = 41520, count = 5, reagents = { [38426] = 1, [41510] = 4 } },
	-- Frostwoven Cowl <- 1x Eternium Thread, 5x Bolt of Frostweave
	{ from = 385, to = 395, spell = 55907, item = 41521, count = 13, reagents = { [38426] = 1, [41510] = 5 } },
	-- Duskweave Belt <- 1x Eternium Thread, 7x Bolt of Frostweave
	{ from = 395, to = 400, spell = 55914, item = 41543, count = 5, reagents = { [38426] = 1, [41510] = 7 } },
	-- Bolt of Imbued Frostweave <- 2x Infinite Dust, 2x Bolt of Frostweave
	{ from = 400, to = 405, spell = 55900, item = 41511, count = 20, reagents = { [34054] = 2, [41510] = 2 } },
	-- Duskweave Wristwraps <- 1x Eternium Thread, 8x Bolt of Frostweave
	{ from = 405, to = 410, spell = 55920, item = 41551, count = 5, reagents = { [38426] = 1, [41510] = 8 } },
	-- Duskweave Gloves <- 1x Eternium Thread, 9x Bolt of Frostweave
	{ from = 410, to = 415, spell = 55922, item = 41545, count = 5, reagents = { [38426] = 1, [41510] = 9 } },
	-- Duskweave Boots <- 1x Eternium Thread, 10x Bolt of Frostweave
	{ from = 415, to = 425, spell = 55924, item = 41544, count = 13, reagents = { [38426] = 1, [41510] = 10 } },
	-- Frostweave Bag <- 2x Eternium Thread, 6x Bolt of Imbued Frostweave
	{ from = 425, to = 440, spell = 56007, item = 41599, count = 20, reagents = { [38426] = 2, [41511] = 6 }, note = "The recipe will be yellow for the last 10 points. You usually have to make around 20-23 to reach 440." },
	-- Frostweave Bag <- 2x Eternium Thread, 6x Bolt of Imbued Frostweave
	{ from = 440, to = 450, spell = 56007, item = 41599, count = 35, reagents = { [38426] = 2, [41511] = 6 }, note = "Green from 440, so the count varies (30-40). Epic gloves/robes also work if you plan to sell them." },
})
