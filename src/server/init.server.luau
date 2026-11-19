-- Brainrot Collector: a 3D collector / tycoon game.
-- The whole world is built here, in code: ground, roads, spawn, trees,
-- lamps, shop plaza and every brainrot model. Nothing has to be built
-- by hand in Studio; Studio is only used to open, test and publish it.
--
-- How to play:
--  * Wild brainrots wander the field. Click one to collect it for coins.
--  * Gold coins spawn around the map; touch one for +10 coins.
--  * Spend coins in the shop (right side of the screen) to buy a brainrot
--    follower. Followers walk behind you and earn coins every second.
--  * The player with the most brainrots collected when the 5-minute
--    round timer ends is announced as the round winner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local ROUND_LENGTH = 300
local FIELD_HALF = 70
local MAX_WILD = 12

-- RemoteEvents used by the client UI.
local buyEvent = Instance.new("RemoteEvent")
buyEvent.Name = "BuyBrainrot"
buyEvent.Parent = ReplicatedStorage

local notifyEvent = Instance.new("RemoteEvent")
notifyEvent.Name = "Notify"
notifyEvent.Parent = ReplicatedStorage

local roundTime = Instance.new("IntValue")
roundTime.Name = "RoundTime"
roundTime.Value = ROUND_LENGTH
roundTime.Parent = ReplicatedStorage

local function notify(player, text)
	notifyEvent:FireClient(player, text)
end

local function notifyAll(text)
	notifyEvent:FireAllClients(text)
end

-- ---------------------------------------------------------------------------
-- World building (all in code)
-- ---------------------------------------------------------------------------

local function makePart(name, size, position, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	if shape then
		part.Shape = shape
	end
	part.Parent = Workspace
	return part
end

local function buildWorld()
	-- Ground, roads and plaza.
	makePart("Ground", Vector3.new(200, 2, 200), Vector3.new(0, 0, 0), Color3.fromRGB(90, 180, 90), Enum.Material.Grass)
	makePart("RoadNS", Vector3.new(10, 0.4, 190), Vector3.new(0, 1.1, 0), Color3.fromRGB(80, 80, 90), Enum.Material.Concrete)
	makePart("RoadEW", Vector3.new(190, 0.4, 10), Vector3.new(0, 1.1, 0), Color3.fromRGB(80, 80, 90), Enum.Material.Concrete)
	makePart("Plaza", Vector3.new(40, 0.6, 40), Vector3.new(0, 1.2, 0), Color3.fromRGB(220, 200, 150), Enum.Material.Concrete)

	-- Spawn point, south side.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = Vector3.new(0, 1.6, -80)
	spawn.Color = Color3.fromRGB(255, 220, 100)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = Workspace

	-- Four coloured brainrot spawn pads, one per quadrant.
	local padColors = {
		Color3.fromRGB(255, 120, 120),
		Color3.fromRGB(120, 180, 255),
		Color3.fromRGB(255, 220, 100),
		Color3.fromRGB(160, 120, 255),
	}
	local padPositions = {
		Vector3.new(-45, 1.3, -45),
		Vector3.new(45, 1.3, -45),
		Vector3.new(-45, 1.3, 45),
		Vector3.new(45, 1.3, 45),
	}
	for i, pos in ipairs(padPositions) do
		local pad = makePart("SpawnPad" .. i, Vector3.new(18, 0.6, 18), pos, padColors[i], Enum.Material.Neon)
		pad.CanCollide = false
		local label = Instance.new("SurfaceGui")
		label.Face = Enum.NormalId.Top
		label.Parent = pad
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Text = "BRAINROT"
		text.TextScaled = true
		text.Font = Enum.Font.SourceSansBold
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.Parent = label
	end

	-- Shop stall in the middle of the plaza.
	makePart("ShopBase", Vector3.new(14, 1, 8), Vector3.new(0, 1.8, 0), Color3.fromRGB(150, 90, 50), Enum.Material.Wood)
	makePart("ShopRoof", Vector3.new(16, 1, 10), Vector3.new(0, 7, 0), Color3.fromRGB(200, 60, 60), Enum.Material.SmoothPlastic)
	local shopSign = makePart("ShopSign", Vector3.new(12, 3, 0.6), Vector3.new(0, 5, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = shopSign
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "BRAINROT SHOP"
	signText.TextScaled = true
	signText.Font = Enum.Font.SourceSansBold
	signText.TextColor3 = Color3.fromRGB(30, 30, 30)
	signText.Parent = signGui

	-- Trees around the edge.
	for i = 1, 16 do
		local angle = (i / 16) * math.pi * 2
		local x = math.cos(angle) * 88
		local z = math.sin(angle) * 88
		makePart("TreeTrunk", Vector3.new(2, 8, 2), Vector3.new(x, 5, z), Color3.fromRGB(120, 80, 40), Enum.Material.Wood)
		makePart("TreeLeaves", Vector3.new(8, 8, 8), Vector3.new(x, 12, z), Color3.fromRGB(40, 140, 60), Enum.Material.Grass, Enum.PartType.Ball)
	end

	-- Lamps along the roads.
	for _, pos in ipairs({
		Vector3.new(-8, 0, -40),
		Vector3.new(8, 0, -40),
		Vector3.new(-8, 0, 40),
		Vector3.new(8, 0, 40),
	}) do
		makePart("LampPost", Vector3.new(1, 7, 1), Vector3.new(pos.X, 4.5, pos.Z), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
		local lamp = makePart("Lamp", Vector3.new(2, 1, 2), Vector3.new(pos.X, 8.5, pos.Z), Color3.fromRGB(255, 240, 150), Enum.Material.Neon, Enum.PartType.Ball)
		lamp.CanCollide = false
	end

	-- Fence around the field.
	for x = -95, 95, 10 do
		makePart("Fence", Vector3.new(2, 3, 2), Vector3.new(x, 2.5, -95), Color3.fromRGB(200, 200, 200), Enum.Material.Wood)
		makePart("Fence", Vector3.new(2, 3, 2), Vector3.new(x, 2.5, 95), Color3.fromRGB(200, 200, 200), Enum.Material.Wood)
	end
	for z = -95, 95, 10 do
		makePart("Fence", Vector3.new(2, 3, 2), Vector3.new(-95, 2.5, z), Color3.fromRGB(200, 200, 200), Enum.Material.Wood)
		makePart("Fence", Vector3.new(2, 3, 2), Vector3.new(95, 2.5, z), Color3.fromRGB(200, 200, 200), Enum.Material.Wood)
	end

	-- A big welcome sign at the spawn.
	local welcome = makePart("WelcomeSign", Vector3.new(20, 4, 0.6), Vector3.new(0, 6, -72), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	local welcomeGui = Instance.new("SurfaceGui")
	welcomeGui.Face = Enum.NormalId.Front
	welcomeGui.Parent = welcome
	local welcomeText = Instance.new("TextLabel")
	welcomeText.Size = UDim2.fromScale(1, 1)
	welcomeText.BackgroundTransparency = 1
	welcomeText.Text = "BRAINROT COLLECTOR"
	welcomeText.TextScaled = true
	welcomeText.Font = Enum.Font.SourceSansBold
	welcomeText.TextColor3 = Color3.fromRGB(30, 120, 30)
	welcomeText.Parent = welcomeGui

	-- Bright daylight.
	local lighting = game:GetService("Lighting")
	lighting.Brightness = 2
	lighting.ClockTime = 14
	lighting.Ambient = Color3.fromRGB(120, 120, 120)
end

-- ---------------------------------------------------------------------------
-- Brainrot models (built in code from BrainrotData)
-- ---------------------------------------------------------------------------

local function buildBrainrotModel(def)
	local s = def.Size
	local model = Instance.new("Model")
	model.Name = def.Name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3 * s, 3 * s, 2 * s)
	body.Color = def.Color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.Parent = model
	model.PrimaryPart = body

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2.2 * s, 2 * s, 2 * s)
	head.Position = Vector3.new(0, 2.5 * s, 0)
	head.Color = def.HeadColor
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model

	local eyeL = Instance.new("Part")
	eyeL.Name = "EyeL"
	eyeL.Size = Vector3.new(0.5 * s, 0.6 * s, 0.2 * s)
	eyeL.Position = Vector3.new(-0.5 * s, 2.7 * s, 1.05 * s)
	eyeL.Color = Color3.fromRGB(0, 0, 0)
	eyeL.Anchored = true
	eyeL.CanCollide = false
	eyeL.Parent = model

	local eyeR = Instance.new("Part")
	eyeR.Name = "EyeR"
	eyeR.Size = Vector3.new(0.5 * s, 0.6 * s, 0.2 * s)
	eyeR.Position = Vector3.new(0.5 * s, 2.7 * s, 1.05 * s)
	eyeR.Color = Color3.fromRGB(0, 0, 0)
	eyeR.Anchored = true
	eyeR.CanCollide = false
	eyeR.Parent = model

	local legL = Instance.new("Part")
	legL.Name = "LegL"
	legL.Size = Vector3.new(0.8 * s, 1.2 * s, 0.8 * s)
	legL.Position = Vector3.new(-0.7 * s, -2 * s, 0)
	legL.Color = Color3.fromRGB(40, 40, 40)
	legL.Anchored = true
	legL.CanCollide = false
	legL.Parent = model

	local legR = Instance.new("Part")
	legR.Name = "LegR"
	legR.Size = Vector3.new(0.8 * s, 1.2 * s, 0.8 * s)
	legR.Position = Vector3.new(0.7 * s, -2 * s, 0)
	legR.Color = Color3.fromRGB(40, 40, 40)
	legR.Anchored = true
	legR.CanCollide = false
	legR.Parent = model

	-- Name + rarity tag floating above the model.
	local tag = Instance.new("BillboardGui")
	tag.Name = "Tag"
	tag.Size = UDim2.new(0, 140, 0, 50)
	tag.StudsOffset = Vector3.new(0, 4 * s, 0)
	tag.AlwaysOnTop = true
	tag.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 0.4
	nameLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.Text = def.Name
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Parent = tag

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Position = UDim2.new(0, 0, 0.6, 0)
	rarityLabel.Size = UDim2.new(1, 0, 0.4, 0)
	rarityLabel.BackgroundTransparency = 0.4
	rarityLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	rarityLabel.Text = def.Rarity .. "  + " .. tostring(def.Reward) .. " coins"
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.SourceSans
	rarityLabel.TextColor3 = BrainrotData.RarityColors[def.Rarity] or Color3.fromRGB(255, 255, 255)
	rarityLabel.Parent = tag

	return model
end

-- ---------------------------------------------------------------------------
-- Player state, wild brainrots, coins, followers
-- ---------------------------------------------------------------------------

local owned = {} -- [player] = { {def=..., model=...}, ... }
local wild = {} -- { {def=..., model=..., target=Vector3, collected=false}, ... }

local function setupPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 100
	coins.Parent = leaderstats

	local collected = Instance.new("IntValue")
	collected.Name = "Brainrots"
	collected.Value = 0
	collected.Parent = leaderstats

	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = leaderstats

	owned[player] = {}
	task.delay(1, function()
		if player.Parent then
			notify(player, "Welcome to Brainrot Collector! Click a wild brainrot to collect it.")
		end
	end)
end

local function totalIncome(player)
	local sum = 0
	for _, entry in ipairs(owned[player] or {}) do
		sum += entry.def.Income
	end
	return sum
end

local function spawnWild()
	local def = BrainrotData.RandomDef()
	local model = buildBrainrotModel(def)
	local x = math.random(-FIELD_HALF, FIELD_HALF)
	local z = math.random(-FIELD_HALF, FIELD_HALF)
	model:PivotTo(CFrame.new(x, 4, z))
	model.Parent = Workspace

	local entry = {
		def = def,
		model = model,
		target = Vector3.new(x, 4, z),
		collected = false,
	}
	table.insert(wild, entry)

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 32
	click.Parent = model.PrimaryPart
	click.MouseClick:Connect(function(player)
		if entry.collected then
			return
		end
		entry.collected = true
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local coins = stats:FindFirstChild("Coins")
			local count = stats:FindFirstChild("Brainrots")
			if coins then
				coins.Value += def.Reward
			end
			if count then
				count.Value += 1
			end
		end
		notify(player, "Collected " .. def.Name .. "! +" .. tostring(def.Reward) .. " coins")
		model:Destroy()
		for i, item in ipairs(wild) do
			if item == entry then
				table.remove(wild, i)
				break
			end
		end
		task.delay(3, spawnWild)
	end)

	-- Despawn after 60 seconds if nobody collects it.
	task.delay(60, function()
		if not entry.collected and model.Parent then
			model:Destroy()
			for i, item in ipairs(wild) do
				if item == entry then
					table.remove(wild, i)
					break
				end
			end
			task.delay(2, spawnWild)
		end
	end)
end

local function spawnCoin()
	local coin = Instance.new("Part")
	coin.Name = "Coin"
	coin.Size = Vector3.new(1.6, 0.2, 1.6)
	coin.Shape = Enum.PartType.Cylinder
	coin.Rotation = Vector3.new(0, 0, 90)
	coin.Color = Color3.fromRGB(255, 210, 0)
	coin.Material = Enum.Material.Neon
	coin.Anchored = true
	coin.CanCollide = false
	coin.Position = Vector3.new(math.random(-FIELD_HALF, FIELD_HALF), 2.5, math.random(-FIELD_HALF, FIELD_HALF))
	coin.Parent = Workspace

	local taken = false
	coin.Touched:Connect(function(hit)
		if taken then
			return
		end
		local character = hit.Parent
		if not character then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		taken = true
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local coins = stats:FindFirstChild("Coins")
			if coins then
				coins.Value += 10
			end
		end
		notify(player, "+10 coins!")
		coin:Destroy()
		task.delay(8, spawnCoin)
	end)

	task.delay(45, function()
		if coin.Parent then
			coin:Destroy()
			task.delay(5, spawnCoin)
		end
	end)
end

local function makeFollower(player, def)
	local model = buildBrainrotModel(def)
	model.Name = def.Name .. " (yours)"
	-- Followers are smaller and float beside the player.
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		model:PivotTo(root.CFrame * CFrame.new(4, 2, 2))
	end
	model.Parent = Workspace
	return model
end

buyEvent.OnServerEvent:Connect(function(player, name)
	local def = BrainrotData.GetByName(name)
	if not def then
		notify(player, "Unknown brainrot.")
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	local coins = stats:FindFirstChild("Coins")
	local income = stats:FindFirstChild("Income")
	if not coins then
		return
	end
	if coins.Value < def.Cost then
		notify(player, "Not enough coins for " .. def.Name .. "! Need " .. tostring(def.Cost) .. ".")
		return
	end
	coins.Value -= def.Cost
	local model = makeFollower(player, def)
	table.insert(owned[player], { def = def, model = model })
	if income then
		income.Value = totalIncome(player)
	end
	notify(player, "Bought " .. def.Name .. "! +" .. tostring(def.Income) .. " coins/sec")
end)

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	for _, entry in ipairs(owned[player] or {}) do
		if entry.model and entry.model.Parent then
			entry.model:Destroy()
		end
	end
	owned[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

-- Movement: wild brainrots wander, followers trail their owner.
RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	for _, entry in ipairs(wild) do
		if entry.model.Parent and not entry.collected then
			local pos = entry.model:GetPivot().Position
			local target = entry.target
			local dx = target.X - pos.X
			local dz = target.Z - pos.Z
			local dist = math.sqrt(dx * dx + dz * dz)
			if dist < 2 then
				entry.target = Vector3.new(
					math.random(-FIELD_HALF, FIELD_HALF),
					4,
					math.random(-FIELD_HALF, FIELD_HALF)
				)
			else
				local step = 3 * dt
				local nx = pos.X + (dx / dist) * step
				local nz = pos.Z + (dz / dist) * step
				local bob = math.sin(now * 3 + pos.X) * 0.4
				entry.model:PivotTo(CFrame.new(nx, 4 + bob, nz))
			end
		end
	end
	for player, list in pairs(owned) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			for i, entry in ipairs(list) do
				if entry.model.Parent then
					local goal = root.Position + Vector3.new(4 + (i % 3) * 2, 2, 3 + math.floor(i / 3) * 2)
					local pos = entry.model:GetPivot().Position
					local dx = goal.X - pos.X
					local dy = goal.Y - pos.Y
					local dz = goal.Z - pos.Z
					local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
					if dist > 0.5 then
						local step = math.min(dist, 10 * dt)
						entry.model:PivotTo(CFrame.new(
							pos.X + (dx / dist) * step,
							pos.Y + (dy / dist) * step,
							pos.Z + (dz / dist) * step
						))
					end
				end
			end
		end
	end
end)

-- Income tick, coin spawns, wild spawns, round timer.
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local stats = player:FindFirstChild("leaderstats")
			if stats then
				local coins = stats:FindFirstChild("Coins")
				if coins then
					coins.Value += totalIncome(player)
				end
			end
		end
	end
end)

buildWorld()
for _ = 1, MAX_WILD do
	spawnWild()
	task.wait(0.2)
end
for _ = 1, 10 do
	spawnCoin()
	task.wait(0.2)
end

task.spawn(function()
	while true do
		task.wait(1)
		roundTime.Value -= 1
		if roundTime.Value <= 0 then
			local best = nil
			local bestCount = -1
			for _, player in ipairs(Players:GetPlayers()) do
				local stats = player:FindFirstChild("leaderstats")
				local count = stats and stats:FindFirstChild("Brainrots")
				if count and count.Value > bestCount then
					bestCount = count.Value
					best = player
				end
			end
			if best then
				notifyAll("Round over! Winner: " .. best.Name .. " with " .. tostring(bestCount) .. " brainrots!")
			else
				notifyAll("Round over! No winner this time.")
			end
			roundTime.Value = ROUND_LENGTH
		end
	end
end)

print("Brainrot Collector started: wild brainrots, coins, shop and round timer running.")
