# SCons build options for the smallest Godot 4.7.2 web export template
# that PogoPat still runs on. Based on the Pacey Pat (StickShot) version,
# checked against everything PogoPat uses (scenes, scripts, Poki SDK).
#
# How to use:
#   1. Put this file and pogo_pat.gdbuild in the root of the Godot 4.7.2
#      source folder (next to SConstruct).
#   2. In the Command Prompt (cmd, not PowerShell), activate Emscripten
#      (emsdk_env.bat), then run:
#        python -m SCons profile=custom.py target=template_release optimize=size_extra
#      target and optimize MUST be on the command line: the web platform
#      sets its own defaults for them (template_debug, size), and those win
#      over this file.
#   3. The template lands in bin/ as godot.web.template_release.wasm32.nothreads.zip
#      NOTE: this overwrites the Pacey Pat template in the same bin/ folder.
#      Rename/copy the Pacey Pat zip first, or copy this zip somewhere else
#      afterwards (for example PogoPat-builds/engine/).
#   4. Fill it in under Project > Export > Web > Custom Template > Release.
#
# Needs the project setting rendering/textures/lossless_compression/force_png
# turned on (and all textures reimported, also Sky.jpg), because WebP is
# left out.

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

# PogoPat is fully 2D. (The "Jolt Physics" setting in project.godot is
# for 3D only and is ignored.) No navigation: TileMapLayer's navigation
# code is behind NAVIGATION_2D_DISABLED, and the tile sets have no
# navigation layers.
disable_3d = "yes"
disable_physics_3d = "yes"
disable_navigation_3d = "yes"
disable_navigation_2d = "yes"
disable_xr = "yes"

# Tree, TextEdit, RichTextLabel, ColorPicker, dialogs, SpinBox, ...:
# none are used. PogoPat has Label, Button, Panel, TextureRect,
# TextureProgressBar, CenterContainer, GridContainer and TouchScreenButton.
disable_advanced_gui = "yes"

# 115 more classes the game doesn't use (old TileMap, lights, skeletons,
# animation trees, audio effects, video, parallax, ...). This is the
# Pacey Pat list MINUS what PogoPat does use: TileMapLayer, TileSet,
# TileSetAtlasSource, TileSetSource, TileData, TileMapPattern,
# AnimatedSprite2D, SpriteFrames and TextureProgressBar.
# Careful: disabling a class also disables every class that inherits
# from it, so TileSetSource must stay on for TileSetAtlasSource.
build_profile = "pogo_pat.gdbuild"

# Start with no modules at all and switch on only what the game needs.
modules_enabled_by_default = "no"
module_gdscript_enabled = "yes"         # all game code + the Poki SDK script built at runtime
module_godot_physics_2d_enabled = "yes" # CharacterBody2D, Area2D, tile collision
module_freetype_enabled = "yes"         # drawing text (labels, level numbers)
module_text_server_fb_enabled = "yes"   # simple text: replaces the big text_server_adv (ICU, HarfBuzz)
module_regex_enabled = "yes"            # RegEx in character_body_2d.gd (finding the next level number)
# Left out: svg (only the engine's own theme icons, never shown), webp
# (textures saved as PNG instead, see above) and jpg (Sky.jpg is converted
# to a texture at import time, so the .jpg loader isn't needed at runtime).
# No audio files in the project, so no ogg/vorbis/mp3 either.

# Brotli must stay: Godot's built-in font is stored as WOFF2, and without
# brotli no text at all is shown. Minizip is only for ZIP files.
brotli = "yes"
minizip = "no"
