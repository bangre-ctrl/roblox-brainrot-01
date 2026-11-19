-- Brainrot Collector client UI.
-- Top bar (coins / brainrots / income / round timer), shop panel on the
-- right with one buy button per brainrot, a start screen, notifications
-- and a small live leaderboard. Movement is the normal Roblox character.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local buyEvent = ReplicatedStorage:WaitForChild("BuyBrainrot")
local notifyEvent = ReplicatedStorage:WaitForChild("Notify")
local roundTime = ReplicatedStorage:WaitForChild("RoundTime")

local playerGui = player:WaitForChild("PlayerGui")
local leaderstats = player:WaitForChild("leaderstats")
local coinsValue = leaderstats:WaitForChild("Coins")
local brainrotsValue = leaderstats:WaitForChild("Brainrots")
local incomeValue = leaderstats:WaitForChild("Income")

local gui = Instance.new("ScreenGui")
gui.Name = "GameGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function label(parent, name, text, size, position, textSize, color)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = position
	l.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	l.BackgroundTransparency = 0.4
	l.Text = text
	l.TextSize = textSize
	l.Font = Enum.Font.SourceSansBold
	l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	l.TextScaled = false
	l.Parent = parent
	return l
end

-- Top bar.
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 44)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topBar.BackgroundTransparency = 0.2
topBar.BorderSizePixel = 0
topBar.Parent = gui

local coinsLabel = label(topBar, "Coins", "Coins: 100", UDim2.new(0, 180, 1, 0), UDim2.new(0, 10, 0, 0), 20, Color3.fromRGB(255, 210, 0))
local brainrotsLabel = label(topBar, "Brainrots", "Brainrots: 0", UDim2.new(0, 180, 1, 0), UDim2.new(0, 200, 0, 0), 20)
local incomeLabel = label(topBar, "Income", "+0 / sec", UDim2.new(0, 160, 1, 0), UDim2.new(0, 390, 0, 0), 20, Color3.fromRGB(120, 255, 120))
local timerLabel = label(topBar, "Timer", "Round: 5:00", UDim2.new(0, 160, 1, 0), UDim2.new(1, -170, 0, 0), 20)

local function refreshStats()
	coinsLabel.Text = "Coins: " .. tostring(coinsValue.Value)
	brainrotsLabel.Text = "Brainrots: " .. tostring(brainrotsValue.Value)
	incomeLabel.Text = "+" .. tostring(incomeValue.Value) .. " / sec"
end
coinsValue.Changed:Connect(refreshStats)
brainrotsValue.Changed:Connect(refreshStats)
incomeValue.Changed:Connect(refreshStats)
refreshStats()

local function refreshTimer()
	local t = roundTime.Value
	local mins = math.floor(t / 60)
	local secs = t % 60
	timerLabel.Text = string.format("Round: %d:%02d", mins, secs)
end
roundTime.Changed:Connect(refreshTimer)
refreshTimer()

-- Notification toast.
local toast = label(gui, "Toast", "", UDim2.new(0, 500, 0, 40), UDim2.new(0.5, -250, 0, 54), 20)
toast.BackgroundTransparency = 0.4
toast.Visible = false
notifyEvent.OnClientEvent:Connect(function(text)
	toast.Text = text
	toast.Visible = true
	task.delay(4, function()
		toast.Visible = false
	end)
end)

-- Shop panel.
local shop = Instance.new("Frame")
shop.Name = "Shop"
shop.Size = UDim2.new(0, 260, 0, 420)
shop.Position = UDim2.new(1, -270, 0, 60)
shop.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
shop.BackgroundTransparency = 0.2
shop.BorderSizePixel = 0
shop.Parent = gui

label(shop, "ShopTitle", "BRAINROT SHOP", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 0), 22, Color3.fromRGB(255, 210, 0))

local shopList = Instance.new("ScrollingFrame")
shopList.Name = "ShopList"
shopList.Size = UDim2.new(1, -10, 1, -46)
shopList.Position = UDim2.new(0, 5, 0, 41)
shopList.BackgroundTransparency = 1
shopList.ScrollBarThickness = 6
shopList.CanvasSize = UDim2.new(0, 0, 0, #BrainrotData.List * 62)
shopList.Parent = shop

for i, def in ipairs(BrainrotData.List) do
	local row = Instance.new("Frame")
	row.Name = def.Name
	row.Size = UDim2.new(1, -6, 0, 56)
	row.Position = UDim2.new(0, 3, 0, (i - 1) * 62)
	row.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	row.BackgroundTransparency = 0.2
	row.BorderSizePixel = 0
	row.Parent = shopList

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -80, 0, 26)
	nameLabel.Position = UDim2.new(0, 8, 0, 2)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.Name
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, -80, 0, 22)
	infoLabel.Position = UDim2.new(0, 8, 0, 28)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = def.Rarity .. "  |  +" .. tostring(def.Income) .. "/sec"
	infoLabel.TextSize = 14
	infoLabel.Font = Enum.Font.SourceSans
	infoLabel.TextColor3 = BrainrotData.RarityColors[def.Rarity] or Color3.fromRGB(255, 255, 255)
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = row

	local buyButton = Instance.new("TextButton")
	buyButton.Name = "Buy"
	buyButton.Size = UDim2.new(0, 64, 0, 36)
	buyButton.Position = UDim2.new(1, -72, 0, 10)
	buyButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	buyButton.Text = tostring(def.Cost) .. " c"
	buyButton.TextSize = 16
	buyButton.Font = Enum.Font.SourceSansBold
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.Parent = row
	buyButton.MouseButton1Click:Connect(function()
		buyEvent:FireServer(def.Name)
	end)
end

-- Live leaderboard (top 5 by coins).
local board = Instance.new("Frame")
board.Name = "Leaderboard"
board.Size = UDim2.new(0, 200, 0, 170)
board.Position = UDim2.new(0, 10, 0, 60)
board.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
board.BackgroundTransparency = 0.2
board.BorderSizePixel = 0
board.Parent = gui

label(board, "BoardTitle", "TOP PLAYERS", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 18, Color3.fromRGB(255, 210, 0))
local boardText = label(board, "BoardText", "", UDim2.new(1, -10, 1, -36), UDim2.new(0, 5, 0, 33), 15)
boardText.BackgroundTransparency = 1
boardText.TextYAlignment = Enum.TextYAlignment.Top
boardText.TextXAlignment = Enum.TextXAlignment.Left

local function refreshBoard()
	local rows = {}
	for _, other in ipairs(Players:GetPlayers()) do
		local stats = other:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		table.insert(rows, { name = other.Name, coins = coins and coins.Value or 0 })
	end
	table.sort(rows, function(a, b)
		return a.coins > b.coins
	end)
	local lines = {}
	for i = 1, math.min(5, #rows) do
		table.insert(lines, tostring(i) .. ". " .. rows[i].name .. " - " .. tostring(rows[i].coins) .. "c")
	end
	boardText.Text = table.concat(lines, "\n")
end
task.spawn(function()
	while true do
		refreshBoard()
		task.wait(2)
	end
end)

-- Start screen.
local startScreen = Instance.new("Frame")
startScreen.Name = "StartScreen"
startScreen.Size = UDim2.fromScale(1, 1)
startScreen.BackgroundColor3 = Color3.fromRGB(20, 40, 20)
startScreen.BackgroundTransparency = 0.1
startScreen.Parent = gui

local title = label(startScreen, "Title", "BRAINROT COLLECTOR", UDim2.new(0, 500, 0, 60), UDim2.new(0.5, -250, 0, 120), 40, Color3.fromRGB(255, 210, 0))
title.BackgroundTransparency = 1
local how = label(startScreen, "How", "Click wild brainrots to collect coins.\nBuy brainrot followers in the shop.\nFollowers earn coins every second.\nMost brainrots at the end of the round wins!", UDim2.new(0, 500, 0, 140), UDim2.new(0.5, -250, 0, 200), 20)
how.BackgroundTransparency = 1

local playButton = Instance.new("TextButton")
playButton.Name = "Play"
playButton.Size = UDim2.new(0, 200, 0, 60)
playButton.Position = UDim2.new(0.5, -100, 0, 360)
playButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
playButton.Text = "PLAY"
playButton.TextSize = 28
playButton.Font = Enum.Font.SourceSansBold
playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playButton.Parent = startScreen
playButton.MouseButton1Click:Connect(function()
	startScreen.Visible = false
end)

print("Brainrot Collector client UI ready.")
