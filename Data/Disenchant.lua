-- Disenchanting outcomes for WotLK 3.3.5a, by item quality and item level.
-- Bracket boundaries, quantities and chances are the commonly published
-- WotLK tables (wowwiki / Wowhead disenchanting data); item IDs checked
-- against Wowhead. Brackets that couldn't be confirmed (e.g. TBC greens below
-- item level 79) are left out, so the advisor simply says "unknown" there.
--
-- Uncommon (green) brackets list dust / essence / shard as
-- { itemID, minQty, maxQty }; armor rolls dust most often and weapons roll
-- essence most often (see GREEN_CHANCES). Rare and epic brackets list their
-- outcomes directly as { itemID, minQty, maxQty, chance }.
-- `skill` is the Enchanting skill needed to disenchant items in the bracket.
local NS = JohnnysProfessions

-- Mats
local STRANGE, SOUL, VISION, DREAM, ILLUSION, ARCANE, INFINITE = 10940, 11083, 11137, 11176, 16204, 22445, 34054
local LMAGIC, GMAGIC, LASTRAL, GASTRAL, LMYSTIC, GMYSTIC = 10938, 10939, 10998, 11082, 11134, 11135
local LNETHER, GNETHER, LETERNAL, GETERNAL = 11174, 11175, 16202, 16203
local LPLANAR, GPLANAR, LCOSMIC, GCOSMIC = 22447, 22446, 34056, 34055
local SGLIMMER, LGLIMMER, SGLOW, LGLOW, SRADIANT, LRADIANT = 10978, 11084, 11138, 11139, 11177, 11178
local SBRILLIANT, LBRILLIANT, SPRISM, LPRISM, SDREAM, DREAMSHARD = 14343, 14344, 22448, 22449, 34053, 34052
local NEXUS, VOID, ABYSS = 20725, 22450, 34057

NS.DISENCHANT = {
	-- chances for green items: { dust, essence, shard }
	GREEN_CHANCES = {
		classic = { armor = { 0.75, 0.20, 0.05 }, weapon = { 0.20, 0.75, 0.05 } },
		modern = { armor = { 0.75, 0.22, 0.03 }, weapon = { 0.22, 0.75, 0.03 } },
	},
	uncommon = {
		{ min = 5, max = 15, skill = 1, era = "classic", dust = { STRANGE, 1, 2 }, essence = { LMAGIC, 1, 2 } },
		{ min = 16, max = 20, skill = 1, era = "classic", dust = { STRANGE, 2, 3 }, essence = { GMAGIC, 1, 2 }, shard = { SGLIMMER, 1, 1 } },
		{ min = 21, max = 25, skill = 25, era = "classic", dust = { STRANGE, 4, 6 }, essence = { LASTRAL, 1, 2 }, shard = { SGLIMMER, 1, 1 } },
		{ min = 26, max = 30, skill = 50, era = "classic", dust = { SOUL, 1, 2 }, essence = { GASTRAL, 1, 2 }, shard = { LGLIMMER, 1, 1 } },
		{ min = 31, max = 35, skill = 75, era = "classic", dust = { SOUL, 2, 5 }, essence = { LMYSTIC, 1, 2 }, shard = { SGLOW, 1, 1 } },
		{ min = 36, max = 40, skill = 100, era = "classic", dust = { VISION, 1, 2 }, essence = { GMYSTIC, 1, 2 }, shard = { LGLOW, 1, 1 } },
		{ min = 41, max = 45, skill = 125, era = "classic", dust = { VISION, 2, 5 }, essence = { LNETHER, 1, 2 }, shard = { SRADIANT, 1, 1 } },
		{ min = 46, max = 50, skill = 150, era = "classic", dust = { DREAM, 1, 2 }, essence = { GNETHER, 1, 2 }, shard = { LRADIANT, 1, 1 } },
		{ min = 51, max = 55, skill = 175, era = "classic", dust = { DREAM, 2, 5 }, essence = { LETERNAL, 1, 2 }, shard = { SBRILLIANT, 1, 1 } },
		{ min = 56, max = 60, skill = 200, era = "classic", dust = { ILLUSION, 1, 2 }, essence = { GETERNAL, 1, 2 }, shard = { LBRILLIANT, 1, 1 } },
		{ min = 61, max = 65, skill = 225, era = "classic", dust = { ILLUSION, 2, 5 }, essence = { GETERNAL, 2, 3 }, shard = { LBRILLIANT, 1, 1 } },
		{ min = 79, max = 99, skill = 225, era = "modern", dust = { ARCANE, 1, 3 }, essence = { LPLANAR, 1, 3 }, shard = { SPRISM, 1, 1 } },
		{ min = 100, max = 120, skill = 275, era = "modern", dust = { ARCANE, 2, 5 }, essence = { GPLANAR, 1, 2 }, shard = { LPRISM, 1, 1 } },
		{ min = 130, max = 154, skill = 325, era = "modern", dust = { INFINITE, 1, 3 }, essence = { LCOSMIC, 1, 2 }, shard = { SDREAM, 1, 1 } },
		{ min = 155, max = 182, skill = 350, era = "modern", dust = { INFINITE, 4, 7 }, essence = { GCOSMIC, 1, 2 }, shard = { DREAMSHARD, 1, 1 } },
	},
	rare = {
		{ min = 11, max = 25, skill = 25, { SGLIMMER, 1, 1, 1 } },
		{ min = 26, max = 30, skill = 50, { LGLIMMER, 1, 1, 1 } },
		{ min = 31, max = 35, skill = 75, { SGLOW, 1, 1, 1 } },
		{ min = 36, max = 40, skill = 100, { LGLOW, 1, 1, 1 } },
		{ min = 41, max = 45, skill = 125, { SRADIANT, 1, 1, 1 } },
		{ min = 46, max = 50, skill = 150, { LRADIANT, 1, 1, 1 } },
		{ min = 51, max = 55, skill = 175, { SBRILLIANT, 1, 1, 1 } },
		{ min = 56, max = 65, skill = 200, { LBRILLIANT, 1, 1, 0.995 }, { NEXUS, 1, 1, 0.005 } },
		{ min = 66, max = 99, skill = 225, { SPRISM, 1, 1, 0.995 }, { NEXUS, 1, 1, 0.005 } },
		{ min = 100, max = 120, skill = 275, { LPRISM, 1, 1, 0.995 }, { VOID, 1, 1, 0.005 } },
		{ min = 121, max = 164, skill = 325, { SDREAM, 1, 1, 0.995 }, { ABYSS, 1, 1, 0.005 } },
		{ min = 165, max = 200, skill = 350, { DREAMSHARD, 1, 1, 0.995 }, { ABYSS, 1, 1, 0.005 } },
	},
	epic = {
		{ min = 40, max = 45, skill = 225, { SRADIANT, 2, 4, 1 } },
		{ min = 46, max = 50, skill = 225, { LRADIANT, 2, 4, 1 } },
		{ min = 51, max = 55, skill = 225, { SBRILLIANT, 2, 4, 1 } },
		{ min = 56, max = 60, skill = 225, { NEXUS, 1, 1, 1 } },
		{ min = 61, max = 94, skill = 300, { NEXUS, 1, 2, 1 } },
		{ min = 95, max = 164, skill = 300, { VOID, 1, 2, 1 } },
		{ min = 165, max = 300, skill = 375, { ABYSS, 1, 1, 1 } },
	},
}
