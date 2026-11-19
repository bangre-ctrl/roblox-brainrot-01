-- Frozen food products sold in Frozen Brainrot Mart.
-- Plain data only: name, price in coins, unlock cost (0 = sold from
-- the start), and a colour used on posters and stock indicators.
-- Stock lives on the server; this module only describes the goods.
--
-- v6: three product families.
--  * Biasa: Kentang, Nugget, Sosis, Bakso, Es Krim, Dimsum.
--  * Sultan: versi emas dari SEMUA produk biasa, harga 3x. Dibuka
--    sekaligus oleh upgrade Menu Sultan (1000c). Hanya pelanggan
--    VIP Sultan yang memesan produk Sultan; pelanggan biasa tidak
--    pernah memesan Sultan. Stok Sultan terpisah dari stok biasa
--    (freezer emas sendiri).
--  * Hypermart (World 2): Pizza Beku, Ayam Beku, Seafood Beku,
--    Wagyu Beku. Dibuka sekaligus saat Hypermart (World 2) dibuka
--    (gratis, syarat Perluas Toko Lv5).

local Products = {}

Products.List = {
	-- Produk biasa (World 1).
	{
		Name = "Nugget",
		Price = 20,
		UnlockCost = 0,
		Color = Color3.fromRGB(255, 200, 80),
	},
	{
		Name = "Kentang",
		Price = 15,
		UnlockCost = 0,
		Color = Color3.fromRGB(255, 230, 120),
	},
	{
		Name = "Sosis",
		Price = 25,
		UnlockCost = 0,
		Color = Color3.fromRGB(255, 120, 120),
	},
	{
		Name = "Bakso",
		Price = 30,
		UnlockCost = 0,
		Color = Color3.fromRGB(200, 160, 120),
	},
	{
		Name = "Es Krim",
		Price = 40,
		UnlockCost = 200,
		Color = Color3.fromRGB(255, 180, 220),
	},
	{
		Name = "Dimsum",
		Price = 50,
		UnlockCost = 400,
		Color = Color3.fromRGB(180, 220, 255),
	},
	-- Produk Sultan: emas, harga 3x produk biasa.
	{
		Name = "Kentang Sultan",
		Price = 45,
		UnlockCost = 1000,
		IsSultan = true,
		BaseName = "Kentang",
		Color = Color3.fromRGB(255, 215, 0),
	},
	{
		Name = "Nugget Sultan",
		Price = 60,
		UnlockCost = 1000,
		IsSultan = true,
		BaseName = "Nugget",
		Color = Color3.fromRGB(255, 200, 0),
	},
	{
		Name = "Sosis Sultan",
		Price = 75,
		UnlockCost = 1000,
		IsSultan = true,
		BaseName = "Sosis",
		Color = Color3.fromRGB(255, 180, 0),
	},
	{
		Name = "Bakso Sultan",
		Price = 90,
		UnlockCost = 1000,
		IsSultan = true,
		BaseName = "Bakso",
		Color = Color3.fromRGB(230, 180, 40),
	},
	{
		Name = "Es Krim Sultan",
		Price = 120,
		UnlockCost = 1000,
		IsSultan = true,
		BaseName = "Es Krim",
		Color = Color3.fromRGB(255, 220, 120),
	},
	{
		Name = "Dimsum Sultan",
		Price = 150,
		UnlockCost = 1000,
		IsSultan = true,
		BaseName = "Dimsum",
		Color = Color3.fromRGB(255, 200, 80),
	},
	-- Produk Hypermart (World 2).
	{
		Name = "Pizza Beku",
		Price = 120,
		UnlockCost = 0,
		IsHypermart = true,
		Color = Color3.fromRGB(255, 120, 60),
	},
	{
		Name = "Ayam Beku",
		Price = 150,
		UnlockCost = 0,
		IsHypermart = true,
		Color = Color3.fromRGB(255, 160, 40),
	},
	{
		Name = "Seafood Beku",
		Price = 200,
		UnlockCost = 0,
		IsHypermart = true,
		Color = Color3.fromRGB(80, 180, 255),
	},
	{
		Name = "Wagyu Beku",
		Price = 300,
		UnlockCost = 0,
		IsHypermart = true,
		Color = Color3.fromRGB(180, 60, 60),
	},
}

Products.StartStock = 20
Products.StartMaxStock = 30

function Products.GetByName(name)
	for _, def in ipairs(Products.List) do
		if def.Name == name then
			return def
		end
	end
	return nil
end

function Products.IsSultan(def)
	return def ~= nil and def.IsSultan == true
end

function Products.IsHypermart(def)
	return def ~= nil and def.IsHypermart == true
end

return Products
