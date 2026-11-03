# Attribution and modifications

Original project: Necto / Nexto by Rolv-Arild and the Necto/Nexto contributors.

Source: https://github.com/Rolv-Arild/Necto

Revision: 2e6ed7d6ed2b352e8ff529d4a12a0c9c70c28cca

Licence: Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International.
The full original licence is included in LICENSE.

The original checkpoint, agent.py, nexto_obs.py and upstream README are retained in vendor/nexto. The model and observation/action behavior are adapted into native Luau. The fixed action-embedding network is evaluated at export time; remaining tensors are retained as float32. The matrix implementation packs triples of float32 values into Luau vectors. This introduces normal floating point rounding differences, measured in validation.json.

New integration code supplies the Roblox state adapter, default keyboard/mouse mapping, local admin input transport, panel, pause/unload behavior, package builder and verification scripts. Adaptations are supplied under the same CC BY-NC-SA 4.0 licence. The original authors do not endorse this port.

Rocket League, Roblox and related marks belong to their respective owners. This repository includes no Rocket League game art, maps, audio, or game executable.
