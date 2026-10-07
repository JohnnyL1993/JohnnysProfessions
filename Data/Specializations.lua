-- Profession specializations available in WotLK 3.3.5a and the quests that
-- grant them. Quest/NPC/item IDs, quest levels, objectives and NPC map
-- coordinates are from Wowhead's WotLK database (wowhead.com/wotlk); skill
-- requirements are from the wow-professions.com WotLK guides. Fields that
-- couldn't be confirmed are left out rather than guessed.
--
-- Step fields: quest, title, level (quest level), req ("needs ..."), npc,
-- zone, coords, faction ("Alliance"/"Horde", nil = both), text, items
-- ({ id, count, source }), reward (itemID). `spells` lists the spell IDs
-- the specialization teaches - used to detect it on this character.
local NS = JohnnysProfessions

NS.SPECIALIZATIONS = {
	{
		prof = "Alchemy",
		intro = "At Alchemy 325 and level 68 you can pick one specialization with a quest in Outland. Each gives a chance to make extra potions, elixirs/flasks or transmutes - this still applies to Northrend recipes. You can only have one.",
		specs = {
			{
				name = "Transmutation Master",
				spells = { 28672, 28674 },
				summary = "Chance to create extra items when transmuting.",
				steps = {
					{
						quest = 10899, title = "Master of Transmutation", level = 70, req = "needs level 68, Alchemy 325",
						npc = "Zarevhi", zone = "Netherstorm", coords = "44.0, 36.4",
						text = "Bring Zarevhi at the Stormspire 4 Primal Might.",
						items = { { id = 23571, count = 4, source = "Alchemy: Transmute Primal Might" } },
					},
				},
			},
			{
				name = "Elixir Master",
				spells = { 28677, 28678 },
				summary = "Chance to create extra elixirs and flasks.",
				steps = {
					{
						quest = 10902, title = "Master of Elixirs", level = 70, req = "needs level 68, Alchemy 325",
						npc = "Lorokeem", zone = "Shattrath City", coords = "45.4, 21.8",
						text = "Get 10 Essence of Infinity from Rift Lords and Rift Keepers in the Black Morass (Caverns of Time), and bring them with 5 of each elixir to Lorokeem in Lower City.",
						items = {
							{ id = 31753, count = 10, source = "Black Morass: Rift Lords / Rift Keepers" },
							{ id = 22834, count = 5, source = "Alchemy" },
							{ id = 28104, count = 5, source = "Alchemy" },
							{ id = 22831, count = 5, source = "Alchemy" },
						},
					},
				},
			},
			{
				name = "Potion Master",
				spells = { 28675, 28676 },
				summary = "Chance to create extra potions.",
				steps = {
					{
						quest = 10897, title = "Master of Potions", level = 70, req = "needs level 68, Alchemy 325",
						npc = "Lauranna Thar'well", zone = "Zangarmarsh", coords = "80.2, 64.2",
						text = "Get the Botanist's Field Guide from High Botanist Freywinn in the Botanica (Tempest Keep) and bring it to Cenarion Refuge with 5 of each potion.",
						items = {
							{ id = 31744, count = 1, source = "The Botanica: High Botanist Freywinn" },
							{ id = 22829, count = 5, source = "Alchemy" },
							{ id = 22832, count = 5, source = "Alchemy" },
							{ id = 22836, count = 5, source = "Alchemy" },
						},
					},
				},
			},
		},
	},
	{
		prof = "Blacksmithing",
		intro = "At Blacksmithing 200 and level 40 you can become an Armorsmith or a Weaponsmith. It's optional and doesn't matter much in WotLK - every level 80 recipe can be made without it; it only unlocks some older recipes.",
		specs = {
			{
				name = "Armorsmith",
				spells = { 9788, 9790 },
				summary = "Unlocks special armor plans that a normal blacksmith can't learn.",
				steps = {
					{
						quest = 5283, title = "The Art of the Armorsmith", level = 40, req = "needs level 40, Blacksmithing 200",
						npc = "Grumnus Steelshaper", zone = "Ironforge", coords = "49.4, 43.0", faction = "Alliance",
						text = "Make the following and bring them to Grumnus.",
						items = {
							{ id = 7937, count = 4, source = "Blacksmithing" },
							{ id = 7936, count = 2, source = "Blacksmithing" },
							{ id = 7935, count = 1, source = "Blacksmithing" },
						},
					},
					{
						quest = 5301, title = "The Art of the Armorsmith", level = 40, req = "needs level 40, Blacksmithing 200",
						npc = "Okothos Ironrager", zone = "Orgrimmar", coords = "79.8, 23.4", faction = "Horde",
						text = "Make the following and bring them to Okothos.",
						items = {
							{ id = 7937, count = 4, source = "Blacksmithing" },
							{ id = 7936, count = 2, source = "Blacksmithing" },
							{ id = 7935, count = 1, source = "Blacksmithing" },
						},
					},
				},
			},
			{
				name = "Weaponsmith",
				spells = { 9787, 9789 },
				summary = "Unlocks special weapon plans. Weaponsmiths can later pick Axe, Hammer or Sword mastery (not covered here).",
				steps = {
					{
						quest = 5284, title = "The Way of the Weaponsmith", level = 40, req = "needs level 40, Blacksmithing 200",
						npc = "Ironus Coldsteel", zone = "Ironforge", coords = "49.4, 44.8", faction = "Alliance",
						text = "Make the following and bring them to Ironus.",
						items = {
							{ id = 3853, count = 4, source = "Blacksmithing" },
							{ id = 3855, count = 4, source = "Blacksmithing" },
							{ id = 7941, count = 2, source = "Blacksmithing" },
							{ id = 7945, count = 2, source = "Blacksmithing" },
						},
					},
					{
						quest = 5302, title = "The Way of the Weaponsmith", level = 40, req = "needs level 40, Blacksmithing 200",
						npc = "Borgosh Corebender", zone = "Orgrimmar", coords = "79.4, 23.4", faction = "Horde",
						text = "Make the following and bring them to Borgosh.",
						items = {
							{ id = 3853, count = 4, source = "Blacksmithing" },
							{ id = 3855, count = 4, source = "Blacksmithing" },
							{ id = 7941, count = 2, source = "Blacksmithing" },
							{ id = 7945, count = 2, source = "Blacksmithing" },
						},
					},
				},
			},
		},
	},
	{
		prof = "Engineering",
		intro = "At Engineering 200 you can choose Gnomish or Goblin Engineering. Your Engineering trainer gives you the Manual of Engineering Disciplines - take it to the master of the one you want. Some items need a specific specialization to use; others are made by one but usable by any engineer.",
		specs = {
			{
				name = "Gnomish Engineering",
				spells = { 20219, 20220 },
				summary = "Gnomish gadgets and devices.",
				steps = {
					{
						quest = 3632, title = "Gnome Engineering", req = "needs level 10",
						npc = "Springspindle Fizzlegear", zone = "Ironforge", coords = "68.2, 43.4", faction = "Alliance",
						text = "Take the Manual of Engineering Disciplines to Tinkmaster Overspark in Ironforge. Lilliam Sparkspindle in Stormwind gives the same quest.",
						items = { { id = 10789, count = 1, source = "Given by the trainer" } },
					},
					{
						quest = 3635, title = "Gnome Engineering", req = "needs level 10",
						npc = "Graham Van Talen", zone = "Undercity", coords = "75.2, 72.4", faction = "Horde",
						text = "Take the Manual of Engineering Disciplines to Oglethorpe Obnoticus in Booty Bay. Tinkerwiz in The Barrens gives the same quest.",
						items = { { id = 10789, count = 1, source = "Given by the trainer" } },
					},
					{
						quest = 3641, title = "Show Your Work", req = "needs level 10",
						npc = "Tinkmaster Overspark", zone = "Ironforge", coords = "69.4, 50.4", faction = "Alliance",
						text = "Make these and bring them to the master.",
						items = {
							{ id = 10559, count = 6, source = "Engineering" },
							{ id = 4407, count = 1, source = "Engineering" },
							{ id = 4392, count = 2, source = "Engineering" },
						},
						reward = 10790,
					},
					{
						quest = 3643, title = "Show Your Work", req = "needs level 10",
						npc = "Oglethorpe Obnoticus", zone = "Stranglethorn Vale", coords = "28.2, 76.2", faction = "Horde",
						text = "Make these and bring them to the master.",
						items = {
							{ id = 10559, count = 6, source = "Engineering" },
							{ id = 4407, count = 1, source = "Engineering" },
							{ id = 4392, count = 2, source = "Engineering" },
						},
						reward = 10790,
					},
				},
			},
			{
				name = "Goblin Engineering",
				spells = { 20222, 20221 },
				summary = "Goblin explosives and devices.",
				steps = {
					{
						quest = 4181, title = "Goblin Engineering", req = "needs level 10",
						npc = "Springspindle Fizzlegear", zone = "Ironforge", coords = "68.2, 43.4", faction = "Alliance",
						text = "Take the Manual of Engineering Disciplines to Nixx Sprocketspring in Gadgetzan. Lilliam Sparkspindle in Stormwind gives the same quest.",
						items = { { id = 10789, count = 1, source = "Given by the trainer" } },
					},
					{
						quest = 3526, title = "Goblin Engineering", req = "needs level 10",
						npc = "Graham Van Talen", zone = "Undercity", coords = "75.2, 72.4", faction = "Horde",
						text = "Take the Manual of Engineering Disciplines to Nixx Sprocketspring in Gadgetzan. Tinkerwiz in The Barrens gives the same quest.",
						items = { { id = 10789, count = 1, source = "Given by the trainer" } },
					},
					{
						quest = 3639, title = "Show Your Work", req = "needs level 10",
						npc = "Nixx Sprocketspring", zone = "Tanaris", coords = "52.4, 27.2",
						text = "Make these and bring them to Nixx in Gadgetzan.",
						items = {
							{ id = 4394, count = 20, source = "Engineering" },
							{ id = 10507, count = 20, source = "Engineering" },
							{ id = 4384, count = 5, source = "Engineering" },
						},
						reward = 10791,
					},
				},
			},
		},
	},
	{
		prof = "Leatherworking",
		intro = "At level 40 you can choose Dragonscale, Elemental or Tribal Leatherworking. Each unlocks its own set of older armor patterns; Northrend patterns don't need it. Picking one locks out the other two.",
		specs = {
			{
				name = "Dragonscale Leatherworking",
				spells = { 10656, 10657 },
				summary = "Dragonscale mail armor.",
				steps = {
					{
						quest = 5141, title = "Dragonscale Leatherworking", level = 55, req = "needs level 40",
						npc = "Peter Galen", zone = "Azshara", coords = "37.4, 65.4",
						text = "Bring the following to Peter Galen. Thorkaf Dragoneye in the Badlands (62.4, 57.4) gives the same quest.",
						items = {
							{ id = 8203, count = 2, source = "Leatherworking" },
							{ id = 8204, count = 2, source = "Leatherworking" },
							{ id = 8165, count = 10, source = "Drop" },
						},
					},
				},
			},
			{
				name = "Elemental Leatherworking",
				spells = { 10658, 10659 },
				summary = "Armor infused with elemental power.",
				steps = {
					{
						quest = 5144, title = "Elemental Leatherworking", level = 55, req = "needs level 40",
						npc = "Sarah Tanner", zone = "Searing Gorge", coords = "63.2, 75.4",
						text = "Bring the following to Sarah Tanner. Brumn Winterhoof in Arathi Highlands (28.2, 45.0) gives the same quest.",
						items = {
							{ id = 7077, count = 2, source = "Elementals" },
							{ id = 7079, count = 2, source = "Elementals" },
							{ id = 7075, count = 2, source = "Elementals" },
							{ id = 7081, count = 2, source = "Elementals" },
						},
					},
				},
			},
			{
				name = "Tribal Leatherworking",
				spells = { 10660, 10661 },
				summary = "Tribal leather armor.",
				steps = {
					{
						quest = 5143, title = "Tribal Leatherworking", level = 55, req = "needs level 40",
						npc = "Caryssia Moonhunter", zone = "Feralas", coords = "89.4, 46.4",
						text = "Bring the following to Caryssia Moonhunter. Se'Jib in Stranglethorn Vale (36.4, 34.0) gives the same quest.",
						items = {
							{ id = 8211, count = 1, source = "Leatherworking" },
							{ id = 8214, count = 1, source = "Leatherworking" },
						},
					},
				},
			},
		},
	},
	{
		prof = "Tailoring",
		intro = "At Tailoring 350 and level 60 you can pick a specialization in Shattrath's Lower City. It mainly matters for Burning Crusade cloth and sets - Northrend's Moonshroud, Ebonweave and Spellweave can be made by any Grand Master tailor. You can only have one.",
		specs = {
			{
				name = "Mooncloth Tailoring",
				spells = { 26798, 26799 },
				summary = "Chance of extra Primal Mooncloth; Mooncloth sets.",
				steps = {
					{
						quest = 10831, title = "Becoming a Mooncloth Tailor", level = 70, req = "needs level 60, Tailoring 350",
						npc = "Nasmara Moonsong", zone = "Shattrath City", coords = "66.4, 69.0",
						text = "Use the Square of Imbued Netherweave while standing in Cenarion Refuge's moonwell (Zangarmarsh) to create a Sample of Primal Mooncloth, then bring it back.",
						items = { { id = 31530, count = 1, source = "Made at the Cenarion Refuge moonwell" } },
					},
				},
			},
			{
				name = "Shadoweave Tailoring",
				spells = { 26801, 26800 },
				summary = "Chance of extra Shadowcloth; Shadoweave sets.",
				steps = {
					{
						quest = 10833, title = "Becoming a Shadoweave Tailor", level = 70, req = "needs level 60, Tailoring 350",
						npc = "Andrion Darkspinner", zone = "Shattrath City", coords = "66.4, 68.2",
						text = "Use the Crystal of Deep Shadows near the Altar of Shadows (Shadowmoon Valley) to deepen your attunement, then return to Andrion.",
						items = { { id = 31736, count = 1, source = "Given by Andrion" } },
					},
				},
			},
			{
				name = "Spellfire Tailoring",
				spells = { 26797, 26796 },
				summary = "Chance of extra Spellcloth; Spellfire sets.",
				steps = {
					{
						quest = 10832, title = "Becoming a Spellfire Tailor", level = 70, req = "needs level 60, Tailoring 350",
						npc = "Gidge Spellweaver", zone = "Shattrath City", coords = "66.4, 68.4",
						text = "Bring a sample of Nether-wraith Essence to Gidge Spellweaver.",
						items = { { id = 31741, count = 1, source = "Nether-wraiths, using the Nether-wraith Beacon" } },
					},
				},
			},
		},
	},
}
