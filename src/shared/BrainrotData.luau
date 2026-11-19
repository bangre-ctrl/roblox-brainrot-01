-- Brainrot definitions shared by server and client.
-- Each brainrot: name, rarity, cost to buy as a follower, income per second,
-- collect reward when clicked in the wild, colour and size of its 3D body.
-- All values are plain data: the 3D models are built from these in code,
-- so no terrain or model has to be built by hand in Studio.

local BrainrotData = {}

BrainrotData.List = {
	{
		Name = "Tung Tung Tung Sahur",
		Rarity = "Common",
		Cost = 50,
		Income = 2,
		Reward = 15,
		Color = Color3.fromRGB(139, 90, 43),
		HeadColor = Color3.fromRGB(210, 180, 140),
		Size = 1.0,
	},
	{
		Name = "Tralalero Tralala",
		Rarity = "Common",
		Cost = 100,
		Income = 4,
		Reward = 25,
		Color = Color3.fromRGB(60, 130, 200),
		HeadColor = Color3.fromRGB(180, 220, 255),
		Size = 1.1,
	},
	{
		Name = "Chimpanzini Bananini",
		Rarity = "Rare",
		Cost = 250,
		Income = 10,
		Reward = 60,
		Color = Color3.fromRGB(240, 200, 60),
		HeadColor = Color3.fromRGB(120, 80, 40),
		Size = 1.1,
	},
	{
		Name = "Bombardiro Crocodilo",
		Rarity = "Rare",
		Cost = 400,
		Income = 16,
		Reward = 90,
		Color = Color3.fromRGB(60, 160, 80),
		HeadColor = Color3.fromRGB(200, 230, 180),
		Size = 1.3,
	},
	{
		Name = "Lirili Larila",
		Rarity = "Epic",
		Cost = 800,
		Income = 35,
		Reward = 180,
		Color = Color3.fromRGB(40, 180, 180),
		HeadColor = Color3.fromRGB(255, 220, 180),
		Size = 1.2,
	},
	{
		Name = "Cappuccino Assassino",
		Rarity = "Epic",
		Cost = 1200,
		Income = 55,
		Reward = 280,
		Color = Color3.fromRGB(110, 70, 40),
		HeadColor = Color3.fromRGB(240, 220, 200),
		Size = 1.2,
	},
	{
		Name = "Brr Brr Patapim",
		Rarity = "Legendary",
		Cost = 2500,
		Income = 120,
		Reward = 600,
		Color = Color3.fromRGB(240, 120, 40),
		HeadColor = Color3.fromRGB(255, 240, 200),
		Size = 1.5,
	},
	{
		Name = "La Vaca Saturno Saturnita",
		Rarity = "Mythic",
		Cost = 5000,
		Income = 250,
		Reward = 1200,
		Color = Color3.fromRGB(150, 80, 200),
		HeadColor = Color3.fromRGB(255, 255, 255),
		Size = 1.6,
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
