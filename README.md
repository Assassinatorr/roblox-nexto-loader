# Nexto Roblox runtime

Public runtime-only distribution of the official pretrained Nexto policy port and its client panel. The development repository and inspected game scripts are private.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Assassinatorr/roblox-nexto-loader/v1.5.0/loader.luau"))()
```

The loader reads `roblox-nexto-path.json` in the executor workspace (created with cacheFolder set to roblox-nexto if absent), then checks the versioned cached client. A missing/corrupt copy is downloaded from the pinned revision, checked for byte length and SHA-256, compiled, written, read back and verified before its file contents execute. A valid cache avoids the payload download. The host supplies HTTP, loadstring, readfile, writefile, makefolder and normally isfolder. Rewire `RobloxNextoLoaderConfig.FileIO` if needed. Paths stay relative to the host's executor workspace; no installation directory is scanned. It grants no executor permissions.

The payload contains the actual pretrained Nexto network. It does not call a model server. F6 toggles; F7 unloads. Start/Pause and Unload are also clickable, and the UI displays key/mouse outputs and game-profile selection.

The executor script automatically locates the inspected simulator through its existing prediction-module updates. A temporary observer captures live state and is then removed. Key mode is the default and does not replace Input.Read: output uses the host's keypress/keyrelease and mouse1/2press/release functions, or existing game-targeted virtual input. Set KeyCodeFormat to enum if the host expects Enum.KeyCode values rather than virtual-key numbers. An optional legacy controller mode remains. A Studio bridge and custom ReadState callback are optional.

Start becomes available only after model loading and a valid live state connection. Unconfigured profiles are excluded from the UI cycle. Missing or stale state releases controls and returns to Connecting; the profile button retries discovery. Other controller implementations can register a profile or state provider.

TEAMMATE MODE starts at NO, retaining the v1.2 policy behavior without the v1.3 waiting rule. Tick YES to enable the optional bounded one-second yield. Both modes use the same unchanged pretrained Nexto weights. The checkbox can switch during play. The rule avoids indefinitely extending a wait or dropping the bot's own aerial/immediate defence. Reloading stops previous registered instances in executor globals and `_G`.

Background play defaults on. Rewire BackgroundSendKey/BackgroundSendMouse for a game-targeted mimic host, or explicitly declare InputTargetsGame only when the ordinary host API targets this game while unfocused. Otherwise background output uses existing game-targeted virtual input; a denied capability pauses visibly. OS-global keypress is not sent to another foreground application. The inspected game's replay events trigger one ordinary right-click skip pulse, followed by release and normal play. Different games can supply ReadMatchPhase. No skip remote is fired by the bot.

Cache/download time and inference cost are separate. The neural model still needs live state and local CPU time; no speed-up or live host compatibility is claimed without measuring it in that host.

Version 1.5.0 adds the built-in **Football · 101880234193261** profile for the second inspected simulator. Auto selects it in that place or an owned copy with the same module layout, including Studio exports whose PlaceId is zero. It reads indexed match cars and standard free-play body state, assigned local-car index, both teams, boost/flip/demo flags and 34 pads. Temporary module observers are removed after capture. Normal Input.read stays intact. The session replay flag drives the ordinary right-click skip. Join a standard football match or free play, wait for Ready, then click Start.

Supported profiles: the new place profile, automatic attachment to the original inspected live simulator, an optional owned simulator bridge exposing `roblox-nexto/car-football@1`, attribute-backed Cars/Ball/BoostPads, and registered custom state providers. The policy is for compatible car-football games, with at most six cars and the standard 34-pad layout. Other modes and larger matches need a suitable trained policy. Actual host/gameplay performance for the new profile is unverified; source inspection, native Studio vector checks and complete mocked-runtime inference/input/replay checks passed.

`SimulatorBridge.luau` is an optional original bridge module for your own simulation code; install it beside your client controller and supply the live arena, local-car selector and input interfaces. It contains no copied game scripts. State and controls stay on the client and are not uploaded to this repository.

Version: 1.5.0. Source model: [Rolv-Arild/Necto](https://github.com/Rolv-Arild/Necto), revision `2e6ed7d6ed2b352e8ff529d4a12a0c9c70c28cca`.

Licence: **CC BY-NC-SA 4.0, noncommercial use only**. Attribution and full licence are included. Original Nexto authors do not endorse this port. Keyboard controls share axes and can differ from the original independent bot-controller outputs. Match strength and physics transfer must be checked in each game.

The separate [Rugpull ML runtime](rugpull/README.md) is an original online-learning client for the user's owned Rugpull Simulator game. Its readable source and MIT licence are in `rugpull/`; it uses its own model, cache and panel.
