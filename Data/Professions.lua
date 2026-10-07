-- Static profession facts for WotLK 3.3.5a. Keys are the enUS skill line
-- names GetSkillLineInfo / GetTradeSkillLine return (Warmane runs an enUS
-- client), so they double as the lookup from the game's own strings.
local NS = JohnnysProfessions

NS.PROFESSIONS = {
	{ key = "Alchemy", kind = "craft", icon = "Interface\\Icons\\Trade_Alchemy" },
	{ key = "Blacksmithing", kind = "craft", icon = "Interface\\Icons\\Trade_BlackSmithing" },
	{ key = "Enchanting", kind = "craft", icon = "Interface\\Icons\\Trade_Engraving" },
	{ key = "Engineering", kind = "craft", icon = "Interface\\Icons\\Trade_Engineering" },
	{ key = "Inscription", kind = "craft", icon = "Interface\\Icons\\INV_Inscription_Tradeskill01" },
	{ key = "Jewelcrafting", kind = "craft", icon = "Interface\\Icons\\INV_Misc_Gem_01" },
	{ key = "Leatherworking", kind = "craft", icon = "Interface\\Icons\\INV_Misc_ArmorKit_17" },
	{ key = "Tailoring", kind = "craft", icon = "Interface\\Icons\\Trade_Tailoring" },
	{ key = "Herbalism", kind = "gather", icon = "Interface\\Icons\\Trade_Herbalism" },
	{ key = "Mining", kind = "gather", icon = "Interface\\Icons\\Trade_Mining" },
	{ key = "Skinning", kind = "gather", icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" },
	{ key = "Cooking", kind = "craft", secondary = true, icon = "Interface\\Icons\\INV_Misc_Food_15" },
	{ key = "First Aid", kind = "craft", secondary = true, icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice" },
	{ key = "Fishing", kind = "gather", secondary = true, icon = "Interface\\Icons\\Trade_Fishing" },
}

NS.PROF_BY_KEY = {}
for _, p in ipairs(NS.PROFESSIONS) do
	NS.PROF_BY_KEY[p.key] = p
end

-- Trainer ranks: `cap` is the max skill the rank allows, `learnAt` the skill
-- you need before a trainer will teach it, `level` the character level.
NS.RANKS = {
	{ name = "Apprentice", cap = 75, learnAt = 0, level = 5 },
	{ name = "Journeyman", cap = 150, learnAt = 50, level = 10 },
	{ name = "Expert", cap = 225, learnAt = 125, level = 20 },
	{ name = "Artisan", cap = 300, learnAt = 200, level = 35 },
	{ name = "Master", cap = 375, learnAt = 275, level = 50 },
	{ name = "Grand Master", cap = 450, learnAt = 350, level = 65 },
}

-- Primary gathering professions (Herbalism, Mining, Skinning) train at lower
-- character levels than the crafting ones.
NS.GATHER_RANK_LEVELS = { 5, 10, 10, 25, 40, 55 }

local function RankLevel(index, prof)
	local p = prof and NS.PROF_BY_KEY[prof]
	if p and p.kind == "gather" and not p.secondary then
		return NS.GATHER_RANK_LEVELS[index]
	end
	return NS.RANKS[index].level
end

-- The rank whose cap is `maxRank` (what GetSkillLineInfo reports as max).
function NS:RankForCap(maxRank)
	for i, r in ipairs(self.RANKS) do
		if r.cap == maxRank then
			return i, r
		end
	end
end

-- Returns a short "go train" hint for a skill, or nil if nothing to do yet.
function NS:TrainerHint(rank, maxRank, level, prof)
	local i = self:RankForCap(maxRank)
	local nextRank = i and self.RANKS[i + 1]
	if not nextRank then
		return nil
	end
	local needLevel = RankLevel(i + 1, prof)
	if rank < nextRank.learnAt then
		if maxRank - rank <= 25 then
			return string.format("Train %s at %d skill (level %d).", nextRank.name, nextRank.learnAt, needLevel)
		end
		return nil
	end
	if level and level < needLevel then
		return string.format("|cffff8040%s needs level %d - skill is capped at %d until then.|r", nextRank.name, needLevel, maxRank)
	end
	return string.format("|cff40ff40Visit a trainer: you can learn %s now.|r", nextRank.name)
end
