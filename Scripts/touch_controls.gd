extends Control

# Touch-besturing voor telefoon/tablet:
#   - joystick vast linksonder: analoog links/rechts (half duwen = langzamer en kleinere mikhoek)
#   - springknop rechtsonder: ingedrukt houden = opladen, loslaten = springen. Laadring rond de knop.
# Alles schaalt mee met de korte kant van het scherm (werkt liggend en staand).
# Wordt getekend in code (geen plaatjes). Rust: 40% zichtbaar, aangeraakt: 75%.

const JOY_STRAAL = 0.14       # straal joystick als deel van de korte schermkant (diameter 28%)
const KNOP_STRAAL = 0.10      # straal springknop (diameter 20%)
const MARGE = 0.06            # afstand tot de schermrand
const RAAKVLAK = 1.6          # je mag tot 1,6x de straal ernaast tikken
const DODE_ZONE = 0.15        # kleine duimbewegingen negeren
const RUST = 0.4
const ACTIEF = 0.75

var joy_touch = -1            # vinger-index op de joystick (-1 = geen)
var joy_x = 0.0               # -1 .. 1
var knop_touch = -1
var lading = 0.0              # 0 .. 1, van de speler
var pulseren = false          # level 1: zacht oplichten tot je ze gebruikt
var tijd = 0.0

func setup(player: Node, pulse: bool) -> void:
	player.charge_changed.connect(func(r):
		lading = r
		queue_redraw())
	pulseren = pulse

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS     # loslaten moet ook werken als het spel even pauzeert
	resized.connect(queue_redraw)

func _exit_tree() -> void:
	_alles_los()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_alles_los()

func _process(delta: float) -> void:
	if pulseren:
		tijd += delta
		queue_redraw()

# --- Maten (alles relatief aan de korte schermkant) ---
func _kort() -> float:
	return min(size.x, size.y)

func _joy_centrum() -> Vector2:
	var r = _kort() * JOY_STRAAL
	var m = _kort() * MARGE
	return Vector2(m + r, size.y - m - r)

func _knop_centrum() -> Vector2:
	var r = _kort() * KNOP_STRAAL
	var m = _kort() * MARGE
	return Vector2(size.x - m - r * 1.3, size.y - m - r * 1.3)

# --- Invoer (meerdere vingers tegelijk) ---
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var p = event.position
		if event.pressed:
			if joy_touch == -1 and p.distance_to(_joy_centrum()) < _kort() * JOY_STRAAL * RAAKVLAK:
				joy_touch = event.index
				_zet_joystick(p)
				pulseren = false
			elif knop_touch == -1 and p.distance_to(_knop_centrum()) < _kort() * KNOP_STRAAL * RAAKVLAK:
				knop_touch = event.index
				Input.action_press("charge_jump")
				pulseren = false
		else:
			if event.index == joy_touch:
				joy_touch = -1
				joy_x = 0.0
				_zet_acties()
			elif event.index == knop_touch:
				knop_touch = -1
				Input.action_release("charge_jump")
		queue_redraw()
	elif event is InputEventScreenDrag and event.index == joy_touch:
		_zet_joystick(event.position)
		queue_redraw()

func _zet_joystick(p: Vector2) -> void:
	joy_x = clamp((p.x - _joy_centrum().x) / (_kort() * JOY_STRAAL), -1.0, 1.0)
	_zet_acties()

func _zet_acties() -> void:
	var kracht = (abs(joy_x) - DODE_ZONE) / (1.0 - DODE_ZONE)
	if kracht <= 0.0:
		Input.action_release("move_left")
		Input.action_release("move_right")
	elif joy_x > 0.0:
		Input.action_release("move_left")
		Input.action_press("move_right", kracht)
	else:
		Input.action_release("move_right")
		Input.action_press("move_left", kracht)

func _alles_los() -> void:
	joy_touch = -1
	knop_touch = -1
	joy_x = 0.0
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("charge_jump")

# --- Tekenen ---
func _alpha(actief: bool) -> float:
	if actief:
		return ACTIEF
	if pulseren:
		return RUST + 0.35 * (0.5 + 0.5 * sin(tijd * 5.0))
	return RUST

func _draw() -> void:
	var k = _kort()
	var wit = Color(1, 1, 1)

	# Joystick: ronde basis met pijltjes links/rechts, knop beweegt alleen horizontaal
	var a = _alpha(joy_touch != -1)
	var jc = _joy_centrum()
	var jr = k * JOY_STRAAL
	draw_circle(jc, jr, Color(1, 1, 1, 0.22 * a))
	draw_arc(jc, jr, 0, TAU, 48, Color(wit, a), max(2.0, k * 0.008), true)
	for kant in [-1.0, 1.0]:
		var punt = jc + Vector2(kant * jr * 0.82, 0)
		var basis = jc + Vector2(kant * jr * 0.62, 0)
		draw_colored_polygon(PackedVector2Array([punt, basis + Vector2(0, -jr * 0.14), basis + Vector2(0, jr * 0.14)]), Color(wit, a))
	draw_circle(jc + Vector2(joy_x * jr, 0), jr * 0.45, Color(wit, min(1.0, a + 0.1)))

	# Springknop met pijl omhoog en laadring
	a = _alpha(knop_touch != -1)
	var kc = _knop_centrum()
	var kr = k * KNOP_STRAAL
	draw_circle(kc, kr, Color(1, 1, 1, (0.35 if knop_touch != -1 else 0.22) * a))
	draw_arc(kc, kr, 0, TAU, 40, Color(wit, a), max(2.0, k * 0.008), true)
	var pijl = kr * 0.45
	draw_colored_polygon(PackedVector2Array([kc + Vector2(0, -pijl), kc + Vector2(pijl * 0.8, 0), kc + Vector2(-pijl * 0.8, 0)]), Color(wit, a))
	draw_rect(Rect2(kc + Vector2(-pijl * 0.3, 0), Vector2(pijl * 0.6, pijl * 0.8)), Color(wit, a))
	if lading > 0.0:
		draw_arc(kc, kr + k * 0.015, -PI / 2, -PI / 2 + TAU * lading, 48, Color(1.0, 0.85, 0.2, 0.95), k * 0.018, true)
