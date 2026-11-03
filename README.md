# Nexto Roblox runtime

Public runtime-only distribution of the official pretrained Nexto policy port and its client panel. The development repository and inspected game scripts are private.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Assassinatorr/roblox-nexto-loader/v1.2.0/loader.luau"))()
```

The loader shows a download panel, then fetches the versioned payload and opens the ML control panel. It needs the HTTP and `loadstring` capabilities already supplied by your own client admin environment. It grants no executor permissions.

The payload contains the actual pretrained Nexto network. It does not call a model server. F6 toggles; F7 unloads. Start/Pause and Unload are also clickable, and the UI displays key/mouse outputs and game-profile selection.

The executor script automatically locates the inspected simulator through its existing prediction-module updates. A temporary observer captures the live simulator and is then removed; the game's own keyboard resolver receives bot key states. If exposed by the user's internal executor, `getgc` can also supply matching state tables. A Studio bridge and a custom ReadState callback are optional. The script does not grant any new executor capabilities.

Start becomes available only after model loading and a valid live state connection. Unconfigured profiles are excluded from the UI cycle. Missing or stale state releases controls and returns to Connecting; the profile button retries discovery. Other controller implementations can register a profile or state provider.

Supported profiles: automatic attachment to the inspected live simulator, an optional owned simulator bridge exposing `roblox-nexto/car-football@1`, attribute-backed Cars/Ball/BoostPads, and registered custom state providers. The policy is for compatible car-football games, with at most six cars and the standard 34-pad layout. Other game genres require a suitable trained policy.

`SimulatorBridge.luau` is an optional original bridge module for your own simulation code; install it beside your client controller and supply the live arena, local-car selector and input interfaces. It contains no copied game scripts. State and controls stay on the client and are not uploaded to this repository.

Version: 1.2.0. Source model: [Rolv-Arild/Necto](https://github.com/Rolv-Arild/Necto), revision `2e6ed7d6ed2b352e8ff529d4a12a0c9c70c28cca`.

Licence: **CC BY-NC-SA 4.0, noncommercial use only**. Attribution and full licence are included. Original Nexto authors do not endorse this port. Keyboard controls share axes and can differ from the original independent bot-controller outputs. Match strength and physics transfer must be checked in each game.
