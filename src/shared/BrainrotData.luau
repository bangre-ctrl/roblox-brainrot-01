-- Brainrot cast for Frozen Brainrot Mart: the polite customers.
-- Original meme-absurd characters, named after the viral Italian
-- brainrot, with twisted spellings kept as the community knows them.
-- No photos, decals or copyrighted images are used anywhere: every
-- model is built from Parts in code, from the data below.
-- Each entry: name, rarity, body/head colour, size and an accessory
-- the model builder draws from Parts only.

local BrainrotData = {}

BrainrotData.List = {
	{
		Name = "Tung Tung Tung Sahur",
		Rarity = "Common",
		Color = Color3.fromRGB(150, 100, 50),
		HeadColor = Color3.fromRGB(170, 120, 60),
		Size = 1.2,
		Accessory = "log",
	},
	{
		Name = "Tralalero Tralala",
		Rarity = "Common",
		Color = Color3.fromRGB(60, 140, 255),
		HeadColor = Color3.fromRGB(90, 170, 255),
		Size = 1.1,
		Accessory = "sharkfin",
	},
	{
		Name = "Ballerina Cappuccina",
		Rarity = "Rare",
		Color = Color3.fromRGB(255, 150, 200),
		HeadColor = Color3.fromRGB(255, 210, 225),
		Size = 1.0,
		Accessory = "tutu",
	},
	{
		Name = "Bombardiro Crocodilo",
		Rarity = "Rare",
		Color = Color3.fromRGB(60, 180, 80),
		HeadColor = Color3.fromRGB(80, 200, 100),
		Size = 1.3,
		Accessory = "wings",
	},
	{
		Name = "Chimpanzini Bananini",
		Rarity = "Epic",
		Color = Color3.fromRGB(255, 220, 60),
		HeadColor = Color3.fromRGB(255, 235, 120),
		Size = 1.0,
		Accessory = "banana",
	},
	{
		Name = "Lirili Larila",
		Rarity = "Epic",
		Color = Color3.fromRGB(90, 190, 110),
		HeadColor = Color3.fromRGB(120, 210, 130),
		Size = 1.2,
		Accessory = "cactus",
	},
	{
		Name = "Brr Brr Patapim",
		Rarity = "Legendary",
		Color = Color3.fromRGB(180, 140, 100),
		HeadColor = Color3.fromRGB(200, 160, 120),
		Size = 1.4,
		Accessory = "bignose",
	},
	{
		Name = "Cappuccino Assassino",
		Rarity = "Mythic",
		Color = Color3.fromRGB(120, 80, 50),
		HeadColor = Color3.fromRGB(150, 105, 70),
		Size = 1.1,
		Accessory = "katana",
	},
}

BrainrotData.RarityColors = {
	Common = Color3.fromRGB(180, 180, 180),
	Rare = Color3.fromRGB(60, 160, 255),
	Epic = Color3.fromRGB(170, 80, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(255, 60, 120),
}

function BrainrotData.GetByName(name)
	for _, def in ipairs(BrainrotData.List) do
		if def.Name == name then
			return def
		end
	end
	return nil
end

function BrainrotData.RandomDef()
	local roll = math.random(1, 100)
	local pool = {}
	if roll <= 40 then
		pool = { BrainrotData.List[1], BrainrotData.List[2] }
	elseif roll <= 70 then
		pool = { BrainrotData.List[3], BrainrotData.List[4] }
	elseif roll <= 90 then
		pool = { BrainrotData.List[5], BrainrotData.List[6] }
	elseif roll <= 97 then
		pool = { BrainrotData.List[7] }
	else
		pool = { BrainrotData.List[8] }
	end
	return pool[math.random(1, #pool)]
end

return BrainrotData
