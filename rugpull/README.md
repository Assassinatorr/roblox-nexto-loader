# Rugpull ML 0.3.1

Readable client automation for the user's owned Roblox Rugpull Simulator. Execute in the internal executor, wait for the account to connect, then click Start Bot / F6. F7 unloads. It starts paused unless `RugpullMLConfig.StartEnabled=true`.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Assassinatorr/roblox-nexto-loader/rugpull-v0.3.1/rugpull/loader.luau"))()
```

The cycle is now **create -> 2,000 dev buy -> wait for a pump -> sell the full position -> repeat**. It uses normal game calls and does not call RequestRug. A failed atomic dev buy gets a separate quoted Buy only when failure was explicitly reported. Unknown outcomes are checkpointed and reconciled without repeating the transaction.

Version 0.2.1 fixes `Cannot require a non-RobloxScript module from a RobloxScript`. The shipped bundle contains no `require()` calls. It uses `ReplicatedStorage.Remotes` directly, reads account/market/feed snapshots, and subscribes to AccountUpdate, CoinAdded/Removed, full/fast MarketTick, PostAdded/Removed and MarketEvent. Local reserve calculations provide ordinary buy/sell quotes; no controller helper is called. Push updates take precedence over stale RPC responses. It needs neither hookfunction nor a change to thread identity. [Potassium hookfunction reference](https://docs.potassium.pro/api-reference/Closure%20Library/hookfunction), [loadstring reference](https://docs.potassium.pro/api-reference/Closure%20Library/loadstring).

Version 0.3.1 fixes an initial connection race: market rows arriving before their coin metadata are queued and merged with the snapshot, preserving the latest full reserves and fast price. A removed coin is not recreated by a late tick. The queue holds at most 256 unknown coins. Metadata is still accepted if an older queued row had to be evicted.

While holding, a small observer records the highest net quote received for that position between workflow updates. A brief peak can therefore inform the next trailing/crash check even if price has already pulled back. The observer performs no remote calls, UI rendering or learner selection. It watches one coin, uses constant-size quote state, resets across position-quantity changes and disconnects on unload. Stall timing uses when the high was observed. Trading and UI processing remain capped at two workflow updates per second; a peak that never reaches this client cannot be recovered.

`StartEnabled=true` now waits for the first valid connection and starts once if the remotes load late. An explicit Pause cancels that pending start. The ordinary default remains paused.

It alternates **Solara and Ethera**; set `Network="solara"` or `"ethera"` to fix the chain. The default entry is 2,000 market balance plus trading fees. Normal launch fees also apply: without passes the initial requirement is 2,270 on Solara or 2,640 on Ethera. `ReserveBalance` now defaults to zero. Low-balance status shows the exact balance, required amount and fee breakdown. The old six-owned-coins client guard was removed: Config.GlobalMarket.MaxLiveCoins describes live-market watching, and the server enforces creation eligibility.

It reads recent **in-game** posts through the normal latest feed and listens to MarketEvent. Text such as “Space is trending” selects Space art, including a rocket or NASA theme. Server categories remain Animals, Space, Food, Gaming, Fantasy, Robots, Internet, Absurd and Seasonal. Posts are parsed into known categories only; instructions inside posts are never executed. Old or negative trend signals are excluded. “DeadSec” is recognised as a name instead of being discarded as a dead-market signal.

There are **48 locally generated pixel themes**: nine original designs; 14 company interpretations (Apple, Microsoft, Google, YouTube, Spotify, Tesla, Nike, Adidas, Nvidia, Discord, GitHub, Roblox, Nintendo, McDonalds); 14 flags (UK, USA, France, Germany, Italy, Japan, Ukraine, Canada, Brazil, India, Spain, Poland, China, EU); DedSec, Anonymous, LulzSec and CCC; FBI, CIA, NSA, MI5, MI6, NASA and Interpol. They are small hand-authored pixel interpretations, with unofficial fan-art descriptions. They use ordinary 32x32 RGBA buffers and preserve valid category/icon pairs. No image API or asset downloads are required. See art-preview.png in the development package for the exact generated buffers.

Click **ART** to cycle All, Original, Companies, Flags, Hackers and Agencies for future launches. The selection is saved. All follows the detected category when one is available. A specific set takes priority when that set has no art for the current trend. `ArtTheme="fbi"` or `ArtTheme="dedsec"` forces one design; `deadsec` is an accepted alias. Changing the art preference does not modify a coin that is already launched. Drafts vary their names, tickers, palette/background and small pixel details.

The online LinUCB learner chooses campaign variants/holding plans. For the first six categories, a detected trend limits selection to the corresponding arms. Visual designs are selected from the expanded library within the chosen art preference/category. The learner starts untrained and updates from completed, confirmed sell outcomes. Rewards use observed account balance change per time, which can be affected by other account activity. Existing pump learning and saved campaigns remain compatible. [LinUCB reference](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/p661.pdf).

Version 0.3.0 defaults to **adaptive exits**. The 35%/65% quick/patient thresholds arm a stall exit rather than selling immediately through a rising pump. The position continues while meaningful new highs arrive. A pullback exits at 8% for quick plans or 12% for patient plans once the peak has reached a 15% gain. The trail tightens to at most 5% after 10x entry cost, and 3% after 100x. Above the 35%/65% threshold, no meaningful new high for 8/15 seconds triggers a stall exit. The minimum hold for stall exits is 10 seconds; maximum holds remain 300/480 seconds.

A **20% drop between observations within five seconds** triggers a sudden-crash exit. A **25% loss from entry cost** triggers a stop loss. These and profit-protection pullbacks can act before the minimum hold. Rules use the actual **net liquidation quote**, including AMM impact and trading fees. A million market cap is not a million in sale proceeds. `CashOutValue=1000000` optionally exits at that net position value; there is no default million-value target. `ExitMode="fixed"` restores selling at the fixed profit threshold. `PumpMultiple`, `TrailDrawdown`, `PumpStallSeconds`, `CrashDrop`, `CrashWindow` and `MaxHoldSeconds` can override the respective defaults. Known declined sells retry with a fresh quote after two seconds; ambiguous outcomes remain paused and are never resubmitted blindly.

Risk observations and peaks are checkpointed at most once every five seconds while holding, and immediately with a transaction intent. A saved peak is used after reload. The bot observes prices at its bounded workflow cadence; it cannot predict random events, guarantee a pump, or ensure a request fills before a crash. Moving directly from one quote to another can skip prices that were never observed.

Posts and Chat remain separate YES/NO switches. Defaults are 35 seconds per feed post and 45 seconds per chat message, up to four posts and three chat messages per coin. Chat uses moderated SendAsync, then ChatRelay:FireServer only on success. Push events update a local cache, with account reconciliation every 10 seconds and market/feed reconciliation every 30 seconds. Workflow processing is limited to two updates per second, even during tick bursts. Sends obey cooldowns and one-request-at-a-time processing. All listeners disconnect on unload.

Uses the same [Potassium-style workspace API](https://docs.potassium.pro/api-reference/introduction): readfile, writefile, makefolder, optional isfile/isfolder and checked crypt.hash with SHA-256 fallback. The cache path file is `rugpull-ml-path.json`, and the current cached script is `rugpull-ml/RugpullML-0.3.1.client.luau`. The loader checks byte length/hash, compiles, writes and verifies exact read-back before executing the disk contents.

Pump learning is isolated in **rugpull-ml/pump-learning-<UserId>.json** with .bak/.tmp recovery. Existing v0.1 rug-strategy data is preserved separately and is not reused as pump-strategy training. Set a different StateFile for a fresh experiment. JSON policy data is never evaluated as code.

```lua
getgenv().RugpullMLConfig = {
    StartEnabled = true,
    BuyAmount = 2000,
    ReserveBalance = 0,
    PostsEnabled = true,
    ChatEnabled = true,
    ArtSet = "All", -- Original / Companies / Flags / Hackers / Agencies
    ExitMode = "adaptive",
    -- ArtTheme = "fbi", -- force one design; e.g. dedsec, apple, japan
    -- CashOutValue = 1000000, -- net sell value of the position, not market cap
    -- Network = "solara", -- optional; otherwise alternates solara / ethera
    -- PumpMultiple = 1.35,
    -- MaxHoldSeconds = 300,
    -- FileIO = {readfile=...,writefile=...,makefolder=...,isfile=...,isfolder=...},
}
```

The existing Save / Stop / SetEnabled / GetDiagnostics API remains available as RugpullML in the shared environment. Diagnostics include the phase, chain, trend, status and pending checkpoint. A request already dispatched can finish after pausing; no following action is dispatched while paused. Concurrent user trades can affect observed balance-based learning.

The inspected Studio export is Place_138310989671326.rbxlx, which reports PlaceId zero. Its live published counterpart and actual internal executor behavior are unverified. Tests execute the exact bundled runtime against serialized synthetic remotes, with no game modules present and require forced to raise the reported error. Separate tests cover million-plus net-value observations, crash exits, saved peaks, all 48 logos, stale snapshot/event races, fees, slippage, cache integrity and learner persistence. No live coins, posts, buys, sells or rugs were sent during development. Game source and account data are not included in the public distribution.

Development checks: `luau.exe -O2 tests/trends.luau`, `luau.exe -O2 tests/core.luau`, `luau.exe -O2 tests/remote_adapter.luau`, `luau.exe -O2 tests/exit_policy.luau`, `luau.exe -O2 tests/art.luau`, `python scripts/test_pump.py --luau C:/path/to/luau.exe`, and `python scripts/test_loader.py --luau C:/path/to/luau.exe`. The runtime harness also accepts `--checks tests/flash_peak.luau`, `--checks tests/init_recovery.luau` and `--checks tests/reload_peak.luau` for targeted regressions. build.py creates the readable payload and rejects remaining require calls; build_loader.py prepares the runtime-only distribution. See verification.json in the development package for exact checks and limits. MIT licence. Existing company, agency and group marks belong to their respective owners; this collection makes no affiliation claim.
