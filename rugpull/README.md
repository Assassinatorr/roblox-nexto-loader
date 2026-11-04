# Rugpull ML

An original, readable client script for the user's owned **Rugpull Simulator** Roblox game. It creates simulated coins with varied original 32×32 pixel-art logos, posts about its own coin in the game's feed, sends in-game chat messages, waits for server rug eligibility, performs the fictional rug action and repeats. Execution opens a mouse-operated panel and starts paused.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Assassinatorr/roblox-nexto-loader/rugpull-v0.1.0/rugpull/loader.luau"))()
```

Version **0.1.0**. The source is unobfuscated. The runtime-only public folder contains this README, licence, readable client, loader and hash manifest. Inspected game scripts, account state and learned data are kept out of that public distribution.

## Running it

Execute the loader in the existing internal client executor, wait for the game account/controllers to connect, review the next coin's art and click **Start Bot**. **F6** toggles Start/Pause; **F7**, **Unload** and **×** unload. Posts and Chat each have an independent YES/NO button. The choices and learned state are saved on checkpoints, Save and unload. A new instance stops the previous idle instance; an outstanding request blocks duplicate initialization.

The script manages one coin it created at a time. It reads the assigned account and live market, uses a fresh name/ticker and a different recent art image, reserves the launch fee, promotes its coin, waits for the normal minimum age and server eligibility, submits `RequestRug` with the matching ticker and moves to the next campaign. It does not manage unrelated existing coins. Repeated rugs incur the game's normal reputation penalties and can reduce future demand.

Default message cadence is **35 seconds per feed post** and **45 seconds per chat message**, with at most four posts and three chat messages per coin. The scheduler also respects the inspected game cooldowns. Chat goes through Roblox `TextChannel:SendAsync`; the game's local `ChatRelay` is used only after a successful moderated send. An unavailable/refused message gets a longer backoff. It uses the same ordinary client interfaces, filters and eligibility responses as the inspected game.

The workflow keeps running when the game loses focus because it uses the game's client interfaces. Real background scheduling, host compatibility and performance require validation in the user's executor.

## What learns

The policy is an **online disjoint LinUCB contextual bandit** with 12 campaign arms and eight features. Each arm combines one of six original art families (cat, rocket, robot, donut, ghost, alien) with a quick or patient holding plan. It observes balance, owned/live coin count and aggregate heat, price movement, volume and holder counts. It learns campaign selection from completed, confirmed game outcomes. Names, palettes, image detail and message templates supply variation.

It starts **untrained**. It contains no pretrained rug-pulling model, LLM or external inference service. The workflow enforces the game rules; the learned model chooses the campaign art family and holding plan. The first campaigns gather observations, and learned performance is not established until real outcomes are measured.

The reward is `tanh((confirmed payout + observed coin dev fees - quoted launch fee) / 500 / max(age / 120, 1))`. This is a bounded estimate of fictional game profit per time, not a causal or guaranteed-profit evaluation. Unconfirmed payouts add no learning sample. The quick plan normally holds for at least the game's minimum rug age plus 15 seconds; the patient plan adds 90 seconds. It checks a payout target and a later exit deadline, while requiring server eligibility every time.

Algorithm reference: [Li, Chu, Langford and Schapire, 2010, Algorithm 1](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/p661.pdf). Matrix updates, learned arm preference, analytical regression results and save/restore behavior are checked in the included development tests. Synthetic test rewards are not shipped as training data.

## Executor workspace and API

Uses the same [Potassium-style file API](https://docs.potassium.pro/api-reference/introduction) as the earlier bot: `readfile`, `writefile`, `makefolder` and optional `isfile`/`isfolder`, exposed as native globals or through `getgenv()`. The internal executor supplies these capabilities. No installation/backend path is inspected.

The HTTPS loader reads or creates `rugpull-ml-path.json` in the workspace:

```json
{"cacheFolder":"rugpull-ml"}
```

It downloads `rugpull-ml/RugpullML-0.1.0.client.luau` from an immutable Git revision, checks byte length and SHA-256, compiles it, writes it, verifies exact read-back and executes the disk contents. A valid cache avoids another client download. SHA uses a checked `crypt.hash(data,"sha256")` when available and the included pure-Luau fallback otherwise. [writefile](https://docs.potassium.pro/api-reference/FileSystem%20Library/writefile), [readfile](https://docs.potassium.pro/api-reference/FileSystem%20Library/readfile), [crypt.hash](https://docs.potassium.pro/api-reference/Crypt%20Library/crypt.hash)

The learning file is `rugpull-ml/learning-<Roblox UserId>.json`, with `.bak` and `.tmp` recovery files. It stores model matrices, counts, current campaign, intent checkpoints and bounded history. It is JSON data and is never evaluated as code. With the example workspace layout, the folder resolves beneath `%LOCALAPPDATA%\Potassium\workspace\rugpull-ml`. Rewiring the internal file API changes that root naturally.

To use the downloaded script directly:

```lua
loadstring(readfile("rugpull-ml/RugpullML-0.1.0.client.luau"),"Rugpull ML")()
```

Or paste all of the development package's `dist/Execute.luau` into the internal executor. That self-contained file still uses the workspace APIs for learning state.

Optional settings before execution:

```lua
getgenv().RugpullMLConfig = {
    StartEnabled = false,
    PostsEnabled = true,
    ChatEnabled = true,
    ReserveBalance = 1000, -- fictional market balance kept aside
    PostEvery = 35,
    ChatEvery = 45,
    MaxPostsPerCoin = 4,
    MaxChatsPerCoin = 3,
    Exploration = 0.6,
    RequestTimeout = 20,
    -- CacheFolder = "rugpull-ml",
    -- StateFile = "learning-experiment-1.json",
    -- FileIO = {readfile=...,writefile=...,makefolder=...,isfolder=...,isfile=...},
}
```

The loader has separate `RugpullMLLoaderConfig.FileIO`, `CacheFolder` and `PathFile` options if the host needs rewiring. Its resolved FileIO and folder become runtime defaults. `RugpullML:Save()`, `:SetEnabled(true/false)`, `:Stop()` and `:GetDiagnostics()` are available in the shared environment. A new StateFile creates a fresh learner while preserving the previous file.

## Requests, pausing and verification limits

Creation and rug intents are saved before dispatch. If a response is lost, the next run reconciles the bot's unique owned ticker or rugged coin state and pauses when the outcome remains unknown. It does not blindly repeat that mutation. Message slots are reserved before submission to avoid replaying them after reload. Pausing prevents new actions; an already dispatched request may finish and be recorded. The learning file uses checked writes and a valid backup, rather than claiming filesystem-atomic replacement.

The inspected file is `Place_138310989671326.rbxlx`, opened through Studio MCP on 4 November 2026. It reports PlaceId zero and contains the client export. The numeric place hint comes from that file name; matching game/controller capabilities also identify compatible owned copies. The live server implementation was not inspected, and no real launch, post, chat, rug, purchase or gameplay was performed by this development session.

Validation details are in the development package's `verification.json`. Actual executor execution, live filtering/acceptance, rewards and profitability remain unverified. The preview uses ordinary pixel Frames and needs no EditableImage setting.

## Development

`python scripts/build.py` produces the readable payload and paste-ready wrapper. Run `luau.exe -O2 tests/core.luau`, then `python scripts/test_runtime.py --luau C:/path/to/luau.exe` and `python scripts/test_loader.py --luau C:/path/to/luau.exe`. The optional art-preview tool uses `requirements-dev.txt`. `scripts/build_loader.py` prepares the dedicated runtime-only folder; it does not push anything. No game source is included in the package.
