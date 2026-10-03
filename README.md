# CONTRA (Godot 4.7)

[简体中文](README_ZH.md) | **English**

A classic side-scrolling run-and-gun remake built with Godot 4.7. All pixel art
and 8-bit audio are generated procedurally by the Python scripts in `tools/` —
no external assets required.

## Running

Open this folder with Godot 4.7+ (Steam version: "Add New Game" → pick this
folder), or from the command line:

```bash
# Steam version example path
"$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" --path .
```

## Controls (two-hand layout: left hand moves, right hand attacks)

| Key | Action |
|-----|--------|
| A / D (left hand) | Move left / right |
| W / S (left hand) | Aim up / go prone (hold S) |
| J (right hand) | Shoot (8 directions: combine with W / A / S) |
| K or Space (right hand) | Jump (hold for higher; a full jump reaches both platform tiers from the ground) |
| W / S (title screen) | Select 1 PLAYER / 2 PLAYERS |
| A / D (title screen) | Select difficulty EASY / NORMAL / HARD (lives 5/3/2; enemy fire rate and spawn pace vary) |
| Enter or J | Start game |
| M | Mute |

Alternative: Arrow keys to move + Z to jump + X to shoot (classic NES layout —
both layouts are active at the same time).

**Gamepad**: plug and play — P1 uses gamepad 1, P2 uses gamepad 2 in co-op.
Left stick / d-pad to move and aim, `A` to jump, `X` or `RB` to shoot,
`Start` to begin. Keyboard and gamepad can be mixed (one player on keys,
the other on a pad).

**Two-player mode**: pick `2 PLAYERS` on the title screen. P1 wears the red
bandana (WASD + J/K), P2 the blue one (Arrow keys + Z/X). Each player has
independent lives and weapons; the camera follows the leader, stragglers get
pushed back by the left screen edge, and it's Game Over only when every player
is dead.

**Konami code**: on the title screen, enter `↑ ↑ ↓ ↓ ← → ← → B A` → start with
30 lives.

## Gameplay (faithful to the original)

- **8-direction shooting**: horizontal, diagonal-up and straight-up while
  standing; diagonal-up while running; prone shots hugging the ground
- **One hit, one death**: touching an enemy or an enemy bullet kills instantly,
  the body flies backward, and weapons are cleared on death
- **Weapon system** (shoot down the red flying capsule to drop a falcon box):
  - `M` Machine gun: hold for continuous fire
  - `S` Spread gun: 5 pellets per shot in a fan
  - `L` Laser: piercing, single shot while held
  - `F` Fire gun: spiral bullet path
  - `R` Rapid: faster fire rate, stacks
  - `B` Barrier: 12 seconds of invincibility; touching enemies destroys them
  - `★` Falcon: instantly wipes every enemy on screen
- **Level 1 Jungle**: side-scrolling terrain + floating platforms + a bridge
  that explodes segment by segment as you cross + water gaps (swimming,
  dive underwater with ↓, leap out with jump)
- **Level 2 Waterfall**: vertical climb (the camera only moves up), zig-zag
  platforms leading to the fortress on top, falling rocks; twin turrets guard
  the fortress core
- **Level 3 Snowfield**: night snow stage (aurora / snow particles / icy
  water), denser enemy placements
- **Title screen**: three-row cursor menu for 1P/2P, starting stage (STAGE 1~3)
  and difficulty (EASY/NORMAL/HARD); works with mouse and gamepad
- **Bosses**: a red core inside the fortress wall (jungle) / the fortress core
  (waterfall) / the snowfield core. The gate opens and closes periodically —
  you can only damage the core while it's open; **enrage at half HP** — double
  fire rate + five-way volley. Destroying it triggers a chain explosion →
  mission complete → next stage; clearing all stages loops back to the jungle
  and raises the loop count (faster guns, bullets and spawns)
- **Camera**: scrolls forward only, never back (classic rule)
- **High score / career stats**: record-breaking scores, career kills and
  mission count are saved automatically (`user://highscore.cfg`); the title
  screen shows HI-SCORE and the stage-clear panel counts up your score
- **Pause menu**: P — resume / restart / title, plus separate BGM·SFX volume
  sliders (A/D)

## Web build / publishing to itch.io

The Web export is preconfigured (`export_presets.cfg`, no-threads variant, no
special server headers required):

```bash
GODOT="$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot"
"$GODOT" --headless --export-release "Web" export/web/index.html   # rebuild
cd export/web && zip -r ../web.zip .                                # package (index.html at root)
```

Publishing steps are in [ITCH_IO.md](ITCH_IO.md): create an HTML project on
itch.io, upload `export/web.zip` and tick "play in browser", or push updates
incrementally with butler.
Local preview: `python3 tools/preview_server.py export/web` (no-cache headers).

## Project structure

```
project.godot          Project config (320x240 pixel viewport, 3x window)
scenes/                main.tscn (level) / title.tscn (title screen)
scripts/
  boot.gd              Autoload: input registration / audio pool / global state
  game_data.gd         Constants: collision layers / weapon table / level geometry
  game.gd              Main scene: terrain building / enemy spawns / camera / boss fight
  player.gd            Player: movement, jumping, shooting / pose animation / hit & respawn
  enemy*.gd            Runner / sniper / turret / flying capsule
  boss_core.gd         Boss core (shutter timing / three-way volley)
  boss_wall.gd         Boss wall + metal shutter
  bridge.gd            Bridge that explodes segment by segment
  item_box.gd          Weapon pickup box
  bullet.gd / ebullet.gd / fx.gd   Bullets and effects
  hud.gd / title.gd    HUD and title screen
assets/
  sprites/             Procedurally generated PNG sprites
  audio/               Procedurally synthesized 8-bit WAV (16 SFX + 2 music tracks)
  text/                Pre-rendered Chinese text (PingFang)
tools/
  gen_sprites.py       Pixel art generator (Pillow)
  gen_audio.py         Audio synthesizer (pure sine/square/noise synthesis)
  gen_text.py          Chinese text renderer
  test_runner.gd       Headless automated tests (gameplay assertions)
  screenshot_tour.gd   Screenshot tour
  preview_server.py    Local preview server (no-cache)
export/
  web/                 HTML5 build output
  web.zip              itch.io upload package
```

## Tests

```bash
GODOT=".../Godot.app/Contents/MacOS/Godot"   # Steam version Godot binary
"$GODOT" --headless --path . res://tools/test_main.tscn   # exit code 0 = all assertions pass
```

Covers: terrain construction / co-op spawning / high-score persistence /
shooting kills / weapon pickup / shield kill-on-touch / death and life loss /
auto respawn with protection / jump height / bridge explosion / boss trigger
and shutter / boss destruction and stage clear.
