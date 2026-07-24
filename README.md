Palworld YetAnotherMinimap Mod
---

To work on this mod put all assets to `Content/Mods/YetAnotherMinimap` of your [Palworld Modding Kit](https://github.com/localcc/PalworldModdingKit), then start the modding kit.

## In-game settings localization (zh / en)

The blueprint settings panel (`WBT_MinimapSettings`) ships with English labels. A small **UE4SS Lua companion** can re-label the panel to match the game's current language:

| Game language | Settings panel |
|---|---|
| `zh*` (简体/繁体) | Chinese |
| anything else | English (stock strings) |

### Install the companion

Copy the folder into your active UE4SS `Mods` directory (same place `BPModLoaderMod` lives):

```text
UE4SS/YetAnotherMinimapLoc/enabled.txt
UE4SS/YetAnotherMinimapLoc/Scripts/main.lua
```

Ensure it is enabled in `Mods/mods.txt`:

```text
YetAnotherMinimapLoc : 1
```

Palworld only applies language changes after a full restart — the script detects the culture once per run via `KismetInternationalizationLibrary`.

This does **not** replace the LogicMod pak and does not require the outdated Nexus “CHS” DLL patch (which targeted older 0.5.x builds).

## Why this is open source

This mod is open source so that if I (SvenBrnn) ever disappear or stop maintaining it, others have everything they need to fork it and keep it alive. It also serves as an open example of how this kind of mod is built, for anyone learning Palworld/UE4SS modding.

## License

This project is licensed under the [MIT License](LICENSE). In short: you're free to use, modify, fork, and continue development of this mod, but the original copyright notice (crediting SvenBrnn as the original author) must be kept in any copy, fork, or derivative work.
