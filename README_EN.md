# CONTRA (Godot 4.7)

[简体中文](README.md) | **English**

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
| Enter or J | Start game |
| M | Mute |

Alternative: Arrow keys to move + Z to jump + X to shoot (classic NES layout —
both layouts are active at the same time).

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
- **Level**: jungle terrain + floating platforms + a bridge that explodes
  segment by segment as you cross + water gaps (falling in is fatal)
- **Boss**: a red core embedded in the fortress wall; the metal shutter opens
  and closes periodically — you can only damage the core while it's open
  (HP 30+). Destroying it triggers a chain explosion → mission complete →
  the next loop raises the difficulty (faster guns and bullets)
- **Camera**: scrolls forward only, never back (classic rule)

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
```

## Tests

```bash
GODOT=".../Godot.app/Contents/MacOS/Godot"   # Steam version Godot binary
"$GODOT" --headless --path . res://tools/test_main.tscn   # exit code 0 = all assertions pass
```

Covers: terrain construction / shooting kills / weapon pickup / shield
kill-on-touch / death and life loss / auto respawn with protection / bridge
explosion / boss trigger and shutter / boss destruction and stage clear.
