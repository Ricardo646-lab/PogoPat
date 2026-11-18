extends Control

# Laat 10 levels per pagina zien. De eerste knop in de grid is het sjabloon.

const PER_PAGE = 10

@onready var grid: GridContainer = find_child("GridContainer", true, false)
@onready var prev_button: Button = find_child("Prev", true, false)
@onready var next_button: Button = find_child("Next", true, false)
@onready var page_label: Label = find_child("PageLabel", true, false)

var buttons = []
var page = 0
var page_count = ceili(GameManager.LEVEL_COUNT / float(PER_PAGE))

func _ready() -> void:
# Start de muziek als deze nog niet speelt wanneer je in de level selector komt
	if not AudioManager.level_background_music.playing:
		AudioManager.level_background_music.play()

	var template = grid.get_child(0)
	buttons.append(template)
	for i in PER_PAGE - 1:
		var b = template.duplicate()
		grid.add_child(b)
		buttons.append(b)

	prev_button.pressed.connect(func(): _show_page(page - 1))
	next_button.pressed.connect(func(): _show_page(page + 1))

	# Paneel kleiner maken als het scherm smaller is (telefoon rechtop)
	resized.connect(_pas_grootte_aan)
	_pas_grootte_aan()

	# Begin op de pagina van het level waar je bent
	_show_page(floori((GameManager.current_level - 1) / float(PER_PAGE)))

# Zodra je naar een level gaat en de level selector-scène afsluit, stopt de muziek direct.
func _exit_tree() -> void:
	if AudioManager.level_background_music.playing:
		AudioManager.level_background_music.stop()

func _show_page(p: int) -> void:
	page = clampi(p, 0, page_count - 1)
	for i in PER_PAGE:
		var level = page * PER_PAGE + i + 1
		buttons[i].visible = level <= GameManager.LEVEL_COUNT
		buttons[i].target_level_number = level
		buttons[i].update_level_state()
	prev_button.disabled = page == 0
	next_button.disabled = page == page_count - 1
	page_label.text = "%d / %d" % [page + 1, page_count]

func _pas_grootte_aan() -> void:
	# De CenterContainer schalen (een container zet de schaal van zijn kinderen steeds terug op 1)
	var midden: Control = get_node_or_null("CenterContainer")
	var paneel: Control = find_child("Panel", true, false)
	if midden and paneel and size.x > 0:
		midden.pivot_offset = midden.size / 2.0
		var schaal = min(1.0, (size.x - 30.0) / paneel.custom_minimum_size.x)
		midden.scale = Vector2(schaal, schaal)
