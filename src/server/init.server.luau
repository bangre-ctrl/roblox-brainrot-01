-- Frozen Brainrot Mart: a comedy-absurd frozen-food cashier simulator.
-- The whole world is built here, in code: a minimalist rectangular
-- shop, glass front door, cashier counter at the back, chest freezers
-- along both walls, posters, a road and a supplier truck outside.
-- Nothing has to be built by hand in Studio; Studio is only used to
-- open, test and publish it.
--
-- How to play:
--  * Brainrot customers walk in, queue neatly and pay exactly. Stand
--    behind the counter and press SCAN (or click the customer at the
--    counter) to scan their order. Money and stock move per item.
--  * Emak-Emak is NOT a customer and never joins the queue: she
--    paces along the queue for 5 seconds (shoving brainrots one
--    slot back), then stands by the counter for 10 seconds making
--    scans take twice as long. There is no voucher anymore
--    (removed in v6): just wait her out — no stock or
--    reputation penalty from her.
--  * Oknum Ormas demand protection money. Pay 100c, call the satpam
--    (if hired), or honk the telolet horn to chase them away.
--  * If total stock hits 0, brainrot customers hold a peaceful protest
--    inside the shop and nothing sells. Order a supplier truck (80c),
--    carry its boxes to a freezer, and the protest ends.
--  * Spend coins on upgrades: faster scanner, a brainrot security
--    guard, bigger stock, Es Krim, Dimsum, Menu Sultan (gold Sultan
--    versions of every product, 3x price, VIP customers only), a
--    helper cashier and an elite helper, viral ads, an express
--    truck, an elite guard, a 5-level shop expansion, a safe, and
--    Hypermart (World 2, free once the shop is fully expanded).
--  * Money comes ONLY from sales — no cashier wage. Sales income
--    is enough to afford the 80c supplier truck.
--
-- NPCs are Part models moved with PivotTo on Heartbeat. No Humanoid
-- rigs are used anywhere: they are too fragile for code-built NPCs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Products = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Products"))

local SHIFT_LENGTH = 300
local FLOOR_Y = 1.5
local PIVOT_Y = 4.2
local QUEUE_Z = { -10, -6, -2, 2, 6, 10 }
local COUNTER_POS = Vector3.new(0, PIVOT_Y, -13)
local DOOR_POS = Vector3.new(0, PIVOT_Y, 20)
local OUTSIDE_POS = Vector3.new(0, PIVOT_Y, 28)
local SCAN_TIMES = { 3, 2.2, 1.6, 1.1, 0.7 }
local SCAN_COSTS = { 150, 350, 700, 1200 }
local TRUCK_WAIT_TIMES = { 8, 4, 2 }
local TRUCK_BOX_COUNTS = { 4, 5, 6 }
local EXPAND_COSTS = { 400, 800, 1500, 2500, 4000 }
local HELPER_COST = 3000
local HELPER_ELITE_COST = 6000
local AD_COST = 750
local TRUCK_EXPRESS_COST = 1500
local ELITE_COST = 10000
local SULTAN_COST = 1000
local HELPER_INTERVAL = 8
local HELPER_ELITE_INTERVAL = 4
local VIP_CHANCE = 0.22
local EMAK_PHRASES = {
	"Anak saya udah lapar!",
	"Saya buru-buru!",
	"Panggil managernya!",
}
local PROTEST_SIGNS = {
	"STOK HABIS!!",
	"KAMI LAPAR",
	"FROZEN FOOD MANA?",
}

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------

local stock = {}
local unlocked = {}
local customers = {} -- ordered front-to-back; [1] is at (or heading to) the counter
local protesters = {}
local carrying = {} -- [player] = box entry
-- Emak-Emak is a standalone disruptor, NEVER inside customers:
-- { model, phase ("pacing"/"jamming"), timeLeft (15 total),
--   phaseTimeLeft, pushAccum, target, speed }.
local emak = nil
local emakLeaving = nil -- { model, target, speed } walking out the door
local ormas = nil -- { models = {...}, timer = n, securityTimer = n }
local truck = nil -- { model = ..., boxes = {...} }
local truckActive = false
local demoActive = false
local scannerLevel = 1
local hasSecurity = false
local stockLevel = 0
local reputation = 100
local scanning = false
local teloletCooldownUntil = 0
local helperOwned = false
local helperEliteOwned = false
local helperTimer = 0
local adLevel = 0
local truckLevel = 0
local eliteOwned = false
local expandLevel = 0
local sultanUnlocked = false
local hypermartOpen = false
local safeOwned = false

for _, def in ipairs(Products.List) do
	if def.UnlockCost == 0 and not def.IsSultan and not def.IsHypermart then
		stock[def.Name] = Products.StartStock
		unlocked[def.Name] = true
	else
		stock[def.Name] = 0
		unlocked[def.Name] = false
	end
end

-- Forward declarations (assigned further down, called from world code).
local deliverBox
local carryBox
local startDemo
local endDemo
local checkDemo

-- ---------------------------------------------------------------------------
-- RemoteEvents and shared state values
-- ---------------------------------------------------------------------------

local function makeRemote(name)
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = ReplicatedStorage
	return ev
end

local scanEvent = makeRemote("ScanCustomer")
local buyUpgradeEvent = makeRemote("BuyUpgrade")
local payOrmasEvent = makeRemote("PayOrmas")
local callSecurityEvent = makeRemote("CallSecurity")
local honkEvent = makeRemote("HonkTelolet")
local orderTruckEvent = makeRemote("OrderTruck")
local carryBoxEvent = makeRemote("CarryBox")
local deliverBoxEvent = makeRemote("DeliverBox")
local notifyEvent = makeRemote("Notify")

local function makeValue(className, name, value)
	local v = Instance.new(className)
	v.Name = name
	v.Value = value
	v.Parent = ReplicatedStorage
	return v
end

local shiftTime = makeValue("IntValue", "ShiftTime", SHIFT_LENGTH)
local totalStockValue = makeValue("IntValue", "TotalStock", 0)
local threatTypeValue = makeValue("StringValue", "ThreatType", "none")
local threatTimerValue = makeValue("IntValue", "ThreatTimer", 0)
local emakPhaseValue = makeValue("StringValue", "EmakPhase", "")
local demoValue = makeValue("BoolValue", "DemoMode", false)
local scannerLevelValue = makeValue("IntValue", "ScannerLevel", 1)
local hasSecurityValue = makeValue("BoolValue", "HasSecurity", false)
local stockLevelValue = makeValue("IntValue", "StockLevel", 0)
local unlockedStateValue = makeValue("StringValue", "UnlockedState", "")
local stockStateValue = makeValue("StringValue", "StockState", "")
local frontOrderValue = makeValue("StringValue", "FrontOrder", "")
local truckActiveValue = makeValue("BoolValue", "TruckActive", false)
local helperOwnedValue = makeValue("BoolValue", "HelperOwned", false)
local adLevelValue = makeValue("IntValue", "AdLevel", 0)
local truckLevelValue = makeValue("IntValue", "TruckLevel", 0)
local eliteOwnedValue = makeValue("BoolValue", "EliteOwned", false)
local expandLevelValue = makeValue("IntValue", "ExpandLevel", 0)
local expandOwnedValue = makeValue("BoolValue", "ExpandOwned", false)
local sultanUnlockedValue = makeValue("BoolValue", "SultanUnlocked", false)
local hypermartOpenValue = makeValue("BoolValue", "HypermartOpen", false)
local helperEliteOwnedValue = makeValue("BoolValue", "HelperEliteOwned", false)
local safeOwnedValue = makeValue("BoolValue", "SafeOwned", false)

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function notify(player, text)
	notifyEvent:FireClient(player, text)
end

local function notifyAll(text)
	notifyEvent:FireAllClients(text)
end

local function getCoins(player)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if coins then
		return coins.Value
	end
	return 0
end

local function addCoins(player, amount)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if coins then
		coins.Value = math.max(0, coins.Value + amount)
	end
end

local function getEmakJamTime()
	return eliteOwned and 5 or 10
end

local function getTruckWaitTime()
	return TRUCK_WAIT_TIMES[truckLevel + 1]
end

local function getTruckBoxCount()
	return TRUCK_BOX_COUNTS[truckLevel + 1]
end

local function getMaxStock()
	return Products.StartMaxStock + 10 * stockLevel
end

local function getMaxQueue()
	return 6 + 2 * expandLevel
end

local function getHelperInterval()
	return helperEliteOwned and HELPER_ELITE_INTERVAL or HELPER_INTERVAL
end

local function getTotalStock()
	local sum = 0
	for _, def in ipairs(Products.List) do
		sum += stock[def.Name] or 0
	end
	return sum
end

local function setReputation(value)
	reputation = math.clamp(value, 0, 100)
	for _, player in ipairs(Players:GetPlayers()) do
		local stats = player:FindFirstChild("leaderstats")
		local rep = stats and stats:FindFirstChild("Reputasi")
		if rep then
			rep.Value = reputation
		end
	end
end

local function updateState()
	totalStockValue.Value = getTotalStock()
	scannerLevelValue.Value = scannerLevel
	hasSecurityValue.Value = hasSecurity
	stockLevelValue.Value = stockLevel
	helperOwnedValue.Value = helperOwned
	helperEliteOwnedValue.Value = helperEliteOwned
	adLevelValue.Value = adLevel
	truckLevelValue.Value = truckLevel
	eliteOwnedValue.Value = eliteOwned
	expandLevelValue.Value = expandLevel
	expandOwnedValue.Value = expandLevel > 0
	hypermartOpenValue.Value = hypermartOpen
	sultanUnlockedValue.Value = sultanUnlocked
	safeOwnedValue.Value = safeOwned
	local unlockedParts = {}
	for _, def in ipairs(Products.List) do
		if unlocked[def.Name] then
			table.insert(unlockedParts, def.Name)
		end
	end
	unlockedStateValue.Value = table.concat(unlockedParts, ",")
	demoValue.Value = demoActive
	truckActiveValue.Value = truckActive
	if emak then
		threatTypeValue.Value = "emak"
		threatTimerValue.Value = emak.timeLeft
		emakPhaseValue.Value = emak.phase
	elseif ormas then
		threatTypeValue.Value = "ormas"
		threatTimerValue.Value = ormas.timer
		emakPhaseValue.Value = ""
	else
		threatTypeValue.Value = "none"
		threatTimerValue.Value = 0
		emakPhaseValue.Value = ""
	end
	local parts = {}
	for _, def in ipairs(Products.List) do
		table.insert(parts, def.Name .. ":" .. tostring(stock[def.Name] or 0))
	end
	stockStateValue.Value = table.concat(parts, ";")
	local front = customers[1]
	if front and front.state == "at_counter" and front.order then
		local who = front.isVip and "VIP SULTAN " .. front.def.Name or front.def.Name
		frontOrderValue.Value = who .. ": " .. table.concat(front.order, ", ") .. " = " .. tostring(front.total) .. "c"
	elseif front then
		frontOrderValue.Value = "Antrean: " .. front.def.Name .. " jalan ke kasir..."
	elseif #protesters > 0 then
		frontOrderValue.Value = "DEMO DAMAI! Stok habis, pesan truk supplier!"
	else
		frontOrderValue.Value = "Belum ada pelanggan di kasir."
	end
end

-- ---------------------------------------------------------------------------
-- World building (all in code)
-- ---------------------------------------------------------------------------

local freezerPositions = {}

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

local function makePoster(text, position, face, color)
	local board = makePart("Poster", Vector3.new(0.5, 3, 5), position, Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = color
	label.BackgroundTransparency = 0.2
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(30, 30, 30)
	label.Parent = gui
	return board
end

local function buildWorld()
	-- Outside ground, road and sidewalk.
	makePart("OutsideGround", Vector3.new(120, 2, 120), Vector3.new(0, 0, 0), Color3.fromRGB(110, 160, 110), Enum.Material.Grass)
	makePart("Road", Vector3.new(80, 0.4, 16), Vector3.new(0, 1.2, 32), Color3.fromRGB(60, 60, 70), Enum.Material.Concrete)
	makePart("Sidewalk", Vector3.new(70, 0.5, 4), Vector3.new(0, 1.25, 22), Color3.fromRGB(180, 180, 180), Enum.Material.Concrete)

	-- Shop floor and walls. Front wall (Z=+20) has a glass door gap.
	makePart("ShopFloor", Vector3.new(64, 0.6, 40), Vector3.new(0, 1.2, 0), Color3.fromRGB(230, 230, 220), Enum.Material.Concrete)
	makePart("WallBack", Vector3.new(64, 8, 1), Vector3.new(0, 5.5, -20), Color3.fromRGB(200, 220, 255), Enum.Material.Concrete)
	makePart("WallLeft", Vector3.new(1, 8, 40), Vector3.new(-32, 5.5, 0), Color3.fromRGB(200, 220, 255), Enum.Material.Concrete)
	makePart("WallRight", Vector3.new(1, 8, 40), Vector3.new(32, 5.5, 0), Color3.fromRGB(200, 220, 255), Enum.Material.Concrete)
	makePart("WallFrontL", Vector3.new(28, 8, 1), Vector3.new(-18, 5.5, 20), Color3.fromRGB(200, 220, 255), Enum.Material.Concrete)
	makePart("WallFrontR", Vector3.new(28, 8, 1), Vector3.new(18, 5.5, 20), Color3.fromRGB(200, 220, 255), Enum.Material.Concrete)
	makePart("WallFrontTop", Vector3.new(8, 1, 1), Vector3.new(0, 9, 20), Color3.fromRGB(200, 220, 255), Enum.Material.Concrete)

	-- Glass entrance door (see-through, walk-through).
	local door = makePart("GlassDoor", Vector3.new(8, 7, 0.4), Vector3.new(0, 5, 20), Color3.fromRGB(180, 220, 255), Enum.Material.Glass)
	door.Transparency = 0.6
	door.CanCollide = false
	makePart("DoorFrameL", Vector3.new(0.6, 7, 0.6), Vector3.new(-4, 5, 20), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)
	makePart("DoorFrameR", Vector3.new(0.6, 7, 0.6), Vector3.new(4, 5, 20), Color3.fromRGB(40, 40, 40), Enum.Material.Metal)

	-- Store sign above the door.
	local sign = makePart("StoreSign", Vector3.new(26, 4, 0.6), Vector3.new(0, 12, 21), Color3.fromRGB(30, 60, 140), Enum.Material.Neon)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "FROZEN BRAINROT MART"
	signText.TextScaled = true
	signText.Font = Enum.Font.SourceSansBold
	signText.TextColor3 = Color3.fromRGB(255, 230, 80)
	signText.Parent = signGui

	-- Neon light strips on the ceiling line.
	for _, x in ipairs({ -16, 0, 16 }) do
		local strip = makePart("NeonLight", Vector3.new(10, 0.4, 1), Vector3.new(x, 9.4, 0), Color3.fromRGB(255, 240, 150), Enum.Material.Neon)
		strip.CanCollide = false
	end

	-- Cashier counter at the back, facing the door.
	makePart("CounterBase", Vector3.new(12, 2, 2), Vector3.new(0, 2.5, -16), Color3.fromRGB(90, 140, 220), Enum.Material.Wood)
	makePart("CounterTop", Vector3.new(13, 0.6, 3), Vector3.new(0, 3.8, -16), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
	local register = makePart("CashRegister", Vector3.new(2, 1.6, 1.6), Vector3.new(-3, 4.9, -16), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
	local regGui = Instance.new("SurfaceGui")
	regGui.Face = Enum.NormalId.Front
	regGui.Parent = register
	local regText = Instance.new("TextLabel")
	regText.Size = UDim2.fromScale(1, 1)
	regText.BackgroundTransparency = 1
	regText.Text = "KASIR"
	regText.TextScaled = true
	regText.Font = Enum.Font.SourceSansBold
	regText.TextColor3 = Color3.fromRGB(255, 210, 0)
	regText.Parent = regGui
	makePart("ScannerProp", Vector3.new(1, 0.6, 1.4), Vector3.new(3, 4.4, -16), Color3.fromRGB(200, 40, 40), Enum.Material.SmoothPlastic)

	-- Player spawn behind the counter, facing the door.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 2, -14)
	spawn.Color = Color3.fromRGB(255, 220, 100)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = Workspace

	-- Chest freezers along both walls, with a stock light on top.
	local freezerZ = { -12, -6, 0, 6, 12 }
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs(freezerZ) do
			local x = side * 29
			local freezer = makePart("Freezer", Vector3.new(3, 3, 4), Vector3.new(x, 3, z), Color3.fromRGB(240, 245, 255), Enum.Material.SmoothPlastic)
			local lid = makePart("FreezerLid", Vector3.new(3.2, 0.5, 4.2), Vector3.new(x, 4.7, z), Color3.fromRGB(120, 180, 255), Enum.Material.SmoothPlastic)
			lid.CanCollide = false
			local light = makePart("StockLight", Vector3.new(0.6, 0.6, 0.6), Vector3.new(x - side * 1.6, 4.2, z), Color3.fromRGB(80, 255, 80), Enum.Material.Neon)
			light.CanCollide = false
			table.insert(freezerPositions, freezer.Position)
			local click = Instance.new("ClickDetector")
			click.MaxActivationDistance = 32
			click.Parent = freezer
			click.MouseClick:Connect(function(player)
				deliverBox(player)
			end)
		end
	end

	-- Posters above the freezers: one per product.
	local posterData = {
		{ text = "NUGGET\n20c", pos = Vector3.new(-31.2, 6.5, -10), face = Enum.NormalId.Right, color = Products.List[1].Color },
		{ text = "SOSIS\n25c", pos = Vector3.new(-31.2, 6.5, 0), face = Enum.NormalId.Right, color = Products.List[3].Color },
		{ text = "BAKSO\n30c", pos = Vector3.new(-31.2, 6.5, 10), face = Enum.NormalId.Right, color = Products.List[4].Color },
		{ text = "KENTANG\n15c", pos = Vector3.new(31.2, 6.5, -10), face = Enum.NormalId.Left, color = Products.List[2].Color },
		{ text = "ES KRIM\n40c", pos = Vector3.new(31.2, 6.5, 0), face = Enum.NormalId.Left, color = Products.List[5].Color },
		{ text = "DIMSUM\n50c", pos = Vector3.new(31.2, 6.5, 10), face = Enum.NormalId.Left, color = Products.List[6].Color },
		{ text = "MENU SULTAN\nHARGA 3x", pos = Vector3.new(-31.2, 6.5, 17), face = Enum.NormalId.Right, color = Color3.fromRGB(255, 200, 0) },
	}
	for _, p in ipairs(posterData) do
		makePoster(p.text, p.pos, p.face, p.color)
	end

	-- Freezer emas Sultan (terpisah dari freezer biasa): stok Sultan
	-- disimpan di sini. Dibangun sejak awal supaya tokonya langsung
	-- kelihatan "sultan", tapi stok Sultan baru terisi setelah
	-- Menu Sultan dibeli.
	for _, x in ipairs({ -24, 24 }) do
		local gold = makePart("FreezerSultan", Vector3.new(3, 3, 4), Vector3.new(x, 3, -17.5), Color3.fromRGB(255, 200, 0), Enum.Material.Neon)
		gold.Transparency = 0.15
		local lid = makePart("FreezerSultanLid", Vector3.new(3.2, 0.5, 4.2), Vector3.new(x, 4.7, -17.5), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
		lid.CanCollide = false
		table.insert(freezerPositions, gold.Position)
		local click = Instance.new("ClickDetector")
		click.MaxActivationDistance = 32
		click.Parent = gold
		click.MouseClick:Connect(function(player)
			deliverBox(player)
		end)
	end
	local sultanSign = makePart("SultanSign", Vector3.new(14, 3, 0.6), Vector3.new(0, 8, -19.4), Color3.fromRGB(255, 200, 0), Enum.Material.Neon)
	local sultanGui = Instance.new("SurfaceGui")
	sultanGui.Face = Enum.NormalId.Back
	sultanGui.Parent = sultanSign
	local sultanText = Instance.new("TextLabel")
	sultanText.Size = UDim2.fromScale(1, 1)
	sultanText.BackgroundTransparency = 1
	sultanText.Text = "MENU SULTAN - EMAS 3x"
	sultanText.TextScaled = true
	sultanText.Font = Enum.Font.SourceSansBold
	sultanText.TextColor3 = Color3.fromRGB(60, 40, 0)
	sultanText.Parent = sultanGui

	local lighting = game:GetService("Lighting")
	lighting.Brightness = 2
	lighting.ClockTime = 14
	lighting.Ambient = Color3.fromRGB(120, 120, 120)
end

-- ---------------------------------------------------------------------------
-- NPC models (built in code from Parts only)
-- ---------------------------------------------------------------------------

local function addTag(model, body, title, sub, subColor, height)
	local tag = Instance.new("BillboardGui")
	tag.Name = "Tag"
	tag.Size = UDim2.new(0, 160, 0, 44)
	tag.StudsOffset = Vector3.new(0, height, 0)
	tag.AlwaysOnTop = false
	tag.Parent = body
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.55, 0)
	titleLabel.BackgroundTransparency = 0.4
	titleLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.Text = title
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Parent = tag
	local subLabel = Instance.new("TextLabel")
	subLabel.Position = UDim2.new(0, 0, 0.55, 0)
	subLabel.Size = UDim2.new(1, 0, 0.45, 0)
	subLabel.BackgroundTransparency = 0.4
	subLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	subLabel.Text = sub
	subLabel.TextScaled = true
	subLabel.Font = Enum.Font.SourceSans
	subLabel.TextColor3 = subColor
	subLabel.Parent = tag
	return tag
end

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

	local function smallPart(name, size, position, color, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Position = position
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		if shape then
			part.Shape = shape
		end
		part.Parent = model
		return part
	end

	smallPart("EyeL", Vector3.new(0.5 * s, 0.6 * s, 0.2 * s), Vector3.new(-0.5 * s, 2.7 * s, 1.05 * s), Color3.fromRGB(0, 0, 0))
	smallPart("EyeR", Vector3.new(0.5 * s, 0.6 * s, 0.2 * s), Vector3.new(0.5 * s, 2.7 * s, 1.05 * s), Color3.fromRGB(0, 0, 0))
	smallPart("LegL", Vector3.new(0.8 * s, 1.2 * s, 0.8 * s), Vector3.new(-0.7 * s, -2 * s, 0), Color3.fromRGB(40, 40, 40))
	smallPart("LegR", Vector3.new(0.8 * s, 1.2 * s, 0.8 * s), Vector3.new(0.7 * s, -2 * s, 0), Color3.fromRGB(40, 40, 40))

	if def.Accessory == "log" then
		local bat = smallPart("Bat", Vector3.new(0.7 * s, 3.4 * s, 0.7 * s), Vector3.new(1.9 * s, 0.5 * s, 0), Color3.fromRGB(120, 80, 40))
		bat.Rotation = Vector3.new(0, 0, -20)
	elseif def.Accessory == "sharkfin" then
		local fin = smallPart("Fin", Vector3.new(0.5 * s, 1.6 * s, 1.4 * s), Vector3.new(0, 3.9 * s, 0), Color3.fromRGB(30, 90, 200))
		fin.Rotation = Vector3.new(-20, 0, 0)
		smallPart("Tail", Vector3.new(1.6 * s, 0.8 * s, 0.4 * s), Vector3.new(0, -0.5 * s, -1.2 * s), Color3.fromRGB(30, 90, 200))
	elseif def.Accessory == "tutu" then
		local tutu = smallPart("Tutu", Vector3.new(4.4 * s, 0.4 * s, 3.4 * s), Vector3.new(0, -0.8 * s, 0), Color3.fromRGB(255, 180, 220), Enum.PartType.Cylinder)
		tutu.Rotation = Vector3.new(0, 0, 90)
		smallPart("Cup", Vector3.new(1.2 * s, 1.2 * s, 1.2 * s), Vector3.new(0, 3.9 * s, 0), Color3.fromRGB(255, 240, 220), Enum.PartType.Cylinder)
	elseif def.Accessory == "wings" then
		smallPart("WingL", Vector3.new(2.4 * s, 0.3 * s, 1.4 * s), Vector3.new(-2.4 * s, 1.5 * s, -0.6 * s), Color3.fromRGB(220, 220, 220))
		smallPart("WingR", Vector3.new(2.4 * s, 0.3 * s, 1.4 * s), Vector3.new(2.4 * s, 1.5 * s, -0.6 * s), Color3.fromRGB(220, 220, 220))
		smallPart("Snout", Vector3.new(1.6 * s, 0.8 * s, 1 * s), Vector3.new(0, 2.2 * s, 1.2 * s), Color3.fromRGB(40, 140, 60))
	elseif def.Accessory == "banana" then
		local banana = smallPart("Banana", Vector3.new(0.8 * s, 2.6 * s, 0.8 * s), Vector3.new(1.8 * s, 1 * s, 0.4 * s), Color3.fromRGB(255, 230, 80))
		banana.Rotation = Vector3.new(0, 0, 25)
		smallPart("BananaTip", Vector3.new(0.9 * s, 0.6 * s, 0.9 * s), Vector3.new(1.3 * s, 2.3 * s, 0.4 * s), Color3.fromRGB(120, 80, 20))
	elseif def.Accessory == "cactus" then
		smallPart("CactusTop", Vector3.new(1.4 * s, 1.6 * s, 1.4 * s), Vector3.new(0, 4 * s, 0), Color3.fromRGB(60, 160, 70))
		smallPart("SpikeL", Vector3.new(0.4 * s, 1 * s, 0.4 * s), Vector3.new(-1.2 * s, 2.6 * s, 0), Color3.fromRGB(60, 160, 70))
		smallPart("SpikeR", Vector3.new(0.4 * s, 1 * s, 0.4 * s), Vector3.new(1.2 * s, 2.6 * s, 0), Color3.fromRGB(60, 160, 70))
	elseif def.Accessory == "bignose" then
		smallPart("BigNose", Vector3.new(1.4 * s, 1.2 * s, 1.2 * s), Vector3.new(0, 2.4 * s, 1.3 * s), Color3.fromRGB(230, 170, 130), Enum.PartType.Ball)
		smallPart("Trunk", Vector3.new(0.7 * s, 1.6 * s, 0.7 * s), Vector3.new(0, 1.4 * s, 1.4 * s), Color3.fromRGB(200, 150, 110))
	elseif def.Accessory == "katana" then
		local blade = smallPart("Katana", Vector3.new(0.3 * s, 3.6 * s, 0.5 * s), Vector3.new(2 * s, 1 * s, 0), Color3.fromRGB(220, 220, 220))
		blade.Rotation = Vector3.new(0, 0, -30)
		smallPart("CupHandle", Vector3.new(1.4 * s, 0.6 * s, 0.6 * s), Vector3.new(1.2 * s, 3.8 * s, 0), Color3.fromRGB(255, 240, 220))
	end

	addTag(model, body, def.Name, def.Rarity .. "  |  pelanggan sopan", BrainrotData.RarityColors[def.Rarity] or Color3.fromRGB(255, 255, 255), 5 * s)
	return model
end

-- Mahkota emas untuk pelanggan VIP Sultan (dan Pembantu Elite).
local function addCrown(model, s)
	local crown = Instance.new("Part")
	crown.Name = "Crown"
	crown.Size = Vector3.new(1.8 * s, 0.6 * s, 1.8 * s)
	crown.Position = Vector3.new(0, 3.9 * s, 0)
	crown.Color = Color3.fromRGB(255, 200, 0)
	crown.Material = Enum.Material.Neon
	crown.Anchored = true
	crown.CanCollide = false
	crown.Parent = model
	return crown
end

local function markVip(model, def)
	addCrown(model, def.Size)
	local body = model.PrimaryPart
	local tag = body and body:FindFirstChild("Tag")
	if tag then
		for _, child in ipairs(tag:GetChildren()) do
			if child:IsA("TextLabel") then
				if child.Position.Y.Scale < 0.5 then
					child.Text = "SULTAN: " .. def.Name
				else
					child.Text = "VIP SULTAN | pelanggan sultan"
					child.TextColor3 = Color3.fromRGB(255, 210, 0)
				end
			end
		end
	end
end

local function buildEmakModel()
	local s = 1.1
	local model = Instance.new("Model")
	model.Name = "Emak-Emak"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3.2 * s, 3 * s, 2.2 * s)
	body.Color = Color3.fromRGB(255, 120, 180)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.Parent = model
	model.PrimaryPart = body
	local function smallPart(name, size, position, color, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Position = position
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		if shape then
			part.Shape = shape
		end
		part.Parent = model
		return part
	end
	smallPart("Head", Vector3.new(2.2 * s, 2 * s, 2 * s), Vector3.new(0, 2.5 * s, 0), Color3.fromRGB(255, 210, 170))
	smallPart("Bun", Vector3.new(1.4 * s, 1.2 * s, 1.4 * s), Vector3.new(0, 3.9 * s, 0), Color3.fromRGB(60, 40, 30), Enum.PartType.Ball)
	smallPart("Hair", Vector3.new(2.4 * s, 0.7 * s, 2.2 * s), Vector3.new(0, 3.5 * s, 0), Color3.fromRGB(60, 40, 30))
	local eyeL = smallPart("EyeL", Vector3.new(0.5 * s, 0.5 * s, 0.2 * s), Vector3.new(-0.5 * s, 2.7 * s, 1.05 * s), Color3.fromRGB(0, 0, 0))
	eyeL.Rotation = Vector3.new(0, 0, 25)
	local eyeR = smallPart("EyeR", Vector3.new(0.5 * s, 0.5 * s, 0.2 * s), Vector3.new(0.5 * s, 2.7 * s, 1.05 * s), Color3.fromRGB(0, 0, 0))
	eyeR.Rotation = Vector3.new(0, 0, -25)
	smallPart("Mouth", Vector3.new(0.9 * s, 0.3 * s, 0.2 * s), Vector3.new(0, 1.9 * s, 1.05 * s), Color3.fromRGB(180, 30, 30))
	smallPart("LegL", Vector3.new(0.8 * s, 1.2 * s, 0.8 * s), Vector3.new(-0.7 * s, -2 * s, 0), Color3.fromRGB(40, 40, 40))
	smallPart("LegR", Vector3.new(0.8 * s, 1.2 * s, 0.8 * s), Vector3.new(0.7 * s, -2 * s, 0), Color3.fromRGB(40, 40, 40))
	addTag(model, body, "EMAK-EMAK", "Pengganggu! Bukan pelanggan.", Color3.fromRGB(255, 80, 80), 5.5)
	-- Speech bubble + remaining-time bar (repurposed: shows timeLeft/15).
	local bubble = Instance.new("BillboardGui")
	bubble.Name = "Speech"
	bubble.Size = UDim2.new(0, 220, 0, 70)
	bubble.StudsOffset = Vector3.new(0, 8, 0)
	bubble.AlwaysOnTop = true
	bubble.Parent = body
	local phrase = Instance.new("TextLabel")
	phrase.Name = "Phrase"
	phrase.Size = UDim2.new(1, 0, 0.6, 0)
	phrase.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	phrase.Text = EMAK_PHRASES[1]
	phrase.TextScaled = true
	phrase.Font = Enum.Font.SourceSansBold
	phrase.TextColor3 = Color3.fromRGB(180, 0, 0)
	phrase.Parent = bubble
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, 0, 0.3, 0)
	barBg.Position = UDim2.new(0, 0, 0.65, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	barBg.Parent = bubble
	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
	barFill.Parent = barBg
	model:SetAttribute("HasBubble", true)
	return model
end

local function buildOrmasModel(index)
	local s = 1.2
	local model = Instance.new("Model")
	model.Name = "Oknum Ormas " .. tostring(index)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3.2 * s, 3 * s, 2.2 * s)
	body.Color = Color3.fromRGB(25, 25, 25)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.Parent = model
	model.PrimaryPart = body
	local function smallPart(name, size, position, color, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Position = position
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		if shape then
			part.Shape = shape
		end
		part.Parent = model
		return part
	end
	smallPart("Head", Vector3.new(2.2 * s, 2 * s, 2 * s), Vector3.new(0, 2.5 * s, 0), Color3.fromRGB(220, 180, 140))
	smallPart("Cap", Vector3.new(2.4 * s, 0.6 * s, 2.2 * s), Vector3.new(0, 3.6 * s, 0), Color3.fromRGB(10, 10, 10))
	smallPart("Sunglasses", Vector3.new(1.8 * s, 0.5 * s, 0.2 * s), Vector3.new(0, 2.8 * s, 1.05 * s), Color3.fromRGB(0, 0, 0))
	smallPart("LegL", Vector3.new(0.8 * s, 1.2 * s, 0.8 * s), Vector3.new(-0.7 * s, -2 * s, 0), Color3.fromRGB(20, 20, 20))
	smallPart("LegR", Vector3.new(0.8 * s, 1.2 * s, 0.8 * s), Vector3.new(0.7 * s, -2 * s, 0), Color3.fromRGB(20, 20, 20))
	addTag(model, body, "OKNUM ORMAS", "Uang keamanan, bos!", Color3.fromRGB(255, 80, 80), 5.5)
	return model
end

local function buildGuardModel()
	local s = 1.2
	local model = Instance.new("Model")
	model.Name = "Satpam Brainrot"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3.2 * s, 3 * s, 2.2 * s)
	body.Color = Color3.fromRGB(40, 90, 200)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.Parent = model
	model.PrimaryPart = body
	local function smallPart(name, size, position, color, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Position = position
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		if shape then
			part.Shape = shape
		end
		part.Parent = model
		return part
	end
	smallPart("Head", Vector3.new(2.2 * s, 2 * s, 2 * s), Vector3.new(0, 2.5 * s, 0), Color3.fromRGB(255, 210, 170))
	smallPart("Cap", Vector3.new(2.4 * s, 0.6 * s, 2.2 * s), Vector3.new(0, 3.6 * s, 0), Color3.fromRGB(20, 40, 120))
	smallPart("Badge", Vector3.new(0.8 * s, 0.8 * s, 0.2 * s), Vector3.new(-0.7 * s, 0.6 * s, 1.15 * s), Color3.fromRGB(255, 210, 0))
	smallPart("EyeL", Vector3.new(0.5 * s, 0.6 * s, 0.2 * s), Vector3.new(-0.5 * s, 2.7 * s, 1.05 * s), Color3.fromRGB(0, 0, 0))
	smallPart("EyeR", Vector3.new(0.5 * s, 0.6 * s, 0.2 * s), Vector3.new(0.5 * s, 2.7 * s, 1.05 * s), Color3.fromRGB(0, 0, 0))
	smallPart("LegL", Vector3.new(0.8 * s, 1.2 * s, 0.8 * s), Vector3.new(-0.7 * s, -2 * s, 0), Color3.fromRGB(20, 20, 40))
	smallPart("LegR", Vector3.new(0.8 * s, 1.2 * s, 0.8 * s), Vector3.new(0.7 * s, -2 * s, 0), Color3.fromRGB(20, 20, 40))
	addTag(model, body, "SATPAM BRAINROT", "Aman terkendali.", Color3.fromRGB(120, 255, 120), 5.5)
	return model
end

-- Kasir Pembantu Brainrot: mini Tung Tung yang auto-scan.
local helperModel = nil

local function spawnHelperModel(isElite)
	local base = BrainrotData.List[1]
	local mini = {}
	for k, v in pairs(base) do
		mini[k] = v
	end
	mini.Name = isElite and "Pembantu Elite" or "Pembantu Brainrot"
	mini.Size = 0.7
	local model = buildBrainrotModel(mini)
	model.Name = isElite and "Kasir Pembantu Elite" or "Kasir Pembantu"
	if isElite then
		addCrown(model, 0.7)
	end
	model:PivotTo(CFrame.new(isElite and 8 or -8, PIVOT_Y, -14))
	model.Parent = Workspace
	return model
end

-- ---------------------------------------------------------------------------
-- Queue / customers
-- ---------------------------------------------------------------------------

local function queueSlot(index)
	if index <= #QUEUE_Z then
		return Vector3.new(0, PIVOT_Y, QUEUE_Z[index])
	end
	-- Perluas Toko: lanjutkan pola 4 stud ke arah pintu.
	return Vector3.new(0, PIVOT_Y, QUEUE_Z[#QUEUE_Z] + (index - #QUEUE_Z) * 4)
end

local function retargetQueue()
	for i, entry in ipairs(customers) do
		if entry.state == "queue" then
			entry.target = queueSlot(i)
		end
	end
end

local function removeCustomer(entry)
	for i, item in ipairs(customers) do
		if item == entry then
			table.remove(customers, i)
			break
		end
	end
	if entry.model and entry.model.Parent then
		entry.model:Destroy()
	end
	retargetQueue()
	updateState()
end

-- VIP Sultan hanya memesan produk Sultan (emas, 3x); pelanggan
-- biasa hanya memesan produk biasa (+ produk Hypermart kalau
-- World 2 sudah dibuka). Kalau stok Sultan habis, VIP memesan
-- produk biasa supaya tidak pulang dengan tangan kosong.
local function makeOrder(isVip)
	local function pool(wantSultan)
		local list = {}
		for _, def in ipairs(Products.List) do
			if unlocked[def.Name] and (stock[def.Name] or 0) > 0 and (def.IsSultan == true) == wantSultan then
				table.insert(list, def)
			end
		end
		return list
	end
	local available = {}
	if isVip then
		available = pool(true)
		if #available == 0 then
			available = pool(false)
		end
	else
		available = pool(false)
	end
	if #available == 0 then
		return nil, 0
	end
	local order = {}
	local total = 0
	local n = math.random(1, 3)
	for _ = 1, n do
		local def = available[math.random(1, #available)]
		table.insert(order, def.Name)
		total += def.Price
	end
	return order, total
end

local function setOrderBubble(entry)
	local body = entry.model and entry.model.PrimaryPart
	if not body then
		return
	end
	local tag = body:FindFirstChild("Tag")
	if not tag then
		return
	end
	local sub = tag:FindFirstChildOfClass("TextLabel")
	if sub then
		-- The second label is the sub-label; find it by position instead.
		for _, child in ipairs(tag:GetChildren()) do
			if child:IsA("TextLabel") and child.Position.Y.Scale > 0.5 then
				child.Text = table.concat(entry.order, " + ") .. " = " .. tostring(entry.total) .. "c"
			end
		end
	end
end

-- Brainrot customers only. Emak-Emak never spawns here anymore:
-- she is a standalone disruptor built by spawnEmak below.
local function spawnCustomer()
	local maxQueue = getMaxQueue()
	if #customers >= maxQueue then
		return
	end
	local def = BrainrotData.RandomDef()
	-- VIP Sultan: ~22% pelanggan, hanya kalau Menu Sultan dibuka.
	-- Dia pakai mahkota emas dan hanya memesan produk Sultan.
	local isVip = sultanUnlocked and math.random() <= VIP_CHANCE
	local model = buildBrainrotModel(def)
	if isVip then
		markVip(model, def)
	end
	local order, total = makeOrder(isVip)
	if not order then
		model:Destroy()
		return
	end
	model:PivotTo(CFrame.new(0, PIVOT_Y, 26))
	model.Parent = Workspace

	local entry = {
		def = def,
		model = model,
		kind = isVip and "vip" or "brainrot",
		isVip = isVip,
		order = order,
		total = total,
		state = "queue",
		target = Vector3.new(0, PIVOT_Y, 26),
		speed = 6,
	}
	table.insert(customers, entry)
	retargetQueue()
	setOrderBubble(entry)

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 32
	click.Parent = model.PrimaryPart
	click.MouseClick:Connect(function(player)
		scanEvent:FireServer()
	end)
	updateState()
end

local function sendLeaving(entry)
	entry.state = "leaving"
	entry.target = OUTSIDE_POS
	entry.speed = 7
end

-- ---------------------------------------------------------------------------
-- Demo (stock-out protest)
-- ---------------------------------------------------------------------------

startDemo = function()
	if demoActive then
		return
	end
	demoActive = true
	notifyAll("STOK HABIS! Pelanggan brainrot demo damai di dalam toko!")
	local spots = {
		Vector3.new(-14, PIVOT_Y, 2),
		Vector3.new(-5, PIVOT_Y, 6),
		Vector3.new(5, PIVOT_Y, 2),
		Vector3.new(14, PIVOT_Y, 6),
	}
	local protestCount = 0
	while #customers > 0 do
		local entry = customers[1]
		table.remove(customers, 1)
		if entry.state == "leaving" then
			-- Already served and walking out: keep walking out, do
			-- not drag them back in as a protester.
			table.insert(protesters, entry)
		elseif protestCount < 4 then
			protestCount += 1
			entry.state = "protesting"
			entry.target = spots[protestCount]
			entry.speed = 5
			local body = entry.model.PrimaryPart
			if body then
				local signPart = Instance.new("Part")
				signPart.Name = "ProtestSign"
				signPart.Size = Vector3.new(3.4, 2, 0.2)
				signPart.Position = Vector3.new(0, 1.5, 1.6)
				signPart.Color = Color3.fromRGB(255, 255, 255)
				signPart.Material = Enum.Material.SmoothPlastic
				signPart.Anchored = true
				signPart.CanCollide = false
				signPart.Parent = entry.model
				local gui = Instance.new("SurfaceGui")
				gui.Face = Enum.NormalId.Front
				gui.Parent = signPart
				local label = Instance.new("TextLabel")
				label.Size = UDim2.fromScale(1, 1)
				label.BackgroundTransparency = 1
				label.Text = PROTEST_SIGNS[((protestCount - 1) % #PROTEST_SIGNS) + 1]
				label.TextScaled = true
				label.Font = Enum.Font.SourceSansBold
				label.TextColor3 = Color3.fromRGB(180, 0, 0)
				label.Parent = gui
			end
			table.insert(protesters, entry)
		else
			sendLeaving(entry)
			-- Leaving customers stay tracked in protesters until the
			-- heartbeat walks them out and despawns them.
			table.insert(protesters, entry)
		end
	end
	scanning = false
	updateState()
end

endDemo = function()
	if not demoActive then
		return
	end
	demoActive = false
	for _, entry in ipairs(protesters) do
		if entry.state == "protesting" then
			sendLeaving(entry)
		end
	end
	-- Do NOT clear protesters here: the heartbeat walks the leavers
	-- out and despawns them, removing them from the list as they go.
	notifyAll("Stok kembali! Demo bubar, pelanggan kembali antre.")
	updateState()
end

checkDemo = function()
	if getTotalStock() <= 0 and not demoActive then
		startDemo()
	elseif getTotalStock() > 0 and demoActive then
		-- Protesters only leave via endDemo once stock is really back.
		endDemo()
	end
end

-- ---------------------------------------------------------------------------
-- Threats: Emak-Emak and Oknum Ormas
-- ---------------------------------------------------------------------------

-- Emak-Emak, reworked: a standalone disruptor, never a customer.
-- Phase 1 "pacing" (5s): walks back and forth along the queue at
-- X=+3, shoving the frontmost queued brainrot one slot back every
-- ~1.5s (swap with the one behind; order and total are kept).
-- Phase 2 "jamming" (10s): stands beside the counter (X=8, Z=-14)
-- and makes scans take twice as long. No stock or reputation
-- penalty, ever. She leaves on her own after 15s total. There is
-- no voucher anymore (removed in v6).

local EMAK_PACING_TIME = 5
local EMAK_JAM_TIME = 10

local function dismissEmak(reason)
	if not emak then
		return
	end
	local gone = emak
	emak = nil
	notifyAll(reason)
	-- Walk out through the glass door; the heartbeat walks this
	-- model out and despawns it.
	if emakLeaving and emakLeaving.model and emakLeaving.model.Parent then
		emakLeaving.model:Destroy()
	end
	emakLeaving = { model = gone.model, target = OUTSIDE_POS, speed = 7 }
	updateState()
end

local function pushQueueBack()
	-- First brainrot still waiting in line (not at the counter).
	local i = nil
	for index, entry in ipairs(customers) do
		if entry.state == "queue" then
			i = index
			break
		end
	end
	if not i then
		return
	end
	local nextEntry = customers[i + 1]
	if not nextEntry or nextEntry.state ~= "queue" then
		-- Nobody behind to swap with: nothing to shove.
		return
	end
	local shoved = customers[i]
	customers[i] = nextEntry
	customers[i + 1] = shoved
	retargetQueue()
	notifyAll("Emak-Emak mendorong " .. shoved.def.Name .. " mundur!")
	updateState()
end

local function spawnEmak()
	if emak then
		return
	end
	if demoActive then
		-- Never spawn during a protest: the truck mini-game is
		-- chaotic enough without her.
		return
	end
	local model = buildEmakModel()
	model:PivotTo(CFrame.new(DOOR_POS))
	model.Parent = Workspace
	emak = {
		model = model,
		phase = "pacing",
		timeLeft = EMAK_PACING_TIME + getEmakJamTime(),
		totalTime = EMAK_PACING_TIME + getEmakJamTime(),
		phaseTimeLeft = EMAK_PACING_TIME,
		pushAccum = 0,
		target = Vector3.new(3, PIVOT_Y, -8),
		speed = 6,
	}
	notifyAll("Emak-Emak datang mondar-mandir di antrean! Awas, dia dorong pelanggan mundur!")
	updateState()
end

local function dismissOrmas(reason)
	if not ormas then
		return
	end
	for _, m in ipairs(ormas.models) do
		if m and m.Parent then
			-- They storm out off-screen: vanish after a short delay.
			task.delay(6, function()
				if m.Parent then
					m:Destroy()
				end
			end)
		end
	end
	notifyAll(reason)
	ormas = nil
	updateState()
end

local function ormasTimeout()
	if not ormas then
		return
	end
	-- Demo doubles the penalties first; Brankas then halves them.
	local repPenalty = demoActive and 40 or 20
	local coinPenalty = demoActive and 100 or 50
	if safeOwned then
		repPenalty = math.floor(repPenalty / 2)
		coinPenalty = math.floor(coinPenalty / 2)
	end
	setReputation(reputation - repPenalty)
	for _, player in ipairs(Players:GetPlayers()) do
		addCoins(player, -coinPenalty)
	end
	notifyAll("Ormas mengacak-acak toko! Reputasi -" .. tostring(repPenalty) .. ", uang -" .. tostring(coinPenalty) .. "c!")
	dismissOrmas("Ormas pergi setelah mengacak-acak toko.")
	checkDemo()
end

local function spawnOrmas()
	if ormas then
		return
	end
	local m1 = buildOrmasModel(1)
	m1:PivotTo(CFrame.new(-3, PIVOT_Y, -13))
	m1.Parent = Workspace
	local m2 = buildOrmasModel(2)
	m2:PivotTo(CFrame.new(3, PIVOT_Y, -13))
	m2.Parent = Workspace
	ormas = { models = { m1, m2 }, timer = 25, securityTimer = 0, eliteTimer = 0 }
	if hasSecurity then
		notifyAll("Ormas datang! Satpam brainrot sudah siaga, mereka pergi sendiri 5 detik lagi.")
	else
		notifyAll("Oknum Ormas datang! 'Uang keamanan, bos!'")
	end
	updateState()
end

-- ---------------------------------------------------------------------------
-- World 2: Brainrot Hypermart
-- ---------------------------------------------------------------------------
-- Jujur soal implementasi (v6): Hypermart TIDAK pakai teleport ke map
-- lain — itu terlalu berisiko untuk sistem antre/scan yang sudah
-- jalan. Hypermart adalah ekspansi di area yang sama: begitu Perluas
-- Toko mencapai Lv5, tombol "Buka Hypermart (World 2)" muncul
-- (gratis). Membukanya membangun papan Hypermart, 4 freezer
-- Hypermart di dinding belakang, dan poster 4 produk baru, lalu
-- produk Hypermart masuk ke pool pesanan pelanggan biasa. Antrean,
-- scan, stok, Emak, Ormas, dan demo tetap memakai sistem yang sama.

local function buildHypermart()
	local sign = makePart("HypermartSign", Vector3.new(30, 4, 0.6), Vector3.new(0, 12, -19.4), Color3.fromRGB(140, 60, 220), Enum.Material.Neon)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Back
	signGui.Parent = sign
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "BRAINROT HYPERMART - WORLD 2"
	signText.TextScaled = true
	signText.Font = Enum.Font.SourceSansBold
	signText.TextColor3 = Color3.fromRGB(255, 210, 0)
	signText.Parent = signGui
	-- 4 freezer Hypermart di dinding belakang.
	for _, x in ipairs({ -20, -12, 12, 20 }) do
		local freezer = makePart("FreezerHypermart", Vector3.new(3, 3, 4), Vector3.new(x, 3, -17.5), Color3.fromRGB(160, 90, 220), Enum.Material.SmoothPlastic)
		local lid = makePart("FreezerHypermartLid", Vector3.new(3.2, 0.5, 4.2), Vector3.new(x, 4.7, -17.5), Color3.fromRGB(200, 140, 255), Enum.Material.SmoothPlastic)
		lid.CanCollide = false
		table.insert(freezerPositions, freezer.Position)
		local click = Instance.new("ClickDetector")
		click.MaxActivationDistance = 32
		click.Parent = freezer
		click.MouseClick:Connect(function(player)
			deliverBox(player)
		end)
	end
	-- Poster 4 produk Hypermart di dinding belakang.
	local function backPoster(text, x, color)
		local board = makePart("PosterHypermart", Vector3.new(5, 2.5, 0.5), Vector3.new(x, 6.5, -19.4), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Back
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = color
		label.BackgroundTransparency = 0.2
		label.Text = text
		label.TextScaled = true
		label.Font = Enum.Font.SourceSansBold
		label.TextColor3 = Color3.fromRGB(30, 30, 30)
		label.Parent = gui
	end
	backPoster("PIZZA BEKU\n120c", -20, Products.GetByName("Pizza Beku").Color)
	backPoster("AYAM BEKU\n150c", -12, Products.GetByName("Ayam Beku").Color)
	backPoster("SEAFOOD BEKU\n200c", 12, Products.GetByName("Seafood Beku").Color)
	backPoster("WAGYU BEKU\n300c", 20, Products.GetByName("Wagyu Beku").Color)
end

-- ---------------------------------------------------------------------------
-- Supplier truck and box carrying
-- ---------------------------------------------------------------------------

local function buildTruck()
	local model = Instance.new("Model")
	model.Name = "SupplierTruck"
	local function part(name, size, position, color, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = position
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = true
		if shape then
			p.Shape = shape
		end
		p.Parent = model
		return p
	end
	part("Bed", Vector3.new(8, 1, 12), Vector3.new(14, 2.5, 30), Color3.fromRGB(220, 220, 220))
	part("Cab", Vector3.new(6, 4, 4), Vector3.new(14, 4, 21), Color3.fromRGB(255, 140, 40))
	part("Windshield", Vector3.new(5, 1.6, 0.4), Vector3.new(14, 5, 18.9), Color3.fromRGB(180, 220, 255), Enum.Material.Glass)
	for _, pos in ipairs({
		Vector3.new(10.5, 2, 20),
		Vector3.new(17.5, 2, 20),
		Vector3.new(10.5, 2, 34),
		Vector3.new(17.5, 2, 34),
	}) do
		part("Wheel", Vector3.new(1.6, 1.6, 1), pos, Color3.fromRGB(20, 20, 20), Enum.PartType.Cylinder)
	end
	model.Parent = Workspace
	return model
end

local function spawnBoxes(count)
	local boxes = {}
	for i = 1, count or 4 do
		local boxModel = Instance.new("Model")
		boxModel.Name = "Box" .. tostring(i)
		local boxPart = Instance.new("Part")
		boxPart.Name = "BoxPart"
		boxPart.Size = Vector3.new(2, 2, 2)
		boxPart.Color = Color3.fromRGB(190, 140, 80)
		boxPart.Material = Enum.Material.Wood
		boxPart.Anchored = true
		boxPart.CanCollide = false
		boxPart.Parent = boxModel
		boxModel.PrimaryPart = boxPart
		local spot = Vector3.new(12 + (i % 2) * 4, 4, 27 + math.floor((i - 1) / 2) * 4)
		boxModel:PivotTo(CFrame.new(spot))
		boxModel.Parent = Workspace
		local entry = { model = boxModel, home = spot, taken = false }
		local click = Instance.new("ClickDetector")
		click.MaxActivationDistance = 32
		click.Parent = boxPart
		click.MouseClick:Connect(function(player)
			carryBox(player)
		end)
		table.insert(boxes, entry)
	end
	return boxes
end

carryBox = function(player)
	if carrying[player] then
		notify(player, "Kamu sudah bawa kardus! Antar ke freezer dulu.")
		return
	end
	if not truck or not truck.boxes then
		notify(player, "Belum ada truk supplier.")
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local best = nil
	local bestDist = 20
	for _, box in ipairs(truck.boxes) do
		if not box.taken and box.model.Parent then
			local pos = box.model:GetPivot().Position
			local dx = pos.X - root.Position.X
			local dz = pos.Z - root.Position.Z
			local dist = math.sqrt(dx * dx + dz * dz)
			if dist < bestDist then
				bestDist = dist
				best = box
			end
		end
	end
	if not best then
		notify(player, "Dekati truk dulu untuk mengambil kardus!")
		return
	end
	best.taken = true
	carrying[player] = best
	notify(player, "Kardus di atas kepala! Bawa ke freezer, klik freezer atau tombol ANTAR.")
end

local function dropBox(player, reason)
	local box = carrying[player]
	if not box then
		return
	end
	carrying[player] = nil
	box.taken = false
	if box.model and box.model.Parent then
		box.model:PivotTo(CFrame.new(box.home))
	end
	notify(player, reason)
end

deliverBox = function(player)
	local box = carrying[player]
	if not box then
		notify(player, "Kamu tidak sedang membawa kardus.")
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local nearFreezer = false
	for _, pos in ipairs(freezerPositions) do
		local dx = pos.X - root.Position.X
		local dz = pos.Z - root.Position.Z
		if dx * dx + dz * dz < 12 * 12 then
			nearFreezer = true
			break
		end
	end
	if not nearFreezer then
		notify(player, "Dekati freezer dulu baru antar kardus!")
		return
	end
	-- Restock a random unlocked product that still has room.
	local candidates = {}
	for _, def in ipairs(Products.List) do
		if unlocked[def.Name] and (stock[def.Name] or 0) < getMaxStock() then
			table.insert(candidates, def)
		end
	end
	if #candidates == 0 then
		notify(player, "Semua freezer sudah penuh!")
		return
	end
	local def = candidates[math.random(1, #candidates)]
	local add = math.min(10, getMaxStock() - (stock[def.Name] or 0))
	stock[def.Name] = (stock[def.Name] or 0) + add
	carrying[player] = nil
	if box.model and box.model.Parent then
		box.model:Destroy()
	end
	notifyAll(player.Name .. " mengantar kardus! Stok " .. def.Name .. " +" .. tostring(add) .. ".")
	-- If every box is delivered, the truck leaves and a new one can
	-- be ordered the next time stock runs out.
	if truck and truck.boxes then
		local anyLeft = false
		for _, other in ipairs(truck.boxes) do
			if other.model and other.model.Parent then
				anyLeft = true
				break
			end
		end
		if not anyLeft then
			truckActive = false
			if truck.model and truck.model.Parent then
				truck.model:Destroy()
			end
			truck = nil
			notifyAll("Truk supplier kosong dan sudah pergi.")
		end
	end
	updateState()
	checkDemo()
end

-- ---------------------------------------------------------------------------
-- Scanning and upgrades
-- ---------------------------------------------------------------------------

local function completeScan(player, entry)
	if not entry or not entry.model or not entry.model.Parent then
		return
	end
	if customers[1] ~= entry or entry.state ~= "at_counter" then
		return
	end
	local paid = 0
	for _, itemName in ipairs(entry.order) do
		if (stock[itemName] or 0) > 0 then
			stock[itemName] -= 1
			local def = Products.GetByName(itemName)
			if def then
				paid += def.Price
			end
		end
	end
	if paid <= 0 then
		notify(player, "Stok itemnya habis! Pelanggan pergi kecewa.")
		sendLeaving(entry)
		removeCustomer(entry)
		checkDemo()
		return
	end
	addCoins(player, paid)
	local stats = player:FindFirstChild("leaderstats")
	local served = stats and stats:FindFirstChild("Dilayani")
	if served then
		served.Value += 1
	end
	notify(player, entry.def.Name .. " membayar PAS! +" .. tostring(paid) .. "c. Terima kasih, pelanggan sopan!")
	removeCustomer(entry)
	updateState()
	checkDemo()
end

scanEvent.OnServerEvent:Connect(function(player)
	if scanning then
		notify(player, "Lagi scan, tunggu sebentar...")
		return
	end
	local front = customers[1]
	if not front or front.state ~= "at_counter" then
		notify(player, "Belum ada pelanggan di kasir!")
		return
	end
	local duration = SCAN_TIMES[scannerLevel]
	if emak and emak.phase == "jamming" then
		-- Phase 2: Emak-Emak beside the counter makes scans take
		-- twice as long. Scanning is never blocked outright.
		duration = duration * 2
	end
	scanning = true
	notify(player, "Scan " .. front.def.Name .. "... (" .. tostring(duration) .. " detik)")
	task.spawn(function()
		task.wait(duration)
		scanning = false
		completeScan(player, front)
	end)
end)

buyUpgradeEvent.OnServerEvent:Connect(function(player, name)
	if name == "Scanner" then
		if scannerLevel >= 5 then
			notify(player, "Scanner sudah maksimal (Lv5)!")
			return
		end
		local cost = SCAN_COSTS[scannerLevel]
		if getCoins(player) < cost then
			notify(player, "Uang kurang! Scanner Lv" .. tostring(scannerLevel + 1) .. " butuh " .. tostring(cost) .. "c.")
			return
		end
		addCoins(player, -cost)
		scannerLevel += 1
		notifyAll(player.Name .. " upgrade scanner ke Lv" .. tostring(scannerLevel) .. "!")
	elseif name == "Security" then
		if hasSecurity then
			notify(player, "Satpam sudah disewa!")
			return
		end
		if getCoins(player) < 300 then
			notify(player, "Uang kurang! Sewa satpam butuh 300c.")
			return
		end
		addCoins(player, -300)
		hasSecurity = true
		local guard = buildGuardModel()
		guard:PivotTo(CFrame.new(8, PIVOT_Y, 16))
		guard.Parent = Workspace
		notifyAll(player.Name .. " menyewa Satpam Brainrot! Ormas bakal mikir dua kali.")
	elseif name == "Stock" then
		if stockLevel >= 3 then
			notify(player, "Kapasitas stok sudah maksimal!")
			return
		end
		if getCoins(player) < 200 then
			notify(player, "Uang kurang! Tambah stok butuh 200c.")
			return
		end
		addCoins(player, -200)
		stockLevel += 1
		notifyAll(player.Name .. " menambah kapasitas stok! Maks per produk jadi " .. tostring(getMaxStock()) .. ".")
	elseif name == "EsKrim" or name == "Dimsum" then
		-- Tombol client "EsKrim" = produk "Es Krim" di Products.
		local productName = name == "EsKrim" and "Es Krim" or name
		local def = Products.GetByName(productName)
		if not def then
			return
		end
		if unlocked[productName] then
			notify(player, productName .. " sudah dibuka!")
			return
		end
		if getCoins(player) < def.UnlockCost then
			notify(player, "Uang kurang! Buka " .. productName .. " butuh " .. tostring(def.UnlockCost) .. "c.")
			return
		end
		addCoins(player, -def.UnlockCost)
		unlocked[productName] = true
		stock[productName] = Products.StartStock
		notifyAll(player.Name .. " membuka produk baru: " .. productName .. "!")
	elseif name == "Helper" then
		if helperOwned then
			notify(player, "Kasir Pembantu sudah disewa!")
			return
		end
		if getCoins(player) < HELPER_COST then
			notify(player, "Uang kurang! Kasir Pembantu butuh " .. tostring(HELPER_COST) .. "c.")
			return
		end
		addCoins(player, -HELPER_COST)
		helperOwned = true
		helperModel = spawnHelperModel(false)
		notifyAll(player.Name .. " menyewa Kasir Pembantu Brainrot! Dia auto-scan pelanggan tiap 8 detik.")
	elseif name == "HelperElite" then
		if helperEliteOwned then
			notify(player, "Kasir Pembantu Elite sudah disewa!")
			return
		end
		if not helperOwned then
			notify(player, "Sewa Kasir Pembantu dulu!")
			return
		end
		if getCoins(player) < HELPER_ELITE_COST then
			notify(player, "Uang kurang! Kasir Pembantu Elite butuh " .. tostring(HELPER_ELITE_COST) .. "c.")
			return
		end
		addCoins(player, -HELPER_ELITE_COST)
		helperEliteOwned = true
		helperTimer = 0
		spawnHelperModel(true)
		notifyAll(player.Name .. " menyewa Kasir Pembantu Elite! Auto-scan jadi tiap 4 detik (2x lebih cepat).")
	elseif name == "Iklan" then
		if adLevel >= 3 then
			notify(player, "Iklan Neon Viral sudah maksimal (Lv3)!")
			return
		end
		if getCoins(player) < AD_COST then
			notify(player, "Uang kurang! Iklan Neon Viral Lv" .. tostring(adLevel + 1) .. " butuh " .. tostring(AD_COST) .. "c.")
			return
		end
		addCoins(player, -AD_COST)
		adLevel += 1
		notifyAll(player.Name .. " upgrade Iklan Neon Viral ke Lv" .. tostring(adLevel) .. "! Pelanggan datang lebih cepat.")
	elseif name == "TrukExpress" then
		if truckLevel >= 2 then
			notify(player, "Truk Express sudah maksimal (Lv2)!")
			return
		end
		if getCoins(player) < TRUCK_EXPRESS_COST then
			notify(player, "Uang kurang! Truk Express Lv" .. tostring(truckLevel + 1) .. " butuh " .. tostring(TRUCK_EXPRESS_COST) .. "c.")
			return
		end
		addCoins(player, -TRUCK_EXPRESS_COST)
		truckLevel += 1
		notifyAll(player.Name .. " upgrade Truk Express ke Lv" .. tostring(truckLevel) .. "! Truk datang " .. tostring(getTruckWaitTime()) .. " detik dengan " .. tostring(getTruckBoxCount()) .. " kardus.")
	elseif name == "SatpamElite" then
		if eliteOwned then
			notify(player, "Satpam Elite sudah disewa!")
			return
		end
		if not hasSecurity then
			notify(player, "Sewa satpam dulu!")
			return
		end
		if getCoins(player) < ELITE_COST then
			notify(player, "Uang kurang! Satpam Elite butuh " .. tostring(ELITE_COST) .. "c.")
			return
		end
		addCoins(player, -ELITE_COST)
		eliteOwned = true
		notifyAll(player.Name .. " menyewa Satpam Elite! Ormas langsung kabur, ganggu scan Emak jadi 5 detik.")
	elseif name == "PerluasToko" then
		if expandLevel >= 5 then
			notify(player, "Perluas Toko sudah maksimal (Lv5)!")
			return
		end
		local cost = EXPAND_COSTS[expandLevel + 1]
		if getCoins(player) < cost then
			notify(player, "Uang kurang! Perluas Toko Lv" .. tostring(expandLevel + 1) .. " butuh " .. tostring(cost) .. "c.")
			return
		end
		addCoins(player, -cost)
		expandLevel += 1
		if expandLevel >= 5 then
			notifyAll(player.Name .. " memperluas toko ke Lv5 (MAX)! Antrean muat 16 orang. HYPERMART (World 2) sudah bisa dibuka — gratis!")
		else
			notifyAll(player.Name .. " memperluas toko ke Lv" .. tostring(expandLevel) .. "! Antrean muat " .. tostring(getMaxQueue()) .. " orang.")
		end
	elseif name == "MenuSultan" then
		if sultanUnlocked then
			notify(player, "Menu Sultan sudah dibuka!")
			return
		end
		if getCoins(player) < SULTAN_COST then
			notify(player, "Uang kurang! Menu Sultan butuh " .. tostring(SULTAN_COST) .. "c.")
			return
		end
		addCoins(player, -SULTAN_COST)
		sultanUnlocked = true
		for _, def in ipairs(Products.List) do
			if def.IsSultan then
				unlocked[def.Name] = true
				stock[def.Name] = Products.StartStock
			end
		end
		notifyAll(player.Name .. " membuka MENU SULTAN! 6 produk emas harga 3x: Kentang 45c, Nugget 60c, Sosis 75c, Bakso 90c, Es Krim 120c, Dimsum 150c. Hanya VIP Sultan yang memesan!")
	elseif name == "Hypermart" then
		if hypermartOpen then
			notify(player, "Hypermart (World 2) sudah dibuka!")
			return
		end
		if expandLevel < 5 then
			notify(player, "Buka Hypermart butuh Perluas Toko Lv5 dulu! (sekarang Lv" .. tostring(expandLevel) .. ")")
			return
		end
		hypermartOpen = true
		for _, def in ipairs(Products.List) do
			if def.IsHypermart then
				unlocked[def.Name] = true
				stock[def.Name] = Products.StartStock
			end
		end
		buildHypermart()
		notifyAll(player.Name .. " MEMBUKA BRAINROT HYPERMART (World 2)! Produk baru: Pizza Beku 120c, Ayam Beku 150c, Seafood Beku 200c, Wagyu Beku 300c!")
	elseif name == "Brankas" then
		if safeOwned then
			notify(player, "Brankas sudah dibeli!")
			return
		end
		if getCoins(player) < 200 then
			notify(player, "Uang kurang! Brankas butuh 200c.")
			return
		end
		addCoins(player, -200)
		safeOwned = true
		notifyAll(player.Name .. " membeli Brankas! Penalti Ormas dipotong setengah.")
	else
		notify(player, "Upgrade tidak dikenal.")
		return
	end
	updateState()
end)

payOrmasEvent.OnServerEvent:Connect(function(player)
	if not ormas then
		notify(player, "Tidak ada Ormas di toko.")
		return
	end
	if getCoins(player) < 100 then
		notify(player, "Uang kurang! Uang keamanan 100c.")
		return
	end
	addCoins(player, -100)
	dismissOrmas(player.Name .. " membayar uang keamanan 100c. Ormas pergi.")
end)

callSecurityEvent.OnServerEvent:Connect(function(player)
	if not ormas then
		notify(player, "Tidak ada Ormas di toko.")
		return
	end
	if not hasSecurity then
		notify(player, "Belum ada satpam! Sewa satpam dulu di panel upgrade.")
		return
	end
	dismissOrmas("Satpam Brainrot datang! Ormas kabur ketakutan.")
end)

honkEvent.OnServerEvent:Connect(function(player)
	if not ormas then
		notify(player, "Tidak ada Ormas di toko.")
		return
	end
	if os.clock() < teloletCooldownUntil then
		notify(player, "Klakson telolet masih cooldown, tunggu sebentar!")
		return
	end
	teloletCooldownUntil = os.clock() + 30
	dismissOrmas("TEL-O-LET! Ormas kabur!")
end)

orderTruckEvent.OnServerEvent:Connect(function(player)
	if not demoActive and getTotalStock() > 0 then
		notify(player, "Stok masih ada, belum perlu truk supplier!")
		return
	end
	if truckActive then
		notify(player, "Truk sudah dipesan, tunggu datang!")
		return
	end
	if getCoins(player) < 80 then
		notify(player, "Uang kurang! Truk supplier butuh 80c.")
		return
	end
	addCoins(player, -80)
	truckActive = true
	local waitTime = getTruckWaitTime()
	notifyAll(player.Name .. " memesan truk supplier (80c)! Truk datang " .. tostring(waitTime) .. " detik lagi.")
	updateState()
	task.spawn(function()
		task.wait(waitTime)
		local model = buildTruck()
		local boxes = spawnBoxes(getTruckBoxCount())
		truck = { model = model, boxes = boxes }
		notifyAll("Truk supplier datang! Klik kardus untuk mengangkat, antar ke freezer!")
		updateState()
	end)
end)

carryBoxEvent.OnServerEvent:Connect(function(player)
	carryBox(player)
end)

deliverBoxEvent.OnServerEvent:Connect(function(player)
	deliverBox(player)
end)

-- ---------------------------------------------------------------------------
-- Players, movement, timers
-- ---------------------------------------------------------------------------

local function setupPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 150
	coins.Parent = leaderstats

	local served = Instance.new("IntValue")
	served.Name = "Dilayani"
	served.Value = 0
	served.Parent = leaderstats

	local rep = Instance.new("IntValue")
	rep.Name = "Reputasi"
	rep.Value = reputation
	rep.Parent = leaderstats

	task.delay(1, function()
		if player.Parent then
			notify(player, "Selamat datang di Frozen Brainrot Mart! Pelanggan sopan datang, scan pesanan mereka di kasir.")
		end
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	if carrying[player] then
		dropBox(player, "Kardus kembali ke truk.")
	end
	carrying[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

local function moveToward(entry, dt)
	if not entry.model or not entry.model.Parent then
		return false
	end
	local pos = entry.model:GetPivot().Position
	local target = entry.target
	local dx = target.X - pos.X
	local dz = target.Z - pos.Z
	local dist = math.sqrt(dx * dx + dz * dz)
	if dist < 0.6 then
		return true
	end
	local step = math.min(dist, entry.speed * dt)
	local nx = pos.X + (dx / dist) * step
	local nz = pos.Z + (dz / dist) * step
	local bob = math.sin(os.clock() * 3 + pos.X) * 0.3
	entry.model:PivotTo(CFrame.new(nx, PIVOT_Y + bob, nz))
	return false
end

RunService.Heartbeat:Connect(function(dt)
	-- Customers: walk to queue slot, then to the counter, then out.
	for i = #customers, 1, -1 do
		local entry = customers[i]
		if not entry.model or not entry.model.Parent then
			table.remove(customers, i)
		elseif entry.state == "queue" or entry.state == "to_counter" or entry.state == "leaving" then
			local arrived = moveToward(entry, dt)
			if arrived and entry.state == "leaving" then
				table.remove(customers, i)
				entry.model:Destroy()
			elseif arrived and entry.state == "queue" and i == 1 then
				-- Front of the queue steps up to the counter.
				if #protesters == 0 then
					entry.state = "to_counter"
					entry.target = COUNTER_POS
				end
			elseif arrived and entry.state == "to_counter" then
				entry.state = "at_counter"
				setOrderBubble(entry)
				updateState()
			end
		end
	end
	-- Emak-Emak: phase 1 paces along the queue, phase 2 stands by
	-- the counter jamming scans. She is not in customers.
	if emak and emak.model and emak.model.Parent then
		if emak.phase == "pacing" then
			local arrived = moveToward(emak, dt)
			if arrived then
				-- Turn around: walk back the other way along the queue.
				emak.target = Vector3.new(3, PIVOT_Y, -emak.target.Z)
			end
			emak.pushAccum += dt
			if emak.pushAccum >= 1.5 then
				emak.pushAccum = 0
				pushQueueBack()
			end
		elseif emak.phase == "jamming" then
			moveToward(emak, dt)
		end
	end
	-- A dismissed Emak-Emak walks out the door and despawns.
	if emakLeaving then
		if not emakLeaving.model or not emakLeaving.model.Parent then
			emakLeaving = nil
		else
			local arrived = moveToward(emakLeaving, dt)
			if arrived then
				emakLeaving.model:Destroy()
				emakLeaving = nil
			end
		end
	end
	-- Protesters stand (and bob) with their signs; leavers walk out.
	for i = #protesters, 1, -1 do
		local entry = protesters[i]
		if not entry.model or not entry.model.Parent then
			table.remove(protesters, i)
		elseif entry.state == "leaving" then
			local arrived = moveToward(entry, dt)
			if arrived then
				table.remove(protesters, i)
				entry.model:Destroy()
			end
		elseif entry.state == "protesting" then
			local pos = entry.model:GetPivot().Position
			local bob = math.sin(os.clock() * 2 + pos.X) * 0.2
			entry.model:PivotTo(CFrame.new(pos.X, PIVOT_Y + bob, pos.Z))
		end
	end
	-- Carried boxes ride above the carrier's head.
	for player, box in pairs(carrying) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and box.model and box.model.Parent then
			box.model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 4.5, 0)))
		end
	end
	-- A carried box drops if a threat bumps into the carrier.
	for player, box in pairs(carrying) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local dropped = false
			if emak and emak.model and emak.model.Parent then
				local pos = emak.model:GetPivot().Position
				local dx = pos.X - root.Position.X
				local dz = pos.Z - root.Position.Z
				if dx * dx + dz * dz < 16 then
					dropped = true
				end
			end
			if not dropped and ormas then
				for _, m in ipairs(ormas.models) do
					if m and m.Parent then
						local pos = m:GetPivot().Position
						local dx = pos.X - root.Position.X
						local dz = pos.Z - root.Position.Z
						if dx * dx + dz * dz < 16 then
							dropped = true
							break
						end
					end
				end
			end
			if dropped then
				dropBox(player, "Kardus jatuh! Emak/Ormas menyenggolmu, kardus kembali ke truk.")
			end
		end
	end
end)

-- The 1-second clocks: shift timer, Emak-Emak phases, Ormas timer.
-- No cashier wage anymore: money comes only from sales.
task.spawn(function()
	while true do
		task.wait(1)
		shiftTime.Value -= 1
		if shiftTime.Value <= 0 then
			local best = nil
			local bestServed = -1
			for _, player in ipairs(Players:GetPlayers()) do
				local stats = player:FindFirstChild("leaderstats")
				local served = stats and stats:FindFirstChild("Dilayani")
				if served and served.Value > bestServed then
					bestServed = served.Value
					best = player
				end
			end
			if best then
				notifyAll("Shift selesai! Kasir terbaik: " .. best.Name .. " (" .. tostring(bestServed) .. " pelanggan dilayani)!")
			else
				notifyAll("Shift selesai! Tidak ada pelanggan yang dilayani.")
			end
			shiftTime.Value = SHIFT_LENGTH
		end
		-- Kasir Pembantu: auto-scan tiap 8 detik (tiap 4 detik kalau
		-- sudah Elite); pause saat demo, saat scan manual berjalan,
		-- atau saat Emak fase 2.
		if helperOwned then
			local blocked = scanning or demoActive or (emak and emak.phase == "jamming")
			if not blocked then
				helperTimer += 1
				if helperTimer >= getHelperInterval() then
					local front = customers[1]
					local firstPlayer = Players:GetPlayers()[1]
					if firstPlayer and front and front.state == "at_counter" then
						helperTimer = 0
						completeScan(firstPlayer, front)
					end
				end
			end
		end
		if emak then
			emak.timeLeft -= 1
			emak.phaseTimeLeft -= 1
			local body = emak.model and emak.model.PrimaryPart
			if body then
				local bubble = body:FindFirstChild("Speech")
				if bubble then
					local phrase = bubble:FindFirstChild("Phrase")
					if phrase then
						phrase.Text = EMAK_PHRASES[((emak.totalTime or 15) - emak.timeLeft) % #EMAK_PHRASES + 1]
					end
					local barBg = bubble:FindFirstChild("BarBg")
					local barFill = barBg and barBg:FindFirstChild("BarFill")
					if barFill then
						barFill.Size = UDim2.new(math.max(0, emak.timeLeft) / (emak.totalTime or 15), 0, 1, 0)
					end
				end
			end
			if emak.phaseTimeLeft <= 0 then
				if emak.phase == "pacing" then
					emak.phase = "jamming"
					emak.phaseTimeLeft = getEmakJamTime()
					emak.target = Vector3.new(8, PIVOT_Y, -14)
					emak.speed = 6
					notifyAll("Emak-Emak ganggu scan! Scan jadi 2x lebih lama (" .. tostring(getEmakJamTime()) .. " detik)!")
				else
					-- 15 seconds are up: she leaves on her own,
					-- with no penalty at all.
					dismissEmak("Emak-Emak pergi sendiri. Scan kembali normal!")
				end
			end
		end
		if ormas then
			if eliteOwned then
				ormas.eliteTimer = (ormas.eliteTimer or 0) + 1
				if ormas.eliteTimer >= 2 then
					dismissOrmas("Satpam Elite mengusir Ormas seketika! Toko aman.")
				end
			end
			if ormas then
				ormas.timer -= 1
				if hasSecurity then
					ormas.securityTimer += 1
					if ormas.securityTimer >= 5 then
						dismissOrmas("Satpam Brainrot mengusir Ormas! Toko aman.")
					end
				end
				if ormas and ormas.timer <= 0 then
					ormasTimeout()
				end
			end
		end
		updateState()
	end
end)

-- Spawners.
task.spawn(function()
	while true do
		task.wait(math.random(6, 10) * (0.85 ^ adLevel))
		if not demoActive then
			spawnCustomer()
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(math.random(50, 80))
		spawnEmak()
	end
end)

task.spawn(function()
	while true do
		task.wait(math.random(70, 110))
		spawnOrmas()
	end
end)

buildWorld()
updateState()
print("Frozen Brainrot Mart v6 started: shop, queue, threats, demo, truck and Hypermart running.")
