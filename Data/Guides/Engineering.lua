-- Engineering leveling route 1-450 (WotLK 3.3.5a).
-- Generated from the wow-professions.com WotLK guide; IDs resolved via Wowhead.
-- Reagents are per craft and are replaced by the live trade skill data once
-- you open the profession window.
JohnnysProfessions:RegisterGuide("Engineering", {
	-- Rough Blasting Powder <- 1x Rough Stone
	{ from = 1, to = 30, spell = 3918, item = 4357, count = 60, reagents = { [2835] = 1 }, note = "You might even reach 40 with this recipe. You will need the 60 Rough Blasting Powder later, so keep these." },
	-- Handful of Copper Bolts <- 1x Copper Bar
	{ from = 30, to = 50, spell = 3922, item = 4359, count = 30, reagents = { [2840] = 1 }, note = "You will need around 30 of these later." },
	-- Arclight Spanner <- 6x Copper Bar
	{ from = 50, to = 51, spell = 7430, item = 6219, count = 1, reagents = { [2840] = 6 }, note = "You will use this to craft engineering recipes so keep it." },
	-- Rough Copper Bomb <- 1x Linen Cloth, 1x Copper Bar, 2x Rough Blasting Powder, 1x Handful of Copper Bolts
	{ from = 51, to = 75, spell = 3923, item = 4360, count = 30, reagents = { [2589] = 1, [2840] = 1, [4357] = 2, [4359] = 1 } },
	-- Coarse Blasting Powder <- 1x Coarse Stone
	{ from = 75, to = 90, spell = 3929, item = 4364, count = 60, reagents = { [2836] = 1 }, note = "Keep these." },
	-- Coarse Dynamite <- 1x Linen Cloth, 3x Coarse Blasting Powder
	{ from = 90, to = 100, spell = 3931, item = 4365, count = 20, reagents = { [2589] = 1, [4364] = 3 } },
	-- Silver Contact <- 1x Silver Bar
	{ from = 100, to = 105, spell = 3973, item = 4404, count = 5, reagents = { [2842] = 1 } },
	-- Bronze Tube <- 2x Bronze Bar, 1x Weak Flux
	{ from = 105, to = 125, spell = 3938, item = 4371, count = 25, reagents = { [2841] = 2, [2880] = 1 }, note = "Weak Flux is sold by Engineering Supply vendors near your trainer." },
	-- Standard Scope <- 1x Moss Agate, 1x Bronze Tube
	{ from = 125, to = 135, spell = 3978, item = 4406, count = 10, reagents = { [1206] = 1, [4371] = 1 } },
	-- Heavy Blasting Powder <- 1x Heavy Stone
	{ from = 135, to = 150, spell = 3945, item = 4377, count = 30, reagents = { [2838] = 1 }, note = "Or: Whirring Bronze Gizmo. You will need 30 Heavy Blasting Powder and 15 Whirring Bronze Gizmo later, so make these now and you should reach 150 skill points." },
	-- Bronze Framework <- 1x Medium Leather, 1x Wool Cloth, 2x Bronze Bar
	{ from = 150, to = 160, spell = 3953, item = 4382, count = 15, reagents = { [2319] = 1, [2592] = 1, [2841] = 2 }, note = "Keep these too. By making them now, you might get a lot further - probably towards 160, then stop making these and only make more when you'll need them." },
	-- Explosive Sheep <- 2x Wool Cloth, 1x Whirring Bronze Gizmo, 2x Heavy Blasting Powder, 1x Bronze Framework
	{ from = 160, to = 175, spell = 3955, item = 4384, count = 15, reagents = { [2592] = 2, [4375] = 1, [4377] = 2, [4382] = 1 }, note = "Keep 5 of these, you might need it if you choose Goblin Engineering at 200." },
	-- Solid Blasting Powder <- 2x Solid Stone
	{ from = 175, to = 194, spell = 12585, item = 10505, count = 60, reagents = { [7912] = 2 }, note = "Save these because you will need them later." },
	-- Gyromatic Micro-Adjustor <- 4x Steel Bar
	{ from = 194, to = 195, spell = 12590, item = 10498, count = 1, reagents = { [3859] = 4 }, note = "Keep this, you will need it to craft some of the Engineering recipes." },
	-- Mithril Tube <- 3x Mithril Bar
	{ from = 195, to = 200, spell = 12589, item = 10559, count = 7, reagents = { [3860] = 3 }, note = "Stop making these when you reach 200. Keep 6 Mithril Tubes, because you might need them if you choose Gnomish Engineering at 200." },
	-- Unstable Trigger <- 1x Mithril Bar, 1x Mageweave Cloth, 1x Solid Blasting Powder
	{ from = 200, to = 215, spell = 12591, item = 10560, count = 20, reagents = { [3860] = 1, [4338] = 1, [10505] = 1 } },
	-- Mithril Casing <- 3x Mithril Bar
	{ from = 215, to = 238, spell = 12599, item = 10561, count = 40, reagents = { [3860] = 3 } },
	-- Hi-Explosive Bomb <- 2x Solid Blasting Powder, 1x Unstable Trigger, 2x Mithril Casing
	{ from = 238, to = 250, spell = 12619, item = 10562, count = 20, reagents = { [10505] = 2, [10560] = 1, [10561] = 2 } },
	-- Dense Blasting Powder <- 2x Dense Stone
	{ from = 250, to = 260, spell = 19788, item = 15992, count = 30, reagents = { [12365] = 2 }, note = "Keep at least 15 of these, you will need them at 285. Also, you might need to make more than 30 to reach 260." },
	-- Thorium Widget <- 3x Thorium Bar, 1x Runecloth
	{ from = 260, to = 285, spell = 19791, item = 15994, count = 35, reagents = { [12359] = 3, [14047] = 1 }, note = "It will be yellow for the last few points so you might have to make a few more to reach 285." },
	-- Thorium Shells <- 2x Thorium Bar, 1x Dense Blasting Powder
	{ from = 285, to = 300, spell = 19800, item = 15997, count = 15, reagents = { [12359] = 2, [15992] = 1 } },
	-- Handful of Fel Iron Bolts <- 1x Fel Iron Bar
	{ from = 300, to = 320, spell = 30305, item = 23783, count = 40, reagents = { [23445] = 1 }, note = "Or: Elemental Blasting Powder (4), Fel Iron Casing." },
	-- Fel Iron Bomb <- 1x Elemental Blasting Powder, 1x Fel Iron Casing, 2x Handful of Fel Iron Bolts
	{ from = 320, to = 325, spell = 30310, item = 23736, count = 10, reagents = { [23781] = 1, [23782] = 1, [23783] = 2 }, note = "You might need to make more of these if you are unlucky with the skill point gains." },
	-- Adamantite Grenade <- 4x Adamantite Bar, 1x Elemental Blasting Powder, 2x Handful of Fel Iron Bolts
	{ from = 325, to = 335, spell = 30311, item = 23737, count = 10, reagents = { [23446] = 4, [23781] = 1, [23783] = 2 } },
	-- White Smoke Flare <- 1x Netherweave Cloth, 1x Elemental Blasting Powder
	{ from = 335, to = 350, spell = 30341, item = 23768, count = 60, reagents = { [21877] = 1, [23781] = 1 }, note = "This will be green for the most part, so this is just an approximate number. The Schematic: White Smoke Flare recipe is sold by these vendors:" },
	-- Handful of Cobalt Bolts <- 2x Cobalt Bar
	{ from = 350, to = 375, spell = 56349, item = 39681, count = 35, reagents = { [36916] = 2 }, note = "Or: Volatile Blasting Trigger." },
	-- Overcharged Capacitor <- 4x Cobalt Bar, 1x Crystallized Earth
	{ from = 375, to = 385, spell = 56464, item = 39682, count = 10, reagents = { [36916] = 4, [37701] = 1 }, note = "Save these too. You will need them." },
	-- Explosive Decoy <- 1x Frostweave Cloth, 3x Volatile Blasting Trigger
	{ from = 385, to = 390, spell = 56463, item = 40536, count = 7, reagents = { [33470] = 1, [39690] = 3 } },
	-- Froststeel Tube <- 8x Cobalt Bar, 1x Crystallized Water
	{ from = 390, to = 400, spell = 56471, item = 39683, count = 15, reagents = { [36916] = 8, [37705] = 1 }, note = "Save these too. You will need them later. You will probably reach more than 400, then stop making these and make more only if you need them." },
	-- Diamond-cut Refractor Scope <- 2x Handful of Cobalt Bolts, 1x Froststeel Tube
	{ from = 400, to = 405, spell = 61471, item = 44739, count = 5, reagents = { [39681] = 2, [39683] = 1 } },
	-- Box of Bombs <- 5x Saronite Bar, 1x Volatile Blasting Trigger
	{ from = 405, to = 410, spell = 56468, item = 44951, count = 5, reagents = { [36913] = 5, [39690] = 1 } },
	-- Goblin Beam Welder <- 6x Saronite Bar, 3x Crystallized Fire, 3x Crystallized Water
	{ from = 410, to = 415, spell = 67326, item = 47828, count = 5, reagents = { [36913] = 6, [37702] = 3, [37705] = 3 } },
	-- Mana Injector Kit <- 12x Saronite Bar, 2x Crystallized Water
	{ from = 415, to = 425, spell = 56477, item = 42546, count = 12, reagents = { [36913] = 12, [37705] = 2 } },
	-- Mechanized Snow Goggles <- 2x Borean Leather, 1x Eternal Shadow, 8x Saronite Bar
	{ from = 425, to = 430, spell = 61483, item = 44742, count = 7, reagents = { [33568] = 2, [35627] = 1, [36913] = 8 } },
	-- Noise Machine <- 8x Handful of Cobalt Bolts, 2x Overcharged Capacitor, 2x Froststeel Tube
	{ from = 430, to = 435, spell = 56467, item = 40865, count = 5, reagents = { [39681] = 8, [39682] = 2, [39683] = 2 } },
	-- Gnomish Army Knife <- 1x Mining Pick, 1x Blacksmith Hammer, 1x Skinning Knife, 10x Saronite Bar
	{ from = 435, to = 450, spell = 56462, item = 40772, count = 30, reagents = { [2901] = 1, [5956] = 1, [7005] = 1, [36913] = 10 }, note = "This recipe will be green for the last 5 points, so you will probably have to make more than 30, but it should still be cheaper than making any other items,..." },
})
