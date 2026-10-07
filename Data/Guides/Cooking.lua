-- Cooking leveling route 1-450 (WotLK 3.3.5a).
-- Generated from the wow-professions.com WotLK guide; IDs resolved via Wowhead.
-- Reagents are per craft and are replaced by the live trade skill data once
-- you open the profession window.
JohnnysProfessions:RegisterGuide("Cooking", {
	-- Spice Bread <- 1x Mild Spices, 1x Simple Flour
	{ from = 1, to = 40, spell = 37836, item = 30816, count = 60, reagents = { [2678] = 1, [30817] = 1 }, note = "The recipe will be green for the last few points, so you might have to make more." },
	-- Spiced Wolf Meat <- 1x Stringy Wolf Meat
	{ from = 40, to = 65, spell = 2539, item = 2680, count = 30, reagents = { [2672] = 1 }, note = "Or Roasted Boar Meat, Smoked Bear Meat, Brilliant Smallfish, Slitherskin Mackerel." },
	-- Boiled Clams <- 1x Refreshing Spring Water, 1x Clam Meat
	{ from = 65, to = 110, spell = 6499, item = 5525, count = 65, reagents = { [159] = 1, [5503] = 1 }, note = "Or Coyote Steak, Longjaw Mud Snapper, Bat Bites, Strider Stew - whichever meat is cheapest." },
	-- Crab Cake <- 1x Crawler Meat
	{ from = 110, to = 130, spell = 2544, item = 2683, count = 30, reagents = { [2674] = 1 }, note = "Or Dry Pork Ribs, Bristle Whisker Catfish, Cooked Crab Claw." },
	-- Curiously Tasty Omelet <- 1x Raptor Egg
	{ from = 130, to = 175, spell = 3376, item = 3665, count = 50, reagents = { [3685] = 1 }, note = "The recipe is sold by Kendor Kabonka in Stormwind City and by Keena in Arathi Highlands. Alternative recipes" },
	-- Roast Raptor <- 1x Raptor Flesh
	{ from = 175, to = 225, spell = 15855, item = 12210, count = 50, reagents = { [12184] = 1 }, note = "The Recipe: Roast Raptor is sold by Hammon Karwn and by Keena in Arathi Highlands. Alternative recipes" },
	-- Undermine Clam Chowder <- 2x Zesty Clam Meat
	{ from = 225, to = 250, spell = 20626, item = 16766, count = 25, reagents = { [7974] = 2 }, note = "Or: Spotted Yellowtail, Monster Omelet, Tender Wolf Steak, Filet of Redgill. Recipe: Spotted Yellowtail is sold by Gikkix in Tanaris." },
	-- Juicy Bear Burger <- 1x Bear Flank
	{ from = 250, to = 285, spell = 46688, item = 35565, count = 40, reagents = { [35562] = 1 }, note = "Or: Poached Sunscale Salmon, Nightfin Soup. The drop rate of Bear Flank is around 50%, Wowhead shows a lot lower drop rate." },
	-- Smoked Desert Dumplings <- 1x Sandworm Meat
	{ from = 285, to = 300, spell = 24801, item = 20452, count = 15, reagents = { [20424] = 1 }, note = "Or: Baked Salmon, Lobster Stew. You have to complete two quests in Silithus to get this cooking recipe. Desert Recipe" },
	-- Ravager Dog <- 1x Ravager Flesh
	{ from = 300, to = 325, spell = 33284, item = 27655, count = 30, reagents = { [27674] = 1 }, note = "Or: Buzzard Bites. Recipe location: Recipe: Ravager Dog is sold by Cookie One-Eye (Horde) and Sid Limbardi (Alliance) in Hellfire Peninsula." },
	-- Talbuk Steak <- 1x Talbuk Venison
	{ from = 325, to = 350, spell = 33289, item = 27660, count = 40, reagents = { [27682] = 1 }, note = "Or: Roasted Clefthoof, Warp Burger." },
	-- Northern Stew <- 1x Chilled Meat
	{ from = 350, to = 365, spell = 57421, item = 34747, count = 23, reagents = { [43013] = 1 }, note = "You can get the recipe from the Northern Cooking quest. You can pick up the quest from the Cooking trainers in Howling Fjord and Borean Tundra. (links above)." },
	-- Rhino Dogs <- 1x Rhino Meat
	{ from = 365, to = 400, spell = 45553, item = 34752, count = 70, reagents = { [43012] = 1 }, note = "Or Worm Delight, Shoveltusk Steak, Roasted Worg, Pickled Fangtooth - whichever is cheapest." },
	-- Hearty Rhino <- 1x Northern Spices, 1x Rhino Meat
	{ from = 400, to = 450, spell = 57436, item = 42995, count = 60, reagents = { [43007] = 1, [43012] = 1 }, note = "Recipes cost Epicurean's Awards (Dalaran cooking dailies). Any 400+ recipe works - pick the cheapest meat." },
})
