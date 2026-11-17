# PogoPat – zo klein mogelijke web-build

Een web-build bestaat uit twee grote delen:
1. **Het spel** (`index.pck`): scenes, scripts, plaatjes en geluiden. Nu **±2,0 MB** → doel **±0,3 MB**.
2. **De engine** (`index.wasm`): ons eigen uitgeklede engine-sjabloon (`engine-template/`).

Poki serveert beide met brotli/gzip: de echte download is ±25–35% van de bestandsgrootte.

**Volgorde:** fase 1 (bestanden) → fase 2 (export) → fase 3 (engine) → fase 4 (testen).
Per stap staat erbij **wie** het doet: 🎨 editor/afbeelding, 💻 code (kan Claude doen).

---

## 0. Wat het spel echt gebruikt (niet weghalen)

- **Nodes/resources:** Node, Node2D, CanvasLayer, Camera2D, Sprite2D, AnimatedSprite2D + SpriteFrames + AtlasTexture
  (alleen tutorial; vervalt na stap 1.5), TileMapLayer + TileSet + TileSetAtlasSource, CharacterBody2D,
  AnimatableBody2D, Area2D, CollisionShape2D, Rectangle/Circle/CapsuleShape2D, ConvexPolygonShape2D (tile-botsing),
  AudioStreamPlayer + AudioStreamOggVorbis + AudioStreamWAV, Control, Label, Button, Panel, PanelContainer, TextureRect,
  TextureProgressBar, Center/Grid/HBox/VBox/MarginContainer, StyleBoxFlat, StyleBoxEmpty (standaard-thema),
  FontVariation, Tween, Animation (rekenfuncties voor Tween), ConfigFile, RegEx, RandomNumberGenerator,
  JavaScriptBridge (Poki), CompressedTexture2D, ImageTexture, GradientTexture2D + Gradient (lucht, na stap 1.1).
- **Modules:** gdscript, godot_physics_2d, freetype, text_server_fb, regex, **ogg + vorbis** (muziek en laadlus zijn .ogg; alle andere geluiden .wav, dat is ingebouwd). Brotli aan (lettertype is WOFF2).
- `Docs/` (.md, .py) komt niet in de build.

---

## Fase 1 – Bestanden (index.pck): van ±2,0 MB naar ±0,3 MB

| # | Wat | Nu | Na | Wie |
|---|---|---|---|---|
| 1.1 | Lucht: `Sky.jpg` → kleurverloop | 543 KB | ±1 KB | 🎨 |
| 1.2 | ✔ Gedaan: mp3 vervangen door .ogg (muziek, laadlus) en .wav (QOA-gecomprimeerd bij import) | ±950 KB | ±670 KB | – |
| 1.3 | Optioneel: wav-imports op mono (Import → Force → Mono) | ±380 KB wav | ±200 KB | 🎨 |
| 1.4 | Lege `AnimationPlayer` weg | – | – | 🎨 |
| 1.5 | Tutorial-hints (`Controls.png` + `spacebar_spritesheet.png`) in code tekenen | 303 KB | 0 | 💻 |
| 1.6 | Finishvlag (`FinishFlag.png`) in code tekenen | 46 KB | 0 | 💻 |
| 1.7 | Kleine tile-atlas met alleen de gebruikte tiles | 86 KB | ±15 KB | 💻 |
| 1.8 | Ster: `svg/scale` 0,5 | 18 KB | ±5 KB | 🎨 |
| 1.9 | Overige PNG's optimaliseren (laadbalk) | 15 KB | ±8 KB | 🎨 |
| | **Totaal spel-bestanden** | **±2,0 MB** | **±0,3 MB** | |

### 1.1 Lucht → GradientTexture2D 🎨
1. Open `Game.tscn`, selecteer `SkyBackgroundLayer/TextureRect`. Doe daarna hetzelfde in `LevelSelector.tscn` (node `TextureRect`).
2. Inspector → Texture → **New GradientTexture2D**. Fill = Linear, From (0, 0), To (0, 1), Width 4, Height 256.
3. Klik op de Gradient en zet deze punten (gemeten uit Sky.jpg; links en rechts zijn gelijk):
   `0.0 #005FC6` · `0.25 #146DCD` · `0.5 #62A6E5` · `0.75 #A7DAFB` · `1.0 #B2E0FA`
4. Verwijder `Sprites/Sky.jpg` in het FileSystem-paneel.
- ✅ Lucht ziet er hetzelfde uit (ook het tintje per wereld blijft: dat zit in `modulate`).

### 1.2 Geluid: ✔ gedaan
Alle `.mp3` zijn vervangen door de bestanden in `OGG Sounds/` (muziek, laadlus) en `Wav Sounds/` (de rest);
`Sounds/` bevat alleen nog `bounce-pogo-stick.wav`. De laadlus (`Charging--Loop-Sound.ogg`) staat op herhalen, zoals de mp3.
De wav's worden bij import gecomprimeerd (QOA, `compress/mode=2`).

### 1.3 Optioneel: wav's mono 🎨
Per wav in `Wav Sounds/`: Import-paneel → **Force → Mono** aan → Reimport. Halveert de grootste wav's
(Charging-Sound 133 KB, victory 66 KB). Alleen doen als ze niet bewust stereo klinken.

### 1.4 Lege AnimationPlayer weg 🎨
`LevelComplete.tscn` → node `AnimationPlayer` verwijderen (alle animaties daar zijn Tweens) → opslaan.
- ✅ Het "level gehaald"-scherm animeert nog (paneel + sterren).

### 1.5 Tutorial-hints in code 💻
`Tutorial.tscn` gebruikt `Controls.png` (WASD/pijltjes, 255 KB) en `spacebar_spritesheet.png` (geanimeerde spatiebalk, 48 KB).
Vervangen door één script dat toetsjes (afgeronde vierkantjes met letters W A S D / pijltjes) en een spatiebalk
tekent en laat oplichten, zelfde plek en gedrag (wisselen WASD ↔ pijltjes, spatiebalk "indrukken").
Daarna beide PNG's + `tutorial_prompts.gd` + AnimatedSprite2D/SpriteFrames/AtlasTexture weg.
- ✅ Level 1 op desktop toont dezelfde hints; geen PNG's meer in `Sprites/` behalve tilesheet en laadbalk.

### 1.6 Finishvlag in code 💻
`FinishFlag.png` (46 KB) vervangen door een getekende geblokte vlag op een paal (zelfde grootte en plek).
- ✅ Vlag ziet er hetzelfde uit; finish werkt nog (de botsing is onafhankelijk van het plaatje).

### 1.7 Kleine tile-atlas 💻
We gebruiken ±16 van de 448 tiles uit `platformerPack_industrial_tilesheet@2.png`:
grond (4,0) (5,0) (8,0) (9,0) (8,1) (9,1), spikes (18,7), pijlborden (26,8)(27,8)(26,9)(27,9)(26,12)(27,12)(26,13)(27,13),
finish-streep (14,8) (15,8). Nieuwe PNG met alleen deze tiles (bijv. 8×2 tiles = 560×140 px), `tileset.tres` opnieuw
(botsing + `is_trap` op de spike-tile) en de coördinaten in `level_generator.gd` aanpassen. Daarna de grote sheet weg.
- ✅ Alle 100 levels zien er hetzelfde uit; spikes doden; finish-streep zichtbaar.

### 1.8 Ster kleiner importeren 🎨
`Sprites/UI/star-01-classic.svg` selecteren → tab Import → `svg/scale` = 0.5 → Reimport.
(De sterren zijn TextureRects die zich aan hun vak aanpassen: ze blijven even groot op het scherm.)
- ✅ Sterren in het "level gehaald"-scherm even groot en scherp.

### 1.9 Laadbalk-PNG's optimaliseren 🎨
`barA_pill_progress.png` en `barA_pill_under.png` door TinyPNG / pngquant halen (zelfde naam).

---

## Fase 2 – Exportinstellingen 🎨

1. `GameManager` (autoload): `unlock_all` = **uit**, `touch_testen` = **uit**.
2. Project → Export → **Web**:
   - Options → VRAM Texture Compression → **For Desktop: uit** (2D, alles lossless)
   - Options → Html → **Export Icon: uit**
   - Resources → Export Mode staat al op "Export all resources" (laten)
   - Resources → **Filters to exclude**: `addons/poki-sdk/plugin.gd, addons/poki-sdk/editor-plugin-templates/*`
   - Script Export Mode staat al op **Binary tokens (compressed)** (laten). Thread/Extensions support uit (laten).
3. `project.godot`: regel `rendering_device/driver.windows="d3d12"` mag weg (niet voor web).

---

## Fase 3 – Engine-sjabloon opnieuw bouwen (index.wasm)

**Verplicht**, ook als je verder niets aan de engine wilt veranderen: in het huidige sjabloon staan de ogg/vorbis-modules
uit, dus op Poki speelt de **muziek en de laadlus niet**. `custom.py` heeft ze al aan staan
(`module_ogg_enabled` en `module_vorbis_enabled`; de mp3-module is uit, er zijn geen .mp3-bestanden meer).

### 3.1 Extra klassen uitzetten
Dit staat al klaar in twee profielen in `engine-template/` (kies in `custom.py` bij `build_profile`):
- **`pogo_pat.gdbuild`** (standaard, 137 klassen uit): de oude lijst + groep 1–3 hieronder. Laag risico.
- **`pogo_pat_max.gdbuild`** (154 klassen uit): ook groep 4–5. **Pas gebruiken na stap 1.4 en 1.5**, anders laden
  `LevelComplete.tscn` en de tutorial niet. Testen met fase 4; gaat er iets mis, terug naar `pogo_pat.gdbuild`.

De groepen:

| Groep | Klassen | Risico |
|---|---|---|
| 1. 2D-nodes | `CPUParticles2D`, `Line2D`, `Polygon2D`, `Light2D`, `PointLight2D`, `RigidBody2D`, `CollisionPolygon2D`, `SubViewportContainer` | laag |
| 2. Vormen | `SegmentShape2D`, `SeparationRayShape2D`, `WorldBoundaryShape2D`, `ConcavePolygonShape2D` | laag |
| 3. Textures | `AnimatedTexture`, `CameraTexture`, `CurveTexture`, `CurveXYZTexture`, `GradientTexture1D`, `MeshTexture`, `ExternalTexture`, `DrawableTexture2D`, `PortableCompressedTexture2D`, `Texture2DRD` | laag |
| 4. Animatie (na stap 1.4 en 1.5) | `AnimationPlayer`, `AnimationMixer`, `AnimationLibrary`, `AnimatedSprite2D`, `SpriteFrames`, `AtlasTexture` | middel |
| 5. GUI | `ColorRect`, `ScrollContainer`, `HScrollBar`, `VScrollBar`, `HSplitContainer`, `VSplitContainer`, `FlowContainer`, `HFlowContainer`, `VFlowContainer`, `FoldableContainer`, `HSeparator`, `VSeparator`, `VirtualJoystick` | middel (standaard-thema verwijst naar sommige) |

**Nooit uitzetten:** `AudioStreamOggVorbis`, `AudioStreamWAV`, `CompressedTexture2D`, `ImageTexture`, `GradientTexture2D`,
`Gradient`, `ConvexPolygonShape2D`, `StyleBoxEmpty`, `StyleBoxFlat`, `Tween`, `Animation`, `JavaScriptBridge`.

### 3.2 Bouwen
1. Kopieer `engine-template/custom.py` en `engine-template/pogo_pat.gdbuild` naar de Godot 4.7.2-broncode (naast `SConstruct`).
2. **Command Prompt** (niet PowerShell): `emsdk_env.bat` activeren, dan:
   ```
   python -m SCons profile=custom.py target=template_release optimize=size_extra
   ```
3. Resultaat: `bin/godot.web.template_release.wasm32.nothreads.zip`
   (overschrijft een eventueel ander sjabloon in die map: eerst kopiëren/hernoemen).
4. Project → Export → Web → Custom Template: **Release én Debug** naar dit zip-bestand.

---

## Fase 4 – Exporteren en testen

1. Exporteer naar een lege map. Start daar `python -m http.server` en open `http://localhost:8000`.
2. Checklist:
   - [ ] Geluid: springen, opladen, dood, finish, ster, menu-muziek
   - [ ] Level 1 (tutorial-hints), een level met kogel, zaag, platform, lift, toren
   - [ ] Level gehaald-scherm (sterren animeren), level selector, tandwiel, pauze (Esc)
   - [ ] Telefoon: touch-besturing liggend en staand
   - [ ] Browserconsole (F12): geen rode fouten zoals "class not found"
3. Fout na een groep uit 3.1? Die groep weer weghalen, opnieuw bouwen.
4. Noteer na elke build de groottes:

| Build | index.wasm | index.pck | Opmerking |
|---|---|---|---|
| Huidig | | ±2,0 MB | |
| Na fase 1+2 | | ±0,3 MB | |
| Na fase 3 | | | |
