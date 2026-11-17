# SCons build options for the smallest Godot 4.7.2 web export template
# that PogoPat still runs on. Based on the Pacey Pat (StickShot) version,
# checked against everything PogoPat uses (scenes, scripts, Poki SDK).
# Full plan and test checklist: Docs/KLEINERE_BUILD.md (fase 3 + 4).
#
# How to use:
#   1. Put this file and pogo_pat.gdbuild (and pogo_pat_max.gdbuild, see
#      build_profile below) in the root of the Godot 4.7.2 source folder
#      (next to SConstruct).
#   2. In the Command Prompt (cmd, not PowerShell), activate Emscripten
#      (emsdk_env.bat), then run:
#        python -m SCons profile=custom.py target=template_release optimize=size_extra
#      target and optimize MUST be on the command line: the web platform
#      sets its own defaults for them (template_debug, size), and those win
#      over this file.
#   3. The template lands in bin/ as godot.web.template_release.wasm32.nothreads.zip
#      NOTE: this overwrites another template (e.g. Pacey Pat) in the same
#      bin/ folder. Rename/copy that zip first, or copy this zip somewhere
#      else afterwards (for example PogoPat-builds/engine/).
#   4. Fill it in under Project > Export > Web > Custom Template > Release
#      AND Debug.
#
# Needs the project setting rendering/textures/lossless_compression/force_png
# turned on (and all textures reimported), because WebP is left out.

platform = "web"

# Same as the Web export preset: Thread Support and Extensions Support off.
threads = "no"
dlink_enabled = "no"

# The Poki SDK talks to the page through JavaScriptBridge. Default is on;
# set explicitly so nobody turns it off by accident.
javascript_eval = "yes"

# Make the engine itself as small as possible. Not "production": in
# 4.7.2 that would quietly turn lto back to "thin", which is bigger.
lto = "full"
debug_symbols = "no"
deprecated = "no"

# PogoPat is fully 2D. No navigation: TileMapLayer's navigation code is
# behind NAVIGATION_2D_DISABLED, and the tile set has no navigation layers.
disable_3d = "yes"
disable_physics_3d = "yes"
disable_navigation_3d = "yes"
disable_navigation_2d = "yes"
disable_xr = "yes"

# Tree, TextEdit, RichTextLabel, ColorPicker, dialogs, SpinBox, ...:
# none are used. PogoPat has Label, Button, Panel, PanelContainer,
# TextureRect, TextureProgressBar and Center/Grid/HBox/VBox/MarginContainer.
# Touch controls, background, saws, wrecking balls and platforms are drawn
# in code (no TouchScreenButton, Line2D, Polygon2D, ...).
disable_advanced_gui = "yes"

# Classes the game doesn't use. Disabling a class also disables every class
# that inherits from it (so TileSetSource must stay on for TileSetAtlasSource).
#
#   pogo_pat.gdbuild      (default, 137 classes) = the Pacey Pat list minus
#                         what PogoPat uses, plus groups 1-3 from
#                         Docs/KLEINERE_BUILD.md (unused 2D nodes, shapes and
#                         texture types). Low risk.
#   pogo_pat_max.gdbuild  (154 classes) = also groups 4-5: animation classes
#                         (AnimationPlayer, AnimatedSprite2D, SpriteFrames,
#                         AtlasTexture, ...) and unused GUI containers.
#                         ONLY after steps 1.4 (remove the empty AnimationPlayer
#                         in LevelComplete.tscn) and 1.5 (tutorial hints drawn
#                         in code) are done; otherwise those scenes won't load.
#                         Test with the checklist in Docs/KLEINERE_BUILD.md; if
#                         something breaks, go back to pogo_pat.gdbuild.
#
# Must stay on (look unused but are needed): AudioStreamMP3, AudioStreamWAV,
# CompressedTexture2D, ImageTexture, GradientTexture2D + Gradient (sky),
# ConvexPolygonShape2D (tile collision), StyleBoxEmpty + StyleBoxFlat (theme),
# Tween + Animation (Tween uses its interpolation code), AnimatableBody2D
# (moving platforms), JavaScriptBridge (Poki).
build_profile = "pogo_pat.gdbuild"

# Start with no modules at all and switch on only what the game needs.
modules_enabled_by_default = "no"
module_gdscript_enabled = "yes"         # all game code + the Poki SDK script built at runtime
module_godot_physics_2d_enabled = "yes" # CharacterBody2D, Area2D, AnimatableBody2D, tile collision
module_freetype_enabled = "yes"         # drawing text (labels, level numbers)
module_text_server_fb_enabled = "yes"   # simple text: replaces the big text_server_adv (ICU, HarfBuzz)
module_regex_enabled = "yes"            # RegEx in level_generator.gd (reading the level data)
module_minimp3_enabled = "yes"          # the sounds are .mp3 (the one .wav is core, needs no module).
                                        # WITHOUT this there is no sound at all on Poki.
# Left out: svg (the star .svg is converted to a texture at import time;
# the svg module is only needed to load .svg at runtime), webp (textures
# saved as PNG instead, see above), jpg (no .jpg at runtime) and ogg/vorbis
# (no .ogg files).

# Brotli must stay: Godot's built-in font is stored as WOFF2, and without
# brotli no text at all is shown. Minizip is only for ZIP files.
brotli = "yes"
minizip = "no"
