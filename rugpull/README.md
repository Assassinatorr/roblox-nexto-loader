# Rugpull ML 0.2.0

Readable client automation for the user's owned Roblox Rugpull Simulator. Execute in the internal executor, wait for the account to connect, then click Start Bot / F6. F7 unloads. It starts paused unless `RugpullMLConfig.StartEnabled=true`.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Assassinatorr/roblox-nexto-loader/rugpull-v0.2.0/rugpull/loader.luau"))()
```

The cycle is now **create -> 2,000 dev buy -> wait for a pump -> sell the full position -> repeat**. It uses normal game calls and does not call RequestRug. A failed atomic dev buy gets a separate quoted Buy only when failure was explicitly reported. Unknown outcomes are checkpointed and reconciled without repeating the transaction.

It alternates **Solara and Ethera**; set `Network="solara"` or `"ethera"` to fix the chain. The default entry is 2,000 market balance plus trading fees. Normal launch fees also apply: without passes the initial requirement is 2,270 on Solara or 2,640 on Ethera. `ReserveBalance` now defaults to zero. Low-balance status shows the exact balance, required amount and fee breakdown. The old six-owned-coins client guard was removed: Config.GlobalMarket.MaxLiveCoins describes live-market watching, and the server enforces creation eligibility.

It reads recent **in-game** posts through the normal latest feed and listens to MarketEvent. Text such as “Space is trending” selects Space and a corresponding rocket logo. Supported categories include Animals, Space, Food, Gaming, Fantasy, Robots, Internet, Absurd and Seasonal, with matching original 32x32 pixel art. Posts are parsed into known categories only; instructions inside posts are never executed. Old or negative trend signals are excluded. When there is no trend, the learner selects a campaign normally.

The online LinUCB learner chooses campaign variants/holding plans. For the first six categories, a detected trend limits selection to matching artwork arms. It starts untrained and updates from completed, confirmed sell outcomes. Rewards use observed account balance change per time, which can be affected by other account activity. It is not a guaranteed-profit model. [LinUCB reference](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/p661.pdf).

Pump targets use the actual **net liquidation quote**, including AMM impact and trading fees. Defaults are a 35% target for quick plans, 65% for patient plans, an 8% trailing exit after a 15% gain, a 25% stop loss after 45 seconds, and maximum holds of 300/480 seconds. The minimum hold is 10 seconds. A target is an exit rule, not a promise that the market will reach it. `PumpMultiple` and `MaxHoldSeconds` can override the respective defaults.

Posts and Chat remain separate YES/NO switches. Defaults are 35 seconds per feed post and 45 seconds per chat message, up to four posts and three chat messages per coin. Chat uses moderated SendAsync, then ChatRelay:FireServer only on success. Account, market and post signals wake the scheduler; sends still obey cooldowns and one-request-at-a-time processing. All listeners disconnect on unload.

Uses the same [Potassium-style workspace API](https://docs.potassium.pro/api-reference/introduction): readfile, writefile, makefolder, optional isfile/isfolder and checked crypt.hash with SHA-256 fallback. The cache path file is `rugpull-ml-path.json`, and the current cached script is `rugpull-ml/RugpullML-0.2.0.client.luau`. The loader checks byte length/hash, compiles, writes and verifies exact read-back before executing the disk contents.

Pump learning is isolated in **rugpull-ml/pump-learning-<UserId>.json** with .bak/.tmp recovery. Existing v0.1 rug-strategy data is preserved separately and is not reused as pump-strategy training. Set a different StateFile for a fresh experiment. JSON policy data is never evaluated as code.

```lua
getgenv().RugpullMLConfig = {
    StartEnabled = true,
    BuyAmount = 2000,
    ReserveBalance = 0,
    PostsEnabled = true,
    ChatEnabled = true,
    -- Network = "solara", -- optional; otherwise alternates solara / ethera
    -- PumpMultiple = 1.35,
    -- MaxHoldSeconds = 300,
    -- FileIO = {readfile=...,writefile=...,makefolder=...,isfile=...,isfolder=...},
}
```

The existing Save / Stop / SetEnabled / GetDiagnostics API remains available as RugpullML in the shared environment. Diagnostics include the phase, chain, trend, status and pending checkpoint. A request already dispatched can finish after pausing; no following action is dispatched while paused. Concurrent user trades can affect observed balance-based learning.

The inspected Studio export is Place_138310989671326.rbxlx, which reports PlaceId zero. Its live published counterpart and actual internal executor behavior are unverified. Development tests use synthetic RPCs, optionally with the MCP-inspected AccountController, MarketController, SocialController and Curve helpers. No live coins, posts, buys, sells or rugs were sent during development. Game source and account data are not included in the public distribution.

Development checks: `luau.exe -O2 tests/trends.luau`, `luau.exe -O2 tests/core.luau`, `python scripts/test_pump.py --luau C:/path/to/luau.exe`, and `python scripts/test_loader.py --luau C:/path/to/luau.exe`. build.py creates the readable payload; build_loader.py prepares the runtime-only distribution. See verification.json in the development package for exact checks and limits. MIT licence.
