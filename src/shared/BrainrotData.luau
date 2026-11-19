-- Anime-parody character definitions shared by server and client.
-- Original parody characters, inspired by anime tropes, with twisted
-- names -- NOT the real characters, and no photos or copyrighted
-- images are used anywhere: every model is built from Parts in code.
-- Each entry: name, rarity, cost to buy as a follower, income per
-- second, collect reward when clicked in the wild, body/head colour,
-- size, hair colour/style and an accessory the model builder draws.
-- All values are plain data: the 3D models are built from these in
-- code, so no terrain or model has to be built by hand in Studio.

local BrainrotData = {}

BrainrotData.List = {
	{
		Name = "Narutod",
		Rarity = "Common",
		Cost = 50,
		Income = 2,
		Reward = 15,
		Color = Color3.fromRGB(255, 140, 0),
		HeadColor = Color3.fromRGB(255, 210, 170),
		Size = 1.0,
		HairColor = Color3.fromRGB(255, 220, 0),
		HairStyle = "spiky",
		Accessory = "headband",
	},
	{
		Name = "Gokun",
		Rarity = "Common",
		Cost = 100,
		Income = 4,
		Reward = 25,
		Color = Color3.fromRGB(255, 120, 0),
		HeadColor = Color3.fromRGB(255, 210, 170),
		Size = 1.1,
		HairColor = Color3.fromRGB(30, 30, 30),
		HairStyle = "spiky",
		Accessory = "none",
	},
	{
		Name = "Luffi",
		Rarity = "Rare",
		Cost = 250,
		Income = 10,
		Reward = 60,
		Color = Color3.fromRGB(200, 40, 40),
		HeadColor = Color3.fromRGB(255, 210, 170),
		Size = 1.1,
		HairColor = Color3.fromRGB(30, 30, 30),
		HairStyle = "short",
		Accessory = "strawhat",
	},
	{
		Name = "Zoron",
		Rarity = "Rare",
		Cost = 400,
		Income = 16,
		Reward = 90,
		Color = Color3.fromRGB(40, 160, 80),
		HeadColor = Color3.fromRGB(255, 210, 170),
		Size = 1.3,
		HairColor = Color3.fromRGB(40, 180, 80),
		HairStyle = "spiky",
		Accessory = "headband",
	},
	{
		Name = "Tanjirod",
		Rarity = "Epic",
		Cost = 800,
		Income = 35,
		Reward = 180,
		Color = Color3.fromRGB(40, 120, 80),
		HeadColor = Color3.fromRGB(255, 210, 170),
		Size = 1.2,
		HairColor = Color3.fromRGB(200, 40, 40),
		HairStyle = "long",
		Accessory = "scar",
	},
	{
		Name = "Saitamod",
		Rarity = "Epic",
		Cost = 1200,
		Income = 55,
		Reward = 280,
		Color = Color3.fromRGB(255, 220, 0),
		HeadColor = Color3.fromRGB(255, 210, 170),
		Size = 1.2,
		HairColor = Color3.fromRGB(255, 210, 170),
		HairStyle = "none",
		Accessory = "none",
	},
	{
		Name = "Gojod",
		Rarity = "Legendary",
		Cost = 2500,
		Income = 120,
		Reward = 600,
		Color = Color3.fromRGB(40, 40, 60),
		HeadColor = Color3.fromRGB(240, 220, 200),
		Size = 1.5,
		HairColor = Color3.fromRGB(240, 240, 240),
		HairStyle = "spiky",
		Accessory = "blindfold",
	},
	{
		Name = "Dekun",
		Rarity = "Mythic",
		Cost = 5000,
		Income = 250,
		Reward = 1200,
		Color = Color3.fromRGB(60, 180, 90),
		HeadColor = Color3.fromRGB(255, 210, 170),
		Size = 1.6,
		HairColor = Color3.fromRGB(40, 160, 80),
		HairStyle = "curly",
		Accessory = "none",
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
