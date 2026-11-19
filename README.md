# Frozen Brainrot Mart — Kasir Frozen Food — roblox-brainrot-01

A 3D Roblox cashier-simulator / comedy-absurd (brainrot) game for
make.fun's "Make the best AI Roblox brainrot game" bounty
(roblox-brainrot-01), entry by @bangre / bangre-ctrl.

You are the cashier of a minimalist frozen-food shop. Your customers
are brainrot memes — Tung Tung Tung Sahur, Tralalero Tralala,
Ballerina Cappuccina, Bombardiro Crocodilo, Chimpanzini Bananini,
Lirili Larila, Brr Brr Patapim and Cappuccino Assassino — and they are
the politest customers alive: they queue neatly, order 1–3 frozen
items and always pay the exact amount. The chaos comes from the
normal humans.

## v6 (2026-11-19) — rebalance 1 jam, Menu Sultan, World 2

- **Rebalance: max semua upgrade sekitar 1 jam** (12 shift x 5
  menit). Total biaya max semua upgrade **38.550c** (dulu
  58.700c di harga mahal v5). Harga yang dipangkas paling besar:
  Perluas Toko (20.600c jadi 9.200c total) dan Pembantu Elite.
  Satpam Elite tetap 10.000c sebagai upgrade termahal.
- **Menu Sultan jadi 2 type**: beli Menu Sultan (1.000c) membuka
  versi Sultan emas dari SEMUA produk biasa, harga 3x: Kentang
  Sultan 45c, Nugget Sultan 60c, Sosis Sultan 75c, Bakso Sultan
  90c, Es Krim Sultan 120c, Dimsum Sultan 150c. Eksklusif: kemasan
  emas + glow + mahkota, poster emas, freezer emas terpisah dengan
  stok Sultan terpisah dari stok biasa, dan hanya pelanggan **VIP
  Sultan** (brainrot pakai mahkota emas, ~22% spawn) yang memesan
  produk Sultan — pelanggan biasa tidak pernah memesan Sultan.
- **Voucher dihapus sepenuhnya** (upgrade voucher grosir dan
  tombol voucher). Emak-Emak tidak bisa diusir lagi; dia pergi
  sendiri setelah 15 detik.
- **Perluas Toko 5 level**: 400 / 800 / 1.500 / 2.500 / 4.000c,
  antrean 6 → 8 → 10 → 12 → 14 → 16 orang.
- **Kasir Pembantu Elite** (baru): 6.000c, syarat sudah punya
  Kasir Pembantu (3.000c), auto-scan tiap 4 detik (2x lebih
  cepat dari Pembantu biasa yang tiap 8 detik).
- **World 2 — Brainrot Hypermart**: terbuka setelah Perluas Toko
  Lv5, gratis, lewat tombol "Buka Hypermart (World 2)" di panel
  upgrade / action bar. Produk baru: Pizza Beku 120c, Ayam Beku
  150c, Seafood Beku 200c, Wagyu Beku 300c. Implementasi jujur:
  Hypermart BUKAN teleport ke map lain — itu terlalu berisiko
  untuk sistem antre/scan yang sudah jalan. Hypermart adalah
  ekspansi di area yang sama: papan Hypermart ungu, 4 freezer
  Hypermart di dinding belakang, poster 4 produk baru, dan produk
  Hypermart masuk ke pool pesanan pelanggan biasa. Antrean, scan,
  stok, Emak, Ormas, dan demo tetap memakai sistem yang sama.
- **Bug v5 diperbaiki**: blok `ormasTimeout` ganda yang tertinggal
  di `init.server.luau` (kode yatim yang jalan sekali saat server
  start dan menurunkan reputasi ke 80 + spam toast Ormas) sudah
  dihapus; juga ada `)` berlebih di baris `EMAK_PHRASES[...]` yang
  membuat script server tidak bisa di-parse — sudah diperbaiki.

## How to play

- Stand behind the counter. Brainrot customers walk in through the
  glass door, queue up (front of the queue is nearest the counter)
  and step up to the cashier with an order bubble: Nugget 20c,
  Kentang 15c, Sosis 25c, Bakso 30c (plus Es Krim 40c, Dimsum 50c,
  6 produk Sultan emas harga 3x, dan 4 produk Hypermart World 2
  once unlocked).
- Press the big **SCAN** button (or click the customer at the
  counter) to scan the order. Scanning takes time — 3 seconds with
  the Lv1 scanner, down to 0.7s at Lv5 — with a progress bar. When
  it finishes you get the exact total, stock drops per item, and
  the customer walks out happy. Your leaderboard stats are Coins
  (start 150), Dilayani (customers served) and Reputasi (start 100).
- Money comes ONLY from sales — there is no cashier wage. Every
  product has its own price (Nugget 20c, Kentang 15c, Sosis 25c,
  Bakso 30c, Es Krim 40c, Dimsum 50c) and each order is 1–3 items,
  so what you earn is exactly the sum of the items scanned. Sales
  income is enough to afford the 80c supplier truck.
- The player with the most customers served when the 5-minute shift
  timer ends is announced as the best cashier of the shift.

## The chaos: normal humans

- **Emak-Emak** — spawns every 50–80 seconds (never during a
  protest). She is NOT a customer and never joins the queue, so
  she is never served. She stays for 15 seconds in two phases:
  **(1) Mondar-mandir, 5 seconds** — she walks back and forth
  along the queue (X=+3) and every ~1.5 seconds shoves the
  frontmost waiting brainrot one slot back (they swap places;
  orders and totals are kept, nobody despawns). **(2) Ganggu
  scan, 10 seconds** — she stands beside the counter and every
  scan takes twice as long (Lv1: 3s → 6s, Lv2: 2.2s → 4.4s,
  and so on). Scanning is never blocked outright. The SCAN button
  turns into "SCAN (LAMBAT!)" and the threat panel counts down
  the remaining seconds. She then walks out through the glass
  door on her own — with NO stock or reputation penalty at all.
  There is no voucher anymore: just wait her out. The regular
  satpam does not affect her (he is for Ormas); Satpam Elite cuts
  her scan-jam phase from 10 to 5 seconds.
- **Oknum Ormas** — two NPCs in black, every 70–110 seconds. They
  stand in front of the counter for 25 seconds demanding "uang
  keamanan". Counter them by paying **100c**, calling the **Satpam**
  (only if you hired one — the button is disabled otherwise), or
  honking the free **Telolet** horn (30s cooldown). If the timer
  runs out: reputation −20 and −50c. If you already hired the
  satpam, they leave on their own after 5 seconds.

## Stock-out crisis

- If total stock hits 0, the brainrot customers stop queueing and
  hold a **peaceful protest** inside the shop with signs ("STOK
  HABIS!!", "KAMI LAPAR", "FROZEN FOOD MANA?"). Nothing sells until
  you restock. During a protest, Ormas penalties are doubled
  (−40 reputation, −100c); Emak-Emak never spawns during a protest
  and causes no penalty.
- Click **Pesan Truk Supplier** (80c). After 8 seconds a truck
  parks outside the door with 4 boxes in its bed. **Mini-game:**
  click a box (or the AMBIL KARDUS button) to carry it on your head,
  walk to a freezer and click the freezer (or the ANTAR KARDUS
  button) to deliver it: +10 stock of a random unlocked product.
  If Emak-Emak or Ormas bump into you while you carry a box, the
  box falls and returns to the truck. Once stock is back above 0
  the protest breaks up. When all 4 boxes are delivered the truck
  leaves, and you can order another one next crisis.

## Upgrades (right panel, paid with sales money) — total max 38.550c

- **Scanner** Lv1–5: 150 / 350 / 700 / 1200c, scan time
  3 / 2.2 / 1.6 / 1.1 / 0.7 seconds. Total 2.400c.
- **Satpam Brainrot**: 300c once. A guard NPC stands by the door
  and Ormas leave on their own after 5 seconds.
- **Tambah Stok**: 200c per level, max 3, +10 max stock per product
  (30 → 60). Total 600c.
- **Buka Es Krim**: 200c. **Buka Dimsum**: 400c. Newly unlocked
  products start with 20 stock.
- **Kasir Pembantu Brainrot**: 3.000c once. A mini Tung Tung stands
  beside the counter and auto-scans the front customer every 8
  seconds (paused while Emak-Emak jams the scan, during a protest,
  or while you scan manually). Paid to the first player online.
- **Kasir Pembantu Elite**: 6.000c once, needs the regular
  Pembantu first. A second mini Tung Tung with a gold crown stands
  on the other side of the counter; auto-scan becomes every 4
  seconds (2x faster).
- **Iklan Neon Viral**: 750c per level, max 3 (total 2.250c). Each
  level makes customers arrive 15% faster (spawn interval x0.85
  per level).
- **Truk Express**: 1.500c per level, max 2 (total 3.000c). Lv1:
  truck arrives in 4s with 5 boxes; Lv2: 2s with 6 boxes (was
  8s / 4 boxes). The truck itself still costs 80c, never free.
- **Satpam Elite**: 10.000c once, needs the regular satpam first.
  Ormas flee 2 seconds after spawning, and Emak-Emak's scan-jam
  phase is cut from 10 to 5 seconds (15s total becomes 10s).
- **Perluas Toko**: 5 levels, 400 / 800 / 1.500 / 2.500 / 4.000c
  (total 9.200c). Queue capacity 6 → 8 → 10 → 12 → 14 → 16
  customers. Note: queue slots past the first 6 continue toward
  the door (pre-existing v5 behaviour) — at Lv5 the tail of a
  full queue reaches out the door toward the road.
- **Menu Sultan**: 1.000c once. Unlocks 6 gold Sultan products at
  3x price (Kentang 45c, Nugget 60c, Sosis 75c, Bakso 90c, Es Krim
  120c, Dimsum 150c) with their own gold freezers, gold poster and
  gold sign. Only VIP Sultan customers (gold crown, ~22% of
  spawns) order them.
- **Buka Hypermart (World 2)**: GRATIS, needs Perluas Toko Lv5.
  Unlocks Pizza Beku 120c, Ayam Beku 150c, Seafood Beku 200c,
  Wagyu Beku 300c, plus the Hypermart sign, 4 Hypermart freezers
  and 4 product posters on the back wall.
- **Brankas**: 200c once. Ormas timeout penalties are halved
  (-20 rep / -50c becomes -10 / -25c; doubled in a protest,
  -40 / -100c becomes -20 / -50c). Paying Ormas stays 100c.

## How it is built

- `src/shared/BrainrotData.luau` — the 8 brainrot customers:
  rarity (Common → Mythic), colours, size and a Part-only
  accessory (log + bat, shark fin, tutu, plane wings, banana,
  cactus, big nose, katana).
- `src/shared/Products.luau` — the 16 products in 3 families:
  6 biasa, 6 Sultan (emas, 3x, `IsSultan`), 4 Hypermart
  (`IsHypermart`): price, unlock cost, colour.
- `src/server/init.server.luau` — builds the whole 3D world in
  code (64×40 shop floor, glass front door, cashier counter,
  10 chest freezers + 2 gold Sultan freezers + 4 Hypermart
  freezers, product posters, Sultan gold sign, Hypermart sign,
  store sign, neon lights, road and sidewalk outside, supplier
  truck), the queue, VIP Sultan customers (gold crown, Sultan-only
  orders), order bubbles, Emak-Emak and Ormas threats, the
  protest/demo mode, the truck + box-carrying mini-game, upgrades,
  the shift timer and the leaderboard. There is no cashier wage:
  coins come only from scanned orders (each product has its fixed
  price, each order is 1–3 items). NPCs are Part models moved with
  `PivotTo` on Heartbeat — no Humanoid rigs, no photos or
  copyrighted images anywhere.
- `src/client/Game.client.luau` — top bar (coins / reputation /
  stock / served / shift timer), order + threat + stock + world
  panel, upgrade panel (14 rows), bottom action bar (SCAN, pay
  ormas, call satpam, telolet, order truck, take box, deliver box,
  open Hypermart), scan progress bar, notification toasts and start
  screen. All UI text is Bahasa Indonesia.
- State the client polls lives in ReplicatedStorage: `ShiftTime`,
  `TotalStock`, `ThreatType`, `ThreatTimer`, `EmakPhase`
  ("pacing" / "jamming" / ""), `DemoMode`, `ScannerLevel`,
  `HasSecurity`, `StockLevel`, `StockState`, `FrontOrder`,
  `TruckActive`, `UnlockedState`. Upgrade state: `HelperOwned`,
  `HelperEliteOwned`, `AdLevel`, `TruckLevel`, `EliteOwned`,
  `ExpandLevel`, `ExpandOwned`, `SultanUnlocked`, `HypermartOpen`,
  `SafeOwned`. RemoteEvents: `ScanCustomer`, `BuyUpgrade`,
  `PayOrmas`, `CallSecurity`, `HonkTelolet`, `OrderTruck`,
  `CarryBox`, `DeliverBox`, `Notify` (no voucher event anymore).
- `main.ts` (Node 22, standard library only) hands the game in: it
  copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to
  `/output` and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts` (unchanged).

## Build

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Rojo 7.7.0 is used; on this machine it lives at
`~/workspace/makefun/tools/rojo`.

## Publish (in Roblox Studio, on Windows/Mac)

1. Open this project in Roblox Studio (Rojo plugin, or open
   `game.rbxl`).
2. Play-test: walk behind the counter, scan customers, wait for
   Emak-Emak / Ormas, force a stock-out (sell everything) and run
   the truck mini-game. Take 3 screenshots, replace
   `screenshots/` (the first by name is the cover).
3. Publish as a Public experience, upload an icon and a thumbnail
   (one screenshot must be the game's first thumbnail), put the
   play code in the experience description.
4. Fill in `PLAY.json` with the real place URL, `place_id` and
   `universe_id`.
