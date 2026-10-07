-- Buy prices (copper) for reagents sold by trade goods / profession supply
-- vendors. Used as the cost of these items when there's no cheaper AH price.
-- Prices are the base vendor price (no reputation discount); a few are
-- approximate. Prices.lua records what merchants really charge you (into
-- db.global.vendorPrices) and prefers those over this table.
local NS = JohnnysProfessions

NS.VENDOR_PRICES = {
	-- Threads
	[2320] = 10,      -- Coarse Thread
	[2321] = 100,     -- Fine Thread
	[4291] = 500,     -- Silken Thread
	[8343] = 2000,    -- Heavy Silken Thread
	[14341] = 5000,   -- Rune Thread
	[38426] = 30000,  -- Eternium Thread
	-- Dyes / misc tailoring + leatherworking
	[2324] = 25,      -- Bleach
	[2604] = 50,      -- Red Dye
	[6260] = 50,      -- Blue Dye
	[2605] = 100,     -- Green Dye
	[4340] = 350,     -- Gray Dye
	[4289] = 50,      -- Salt
	-- Vials
	[3371] = 4,       -- Empty Vial
	[3372] = 40,      -- Leaded Vial
	[8925] = 500,     -- Crystal Vial
	[18256] = 2000,   -- Imbued Vial
	-- Smithing / engineering
	[2880] = 100,     -- Weak Flux
	[3466] = 2000,    -- Strong Flux
	[18567] = 30000,  -- Elemental Flux
	[3857] = 500,     -- Coal
	-- Enchanting
	[6217] = 124,     -- Copper Rod
	[4470] = 38,      -- Simple Wood
	-- Inscription (buy prices checked on Wowhead)
	[39354] = 15,     -- Light Parchment
	[10648] = 125,    -- Common Parchment
	[39501] = 1250,   -- Heavy Parchment
	[39502] = 5000,   -- Resilient Parchment
	-- Cooking
	[30817] = 25,     -- Simple Flour
	[2678] = 10,      -- Mild Spices
	[2692] = 40,      -- Hot Spices
	[159] = 5,        -- Refreshing Spring Water
	[1179] = 125,     -- Ice Cold Milk
	[3713] = 160,     -- Soothing Spices
	[43007] = 2500,   -- Northern Spices
}
