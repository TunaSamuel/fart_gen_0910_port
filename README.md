# Fart Generator — Godot port

A conversion of the decompiled GameMaker 8.1 title *Fart Generator* (`fart_gen`)
to **Godot 4**. Load a picture, click where the "hole" is, and the picture emits
gas clouds towards the mouse, complete with sound, shake, zooming and 50 fart
patterns.

Open `project.godot` in Godot 4.4+ (developed and verified against 4.4.1) and
press Play. A fresh clone runs straight away too: scripts preload each other
explicitly instead of relying on the editor's class cache, and images/UI
sprites are decoded from their raw files. The original GameMaker source folders (`Objects/`, `Scripts/`,
`Sprites/`, …) are kept in the repository for reference and are excluded from
Godot's import scan with `.gdignore` files.

## Content folders

The port keeps the original's "drop files next to the game" behaviour. Content
lives in `assets/`:

```
assets/img/            main images       .jpg .jpeg .png .bmp
assets/background/     optional overlay shown behind the main image
                       in Foreground mode (the original's "[F8]" trick)
assets/sound/small/    fart samples      .wav
assets/sound/medium/
assets/sound/big/
assets/sound/huge/
assets/sound/sneaky/
assets/sound/special/
assets/sound/voice1../ optional voices
assets/sound/original1../ optional extra sound groups (Orig1..Orig5)
assets/sound/sfx/      hip press / vacuum effects from the original
```

Everything is read at runtime, so files can be added without touching the code.
When exported, an `assets` folder placed next to the executable is preferred, so
players can keep filling the folders (see *Exporting* below).

Images and WAVs are decoded directly from their files (a small built-in WAV
reader handles 8/16/24/32-bit PCM and float WAVs), so a game exported without
resource imports of those folders still works.

## Controls

| Input | Action |
| --- | --- |
| `Set Hole` button / `S` | arm hole placement, then click the image. Hold `X` while clicking to add an extra hole (up to 9) |
| `0`–`9` (or numpad) | fire pattern 1–10 of the current mode |
| `Space` / left or right click | repeat the last pattern |
| `Shift` | next mode (SHOT → MIST → TORNADO → BURST → EXPERIMENT) |
| mouse wheel | next / previous image |
| `Ctrl` + wheel, `+`/`-` | zoom (0.8× – 4×) |
| middle-drag | pan the image |
| `Backspace` | reset pan |
| `Z` | super zoom |
| `Delete` | clear gas and stop sound |
| `B` | additive / normal blending |
| `R` | reverse fart direction |
| `W` | shake mode: off / vertical / horizontal / zoom / random |
| `C` | slideshow |
| `A` | auto fire (`right` click on the button toggles auto image change) |
| `H` | hide/show the button panel |
| `F8` | foreground mode (needs `assets/background`) |
| `T` | cycle the overlay background |
| `F2` | choose the image folder |
| `V` / `Ctrl`+`V` | play voice / next voice |
| `Esc` | quit (settings and hole positions are saved) |

Buttons behave like the original's: **left** click increments/activates,
**right** click decrements, **middle** click prompts for a numeric value, and
the mouse wheel nudges the value when hovering. The `Color` button randomises
the gas palette (right click restores the default), and the two colour swatches
apply a custom two-colour gradient to every particle type.

## What was ported

* All **50 fart patterns** (5 modes × 10) with their direction/speed spreads,
  particle counts, durations and per-pattern sound-group mapping.
* All the **particle type constructors** (`create_shot_pt`, `create_mist_pt`,
  `create_burst_pt`, `create_smog_pt`, `create_rolling_pt`, `create_fire_pt`,
  `create_gaslack_pt`, `create_shot2_pt`, `create_mist2_pt`, `create_burst2_pt`)
  including step (trail) types, death types, gravity, 3-colour/alpha fades and
  additive blending.
* Emitter behaviour: gas is emitted at the main hole, follows the mouse, can be
  reversed, supports extra holes (`X` + click), and negative particle counts
  ("one particle every N frames").
* Image handling: folder scanning (recursive option), slideshow, zoom, pan,
  foreground overlay, image counter in the title bar.
* Sound: folder banks, random sample + random pitch per shot, voice bank,
  per-pattern sound group selection, synchro mode (gas keeps emitting while the
  sample is still playing).
* Shake, gas size/number/speed/amount scales, blend toggle, clear, auto fire
  with image changing, transparency "foreground" mode.
* Saving: hole positions per image file name, extra holes, and the option
  values (replaces `FartGenerator.ini` + `FartGenerator.sav`).

Not ported, because they depend on Windows-only DLLs or are debug toys:

* FMOD / SuperSound DLL sound systems (`global.use_extra_sound_system`). The
  port always uses Godot's audio, which covers the default (`0`) behaviour.
* `obj_memory` (record/replay fart sequence), the debug soul/heart particle
  generator, the debug window, the `[F8]` file-rename gimmick (replaced by a
  real foreground toggle), screenshot key and the readme window.

## Implementation notes

* **Particle engine** (`scripts/particle_system.gd`): GameMaker's 30 Hz frame
  parameters are converted to a fixed 60 Hz simulation, so motion stays smooth.
  Pattering is drawn with `MultiMesh2D` instances (one per shape/blend pair);
  the six built-in GameMaker particle shapes are generated procedurally
  (`scripts/shape_textures.gd`) since the original bitmaps are not part of the
  decompile.
* **Modes/patterns** (`scripts/gas_generator.gd`) is a direct transcription of
  the `obj_gas_generator` Draw event switch. It ticks at 30 Hz like the
  original, so `farting_time` and sound triggering match.
* **Camera** reproduces the original's variable-size view (`fit_window_size_
  to_image`): the image is letterboxed at 1×, and zooming interpolates the view
  towards the hole.
* **Sound fallback**: the decompiled project contains no fart samples. If all
  sound folders are empty, four fart noises are synthesised
  (`scripts/synth_fart.gd`) so the game is not silent. Any real WAV in the
  folders takes priority.
* Settings and hole positions are stored in `user://fart_generator.cfg`
  (`~/.local/share/godot/app_userdata/Fart Generator/` on Linux).

## Exporting

Because images and WAVs are read from disk at runtime, include the raw asset
folders in the export:

* enable *Export → Resources → Export all resources in the project* **or** add
  `*.png, *.jpg, *.jpeg, *.bmp, *.wav` to the "Filters to export non-resource
  files" field, and
* enable *Export → Resources → Export files outside the project* only if you use
  external folders.

Alternatively, ship a plain `assets/` folder next to the executable — the game
checks there first (`Content.root()`).

## Tests

A headless smoke test boots the real scene, fires all 50 patterns, checks the
WAV reader, particle cap, settings persistence, camera and sound bank:

```
godot --headless --path . res://tests/headless_test.tscn
```

It exits non-zero on failure. All checks currently pass. Rendering and audio
output could not be inspected in the headless build environment (no display),
so the visual result should be checked once in the Godot editor.
