extends Button

@export var target_level_number: int = 1

@export_category("Sounds")
@export var hover_sound: AudioStream
@export var click_sound: AudioStream
@export var locked_sound: AudioStream

var audio_player: AudioStreamPlayer

func _ready() -> void:

	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	if not pressed.is_connected(_on_button_pressed):
		pressed.connect(_on_button_pressed)

	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)

	if not gui_input.is_connected(_gui_input):
		gui_input.connect(_gui_input)

	update_level_state()

func _on_mouse_entered() -> void:
	if not disabled and hover_sound:
		audio_player.stream = hover_sound
		audio_player.play()

func _gui_input(event: InputEvent) -> void:
	if disabled and (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		if locked_sound:
			audio_player.stream = locked_sound
			audio_player.play()

func update_level_state() -> void:
	var is_unlocked = true
	var gm = null
	
	if has_node("/root/GameManager"):
		gm = get_node("/root/GameManager")
			
	if target_level_number > 1 and gm != null:
		var prev_level_name = "Level" + str(target_level_number - 1)
		if not ("level_stars" in gm and gm.level_stars.has(prev_level_name) and gm.level_stars[prev_level_name] > 0):
			is_unlocked = false
			
	disabled = not is_unlocked
	queue_redraw()

func _on_button_pressed() -> void:
	if not disabled:

		if click_sound:
			audio_player.stream = click_sound
			audio_player.play()
			# Wacht heel even (0.5 seconde) zodat het geluid te horen is voordat de scène wisselt
			await get_tree().create_timer(0.5).timeout

		var scene_path = "res://Scenes/Level" + str(target_level_number) + ".tscn"
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file(scene_path)

func _draw() -> void:
	var level_name = "Level" + str(target_level_number)
	var current_stars = 0
	var gm = null
	
	if has_node("/root/GameManager"):
		gm = get_node("/root/GameManager")
		if "level_stars" in gm and gm.level_stars.has(level_name):
			current_stars = gm.level_stars[level_name]

	# --- 1. TEKEN HET LEVELNUMMER (Grotere lettergrootte: 30) ---
	var font = ThemeDB.fallback_font
	var text_color = Color(0.6, 0.6, 0.6) if disabled else Color(0.2, 0.2, 0.2)
	draw_string(font, Vector2(0, size.y * 0.40), str(target_level_number), HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, text_color)

	if disabled:
		# --- 2. TEKEN GROTER SLOTJE ---
		var lock_center = Vector2(size.x / 2, size.y * 0.68)
		
		# Beugel van het slot (grotere boog naar boven)
		draw_arc(lock_center + Vector2(0, -3), 6.0, PI, TAU, 12, Color(0.5, 0.5, 0.5), 2.5)
		
		# Behuizing van het slot (grotere rechthoek)
		draw_rect(Rect2(lock_center + Vector2(-10, -3), Vector2(20, 15)), Color(0.85, 0.5, 0.1))
		
		# Sleutelgat stipje
		draw_circle(lock_center + Vector2(0, 4), 2.0, Color(0.2, 0.1, 0.0))
	else:
		# --- 3. TEKEN GROTERE STERREN ---
		var star_spacing = 26.0
		var total_width = 2 * star_spacing
		var start_x = (size.x - total_width) / 2
		var star_y = size.y * 0.70
		
		for i in range(3):
			var star_pos = Vector2(start_x + (i * star_spacing), star_y)
			var star_filled = i < current_stars
			
			if star_filled:
				draw_true_star(star_pos, 12.0, Color(1.0, 0.85, 0.0), true)
			else:
				draw_true_star(star_pos, 12.0, Color(0.7, 0.7, 0.7), false)

func draw_true_star(center: Vector2, radius: float, color: Color, filled: bool) -> void:
	var points = PackedVector2Array()
	var num_points = 5
	for i in range(num_points * 2):
		var r = radius if i % 2 == 0 else radius * 0.4
		var angle = (i * PI / num_points) - (PI / 2)
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	
	if filled:
		draw_colored_polygon(points, color)
		for i in range(points.size()):
			draw_line(points[i], points[(i + 1) % points.size()], Color(0.9, 0.65, 0.0), 1.5)
	else:
		for i in range(points.size()):
			draw_line(points[i], points[(i + 1) % points.size()], color, 1.8)
