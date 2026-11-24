extends Node2D

# Bouwt level GameManager.current_level uit Scripts/level_data.gd (gemaakt uit Docs/LEVELS.md).
# Elke bouwsteen staat precies beschreven in Docs/LEVELS.md, hoofdstuk 2.
#
# Coordinaten: kolom x (naar rechts), rij (naar beneden). f = de rij van de bovenste grondtegel
# waar je op staat ("vloer"). Omhoog = kleinere rij.

const LevelData = preload("res://Scripts/level_data.gd")

const TILE = 70
const HALF_TILE = 35          # halve tile, als heel getal
const SOURCE = 1
const TOP_TILES = [Vector2i(4, 0), Vector2i(5, 0)]
const FILL_TILES = [Vector2i(8, 0), Vector2i(9, 0), Vector2i(8, 1), Vector2i(9, 1)]
const SPIKE_UP = Vector2i(18, 7)
const ARROW_RIGHT = Vector2i(26, 8)
const ARROW_LEFT = Vector2i(26, 12)
const FINISH_STREEP = [Vector2i(14, 8), Vector2i(15, 8)]   # geel-zwarte streep: hier telt de finish

const SAW = preload("res://Scenes/Obstacles/Sawblade.tscn")
const BALL = preload("res://Scenes/Obstacles/WreckingBall.tscn")
const PLATFORM = preload("res://Scenes/Obstacles/MovingPlatform.tscn")
const TUTORIAL = preload("res://Scenes/Tutorial.tscn")
const Achtergrond = preload("res://Scripts/construction_background.gd")
const TouchControls = preload("res://Scripts/touch_controls.gd")

const SAW_SPEED = {"normaal": 150.0, "snel": 320.0, "razend": 400.0}
const VSAW_SPEED = {"normaal": 150.0, "snel": 250.0}
const SAW_RADIUS = {"klein": 70.0, "normaal": 100.0, "groot": 130.0}
const BALL_SWING = {"normaal": 1.6, "snel": 2.2}
const PLATFORM_SPEED = {"normaal": 170.0, "snel": 230.0}
const PLATFORM_TILES = 3
const WALL_W = 18          # breedte muren aan begin/eind (net buiten beeld)
const MARGE = 12           # muur: zoveel rijen boven het hoogste punt
const MARGE_ONDER = 22     # grond: zoveel rijen onder het laagste punt in beeld (portret kijkt ~20 rijen omlaag)
const ZICHT = 17           # zoveel kolommen ziet de camera links en rechts van de speler

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var player = $Player
@onready var camera = $Camera2D
@onready var flag = $FinishFlag

var level = 1
var decor: TileMapLayer   # pijlborden in torens (geen botsing)
var vulling: TileMapLayer # binnenste grondtiles: de speler kan ze nooit raken, dus geen botsing (sneller laden)
var solids = {}           # Vector2i -> true   (losse grond: richels, vloeren, muren)
var surface = {}          # kolom -> rij van de bovenste grondtegel (grond loopt door naar beneden)
var walls = []            # kolommen van de hoge muren aan begin en eind
var f = 0                 # huidige vloer (rij)
var x = 0                 # huidige kolom
var spawn_col = 0
var kogels = []            # ophangpunten van de sloopkogels (daar komt een kraan in de achtergrond)

# ---------------------------------------------------------------------------------------------
func _ready() -> void:
	level = clampi(GameManager.current_level, 1, LevelData.LEVELS.size() - 1)

	decor = TileMapLayer.new()
	decor.tile_set = tilemap.tile_set
	decor.collision_enabled = false
	decor.z_index = -1
	add_child(decor)

	vulling = TileMapLayer.new()
	vulling.tile_set = tilemap.tile_set
	vulling.collision_enabled = false
	vulling.rendering_quadrant_size = 32
	add_child(vulling)

	for seg in LevelData.LEVELS[level].split(" · "):
		_segment(seg.strip_edges())

	_paint()

	# Getekende bouwplaats-achtergrond (elk level anders) + kranen bij de sloopkogels
	var achtergrond = Achtergrond.new()
	add_child(achtergrond)
	achtergrond.bouw(level, -WALL_W * TILE, (x + WALL_W) * TILE, camera, kogels, get_node_or_null("SkyBackgroundLayer/TextureRect"))

	var spawn = Vector2(spawn_col * TILE + HALF_TILE, -60)
	player.global_position = spawn
	player.spawn_position = spawn
	camera.global_position = spawn

	var stars = LevelData.STARS[level]
	player.fast_time = stars[0]
	player.par_time = stars[1]

	var label = find_child("LevelLabel", true, false)
	if label:
		label.text = "%d / %d" % [level, GameManager.LEVEL_COUNT]
	# Portret: camera iets omhoog, zodat de speler lager in beeld staat en je meer boven je ziet
	get_tree().root.size_changed.connect(_camera_portret)
	_camera_portret()

	var touch = GameManager.is_mobile() or GameManager.touch_testen
	if touch:
		# Joystick + springknop; in level 1 lichten ze op tot je ze gebruikt
		var laag = CanvasLayer.new()
		laag.layer = 4
		add_child(laag)
		var controls = TouchControls.new()
		laag.add_child(controls)
		controls.setup(player, level == 1)
	elif level == 1:
		var tut = TUTORIAL.instantiate()
		tut.position = spawn - Vector2(-93, 270)
		add_child(tut)

func _camera_portret() -> void:
	var beeld = get_viewport().get_visible_rect().size
	if beeld.y > beeld.x:
		camera.offset = Vector2(0, -beeld.y / camera.zoom.y * 0.15)
	else:
		camera.offset = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	# Vangnet: ver onder de grond = dood (zou niet moeten kunnen)
	if player.is_dead or player.level_finished:
		return
	var col = floori(player.global_position.x / TILE)
	var lowest = -9999
	for c in range(col - 6, col + 7):
		lowest = max(lowest, surface.get(c, -9999))
	if lowest > -9999 and player.global_position.y > (lowest + 3) * TILE:
		player.die()

# ---------------------------------------------------------------------------------------------
# Lezen: "OP(3,4)+VZAAG(4,normaal,0)@trede 2" -> [[naam, [args], plek], ...]
func _parse(seg: String) -> Array:
	var re = RegEx.new()
	re.compile("([A-Z][A-Z-]*)\\(([^)]*)\\)(@[^+]*)?")
	var out = []
	for m in re.search_all(seg):
		var args = []
		for a in m.get_string(2).split(","):
			if a.strip_edges() != "":
				args.append(a.strip_edges())
		out.append([m.get_string(1), args, m.get_string(3).trim_prefix("@").strip_edges()])
	if out.is_empty():
		push_error("Level %d: kan '%s' niet lezen" % [level, seg])
	return out

func _segment(seg: String) -> void:
	var parts = _parse(seg)
	if parts.is_empty():
		return
	var targets = _build(parts[0][0], parts[0][1])
	for i in range(1, parts.size()):
		var att = parts[i]
		var plek: String = att[2]
		var list = []
		if plek == "":
			list = [targets.get("main")]
		else:
			var soort = plek.get_slice(" ", 0)
			var nums = plek.get_slice(" ", 1) if plek.contains(" ") else soort
			if soort.is_valid_int():
				soort = "platform"
			for nr in nums.split(","):
				var lst = targets.get(soort, [])
				var idx = nr.to_int() - 1
				if idx >= 0 and idx < lst.size():
					list.append(lst[idx])
				else:
					push_error("Level %d: plek @%s bestaat niet in %s" % [level, plek, seg])
		for t in list:
			if t != null:
				_attach(att[0], att[1], t)
			else:
				push_error("Level %d: %s heeft geen plek voor %s" % [level, seg, att[0]])

# Een doel: waar een obstakel komt. cx = midden in pixels, floor = vloerrij, col0/w = kolommen (voor KUIL op trede)
func _target(col0: int, w: int, floor_row: int) -> Dictionary:
	return {"cx": (col0 + w / 2.0) * TILE, "floor": floor_row, "col0": col0, "w": w}

func _i(v) -> int:
	return String(v).to_int()   # werkt ook voor "+2" en "-1"

# ---------------------------------------------------------------------------------------------
# Bouwstenen
func _build(naam: String, a: Array) -> Dictionary:
	match naam:
		"START":
			return _start(a[0])
		"FINISH":
			return _finish(a[0])
		"VLAK":
			var t = _target(x, _i(a[0]), f)
			_ground(_i(a[0]))
			return {"main": t}
		"OP", "AF":
			f += -_i(a[0]) if naam == "OP" else _i(a[0])
			var t = _target(x, _i(a[1]), f)
			_ground(_i(a[1]))
			return {"main": t}
		"HEUVEL":
			for v in a:
				f -= _i(v)
				_ground(3)
			return {}
		"TRAP", "TRAP-AF":
			var treden = []
			for i in _i(a[0]):
				f += -_i(a[1]) if naam == "TRAP" else _i(a[1])
				treden.append(_target(x, _i(a[2]), f))
				_ground(_i(a[2]))
			return {"trede": treden, "main": treden[floori(treden.size() / 2.0)]}
		"KUIL":
			var t = _target(x, _i(a[0]), f)
			_pit(_i(a[0]), _i(a[1]))
			_ground(2)
			return {"main": t, "kuil": [t]}
		"KUIL-OP":
			var h = _i(a[1])
			var t = _target(x, _i(a[0]), f)
			_pit_at(_i(a[0]), max(f, f - h) + 1)
			f -= h
			_ground(2)
			return {"main": t, "kuil": [t]}
		"DAL":
			var w = _i(a[0])
			var d = _i(a[1])
			var s = _i(a[2])
			var c0 = x
			for c in w:
				surface[x + c] = f + d
			for c in s:
				_spike(c0 + floori((w - s) / 2.0) + c, f + d - 1)
			x += w
			_ground(2)
			return {"main": _target(c0, w, f + d)}
		"PILAREN":
			return _pilaren(a)
		"TREDEPILAREN":
			return _tredepilaren(a)
		"ZAAG":
			var c0 = x
			_ground(_i(a[0]) + 4)
			_saw(Vector2((c0 + 2) * TILE, f * TILE), false, _i(a[0]), a[1], float(a[2]), a[3])
			return {}
		"VZAAG":
			var c0 = x
			_ground(4)
			_vsaw((c0 + 2) * TILE, f, _i(a[0]), a[1], float(a[2]))
			return {}
		"KOGEL":
			return _kogel(a)
		"KOGEL-KUIL":
			return _kogel_kuil(a)
		"PLATFORM":
			var w = _i(a[0])
			var c0 = x
			_pit(w, 2)
			_ground(3)
			_platform(Vector2(c0 * TILE, f * TILE), false, w - PLATFORM_TILES, a[1], float(a[2]))
			return {"main": _target(c0, w, f)}
		"PLATFORMS":
			var n = _i(a[0])
			var c0 = x
			_pit(9 * n, 2)
			_ground(3)
			var lst = []
			for i in n:
				_platform(Vector2((c0 + 9 * i) * TILE, f * TILE), false, 9 - PLATFORM_TILES, a[1], float(a[2]))
				lst.append(_target(c0 + 9 * i, 9, f))
			return {"platform": lst, "main": lst[0]}
		"LIFT", "LIFT-OVER":
			var h = _i(a[0])
			_ground(3)
			var c0 = x
			_pit_at(3, f + 1, false)
			_platform(Vector2(c0 * TILE, f * TILE), true, h, "normaal", 0.0)
			var t = _target(c0, 3, f)
			if naam == "LIFT-OVER":
				_pit_at(_i(a[1]), f + 1)      # spikes onder de oversteek
			f -= h
			_ground(3)
			return {"main": t}
		"LIFT-AF":
			var h = _i(a[0])
			_ground(3)
			var c0 = x
			_pit_at(3, f + h + 3, false)      # liftschacht, spikes diep onderin
			for c in 3:
				_spike(c0 + c, f + h + 2)
			_platform(Vector2(c0 * TILE, (f + h) * TILE), true, h, "normaal", 0.0)
			_pit_at(3, f + h + 1)             # spikes tussen lift en uitgang
			f += h
			_ground(3)
			return {"main": _target(c0, 3, f)}
		"TOREN":
			return _toren(_i(a[0]), a[1], Array(String(a[2]).split("/")))
		"SCHACHT":
			return _schacht(_i(a[0]), a[1], _i(a[2]))
	push_error("Level %d: onbekende bouwsteen %s" % [level, naam])
	return {}

func _start(soort: String) -> Dictionary:
	_wall(x - WALL_W)
	var w = {"vlak": 8, "kort": 3}.get(soort, 5)
	spawn_col = x + (3 if soort == "vlak" else 1)
	_ground(w)
	return {}

func _finish(soort: String) -> Dictionary:
	# Het finishgebied = de grond onder de vlag (col0, breedte). Die tiles krijgen de geel-zwarte streep.
	var col0: int
	var breed: int
	match soort:
		"piek":
			f -= 2
			col0 = x
			breed = 3
			_ground(3)
			f += 2
			_ground(4)
			f -= 2                         # vlag en finishgebied staan op de piek
		"dal":
			f += 2
			col0 = x
			breed = 6
			_ground(6)
		"pilaar":
			_pit(3, 1)
			f -= 3
			col0 = x
			breed = 3
			_ground(3)
		"dak":
			col0 = x
			breed = 4
			_ground(4)
		_:
			col0 = x
			breed = 6
			_ground(6)
	var vloer = f
	if soort == "piek":
		f += 2
	_wall(x)

	# Vlag midden op het finishgebied
	flag.global_position = Vector2((col0 + floori(breed / 2.0)) * TILE + HALF_TILE, vloer * TILE - 49)
	# Botsing: de hele breedte van het finishgebied, van de grond tot 3 tiles erboven
	var vorm = flag.get_node("CollisionShape2D")
	var rect = RectangleShape2D.new()
	rect.size = Vector2(breed * TILE, 3 * TILE)
	vorm.shape = rect
	vorm.global_position = Vector2((col0 + breed / 2.0) * TILE, vloer * TILE - 1.5 * TILE + 10)
	# Geel-zwarte streep over de bovenrand van die tiles (eigen laag, geen botsing, boven de grond)
	var streep = TileMapLayer.new()
	streep.tile_set = tilemap.tile_set
	streep.collision_enabled = false
	streep.z_index = 1
	add_child(streep)
	for c in breed:
		streep.set_cell(Vector2i(col0 + c, vloer), SOURCE, FINISH_STREEP[posmod(col0 + c, 2)])
	return {}

func _pilaren(a: Array) -> Dictionary:
	var hs = Array(String(a[0]).split("/")).map(func(v): return String(v).to_int())
	var b = _i(a[1])
	var gs = Array(String(a[2]).split("/")).map(func(v): return String(v).to_int())
	var kuilen = []
	var c0 = x
	for i in gs.size():
		kuilen.append(_target(x, gs[i], f))
		_pit(gs[i], 1)
		if i < hs.size():
			for c in b:
				surface[x + c] = f - hs[i]
			x += b
	_ground(2)
	return {"kuil": kuilen, "main": _target(c0, x - c0, f)}

func _tredepilaren(a: Array) -> Dictionary:
	var n = _i(a[0])
	var s = _i(a[1])
	var g = _i(a[2])
	var tops = []
	for i in n:
		tops.append(2 + i * s)
	var pit_row = max(f, f - tops.min()) + 1
	var kuilen = []
	for i in n + 1:
		kuilen.append(_target(x, g, f - (tops[i - 1] if i > 0 else 0)))
		_pit_at(g, pit_row)
		if i < n:
			for c in 2:
				surface[x + c] = f - tops[i]
			x += 2
	f -= tops[-1]
	_ground(2)
	return {"kuil": kuilen, "main": kuilen[0]}

func _kogel(a: Array) -> Dictionary:
	var k = _i(a[0])
	var extra = String(a[3]) if a.size() > 3 else ""
	var c0 = x
	if extra == "rand":
		_ground(4)
		_ball(Vector2((c0 + 2) * TILE, (f - k - 2) * TILE), k, float(a[1]), a[2])
		return {}
	_ground(2 * k + 1)
	_ball(Vector2((c0 + k) * TILE + HALF_TILE, (f - k - 2) * TILE), k, float(a[1]), a[2])
	if extra.begins_with("muur "):
		f -= extra.substr(5).to_int()
		_ground(3)
	return {}

func _kogel_kuil(a: Array) -> Dictionary:
	var w = _i(a[0])
	var k = _i(a[1])
	var total = max(w + 2, 2 * k + 1)
	var c0 = x
	var left = floori((total - w) / 2.0)
	_ground(left)
	_pit(w, 1)
	_ground(total - left - w)
	_ball(Vector2(c0 * TILE + total * TILE / 2.0, (f - k - 2) * TILE), k, float(a[2]), a[3])
	if a.size() > 4 and String(a[4]).begins_with("muur "):
		f -= String(a[4]).substr(5).to_int()
		_ground(3)
	return {"main": _target(c0, total, f)}

# Toren: zie Docs/LEVELS.md 2.8. Wordt als raster gebouwd en daarna geplaatst.
func _toren(n: int, richting: String, inhoud: Array) -> Dictionary:
	var W = 22
	var GAP = 6
	var HOLE = 4
	var B = GAP * n + 1
	var g = []
	for r in B + 1:
		g.append([])
		for c in W:
			g[r].append("#" if r == B else ".")
	var s = {}
	for k in range(1, n + 1):
		s[k] = B - GAP * (k - 1)
	for r in range(s[n], B):
		g[r][W - 1] = "#"
	for r in range(s[n] - 5, s[2] + 1):
		g[r][1] = "#"
		g[r][2] = "#"
	for k in range(1, n):
		if k % 2 == 1:
			for r in [s[k] - 2, s[k] - 1]:
				g[r][W - 3] = "#"
				g[r][W - 2] = "#"
			for c in range(1, W - 1 - HOLE):
				g[s[k + 1]][c] = "#"
			g[s[k + 1] - 1][floori(W / 2.0) + 2] = "L"
		else:
			for r in [s[k] - 2, s[k] - 1]:
				g[r][3] = "#"
				g[r][4] = "#"
			for c in range(3 + HOLE, W):
				g[s[k + 1]][c] = "#"
			g[s[k + 1] - 1][floori(W / 2.0) + 2] = "R"
	var m = floori(W / 2.0)
	for k in range(1, n + 1):
		var woord = String(inhoud[k - 1]) if k - 1 < inhoud.size() else "spikes"
		match woord:
			"spikes":
				for c in [m - 2, m - 1, m]:
					g[s[k] - 1][c] = "^"
			"zaag", "zaag-snel":
				g[s[k] - 1][m - 3] = "s" if woord == "zaag" else "t"
				for c in range(m - 2, m + 2):
					g[s[k] - 1][c] = "-"
			"vzaag":
				g[s[k] - 5][m] = "Z"
				for r in range(s[k] - 4, s[k]):
					g[r][m] = "|"
	var rows = []
	for r in g:
		rows.append("".join(r))
	if richting == "omlaag":
		rows = _mirror(rows)
	_place_grid(rows)
	return {}

# Schacht: zie Docs/LEVELS.md 2.8.
func _schacht(h: int, richting: String, rr: int) -> Dictionary:
	var W = 9
	var B = h + 3
	var g = []
	for r in B + 1:
		g.append([])
		for c in W:
			g[r].append("#" if r == B else ".")
	for r in range(B - h, B):
		g[r][W - 1] = "#"                 # muur aan de uitgangskant (staat op de grond), uitgang bovenop
	# Geen muur aan de ingangskant: die zou los in de lucht hangen. De richels daar zijn losse
	# opstapjes van 2 breed, boven het veilige stuk grond bij de ingang (nooit boven spikes).
	for c in range(3, W - 1):
		g[B - 1][c] = "^"                 # spikes, behalve 3 tiles bij de ingang
	var richels = []
	var i = 1
	while i * rr < h:
		var r = B - i * rr
		var cols = [W - 3, W - 2] if i % 2 == 1 else [1, 2]
		for c in cols:
			g[r][c] = "#"
		richels.append(r)
		i += 1
	var rows = []
	for r in g:
		rows.append("".join(r))
	if richting == "omlaag":
		rows = _mirror(rows)
	var x0 = x
	var dy = _place_grid(rows)
	var lijst = []
	for r in richels:
		lijst.append({"cx": (x0 + W / 2.0) * TILE, "floor": r + dy, "col0": x0, "w": W})
	return {"richel": lijst}

# ---------------------------------------------------------------------------------------------
# Obstakels bij een bouwsteen (+X of +X@plek)
func _attach(naam: String, a: Array, t: Dictionary) -> void:
	match naam:
		"HANGZAAG":
			var tiles = _i(a[1])
			var pos = Vector2(t.cx - tiles * TILE / 2.0, (t.floor - _i(a[0])) * TILE)
			_saw(pos, false, tiles, a[2], 0.0, a[3])
		"VZAAG":
			_vsaw(t.cx, t.floor, _i(a[0]), a[1], float(a[2]))
		"ZAAG":
			var tiles = _i(a[0])
			_saw(Vector2(t.cx - tiles * TILE / 2.0, t.floor * TILE), false, tiles, a[1], float(a[2]), a[3])
		"KOGEL":
			var k = _i(a[0])
			_ball(Vector2(t.cx, (t.floor - k - 2) * TILE), k, float(a[1]), a[2])
		"KUIL":
			var w = _i(a[0])
			var d = _i(a[1])
			var c0 = t.col0 + floori((t.w - w) / 2.0)
			for c in w:
				surface[c0 + c] = t.floor + d
				_spike(c0 + c, t.floor + d - 1)
		_:
			push_error("Level %d: %s kan niet als bijlage" % [level, naam])

# ---------------------------------------------------------------------------------------------
# Hulpfuncties
func _ground(w: int) -> void:
	for c in w:
		surface[x + c] = f
	x += w

func _pit(w: int, d: int) -> void:
	_pit_at(w, f + d)

func _pit_at(w: int, bottom_row: int, spikes: bool = true) -> void:
	for c in w:
		surface[x + c] = bottom_row
		if spikes:
			_spike(x + c, bottom_row - 1)
	x += w

func _spike(c: int, r: int) -> void:
	tilemap.set_cell(Vector2i(c, r), SOURCE, SPIKE_UP)

func _wall(from_col: int) -> void:
	for c in range(from_col, from_col + WALL_W):
		surface[c] = f
		walls.append(c)

func _saw(pos: Vector2, vertical: bool, tiles: int, speed: String, offset: float, maat: String) -> void:
	var saw = SAW.instantiate()
	saw.position = pos
	saw.vertical = vertical
	saw.distance = tiles * TILE
	saw.speed = (VSAW_SPEED if vertical else SAW_SPEED).get(speed, 150.0)
	saw.radius = SAW_RADIUS.get(maat, 100.0)
	saw.start_offset = offset
	add_child(saw)

# Verticale zaag: bovenste stand midden 5 rijen boven de vloer, zakt 'slag' rijen
func _vsaw(cx: float, floor_row: int, slag: int, speed: String, offset: float) -> void:
	_saw(Vector2(cx, (floor_row - 5) * TILE + HALF_TILE), true, slag, speed, offset, "normaal")

func _ball(anchor: Vector2, k: int, fase: float, speed: String) -> void:
	var ball = BALL.instantiate()
	ball.position = anchor
	ball.chain_length = k * TILE + HALF_TILE
	ball.ball_radius = 80.0
	ball.swing_speed = BALL_SWING.get(speed, 1.6)
	ball.phase_deg = fase
	add_child(ball)
	kogels.append(anchor)

func _platform(pos: Vector2, vertical: bool, tiles: int, speed: String, offset: float) -> void:
	var p = PLATFORM.instantiate()
	p.position = pos
	p.vertical = vertical
	p.distance = tiles * TILE
	p.width = PLATFORM_TILES * TILE
	p.speed = PLATFORM_SPEED.get(speed, 170.0)
	p.start_offset = offset
	add_child(p)

func _decor(bottom_left: Vector2i, atlas: Vector2i) -> void:
	for dx in 2:
		for dy in 2:
			decor.set_cell(bottom_left + Vector2i(dx, dy - 1), SOURCE, atlas + Vector2i(dx, dy))

# Raster plaatsen (toren/schacht). Kolom 0 begint op de huidige vloer. Geeft dy terug (rij-verschuiving).
func _place_grid(rows: Array) -> int:
	var h = rows.size()
	var w = rows[0].length()
	var dy = f - _stack_top(rows, 0)
	for c in w:
		var col = x + c
		surface[col] = _stack_top(rows, c) + dy
		for r in h:
			var cell = Vector2i(col, r + dy)
			match rows[r][c]:
				"#":
					solids[cell] = true
				"^":
					_spike(col, r + dy)
				"s", "t":
					var n = 0
					while c + 1 + n < w and rows[r][c + 1 + n] == "-":
						n += 1
					_saw(Vector2(col * TILE + HALF_TILE, (r + dy + 1) * TILE), false, n, "normaal" if rows[r][c] == "s" else "snel", 0.0, "klein")
				"Z":
					var n = 0
					while r + 1 + n < h and rows[r + 1 + n][c] == "|":
						n += 1
					_saw(Vector2(col * TILE + HALF_TILE, (r + dy) * TILE + HALF_TILE), true, n, "normaal", 0.0, "normaal")
				"L":
					_decor(cell, ARROW_LEFT)
				"R":
					_decor(cell, ARROW_RIGHT)
	f = _stack_top(rows, w - 1) + dy
	x += w
	return dy

func _stack_top(rows: Array, col: int) -> int:
	var r = rows.size() - 1
	while r > 0 and rows[r - 1][col] == "#":
		r -= 1
	return r

func _mirror(rows: Array) -> Array:
	var out = []
	var r1 = RegEx.new()
	r1.compile("(-+)([st])")
	for row in rows:
		var m: String = row.reverse()
		m = r1.sub(m, "$2$1", true)
		out.append(m)
	return out

# ---------------------------------------------------------------------------------------------
func _paint() -> void:
	# Muren aan begin en eind MARGE rijen boven het hoogste punt (sprong haalt max ~7)
	var highest = 0
	for c in surface:
		highest = min(highest, surface[c])
	for cell in solids:
		highest = min(highest, cell.y)
	for c in walls:
		surface[c] = highest - MARGE
	# Grond loopt per kolom door tot MARGE rijen onder het laagste punt dat vanaf daar in beeld kan
	# komen (17 kolommen links en rechts). Dieper is nooit zichtbaar en kost alleen laadtijd.
	var cols = surface.keys()
	cols.sort()
	var diepte = {}
	for c in cols:
		var laagste = surface[c]
		for k in range(c - ZICHT, c + ZICHT + 1):
			laagste = max(laagste, surface.get(k, laagste))
		diepte[c] = laagste + MARGE_ONDER
	# Kolommen: per kolom van de bovenkant tot de diepte. "Binnen" (geen botsing nodig) als de kolommen
	# links en rechts op die hoogte (en een rij erboven en eronder) ook grond zijn.
	for c in cols:
		var top = surface[c]
		var lo = max(surface.get(c - 1, 99999), top, surface.get(c + 1, 99999))
		var hi = min(diepte.get(c - 1, -99999), diepte[c], diepte.get(c + 1, -99999)) - 1
		for r in range(top, diepte[c]):
			var cell = Vector2i(c, r)
			solids.erase(cell)                    # niet dubbel tekenen in de lus hieronder
			var tile = FILL_TILES[posmod(c, 2) + posmod(r, 2) * 2]
			if r == top and not solids.has(cell + Vector2i.UP):
				tile = TOP_TILES[posmod(c, 2)]
			var binnen = r > lo and r < hi
			(vulling if binnen else tilemap).set_cell(cell, SOURCE, tile)
	# Losse grond (richels, torenvloeren, muren in torens): weinig tiles, gewone controle
	for cell in solids:
		var tile = FILL_TILES[posmod(cell.x, 2) + posmod(cell.y, 2) * 2]
		if not solids.has(cell + Vector2i.UP) and not (surface.has(cell.x) and cell.y - 1 >= surface[cell.x] and cell.y - 1 < diepte[cell.x]):
			tile = TOP_TILES[posmod(cell.x, 2)]
		tilemap.set_cell(cell, SOURCE, tile)
