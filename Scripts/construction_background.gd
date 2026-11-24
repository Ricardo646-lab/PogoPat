extends Node2D

# Getekende achtergrond: een bouwplaats. Elk level anders (seed = levelnummer), elke wereld eigen licht.
# Regels: GEEN zwart of donkere kleuren (de speler is zwart), alles licht en wat vervaagd zodat
# duidelijk is dat het achtergrond is. Er wordt niets geladen: alles wordt met lijnen en vlakken getekend.
#
# Lagen bewegen langzamer mee dan de wereld (diepte). Parallax2D staat uit in onze engine-build,
# daarom doen we het zelf: positie = camera * (1 - factor).

class Stuk extends Node2D:
	var vormen = []
	func _draw() -> void:
		for v in vormen:
			match v[0]:
				"rect": draw_rect(v[1], v[2])
				"lijn": draw_line(v[1], v[2], v[3], v[4])
				"poly": draw_colored_polygon(v[1], v[2])

class Laag extends Node2D:
	const STUK = 1500.0      # breedte van een stuk achtergrond (px)
	var factor = 0.2           # 0 = staat stil op het scherm, 1 = beweegt mee met de wereld
	var vormen = []            # ["rect", Rect2, Color] / ["lijn", a, b, Color, dikte] / ["poly", punten, Color]
	var camera: Camera2D

	func _process(_delta: float) -> void:
		if camera:
			position = camera.get_screen_center_position() * (1.0 - factor)

	# Verdeel de vormen over stukken van STUK px breed. Godot tekent alleen stukken die in beeld zijn.
	# Vormen breder dan een stuk (grondstrook, bouwhek) gaan in een eigen stuk.
	func verdeel() -> void:
		var stukken = {}
		for v in vormen:
			var links: float
			var breed: float
			match v[0]:
				"rect":
					links = v[1].position.x
					breed = v[1].size.x
				"lijn":
					links = min(v[1].x, v[2].x)
					breed = abs(v[2].x - v[1].x)
				_:
					links = v[1][0].x
					breed = 0.0
			var sleutel = "breed" if breed > STUK else str(floori(links / STUK))
			if not stukken.has(sleutel):
				var st = Stuk.new()
				add_child(st)
				stukken[sleutel] = st
			stukken[sleutel].vormen.append(v)
		vormen = []

# Kleuren per wereld: ver (skyline), midden (beton), steiger, kraan, lucht-tint
const PALETTEN = [
	{"ver": Color(0.72, 0.81, 0.90), "beton": Color(0.86, 0.84, 0.78), "steiger": Color(0.95, 0.74, 0.48), "kraan": Color(0.98, 0.82, 0.42), "lucht": Color(1, 1, 1)},          # 1 ochtend
	{"ver": Color(0.80, 0.80, 0.86), "beton": Color(0.88, 0.82, 0.72), "steiger": Color(0.96, 0.70, 0.45), "kraan": Color(0.99, 0.70, 0.40), "lucht": Color(1.0, 0.97, 0.92)},  # 2 steengroeve
	{"ver": Color(0.74, 0.84, 0.86), "beton": Color(0.84, 0.86, 0.80), "steiger": Color(0.93, 0.76, 0.50), "kraan": Color(0.97, 0.86, 0.45), "lucht": Color(0.95, 1.0, 0.98)},  # 3 zagerij
	{"ver": Color(0.78, 0.78, 0.84), "beton": Color(0.87, 0.83, 0.80), "steiger": Color(0.94, 0.66, 0.52), "kraan": Color(0.99, 0.76, 0.48), "lucht": Color(1.0, 0.95, 0.95)},  # 4 sloopwijk
	{"ver": Color(0.70, 0.80, 0.92), "beton": Color(0.85, 0.85, 0.85), "steiger": Color(0.92, 0.78, 0.52), "kraan": Color(0.98, 0.84, 0.40), "lucht": Color(0.95, 0.98, 1.0)},  # 5 hoogbouw (middag)
	{"ver": Color(0.82, 0.78, 0.76), "beton": Color(0.90, 0.84, 0.76), "steiger": Color(0.96, 0.68, 0.46), "kraan": Color(0.99, 0.72, 0.42), "lucht": Color(1.0, 0.93, 0.86)},  # 6 kloof (warm)
	{"ver": Color(0.76, 0.80, 0.84), "beton": Color(0.84, 0.84, 0.82), "steiger": Color(0.90, 0.74, 0.56), "kraan": Color(0.96, 0.80, 0.50), "lucht": Color(0.96, 0.97, 1.0)},  # 7 fabriek
	{"ver": Color(0.86, 0.76, 0.78), "beton": Color(0.90, 0.82, 0.80), "steiger": Color(0.97, 0.66, 0.52), "kraan": Color(0.99, 0.70, 0.50), "lucht": Color(1.0, 0.86, 0.82)},  # 8 mijn (avond)
	{"ver": Color(0.74, 0.78, 0.86), "beton": Color(0.82, 0.84, 0.88), "steiger": Color(0.88, 0.76, 0.60), "kraan": Color(0.95, 0.82, 0.52), "lucht": Color(0.88, 0.92, 1.0)},  # 9 storm (koel)
	{"ver": Color(0.84, 0.80, 0.90), "beton": Color(0.90, 0.86, 0.88), "steiger": Color(0.96, 0.72, 0.56), "kraan": Color(0.99, 0.78, 0.48), "lucht": Color(1.0, 0.92, 0.94)},  # 10 top (zonsondergang)
]

var rng = RandomNumberGenerator.new()
var pal: Dictionary

# level: levelnummer. van/tot: horizontaal bereik van het level (pixels).
# kogels: ophangpunten van de sloopkogels (wereldcoordinaten) -> daar komt een kraan.
# kleuren: palet uit palettes.gd ({} = originele look met luchtfoto en kleuren per wereld)
func bouw(level: int, van: float, tot: float, camera: Camera2D, kogels: Array, lucht: CanvasItem, kleuren: Dictionary = {}) -> void:
	rng.seed = level * 104729 + 17
	pal = PALETTEN[clampi(floori((level - 1) / 10.0), 0, 9)].duplicate()
	pal["container"] = [Color(0.70, 0.84, 0.92), Color(0.80, 0.90, 0.74)]
	pal["cabine"] = Color(0.78, 0.88, 0.96)
	if not kleuren.is_empty():
		pal.ver = kleuren.gebouw.lerp(kleuren.lucht, 0.35)   # verder weg = meer lucht-kleur
		pal.beton = kleuren.gebouw
		pal.steiger = kleuren.rand
		pal.kraan = kleuren.accent
		pal.container = [kleuren.gebouw.lerp(kleuren.grond, 0.4), kleuren.grond.lerp(kleuren.lucht, 0.4)]
		pal.cabine = kleuren.lucht.lightened(0.3)
	if lucht:
		if kleuren.is_empty():
			lucht.modulate = pal.lucht
		else:
			# Vlakke lucht in plaats van de foto
			lucht.self_modulate = Color(1, 1, 1, 0)
			var vlak = ColorRect.new()
			vlak.color = kleuren.lucht
			vlak.set_anchors_preset(Control.PRESET_FULL_RECT)
			vlak.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lucht.add_child(vlak)
	z_index = -20

	var ver = _laag(0.12, camera)
	var midden = _laag(0.32, camera)
	_skyline(ver, van, tot)
	_bouwplaats(midden, van, tot)
	midden.modulate = Color(1, 1, 1, 0.7)    # waas: duidelijk achter het speelveld
	ver.verdeel()
	midden.verdeel()

	# Kranen bij de sloopkogels: in de wereld zelf (factor 1), achter de grond, half doorzichtig
	if not kogels.is_empty():
		var kranen = _laag(1.0, null)
		kranen.z_index = 10              # binnen de achtergrond vooraan, maar nog achter de grond
		kranen.modulate = Color(1, 1, 1, 0.75)
		var i = 0
		for anker in kogels:
			var kant = -1.0 if (i + level) % 2 == 0 else 1.0
			_kogelkraan(kranen, anker, kant)
			i += 1
		kranen.verdeel()

func _laag(factor: float, camera: Camera2D) -> Laag:
	var l = Laag.new()
	l.factor = factor
	l.camera = camera
	add_child(l)
	return l

# Het zichtbare bereik van een laag in zijn eigen coordinaten (met marge)
func _bereik(f: float, van: float, tot: float) -> Vector2:
	return Vector2(van * f - 1800, tot * f + 1800)

# --- Verre laag: skyline van (half)afgebouwde flats + een paar verre kranen ---
func _skyline(l: Laag, van: float, tot: float) -> void:
	var r = _bereik(l.factor, van, tot)
	var basis = 420.0
	var kleur = pal.ver
	var raam = kleur.lightened(0.18)
	l.vormen.append(["rect", Rect2(r.x, basis, r.y - r.x, 4000), kleur.lightened(0.05)])   # grond onder de skyline
	var x = r.x
	while x < r.y:
		var w = rng.randf_range(140, 320)
		var h = rng.randf_range(260, 820)
		var top = basis - h
		var af = rng.randf() < 0.65
		var gebouwd = h * (rng.randf_range(0.55, 0.85) if not af else 1.0)
		l.vormen.append(["rect", Rect2(x, basis - gebouwd, w, gebouwd), kleur])
		for wy in range(int(basis - gebouwd + 24), int(basis - 30), 46):     # ramen: 1 strook per verdieping
			l.vormen.append(["rect", Rect2(x + 14, wy, w - 28, 22), raam])
		if not af:                                                          # bovenste verdiepingen: alleen skelet
			_skelet(l, x, basis - gebouwd, w, h - gebouwd, kleur.darkened(0.06), 3.0)
		if rng.randf() < 0.12:
			_kraan(l, x + w * rng.randf_range(0.2, 0.8), top - rng.randf_range(80, 220), basis, kleur.darkened(0.04), 0.55)
		x += w + rng.randf_range(20, 140)

# --- Middenlaag: betonskeletten, steigers, torenkranen, containers, bouwhek ---
func _bouwplaats(l: Laag, van: float, tot: float) -> void:
	var r = _bereik(l.factor, van, tot)
	var basis = 560.0
	l.vormen.append(["rect", Rect2(r.x, basis, r.y - r.x, 4000), pal.beton.darkened(0.04)])  # bouwterrein
	var x = r.x + rng.randf_range(0, 300)
	while x < r.y:
		var kans = rng.randf()
		var soort = 0 if kans < 0.4 else (4 if kans < 0.65 else (3 if kans < 0.87 else 2))
		match soort:
			0:      # betonskelet met steiger ervoor
				var w = rng.randf_range(260, 520)
				var verd = rng.randi_range(3, 8)
				var h = verd * 90.0
				_skelet(l, x, basis - h, w, h, pal.beton, 7.0)
				if rng.randf() < 0.7:
					_steiger(l, x - 20, basis, rng.randf_range(80, 160), h * rng.randf_range(0.5, 1.0))
				x += w
			2:      # torenkraan
				_kraan(l, x, basis - rng.randf_range(650, 1100), basis, pal.kraan, 1.0)
				x += 120
			3:      # containers / keten
				for i in rng.randi_range(1, 3):
					var c = [pal.steiger, pal.container[0], pal.container[1]][rng.randi_range(0, 2)]
					l.vormen.append(["rect", Rect2(x, basis - 70 * (i + 1), 200, 66), c])
					for s in range(int(x + 14), int(x + 190), 22):
						l.vormen.append(["lijn", Vector2(s, basis - 70 * (i + 1) + 6), Vector2(s, basis - 70 * i - 10), c.lightened(0.15), 4.0])
				x += 210
			4:      # alleen een steiger
				_steiger(l, x, basis, rng.randf_range(160, 300), rng.randf_range(250, 520))
				x += 300
		x += rng.randf_range(80, 320)
	# bouwhek langs de voorkant
	var hek = pal.steiger.lightened(0.25)
	l.vormen.append(["lijn", Vector2(r.x, basis - 60), Vector2(r.y, basis - 60), hek, 4.0])
	for hx in range(int(r.x), int(r.y), 60):
		l.vormen.append(["lijn", Vector2(hx, basis - 70), Vector2(hx, basis), hek, 3.0])

# Betonskelet: kolommen + vloeren
func _skelet(l: Laag, x: float, top: float, w: float, h: float, kleur: Color, dik: float) -> void:
	var vloeren = max(1, int(h / 90.0))
	for i in vloeren + 1:
		var y = top + h - i * (h / vloeren)
		l.vormen.append(["rect", Rect2(x, y - dik, w, dik * 2), kleur])
	var kolommen = max(2, int(w / 110.0))
	for i in kolommen + 1:
		var cx = x + i * (w / kolommen)
		l.vormen.append(["rect", Rect2(cx - dik, top, dik * 2, h), kleur])

# Steiger: staanders, liggers en schoren
func _steiger(l: Laag, x: float, basis: float, w: float, h: float) -> void:
	var c = pal.steiger
	var vakken = max(1, int(w / 60.0))
	var lagen = max(1, int(h / 70.0))
	for i in vakken + 1:
		l.vormen.append(["lijn", Vector2(x + i * w / vakken, basis), Vector2(x + i * w / vakken, basis - h), c, 4.0])
	for j in lagen + 1:
		l.vormen.append(["lijn", Vector2(x, basis - j * h / lagen), Vector2(x + w, basis - j * h / lagen), c, 4.0])
	for j in lagen:
		var a = Vector2(x, basis - j * h / lagen)
		var b = Vector2(x + w / vakken, basis - (j + 1) * h / lagen)
		l.vormen.append(["lijn", a, b, c.lightened(0.1), 3.0])

# Torenkraan met vakwerkmast, giek, contragiek en contragewicht
func _kraan(l: Laag, x: float, top: float, basis: float, kleur: Color, schaal: float) -> void:
	var b = 40.0 * schaal                # breedte mast
	var dik = 4.0 * schaal
	l.vormen.append(["lijn", Vector2(x, basis), Vector2(x, top), kleur, dik])
	l.vormen.append(["lijn", Vector2(x + b, basis), Vector2(x + b, top), kleur, dik])
	var y = basis
	while y > top + b:
		l.vormen.append(["lijn", Vector2(x, y), Vector2(x + b, y - b), kleur, dik * 0.7])
		l.vormen.append(["lijn", Vector2(x + b, y - b), Vector2(x, y - b), kleur, dik * 0.7])
		y -= b
	var lang = rng.randf_range(500, 900) * schaal
	var kort = lang * 0.35
	_giek(l, Vector2(x - kort, top), Vector2(x + b + lang, top), kleur, schaal)
	l.vormen.append(["rect", Rect2(x - kort, top + 4, 70 * schaal, 50 * schaal), kleur.lerp(Color(0.82, 0.82, 0.86), 0.6)])   # contragewicht
	l.vormen.append(["rect", Rect2(x + b, top + 4, 34 * schaal, 30 * schaal), pal.cabine])                                    # cabine
	l.vormen.append(["poly", PackedVector2Array([Vector2(x, top), Vector2(x + b / 2, top - 70 * schaal), Vector2(x + b, top)]), kleur])  # top
	var haak = x + b + lang * rng.randf_range(0.4, 0.9)
	var haak_y = top + rng.randf_range(120, 400) * schaal
	l.vormen.append(["lijn", Vector2(haak, top + 12 * schaal), Vector2(haak, haak_y), kleur.darkened(0.1), 2.0 * schaal])
	l.vormen.append(["rect", Rect2(haak - 8 * schaal, haak_y, 16 * schaal, 14 * schaal), kleur.darkened(0.1)])

# Vakwerkgiek tussen a en b (horizontaal)
func _giek(l: Laag, a: Vector2, b: Vector2, kleur: Color, schaal: float) -> void:
	var h = 26.0 * schaal
	var dik = 4.0 * schaal
	l.vormen.append(["lijn", a, b, kleur, dik])
	l.vormen.append(["lijn", a + Vector2(0, -h), b + Vector2(0, -h * 0.4), kleur, dik])
	var x = a.x
	var stap = 34.0 * schaal
	while x < b.x - stap:
		var t2 = (x + stap - a.x) / (b.x - a.x)
		l.vormen.append(["lijn", Vector2(x, a.y), Vector2(x + stap, a.y - h * (1.0 - 0.6 * t2)), kleur, dik * 0.6])
		l.vormen.append(["lijn", Vector2(x + stap, a.y), Vector2(x + stap, a.y - h * (1.0 - 0.6 * t2)), kleur, dik * 0.6])
		x += stap

# Kraan waar een sloopkogel aan hangt: het loopkatje zit precies op het ophangpunt.
# kant = -1: mast links van de kogel, +1: rechts. De mast loopt door tot ver onder de grond.
func _kogelkraan(l: Laag, anker: Vector2, kant: float) -> void:
	var kleur = pal.kraan
	var mast_x = anker.x + kant * 560.0          # 8 tiles naast de kogel: buiten de zwaai
	var top = anker.y - 30.0                     # giek net boven het ophangpunt
	var b = 46.0
	var links = min(mast_x, mast_x + b * kant)
	# mast
	l.vormen.append(["lijn", Vector2(links, top), Vector2(links, top + 3000), kleur, 5.0])
	l.vormen.append(["lijn", Vector2(links + b, top), Vector2(links + b, top + 3000), kleur, 5.0])
	var y = top + b
	while y < top + 3000:
		l.vormen.append(["lijn", Vector2(links, y), Vector2(links + b, y + b), kleur, 3.5])
		l.vormen.append(["lijn", Vector2(links + b, y + b), Vector2(links, y + b), kleur, 3.5])
		y += b
	# giek naar de kogel (en 2 tiles verder), contragiek de andere kant op
	var giek_eind = anker.x - kant * 140.0
	var contra = mast_x + kant * 260.0
	_giek(l, Vector2(min(contra, giek_eind), top), Vector2(max(contra, giek_eind), top), kleur, 1.0)
	l.vormen.append(["rect", Rect2(min(contra, contra - kant * 90.0), top + 4, 90, 60), kleur.lerp(Color(0.82, 0.82, 0.86), 0.6)])
	l.vormen.append(["poly", PackedVector2Array([Vector2(links, top - 26), Vector2(links + b / 2, top - 110), Vector2(links + b, top - 26)]), kleur])
	l.vormen.append(["rect", Rect2(links + (b if kant < 0 else -40), top - 10, 40, 34), pal.cabine])   # cabine
	# loopkatje met kabel naar het ophangpunt
	l.vormen.append(["rect", Rect2(anker.x - 22, top - 4, 44, 18), kleur.darkened(0.12)])
	l.vormen.append(["lijn", Vector2(anker.x, top + 12), anker, kleur.darkened(0.2), 4.0])
