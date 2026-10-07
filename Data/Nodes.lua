-- Gathering data: every herb and mining node in 3.3.5a with the skill it
-- needs and the item it mainly yields (for its pin icon), the yard size of
-- each zone map (for minimap pins), minimap view sizes, fishing lures and
-- gathering tools. Node skills, lures and tools checked on Wowhead (WotLK);
-- zone/minimap sizes are the standard client map measurements.
local NS = JohnnysProfessions

-- [node name] = { prof = "Mining" | "Herbalism", skill = required skill, item = main yield }
NS.NODES = {
	-- Mining
	["Copper Vein"] = { prof = "Mining", skill = 1, item = 2770 },
	["Tin Vein"] = { prof = "Mining", skill = 65, item = 2771 },
	["Silver Vein"] = { prof = "Mining", skill = 75, item = 2775 },
	["Iron Deposit"] = { prof = "Mining", skill = 125, item = 2772 },
	["Gold Vein"] = { prof = "Mining", skill = 155, item = 2776 },
	["Mithril Deposit"] = { prof = "Mining", skill = 175, item = 3858 },
	["Truesilver Deposit"] = { prof = "Mining", skill = 230, item = 7911 },
	["Dark Iron Deposit"] = { prof = "Mining", skill = 230, item = 11370 },
	["Small Thorium Vein"] = { prof = "Mining", skill = 245, item = 10620 },
	["Rich Thorium Vein"] = { prof = "Mining", skill = 275, item = 10620 },
	["Incendicite Mineral Vein"] = { prof = "Mining", skill = 65, item = 3340 },
	["Lesser Bloodstone Deposit"] = { prof = "Mining", skill = 75, item = 4278 },
	["Indurium Mineral Vein"] = { prof = "Mining", skill = 150, item = 5833 },
	["Ooze Covered Silver Vein"] = { prof = "Mining", skill = 75, item = 2775 },
	["Ooze Covered Gold Vein"] = { prof = "Mining", skill = 155, item = 2776 },
	["Ooze Covered Mithril Deposit"] = { prof = "Mining", skill = 175, item = 3858 },
	["Ooze Covered Truesilver Deposit"] = { prof = "Mining", skill = 230, item = 7911 },
	["Ooze Covered Thorium Vein"] = { prof = "Mining", skill = 245, item = 10620 },
	["Ooze Covered Rich Thorium Vein"] = { prof = "Mining", skill = 275, item = 10620 },
	["Small Obsidian Chunk"] = { prof = "Mining", skill = 305, item = 22202 },
	["Large Obsidian Chunk"] = { prof = "Mining", skill = 305, item = 22203 },
	["Fel Iron Deposit"] = { prof = "Mining", skill = 300, item = 23424 },
	["Adamantite Deposit"] = { prof = "Mining", skill = 325, item = 23425 },
	["Rich Adamantite Deposit"] = { prof = "Mining", skill = 350, item = 23425 },
	["Khorium Vein"] = { prof = "Mining", skill = 375, item = 23426 },
	["Nethercite Deposit"] = { prof = "Mining", skill = 300, item = 32464 },
	["Cobalt Deposit"] = { prof = "Mining", skill = 350, item = 36909 },
	["Rich Cobalt Deposit"] = { prof = "Mining", skill = 375, item = 36909 },
	["Saronite Deposit"] = { prof = "Mining", skill = 400, item = 36912 },
	["Rich Saronite Deposit"] = { prof = "Mining", skill = 425, item = 36912 },
	["Pure Saronite Deposit"] = { prof = "Mining", skill = 450, item = 36912 },
	["Titanium Vein"] = { prof = "Mining", skill = 450, item = 36910 },
	-- Herbalism
	["Peacebloom"] = { prof = "Herbalism", skill = 1, item = 2447 },
	["Silverleaf"] = { prof = "Herbalism", skill = 1, item = 765 },
	["Earthroot"] = { prof = "Herbalism", skill = 15, item = 2449 },
	["Mageroyal"] = { prof = "Herbalism", skill = 50, item = 785 },
	["Briarthorn"] = { prof = "Herbalism", skill = 70, item = 2450 },
	["Stranglekelp"] = { prof = "Herbalism", skill = 85, item = 3820 },
	["Bruiseweed"] = { prof = "Herbalism", skill = 100, item = 2453 },
	["Wild Steelbloom"] = { prof = "Herbalism", skill = 115, item = 3355 },
	["Grave Moss"] = { prof = "Herbalism", skill = 120, item = 3369 },
	["Kingsblood"] = { prof = "Herbalism", skill = 125, item = 3356 },
	["Liferoot"] = { prof = "Herbalism", skill = 150, item = 3357 },
	["Fadeleaf"] = { prof = "Herbalism", skill = 160, item = 3818 },
	["Goldthorn"] = { prof = "Herbalism", skill = 170, item = 3821 },
	["Khadgar's Whisker"] = { prof = "Herbalism", skill = 185, item = 3358 },
	["Wintersbite"] = { prof = "Herbalism", skill = 195, item = 3819 },
	["Firebloom"] = { prof = "Herbalism", skill = 205, item = 4625 },
	["Purple Lotus"] = { prof = "Herbalism", skill = 210, item = 8831 },
	["Arthas' Tears"] = { prof = "Herbalism", skill = 220, item = 8836 },
	["Sungrass"] = { prof = "Herbalism", skill = 230, item = 8838 },
	["Blindweed"] = { prof = "Herbalism", skill = 235, item = 8839 },
	["Ghost Mushroom"] = { prof = "Herbalism", skill = 245, item = 8845 },
	["Gromsblood"] = { prof = "Herbalism", skill = 250, item = 8846 },
	["Golden Sansam"] = { prof = "Herbalism", skill = 260, item = 13464 },
	["Dreamfoil"] = { prof = "Herbalism", skill = 270, item = 13463 },
	["Mountain Silversage"] = { prof = "Herbalism", skill = 280, item = 13465 },
	["Plaguebloom"] = { prof = "Herbalism", skill = 285, item = 13466 },
	["Icecap"] = { prof = "Herbalism", skill = 290, item = 13467 },
	["Black Lotus"] = { prof = "Herbalism", skill = 300, item = 13468 },
	["Felweed"] = { prof = "Herbalism", skill = 300, item = 22785 },
	["Dreaming Glory"] = { prof = "Herbalism", skill = 315, item = 22786 },
	["Ragveil"] = { prof = "Herbalism", skill = 325, item = 22787 },
	["Flame Cap"] = { prof = "Herbalism", skill = 335, item = 22788 },
	["Terocone"] = { prof = "Herbalism", skill = 325, item = 22789 },
	["Ancient Lichen"] = { prof = "Herbalism", skill = 340, item = 22790 },
	["Netherbloom"] = { prof = "Herbalism", skill = 350, item = 22791 },
	["Nightmare Vine"] = { prof = "Herbalism", skill = 365, item = 22792 },
	["Mana Thistle"] = { prof = "Herbalism", skill = 375, item = 22793 },
	["Netherdust Bush"] = { prof = "Herbalism", skill = 350, item = 32468 },
	["Goldclover"] = { prof = "Herbalism", skill = 350, item = 36901 },
	["Tiger Lily"] = { prof = "Herbalism", skill = 375, item = 36904 },
	["Talandra's Rose"] = { prof = "Herbalism", skill = 385, item = 36907 },
	["Adder's Tongue"] = { prof = "Herbalism", skill = 400, item = 36903 },
	["Frozen Herb"] = { prof = "Herbalism", skill = 400 },
	["Lichbloom"] = { prof = "Herbalism", skill = 425, item = 36905 },
	["Icethorn"] = { prof = "Herbalism", skill = 435, item = 36906 },
	["Frost Lotus"] = { prof = "Herbalism", skill = 450, item = 36908 },
	["Firethorn"] = { prof = "Herbalism", skill = 360 },
	["Bloodthistle"] = { prof = "Herbalism", skill = 1, item = 22710 },
}

-- Zone map sizes in yards, keyed by map file name (first return of
-- GetMapInfo()): { width, height }. A map coordinate of 1.0 spans this many
-- yards, which is what converts node positions into minimap offsets.
NS.ZONE_SIZES = {
	Ashenvale = { 5766.7, 3843.7 },
	Aszhara = { 5070.9, 3381.2 },
	AzuremystIsle = { 4070.9, 2714.6 },
	Barrens = { 10133.4, 6756.2 },
	BloodmystIsle = { 3262.5, 2175.0 },
	Darkshore = { 6550.1, 4366.6 },
	Darnassis = { 1058.3, 705.7 },
	Desolace = { 4495.9, 2997.9 },
	Durotar = { 5287.6, 3525.0 },
	Dustwallow = { 5250.1, 3500.0 },
	Felwood = { 5750.1, 3833.3 },
	Feralas = { 6950.1, 4633.3 },
	Moonglade = { 2308.4, 1539.6 },
	Mulgore = { 5137.6, 3425.0 },
	Ogrimmar = { 1402.6, 935.4 },
	Silithus = { 3483.4, 2322.9 },
	StonetalonMountains = { 4883.4, 3256.2 },
	Tanaris = { 6900.1, 4600.0 },
	Teldrassil = { 5091.7, 3393.7 },
	TheExodar = { 1056.8, 704.7 },
	ThousandNeedles = { 4400.0, 2933.3 },
	ThunderBluff = { 1043.8, 695.8 },
	UngoroCrater = { 3700.0, 2466.6 },
	Winterspring = { 7100.1, 4733.3 },
	Alterac = { 2800.0, 1866.7 },
	Arathi = { 3600.0, 2400.0 },
	Badlands = { 2487.5, 1658.3 },
	BlastedLands = { 3350.0, 2233.3 },
	BurningSteppes = { 2929.2, 1952.1 },
	DeadwindPass = { 2500.0, 1666.7 },
	DunMorogh = { 4925.0, 3283.3 },
	Duskwood = { 2700.0, 1800.0 },
	EasternPlaguelands = { 4031.2, 2687.5 },
	Elwynn = { 3470.8, 2314.6 },
	EversongWoods = { 4925.0, 3283.3 },
	Ghostlands = { 3300.0, 2200.0 },
	Hilsbrad = { 3200.0, 2133.3 },
	Hinterlands = { 3850.0, 2566.7 },
	Ironforge = { 790.6, 527.6 },
	LochModan = { 2758.3, 1839.6 },
	Redridge = { 2170.8, 1447.9 },
	SearingGorge = { 2231.2, 1487.5 },
	SilvermoonCity = { 1211.5, 806.8 },
	Silverpine = { 4200.0, 2800.0 },
	Stormwind = { 1737.5, 1158.3 },
	Stranglethorn = { 6381.2, 4254.2 },
	Sunwell = { 3327.1, 2218.8 },
	SwampOfSorrows = { 2293.8, 1529.2 },
	Tirisfal = { 4518.7, 3012.5 },
	Undercity = { 959.4, 640.1 },
	WesternPlaguelands = { 4300.0, 2866.7 },
	Westfall = { 3500.0, 2333.3 },
	Wetlands = { 4135.4, 2756.3 },
	BladesEdgeMountains = { 5425.0, 3616.6 },
	Hellfire = { 5164.6, 3443.6 },
	Nagrand = { 5525.0, 3683.2 },
	Netherstorm = { 5575.0, 3716.6 },
	ShadowmoonValley = { 5500.0, 3666.6 },
	ShattrathCity = { 1306.2, 870.8 },
	TerokkarForest = { 5400.0, 3599.9 },
	Zangarmarsh = { 5027.1, 3352.0 },
	BoreanTundra = { 5764.6, 3843.8 },
	CrystalsongForest = { 2722.9, 1814.6 },
	Dalaran = { 830.0, 553.3 },
	Dragonblight = { 5608.3, 3739.6 },
	GrizzlyHills = { 5250.0, 3500.0 },
	HrothgarsLanding = { 3677.1, 2452.1 },
	HowlingFjord = { 6045.8, 4031.3 },
	IcecrownGlacier = { 6270.8, 4181.3 },
	LakeWintergrasp = { 2975.0, 1983.3 },
	SholazarBasin = { 4356.2, 2904.2 },
	TheStormPeaks = { 7112.5, 4741.7 },
	ZulDrak = { 4993.7, 3329.2 },
}

-- Minimap view diameter in yards per zoom level (Minimap:GetZoom() 0-5).
NS.MINIMAP_SIZES = {
	indoor = { [0] = 300, 240, 180, 120, 80, 50 },
	outdoor = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 },
}

-- Fishing lures: required Fishing skill and the bonus they give.
NS.FISHING_LURES = {
	{ id = 6529, req = 0, bonus = 25 }, -- Shiny Bauble
	{ id = 6530, req = 50, bonus = 50 }, -- Nightcrawlers
	{ id = 6811, req = 50, bonus = 50 }, -- Aquadynamic Fish Lens
	{ id = 6532, req = 100, bonus = 75 }, -- Bright Baubles
	{ id = 7307, req = 100, bonus = 75 }, -- Flesh Eating Worm
	{ id = 6533, req = 100, bonus = 100 }, -- Aquadynamic Fish Attractor
	{ id = 34861, req = 100, bonus = 100 }, -- Sharpened Fish Hook
	{ id = 46006, req = 100, bonus = 100 }, -- Glow Worm (1 hour)
}

-- Items that count as a Mining Pick / Skinning Knife when in your bags or
-- equipped ("Also serves as a mining pick", Gnomish Army Knife, Bladed Pickaxe).
NS.MINING_TOOLS = { 2901, 778, 756, 1819, 20723, 40772, 40893 }
NS.SKINNING_TOOLS = { 7005, 40772, 40893 }
