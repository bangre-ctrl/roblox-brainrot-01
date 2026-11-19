-- Frozen Brainrot Mart client UI.
-- Top bar (coins / reputation / stock / served / shift timer), left
-- panel (order at the counter, threat warning, stock list), right
-- panel (upgrades), bottom action bar (SCAN, ormas actions,
-- truck, carry/deliver), scan progress bar, toasts and a start screen.
-- All text is Bahasa Indonesia. Movement is the normal Roblox
-- character; the player stands behind the counter and scans.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local scanEvent = ReplicatedStorage:WaitForChild("ScanCustomer")
local buyUpgradeEvent = ReplicatedStorage:WaitForChild("BuyUpgrade")
local payOrmasEvent = ReplicatedStorage:WaitForChild("PayOrmas")
local callSecurityEvent = ReplicatedStorage:WaitForChild("CallSecurity")
local honkEvent = ReplicatedStorage:WaitForChild("HonkTelolet")
local orderTruckEvent = ReplicatedStorage:WaitForChild("OrderTruck")
local carryBoxEvent = ReplicatedStorage:WaitForChild("CarryBox")
local deliverBoxEvent = ReplicatedStorage:WaitForChild("DeliverBox")
local notifyEvent = ReplicatedStorage:WaitForChild("Notify")

local shiftTime = ReplicatedStorage:WaitForChild("ShiftTime")
local totalStockValue = ReplicatedStorage:WaitForChild("TotalStock")
local threatTypeValue = ReplicatedStorage:WaitForChild("ThreatType")
local threatTimerValue = ReplicatedStorage:WaitForChild("ThreatTimer")
local emakPhaseValue = ReplicatedStorage:WaitForChild("EmakPhase")
local demoValue = ReplicatedStorage:WaitForChild("DemoMode")
local scannerLevelValue = ReplicatedStorage:WaitForChild("ScannerLevel")
local hasSecurityValue = ReplicatedStorage:WaitForChild("HasSecurity")
local stockLevelValue = ReplicatedStorage:WaitForChild("StockLevel")
local stockStateValue = ReplicatedStorage:WaitForChild("StockState")
local frontOrderValue = ReplicatedStorage:WaitForChild("FrontOrder")
local truckActiveValue = ReplicatedStorage:WaitForChild("TruckActive")
local unlockedStateValue = ReplicatedStorage:WaitForChild("UnlockedState")
local helperOwnedValue = ReplicatedStorage:WaitForChild("HelperOwned")
local adLevelValue = ReplicatedStorage:WaitForChild("AdLevel")
local truckLevelValue = ReplicatedStorage:WaitForChild("TruckLevel")
local eliteOwnedValue = ReplicatedStorage:WaitForChild("EliteOwned")
local expandOwnedValue = ReplicatedStorage:WaitForChild("ExpandOwned")
local sultanUnlockedValue = ReplicatedStorage:WaitForChild("SultanUnlocked")
local safeOwnedValue = ReplicatedStorage:WaitForChild("SafeOwned")
local helperEliteOwnedValue = ReplicatedStorage:WaitForChild("HelperEliteOwned")
local expandLevelValue = ReplicatedStorage:WaitForChild("ExpandLevel")
local hypermartOpenValue = ReplicatedStorage:WaitForChild("HypermartOpen")

local playerGui = player:WaitForChild("PlayerGui")
local leaderstats = player:WaitForChild("leaderstats")
local coinsValue = leaderstats:WaitForChild("Coins")
local servedValue = leaderstats:WaitForChild("Dilayani")
local repValue = leaderstats:WaitForChild("Reputasi")

local SCAN_TIMES = { 3, 2.2, 1.6, 1.1, 0.7 }
local SCAN_COSTS = { 150, 350, 700, 1200 }

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
	l.TextWrapped = true
	l.Parent = parent
	return l
end

local function button(parent, name, text, size, position, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = size
	b.Position = position
	b.BackgroundColor3 = color
	b.Text = text
	b.TextSize = 16
	b.Font = Enum.Font.SourceSansBold
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.TextWrapped = true
	b.Parent = parent
	return b
end

-- Top bar.
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 44)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topBar.BackgroundTransparency = 0.2
topBar.BorderSizePixel = 0
topBar.Parent = gui

local coinsLabel = label(topBar, "Coins", "Coins: 150", UDim2.new(0, 160, 1, 0), UDim2.new(0, 10, 0, 0), 20, Color3.fromRGB(255, 210, 0))
local repLabel = label(topBar, "Rep", "Reputasi: 100", UDim2.new(0, 170, 1, 0), UDim2.new(0, 180, 0, 0), 20, Color3.fromRGB(120, 255, 120))
local stockLabel = label(topBar, "Stock", "Stok: 80", UDim2.new(0, 130, 1, 0), UDim2.new(0, 360, 0, 0), 20)
local servedLabel = label(topBar, "Served", "Dilayani: 0", UDim2.new(0, 150, 1, 0), UDim2.new(0, 500, 0, 0), 20)
local timerLabel = label(topBar, "Timer", "Shift: 5:00", UDim2.new(0, 160, 1, 0), UDim2.new(1, -170, 0, 0), 20)

-- Notification toast.
local toast = label(gui, "Toast", "", UDim2.new(0, 560, 0, 40), UDim2.new(0.5, -280, 0, 54), 18)
toast.BackgroundTransparency = 0.4
toast.Visible = false
notifyEvent.OnClientEvent:Connect(function(text)
	toast.Text = text
	toast.Visible = true
	task.delay(4, function()
		toast.Visible = false
	end)
end)

-- Scan progress bar.
local progressBg = Instance.new("Frame")
progressBg.Name = "ScanProgressBg"
progressBg.Size = UDim2.new(0, 300, 0, 16)
progressBg.Position = UDim2.new(0.5, -150, 0, 104)
progressBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
progressBg.BackgroundTransparency = 0.3
progressBg.Visible = false
progressBg.Parent = gui
local progressFill = Instance.new("Frame")
progressFill.Name = "ScanProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBg

local function showScanProgress(duration)
	progressBg.Visible = true
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	task.spawn(function()
		local start = os.clock()
		while os.clock() - start < duration do
			local frac = (os.clock() - start) / duration
			progressFill.Size = UDim2.new(frac, 0, 1, 0)
			task.wait(0.05)
		end
		progressFill.Size = UDim2.new(1, 0, 1, 0)
		task.wait(0.2)
		progressBg.Visible = false
	end)
end

-- Left panel: order, threat, stock.
local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0, 270, 0, 430)
leftPanel.Position = UDim2.new(0, 10, 0, 60)
leftPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
leftPanel.BackgroundTransparency = 0.2
leftPanel.BorderSizePixel = 0
leftPanel.Parent = gui

label(leftPanel, "Title", "KASIR - PESANAN", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 0), 20, Color3.fromRGB(255, 210, 0))
local orderLabel = label(leftPanel, "Order", "Belum ada pelanggan di kasir.", UDim2.new(1, -16, 0, 70), UDim2.new(0, 8, 0, 42), 17)
orderLabel.BackgroundTransparency = 0.6
local threatLabel = label(leftPanel, "Threat", "Toko aman. Pelanggan sopan semua.", UDim2.new(1, -16, 0, 60), UDim2.new(0, 8, 0, 120), 17, Color3.fromRGB(120, 255, 120))
threatLabel.BackgroundTransparency = 0.6
label(leftPanel, "StockTitle", "STOK FREEZER", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 188), 18, Color3.fromRGB(180, 220, 255))
local stockText = label(leftPanel, "StockText", "", UDim2.new(1, -16, 0, 124), UDim2.new(0, 8, 0, 222), 16)
stockText.BackgroundTransparency = 1
stockText.TextYAlignment = Enum.TextYAlignment.Top
stockText.TextXAlignment = Enum.TextXAlignment.Left
local demoLabel = label(leftPanel, "Demo", "DEMO DAMAI! Pesan truk supplier di bawah!", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 350), 16, Color3.fromRGB(255, 80, 80))
demoLabel.Visible = false
local helperLabel = label(leftPanel, "Helper", "Pembantu: BELUM DISEWA", UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 374), 14, Color3.fromRGB(200, 200, 200))
helperLabel.BackgroundTransparency = 1
local worldLabel = label(leftPanel, "World", "World 1: Frozen Mart", UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 398), 14, Color3.fromRGB(200, 200, 200))
worldLabel.BackgroundTransparency = 1

-- Right panel: upgrades.
local rightPanel = Instance.new("Frame")
rightPanel.Name = "UpgradePanel"
rightPanel.Size = UDim2.new(0, 280, 0, 400)
rightPanel.Position = UDim2.new(1, -290, 0, 60)
rightPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
rightPanel.BackgroundTransparency = 0.2
rightPanel.BorderSizePixel = 0
rightPanel.Parent = gui

label(rightPanel, "Title", "UPGRADE TOKO", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 0), 20, Color3.fromRGB(255, 210, 0))

local upgradeList = Instance.new("ScrollingFrame")
upgradeList.Name = "UpgradeList"
upgradeList.Size = UDim2.new(1, -6, 1, -42)
upgradeList.Position = UDim2.new(0, 3, 0, 40)
upgradeList.BackgroundTransparency = 1
upgradeList.ScrollBarThickness = 6
upgradeList.CanvasSize = UDim2.new(0, 0, 0, 14 * 68 + 8)
upgradeList.Parent = rightPanel

local function upgradeRow(name, y, title, infoText)
	local row = Instance.new("Frame")
	row.Name = name
	row.Size = UDim2.new(1, -12, 0, 62)
	row.Position = UDim2.new(0, 6, 0, y)
	row.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	row.BackgroundTransparency = 0.2
	row.BorderSizePixel = 0
	row.Parent = upgradeList
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -90, 0, 26)
	titleLabel.Position = UDim2.new(0, 8, 0, 4)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = row
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "Info"
	infoLabel.Size = UDim2.new(1, -90, 0, 26)
	infoLabel.Position = UDim2.new(0, 8, 0, 32)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = infoText
	infoLabel.TextSize = 14
	infoLabel.Font = Enum.Font.SourceSans
	infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = row
	local buy = Instance.new("TextButton")
	buy.Name = "Buy"
	buy.Size = UDim2.new(0, 76, 0, 40)
	buy.Position = UDim2.new(1, -82, 0, 11)
	buy.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	buy.Text = "Beli"
	buy.TextSize = 15
	buy.Font = Enum.Font.SourceSansBold
	buy.TextColor3 = Color3.fromRGB(255, 255, 255)
	buy.Parent = row
	return row, buy
end

local scannerRow, scannerBuy = upgradeRow("Scanner", 8, "Scanner", "Lv1 - scan 3 dtk")
local securityRow, securityBuy = upgradeRow("Security", 76, "Satpam Brainrot", "Usir Ormas otomatis")
local stockRow, stockBuy = upgradeRow("Stock", 144, "Tambah Stok", "Lv0 - maks 30/produk")
local eskrimRow, eskrimBuy = upgradeRow("EsKrim", 212, "Buka Es Krim", "40c per pcs")
local dimsumRow, dimsumBuy = upgradeRow("Dimsum", 280, "Buka Dimsum", "50c per pcs")
local helperRow, helperBuy = upgradeRow("Helper", 348, "Kasir Pembantu", "Auto-scan 1 pelanggan/8 dtk (3000c)")
local helperEliteRow, helperEliteBuy = upgradeRow("HelperElite", 416, "Kasir Pembantu Elite", "Auto-scan 2x lebih cepat (4 dtk)")
local adRow, adBuy = upgradeRow("Iklan", 484, "Iklan Neon Viral", "Pelanggan 15% lebih cepat/lv")
local truckRow, truckBuy = upgradeRow("TrukExpress", 552, "Truk Express", "Truk lebih cepat + kardus")
local eliteRow, eliteBuy = upgradeRow("SatpamElite", 620, "Satpam Elite", "Ormas langsung kabur (10k)")
local expandRow, expandBuy = upgradeRow("PerluasToko", 688, "Perluas Toko", "Antrean 6 -> 16, 5 level")
local sultanRow, sultanBuy = upgradeRow("MenuSultan", 756, "Menu Sultan", "6 produk Sultan emas, harga 3x")
local hypermartRow, hypermartBuy = upgradeRow("Hypermart", 824, "Buka Hypermart (World 2)", "Butuh Perluas Lv5 - GRATIS")
local safeRow, safeBuy = upgradeRow("Brankas", 892, "Brankas", "Penalti Ormas -50%")

scannerBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("Scanner")
end)
securityBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("Security")
end)
stockBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("Stock")
end)
eskrimBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("EsKrim")
end)
dimsumBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("Dimsum")
end)

helperBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("Helper")
end)
adBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("Iklan")
end)
truckBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("TrukExpress")
end)
helperEliteBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("HelperElite")
end)
eliteBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("SatpamElite")
end)
expandBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("PerluasToko")
end)
sultanBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("MenuSultan")
end)
hypermartBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("Hypermart")
end)
safeBuy.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("Brankas")
end)

local function setBuyEnabled(buy, enabled)
	buy.Active = enabled
	if enabled then
		buy.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	else
		buy.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	end
end

local function isUnlocked(name)
	for part in string.gmatch(unlockedStateValue.Value, "([^,]+)") do
		if part == name then
			return true
		end
	end
	return false
end

-- Bottom action bar.
local actionBar = Instance.new("Frame")
actionBar.Name = "ActionBar"
actionBar.Size = UDim2.new(0, 780, 0, 116)
actionBar.Position = UDim2.new(0.5, -390, 1, -126)
actionBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
actionBar.BackgroundTransparency = 0.2
actionBar.BorderSizePixel = 0
actionBar.Parent = gui

local scanButton = button(actionBar, "Scan", "SCAN\n(Pelanggan Depan)", UDim2.new(0, 180, 0, 52), UDim2.new(0, 8, 0, 6), Color3.fromRGB(40, 140, 220))
scanButton.TextSize = 18
local payButton = button(actionBar, "PayOrmas", "Bayar Ormas\n(100c)", UDim2.new(0, 180, 0, 52), UDim2.new(0, 196, 0, 6), Color3.fromRGB(180, 60, 60))
local securityButton = button(actionBar, "CallSecurity", "Panggil Satpam", UDim2.new(0, 180, 0, 52), UDim2.new(0, 384, 0, 6), Color3.fromRGB(60, 120, 220))
local honkButton = button(actionBar, "Honk", "Klakson\nTEL-O-LET!", UDim2.new(0, 180, 0, 52), UDim2.new(0, 572, 0, 6), Color3.fromRGB(140, 80, 200))
local truckButton = button(actionBar, "Truck", "Pesan Truk\nSupplier (80c)", UDim2.new(0, 180, 0, 52), UDim2.new(0, 8, 0, 62), Color3.fromRGB(90, 160, 90))
local carryButton = button(actionBar, "Carry", "Ambil Kardus\n(dari truk)", UDim2.new(0, 180, 0, 52), UDim2.new(0, 196, 0, 62), Color3.fromRGB(160, 120, 60))
local deliverButton = button(actionBar, "Deliver", "Antar Kardus\nke Freezer", UDim2.new(0, 180, 0, 52), UDim2.new(0, 384, 0, 62), Color3.fromRGB(60, 180, 120))
local hypermartButton = button(actionBar, "Hypermart", "Buka Hypermart\n(World 2)", UDim2.new(0, 180, 0, 52), UDim2.new(0, 572, 0, 62), Color3.fromRGB(160, 90, 220))

scanButton.MouseButton1Click:Connect(function()
	local duration = SCAN_TIMES[scannerLevelValue.Value] or 3
	if threatTypeValue.Value == "emak" and emakPhaseValue.Value == "jamming" then
		-- Emak-Emak ganggu scan: 2x lebih lama (server yang memutuskan).
		duration = duration * 2
	end
	showScanProgress(duration)
	scanEvent:FireServer()
end)
payButton.MouseButton1Click:Connect(function()
	payOrmasEvent:FireServer()
end)
securityButton.MouseButton1Click:Connect(function()
	callSecurityEvent:FireServer()
end)
honkButton.MouseButton1Click:Connect(function()
	honkEvent:FireServer()
end)
truckButton.MouseButton1Click:Connect(function()
	orderTruckEvent:FireServer()
end)
carryButton.MouseButton1Click:Connect(function()
	carryBoxEvent:FireServer()
end)
deliverButton.MouseButton1Click:Connect(function()
	deliverBoxEvent:FireServer()
end)
hypermartButton.MouseButton1Click:Connect(function()
	buyUpgradeEvent:FireServer("Hypermart")
end)

-- Refresh loop: stats, threat, stock list, upgrade texts, buttons.
local function refresh()
	coinsLabel.Text = "Coins: " .. tostring(coinsValue.Value)
	repLabel.Text = "Reputasi: " .. tostring(repValue.Value)
	stockLabel.Text = "Stok: " .. tostring(totalStockValue.Value)
	servedLabel.Text = "Dilayani: " .. tostring(servedValue.Value)
	local t = shiftTime.Value
	timerLabel.Text = string.format("Shift: %d:%02d", math.floor(t / 60), t % 60)

	orderLabel.Text = frontOrderValue.Value
	demoLabel.Visible = demoValue.Value
	if helperEliteOwnedValue.Value then
		helperLabel.Text = "Pembantu ELITE: AKTIF (auto-scan 4 dtk)"
		helperLabel.TextColor3 = Color3.fromRGB(255, 210, 0)
	elseif helperOwnedValue.Value then
		helperLabel.Text = "Pembantu: AKTIF (auto-scan 8 dtk)"
		helperLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	else
		helperLabel.Text = "Pembantu: BELUM DISEWA"
		helperLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	end
	if hypermartOpenValue.Value then
		worldLabel.Text = "World 2: BRAINROT HYPERMART"
		worldLabel.TextColor3 = Color3.fromRGB(200, 140, 255)
	else
		worldLabel.Text = "World 1: Frozen Mart"
		worldLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	end
	if threatTypeValue.Value == "emak" then
		threatLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		if emakPhaseValue.Value == "jamming" then
			threatLabel.Text = "SCAN DIGANGGU! Scan 2x lebih lama. Sisa: " .. tostring(threatTimerValue.Value) .. " dtk. Tunggu dia pergi sendiri!"
			scanButton.Text = "SCAN (LAMBAT!)\n2x lebih lama"
		else
			threatLabel.Text = "EMAK-EMAK MONDAR-MANDIR! Dia dorong antrean mundur. Pergi: " .. tostring(threatTimerValue.Value) .. " dtk."
			scanButton.Text = "SCAN\n(Pelanggan Depan)"
		end
	elseif threatTypeValue.Value == "ormas" then
		threatLabel.Text = "OKNUM ORMAS! Uang keamanan! Timer: " .. tostring(threatTimerValue.Value) .. " dtk."
		threatLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		scanButton.Text = "SCAN\n(Pelanggan Depan)"
	else
		threatLabel.Text = "Toko aman. Pelanggan sopan semua."
		threatLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
		scanButton.Text = "SCAN\n(Pelanggan Depan)"
	end

	local lines = {}
	for part in string.gmatch(stockStateValue.Value, "([^;]+)") do
		local name, amount = string.match(part, "([^:]+):(%d+)")
		if name and amount then
			local locked = ""
			if not isUnlocked(name) then
				locked = " (terkunci)"
			end
			table.insert(lines, name .. ": " .. amount .. locked)
		end
	end
	stockText.Text = table.concat(lines, "\n")

	-- Upgrades.
	local lvl = scannerLevelValue.Value
	local scannerInfo = scannerRow:FindFirstChild("Info")
	if lvl >= 5 then
		scannerInfo.Text = "Lv5 MAX - scan 0.7 dtk"
		scannerBuy.Text = "MAX"
		setBuyEnabled(scannerBuy, false)
	else
		scannerInfo.Text = "Lv" .. tostring(lvl) .. " - scan " .. tostring(SCAN_TIMES[lvl]) .. " dtk"
		scannerBuy.Text = tostring(SCAN_COSTS[lvl]) .. "c"
		setBuyEnabled(scannerBuy, true)
	end
	local securityInfo = securityRow:FindFirstChild("Info")
	if hasSecurityValue.Value then
		securityInfo.Text = "Sudah disewa - jaga pintu"
		securityBuy.Text = "AKTIF"
		setBuyEnabled(securityBuy, false)
	else
		securityInfo.Text = "Usir Ormas otomatis (300c)"
		securityBuy.Text = "300c"
		setBuyEnabled(securityBuy, true)
	end
	local stockInfo = stockRow:FindFirstChild("Info")
	if stockLevelValue.Value >= 3 then
		stockInfo.Text = "Lv3 MAX - maks 60/produk"
		stockBuy.Text = "MAX"
		setBuyEnabled(stockBuy, false)
	else
		stockInfo.Text = "Lv" .. tostring(stockLevelValue.Value) .. " - maks " .. tostring(30 + 10 * stockLevelValue.Value) .. "/produk"
		stockBuy.Text = "200c"
		setBuyEnabled(stockBuy, true)
	end
	local eskrimInfo = eskrimRow:FindFirstChild("Info")
	if isUnlocked("Es Krim") then
		eskrimInfo.Text = "Sudah dibuka - 40c per pcs"
		eskrimBuy.Text = "DIBUKA"
		setBuyEnabled(eskrimBuy, false)
	else
		eskrimInfo.Text = "Buka produk baru (200c)"
		eskrimBuy.Text = "200c"
		setBuyEnabled(eskrimBuy, true)
	end
	local dimsumInfo = dimsumRow:FindFirstChild("Info")
	if isUnlocked("Dimsum") then
		dimsumInfo.Text = "Sudah dibuka - 50c per pcs"
		dimsumBuy.Text = "DIBUKA"
		setBuyEnabled(dimsumBuy, false)
	else
		dimsumInfo.Text = "Buka produk baru (400c)"
		dimsumBuy.Text = "400c"
		setBuyEnabled(dimsumBuy, true)
	end

	local helperInfo = helperRow:FindFirstChild("Info")
	if helperOwnedValue.Value then
		helperInfo.Text = "AKTIF - auto-scan 1 pelanggan/8 dtk"
		helperBuy.Text = "AKTIF"
		setBuyEnabled(helperBuy, false)
	else
		helperInfo.Text = "Auto-scan 1 pelanggan/8 dtk (3000c)"
		helperBuy.Text = "3000c"
		setBuyEnabled(helperBuy, true)
	end
	local helperEliteInfo = helperEliteRow:FindFirstChild("Info")
	if helperEliteOwnedValue.Value then
		helperEliteInfo.Text = "AKTIF - auto-scan 1 pelanggan/4 dtk"
		helperEliteBuy.Text = "AKTIF"
		setBuyEnabled(helperEliteBuy, false)
	elseif not helperOwnedValue.Value then
		helperEliteInfo.Text = "Butuh Kasir Pembantu dulu (6000c)"
		helperEliteBuy.Text = "6000c"
		setBuyEnabled(helperEliteBuy, true)
	else
		helperEliteInfo.Text = "Auto-scan 2x lebih cepat, 4 dtk (6000c)"
		helperEliteBuy.Text = "6000c"
		setBuyEnabled(helperEliteBuy, true)
	end
	local adInfo = adRow:FindFirstChild("Info")
	if adLevelValue.Value >= 3 then
		adInfo.Text = "Lv3 MAX - pelanggan 39% lebih cepat"
		adBuy.Text = "MAX"
		setBuyEnabled(adBuy, false)
	else
		adInfo.Text = "Lv" .. tostring(adLevelValue.Value) .. " - pelanggan 15% lebih cepat/lv"
		adBuy.Text = "750c"
		setBuyEnabled(adBuy, true)
	end
	local truckInfo = truckRow:FindFirstChild("Info")
	local truckWaits = { 8, 4, 2 }
	local truckBoxes = { 4, 5, 6 }
	if truckLevelValue.Value >= 2 then
		truckInfo.Text = "Lv2 MAX - truk 2 dtk, 6 kardus"
		truckBuy.Text = "MAX"
		setBuyEnabled(truckBuy, false)
	else
		truckInfo.Text = "Lv" .. tostring(truckLevelValue.Value) .. " - truk " .. tostring(truckWaits[truckLevelValue.Value + 1]) .. " dtk, " .. tostring(truckBoxes[truckLevelValue.Value + 1]) .. " kardus"
		truckBuy.Text = "1500c"
		setBuyEnabled(truckBuy, true)
	end
	local eliteInfo = eliteRow:FindFirstChild("Info")
	if eliteOwnedValue.Value then
		eliteInfo.Text = "AKTIF - Ormas langsung kabur"
		eliteBuy.Text = "AKTIF"
		setBuyEnabled(eliteBuy, false)
	else
		eliteInfo.Text = "Butuh Satpam dulu - Ormas kabur 2 dtk (10000c)"
		eliteBuy.Text = "10000c"
		setBuyEnabled(eliteBuy, true)
	end
	local expandInfo = expandRow:FindFirstChild("Info")
	local expandCosts = { 400, 800, 1500, 2500, 4000 }
	local expandLevel = expandLevelValue.Value
	if expandLevel >= 5 then
		expandInfo.Text = "Lv5 MAX - antrean 16 orang"
		expandBuy.Text = "MAX"
		setBuyEnabled(expandBuy, false)
	else
		expandInfo.Text = "Lv" .. tostring(expandLevel) .. "/5 - antrean " .. tostring(6 + 2 * expandLevel) .. " orang, next " .. tostring(expandCosts[expandLevel + 1]) .. "c"
		expandBuy.Text = tostring(expandCosts[expandLevel + 1]) .. "c"
		setBuyEnabled(expandBuy, true)
	end
	local sultanInfo = sultanRow:FindFirstChild("Info")
	if sultanUnlockedValue.Value then
		sultanInfo.Text = "DIBUKA - 6 produk Sultan emas, 3x"
		sultanBuy.Text = "DIBUKA"
		setBuyEnabled(sultanBuy, false)
	else
		sultanInfo.Text = "6 produk Sultan emas, harga 3x (1000c)"
		sultanBuy.Text = "1000c"
		setBuyEnabled(sultanBuy, true)
	end
	local hypermartInfo = hypermartRow:FindFirstChild("Info")
	if hypermartOpenValue.Value then
		hypermartInfo.Text = "DIBUKA - World 2 aktif!"
		hypermartBuy.Text = "DIBUKA"
		setBuyEnabled(hypermartBuy, false)
	elseif expandLevelValue.Value < 5 then
		hypermartInfo.Text = "Butuh Perluas Toko Lv5 dulu - GRATIS"
		hypermartBuy.Text = "TERKUNCI"
		setBuyEnabled(hypermartBuy, false)
	else
		hypermartInfo.Text = "Buka World 2 - GRATIS!"
		hypermartBuy.Text = "BUKA"
		setBuyEnabled(hypermartBuy, true)
	end
	local safeInfo = safeRow:FindFirstChild("Info")
	if safeOwnedValue.Value then
		safeInfo.Text = "AKTIF - penalti Ormas -50%"
		safeBuy.Text = "AKTIF"
		setBuyEnabled(safeBuy, false)
	else
		safeInfo.Text = "Penalti timeout Ormas -50% (200c)"
		safeBuy.Text = "200c"
		setBuyEnabled(safeBuy, true)
	end

	-- Action buttons enable/disable by state.
	setBuyEnabled(hypermartButton, expandLevelValue.Value >= 5 and not hypermartOpenValue.Value)
	setBuyEnabled(payButton, threatTypeValue.Value == "ormas")
	setBuyEnabled(honkButton, threatTypeValue.Value == "ormas")
	setBuyEnabled(truckButton, demoValue.Value)
	setBuyEnabled(carryButton, truckActiveValue.Value)
	setBuyEnabled(deliverButton, truckActiveValue.Value)
	if threatTypeValue.Value == "ormas" and not hasSecurityValue.Value then
		securityButton.Text = "Panggil Satpam\n(sewa dulu!)"
		setBuyEnabled(securityButton, false)
	elseif threatTypeValue.Value == "ormas" then
		securityButton.Text = "Panggil Satpam"
		setBuyEnabled(securityButton, true)
	else
		securityButton.Text = "Panggil Satpam"
		setBuyEnabled(securityButton, false)
	end
end

task.spawn(function()
	while true do
		refresh()
		task.wait(0.5)
	end
end)
refresh()

-- Start screen.
local startScreen = Instance.new("Frame")
startScreen.Name = "StartScreen"
startScreen.Size = UDim2.fromScale(1, 1)
startScreen.BackgroundColor3 = Color3.fromRGB(20, 40, 60)
startScreen.BackgroundTransparency = 0.1
startScreen.Parent = gui

local title = label(startScreen, "Title", "FROZEN BRAINROT MART", UDim2.new(0, 560, 0, 60), UDim2.new(0.5, -280, 0, 110), 38, Color3.fromRGB(255, 210, 0))
title.BackgroundTransparency = 1
local how = label(startScreen, "How", "Kamu kasir toko frozen food. Pelanggan brainrot\n(Tung Tung Sahur, Tralalero Tralala, Ballerina\nCappuccina, dll) antre rapi, sopan, dan bayar PAS.\n\nTekan SCAN atau klik pelanggan di kasir untuk\nmelayani mereka. Uang HANYA dari jualan, tidak\nada gaji per detik. Hati-hati: Emak-Emak mondar-\nmandir 5 detik (dorong antrean mundur) lalu\nganggu scan 10 detik (scan 2x lebih lama). Tunggu dia pergi sendiri —\ntanpa penalti stok/reputasi.\nOrmas minta uang keamanan, dan kalau stok habis\nsemua demo damai! Pesan truk supplier (80c),\nangkut kardusnya ke freezer.\n\nUpgrade scanner, sewa satpam, tambah stok,\nbuka Es Krim & Dimsum.\n\nUpgrade: Kasir Pembantu + Pembantu Elite,\nIklan Neon, Truk Express, Satpam Elite,\nPerluas Toko 5 level, Menu Sultan (produk\nSultan emas 3x, cuma VIP yang pesan),\nBrankas, dan Hypermart World 2!\nJaga reputasi toko!", UDim2.new(0, 560, 0, 300), UDim2.new(0.5, -280, 0, 180), 17)
how.BackgroundTransparency = 1

local playButton = Instance.new("TextButton")
playButton.Name = "Play"
playButton.Size = UDim2.new(0, 200, 0, 60)
playButton.Position = UDim2.new(0.5, -100, 0, 470)
playButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
playButton.Text = "PLAY"
playButton.TextSize = 28
playButton.Font = Enum.Font.SourceSansBold
playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playButton.Parent = startScreen
playButton.MouseButton1Click:Connect(function()
	startScreen.Visible = false
end)

print("Frozen Brainrot Mart client UI ready.")
