-- Alchemy leveling route 1-450 (WotLK 3.3.5a).
-- Generated from the wow-professions.com WotLK guide; IDs resolved via Wowhead.
-- Reagents are per craft and are replaced by the live trade skill data once
-- you open the profession window.
JohnnysProfessions:RegisterGuide("Alchemy", {
	-- Minor Healing Potion <- 1x Silverleaf, 1x Peacebloom, 1x Empty Vial
	{ from = 1, to = 60, spell = 2330, item = 118, count = 65, reagents = { [765] = 1, [2447] = 1, [3371] = 1 }, note = "You'll need these later, so keep all of them." },
	-- Lesser Healing Potion <- 1x Minor Healing Potion, 1x Briarthorn
	{ from = 65, to = 110, spell = 2337, item = 858, count = 65, reagents = { [118] = 1, [2450] = 1 } },
	-- Healing Potion <- 1x Briarthorn, 1x Bruiseweed, 1x Leaded Vial
	{ from = 110, to = 140, spell = 3447, item = 929, count = 35, reagents = { [2450] = 1, [2453] = 1, [3372] = 1 } },
	-- Lesser Mana Potion <- 1x Mageroyal, 1x Empty Vial, 1x Stranglekelp
	{ from = 140, to = 155, spell = 3173, item = 3385, count = 20, reagents = { [785] = 1, [3371] = 1, [3820] = 1 }, note = "This recipe will be yellow for the last 10 points, so you might have to make a few extra." },
	-- Greater Healing Potion <- 1x Kingsblood, 1x Liferoot, 1x Leaded Vial
	{ from = 155, to = 185, spell = 7181, item = 1710, count = 35, reagents = { [3356] = 1, [3357] = 1, [3372] = 1 } },
	-- Elixir of Agility <- 1x Leaded Vial, 1x Stranglekelp, 1x Goldthorn
	{ from = 185, to = 210, spell = 11449, item = 8949, count = 30, reagents = { [3372] = 1, [3820] = 1, [3821] = 1 }, note = "Recipe: Nature Protection Potion is sold by these vendors." },
	-- Elixir of Greater Defense <- 1x Wild Steelbloom, 1x Leaded Vial, 1x Goldthorn
	{ from = 210, to = 215, spell = 11450, item = 8951, count = 5, reagents = { [3355] = 1, [3372] = 1, [3821] = 1 } },
	-- Superior Healing Potion <- 1x Khadgar's Whisker, 1x Sungrass, 1x Crystal Vial
	{ from = 215, to = 230, spell = 11457, item = 3928, count = 15, reagents = { [3358] = 1, [8838] = 1, [8925] = 1 } },
	-- Philosopher's Stone <- 4x Iron Bar, 4x Firebloom, 4x Purple Lotus, 1x Black Vitriol
	{ from = 230, to = 231, spell = 11459, item = 9149, count = 1, reagents = { [3575] = 4, [4625] = 4, [8831] = 4, [9262] = 1 }, note = "You will need this for Alchemy transmutes, so keep it. (don't have to equip it) The recipe is sold by Alchemist Pestlezugg in Tanaris." },
	-- Elixir of Detect Undead <- 1x Arthas' Tears, 1x Crystal Vial
	{ from = 231, to = 265, spell = 11460, item = 9154, count = 45, reagents = { [8836] = 1, [8925] = 1 } },
	-- Superior Mana Potion <- 2x Sungrass, 2x Blindweed, 1x Crystal Vial
	{ from = 265, to = 285, spell = 17553, item = 13443, count = 30, reagents = { [8838] = 2, [8839] = 2, [8925] = 1 } },
	-- Major Healing Potion <- 1x Crystal Vial, 2x Golden Sansam, 1x Mountain Silversage
	{ from = 285, to = 300, spell = 17556, item = 13446, count = 20, reagents = { [8925] = 1, [13464] = 2, [13465] = 1 } },
	-- Volatile Healing Potion <- 1x Golden Sansam, 1x Imbued Vial, 1x Felweed
	{ from = 300, to = 315, spell = 33732, item = 28100, count = 15, reagents = { [13464] = 1, [18256] = 1, [22785] = 1 }, note = "Or: Adept's Elixir, Onslaught Elixir." },
	-- Elixir of Healing Power <- 1x Golden Sansam, 1x Imbued Vial, 1x Dreaming Glory
	{ from = 315, to = 330, spell = 28545, item = 22825, count = 25, reagents = { [13464] = 1, [18256] = 1, [22786] = 1 } },
	-- Elixir of Draenic Wisdom <- 1x Imbued Vial, 1x Felweed, 1x Terocone
	{ from = 330, to = 335, spell = 39638, item = 32067, count = 5, reagents = { [18256] = 1, [22785] = 1, [22789] = 1 } },
	-- Super Healing Potion <- 1x Imbued Vial, 1x Felweed, 2x Netherbloom
	{ from = 335, to = 340, spell = 28551, item = 22829, count = 5, reagents = { [18256] = 1, [22785] = 1, [22791] = 2 }, note = "Make the previous recipe 5 more times if you don't have Netherbloom." },
	-- Super Mana Potion <- 1x Imbued Vial, 1x Felweed, 2x Dreaming Glory
	{ from = 340, to = 350, spell = 28555, item = 22832, count = 10, reagents = { [18256] = 1, [22785] = 1, [22786] = 2 }, note = "Recipe: Super Mana Potion is sold by Daga Ramba and Haalrun." },
	-- Resurgent Healing Potion <- 1x Imbued Vial, 2x Goldclover
	{ from = 350, to = 360, spell = 53838, item = 39671, count = 10, reagents = { [18256] = 1, [36901] = 2 } },
	-- Icy Mana Potion <- 1x Imbued Vial, 2x Talandra's Rose
	{ from = 360, to = 365, spell = 53839, item = 40067, count = 5, reagents = { [18256] = 1, [36907] = 2 } },
	-- Spellpower Elixir <- 1x Imbued Vial, 1x Goldclover, 1x Tiger Lily
	{ from = 365, to = 375, spell = 53842, item = 40070, count = 10, reagents = { [18256] = 1, [36901] = 1, [36904] = 1 } },
	-- Pygmy Oil <- 1x Pygmy Suckerfish
	{ from = 375, to = 380, spell = 53812, item = 40195, count = 5, reagents = { [40199] = 1 } },
	-- Potion of Nightmares <- 1x Imbued Vial, 1x Goldclover, 2x Talandra's Rose
	{ from = 380, to = 385, spell = 53900, item = 40081, count = 5, reagents = { [18256] = 1, [36901] = 1, [36907] = 2 } },
	-- Elixir of Mighty Strength <- 1x Imbued Vial, 2x Tiger Lily
	{ from = 385, to = 395, spell = 54218, item = 40073, count = 12, reagents = { [18256] = 1, [36904] = 2 } },
	-- Elixir of Mighty Agility <- 1x Imbued Vial, 2x Goldclover, 2x Adder's Tongue
	{ from = 395, to = 400, spell = 53840, item = 39666, count = 5, reagents = { [18256] = 1, [36901] = 2, [36903] = 2 } },
	-- Northrend Alchemy Research <- 10x Goldclover, 10x Adder's Tongue, 4x Talandra's Rose, 4x Enchanted Vial
	{ from = 400, to = 401, spell = 60893, count = 1, reagents = { [36901] = 10, [36903] = 10, [36907] = 4, [40411] = 4 } },
	-- Elixir of Mighty Agility <- 1x Imbued Vial, 2x Goldclover, 2x Adder's Tongue
	{ from = 401, to = 405, spell = 53840, item = 39666, count = 7, reagents = { [18256] = 1, [36901] = 2, [36903] = 2 }, note = "Or: Elixir of Mighty Thoughts." },
	-- Indestructible Potion <- 1x Imbued Vial, 2x Icethorn
	{ from = 405, to = 415, spell = 53905, item = 40093, count = 10, reagents = { [18256] = 1, [36906] = 2 } },
	-- Runic Mana Potion <- 1x Imbued Vial, 1x Goldclover, 2x Lichbloom
	{ from = 415, to = 425, spell = 53837, item = 33448, count = 20, reagents = { [18256] = 1, [36901] = 1, [36905] = 2 } },
	-- Transmute: Titanium <- 8x Saronite Bar
	{ from = 425, to = 430, spell = 60350, item = 41163, count = 7, reagents = { [36913] = 8 }, note = "You will need a Philosopher's Stone for transmutes. The recipe is sold by Alchemist Pestlezugg in Tanaris." },
	-- Transmute: Earthsiege Diamond <- 1x Eternal Fire, 1x Huge Citrine, 1x Dark Jade
	{ from = 430, to = 435, spell = 57427, item = 41334, count = 5, reagents = { [36860] = 1, [36929] = 1, [36932] = 1 }, note = "Or: Transmute: Skyflare Diamond." },
	-- Flask of Endless Rage <- 3x Goldclover, 7x Lichbloom, 1x Frost Lotus, 1x Enchanted Vial
	{ from = 435, to = 450, spell = 53903, item = 46377, count = 15, reagents = { [36901] = 3, [36905] = 7, [36908] = 1, [40411] = 1 }, note = "Or: Flask of Pure Mojo, Flask of Stoneblood, Flask of the Frost Wyrm. You can also keep making Transmute: Skyflare Diamond up to 441." },
})
