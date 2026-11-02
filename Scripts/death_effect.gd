extends Node2D

@export var effect_scale: float = 2.0 # 2x zo groot om te matchen met je speler!

var is_active = false
var parts = []
var angel_pos = Vector2.ZERO
var angel_timer = 0.0

func trigger():
	is_active = true
	parts.clear()
	angel_pos = Vector2(0, -60)
	angel_timer = 0.0
	
	# Maak het volledige effect groter
	scale = Vector2(effect_scale, effect_scale)
	
	# Definieer de ledematen en hun startpositie ten opzichte van het centrum
	var part_defs = [
		{"type": "head", "offset": Vector2(0, -48)},
		{"type": "body", "offset": Vector2(0, -24)},
		{"type": "arm", "offset": Vector2(-15, -15)},
		{"type": "arm", "offset": Vector2(15, -15)},
		{"type": "pogo_spring", "offset": Vector2(0, 20)},
		{"type": "pogo_handle", "offset": Vector2(0, -10)}
	]
	
	# Geef elk lichaamsdeel een willekeurige explosie-snelheid en draaisnelheid
	for p in part_defs:
		var vel = Vector2(randf_range(-400, 400), randf_range(-600, -200))
		var rot_speed = randf_range(-15, 15)
		parts.append({"type": p.type, "pos": p.offset, "vel": vel, "rot": 0.0, "rot_speed": rot_speed})
		
	show()

func hide_effect():
	is_active = false
	hide()

func _process(delta):
	if not is_active: return
	
	# Update de vliegende ledematen (zwaartekracht + draaien)
	for p in parts:
		p.vel.y += 1200 * delta # Zwaartekracht
		p.pos += p.vel * delta
		p.rot += p.rot_speed * delta
		
	# Update het vliegende engeltje
	angel_timer += delta
	angel_pos.y -= 80 * delta # Vlieg omhoog
	angel_pos.x = sin(angel_timer * 6.0) * 15.0 # Wiebel heen en weer
	
	queue_redraw() # Teken alles opnieuw op de nieuwe posities

func _draw():
	if not is_active: return
	
	var col_black = Color(0.1, 0.1, 0.1)
	var col_metal = Color(0.7, 0.7, 0.7)
	var col_spring = Color(0.8, 0.2, 0.2)
	var col_helmet = Color(1.0, 0.8, 0.0)
	
	# 1. TEKEN DE EXPLODERENDE LEDEMATEN
	for p in parts:
		draw_set_transform(p.pos, p.rot, Vector2.ONE)
		if p.type == "head":
			draw_circle(Vector2.ZERO, 14, col_black)
			draw_arc(Vector2(0, -4), 16.0, PI, 0.0, 16, col_helmet, 8.0)
			draw_line(Vector2(-20, 2), Vector2(20, 2), col_helmet, 4.0)
		elif p.type == "body":
			draw_line(Vector2(0, -15), Vector2(0, 15), col_black, 6.0)
		elif p.type == "arm":
			draw_line(Vector2(0, -10), Vector2(0, 10), col_black, 5.0)
		elif p.type == "pogo_spring":
			draw_rect(Rect2(-10, -15, 20, 30), col_spring)
			draw_line(Vector2(0, 15), Vector2(0, 35), col_metal, 6.0)
			draw_rect(Rect2(-8, 35, 16, 8), Color(0.3,0.3,0.3))
		elif p.type == "pogo_handle":
			draw_line(Vector2(0, -15), Vector2(0, 15), col_metal, 6.0)
			draw_line(Vector2(-20, 15), Vector2(20, 15), col_metal, 6.0)
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE) # Reset transform
	
	# 2. TEKEN HET POGO-ENGELTJE
	var col_angel = Color(1, 1, 1, 0.6) # Halftransparant wit
	var col_halo = Color(1, 0.9, 0, 0.8) # Goud/Geel
	
	# Klapperende vleugels
	var flap = sin(angel_timer * 15.0) * 10.0
	draw_line(angel_pos + Vector2(0, 5), angel_pos + Vector2(-25, 5 - flap), col_angel, 4.0)
	draw_line(angel_pos + Vector2(0, 5), angel_pos + Vector2(25, 5 - flap), col_angel, 4.0)
	
	# Engeltje lichaam (simpel)
	draw_circle(angel_pos, 10, col_angel) # Hoofd
	draw_line(angel_pos + Vector2(0, 10), angel_pos + Vector2(0, 25), col_angel, 4.0) # Lichaam
	draw_line(angel_pos + Vector2(0, 25), angel_pos + Vector2(0, 45), col_angel, 3.0) # Stick
	draw_arc(angel_pos + Vector2(0, -15), 8.0, 0, TAU, 16, col_halo, 3.0) # Halo (Aureool)