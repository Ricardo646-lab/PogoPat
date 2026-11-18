extends Node

# UI & Menu Geluiden (WAV)
@onready var clicked_button_sound: AudioStreamPlayer = $ClickedButtonSound
@onready var hover_button_sound: AudioStreamPlayer = $HoverButtonSound
@onready var locked_button_sound: AudioStreamPlayer = $LockedButtonSound
@onready var woosh_out: AudioStreamPlayer = $WooshOut
@onready var woosh_back: AudioStreamPlayer = $WooshBack

# Gameplay Geluiden (WAV)
@onready var mini_jump_sound: AudioStreamPlayer = $MiniJumpSound
@onready var bounce_sound: AudioStreamPlayer = $BounceSound
@onready var charge_sound: AudioStreamPlayer = $ChargeSound
@onready var victory_sound: AudioStreamPlayer = $VictorySound
@onready var star_sound: AudioStreamPlayer = $StarSound

# Muziek & Loops (OGG)
@onready var charge_loop_sound: AudioStreamPlayer = $ChargeLoopSound
@onready var background_music: AudioStreamPlayer = $BackgroundMusic

func _ready() -> void:
	# Zorgt ervoor dat de audio blijft spelen als het spel pauzeert
	process_mode = Node.PROCESS_MODE_ALWAYS

# --- UI Functies ---
func play_click() -> void:
	clicked_button_sound.play()

func play_hover() -> void:
	hover_button_sound.play()

func play_locked() -> void:
	locked_button_sound.play()

func play_whoosh_out() -> void:
	woosh_out.play()

func play_whoosh_back() -> void:
	woosh_back.play()

# --- Gameplay Functies ---
func play_mini_jump() -> void:
	mini_jump_sound.play()

func play_bounce() -> void:
	bounce_sound.play()

func play_victory() -> void:
	victory_sound.play()

func play_star() -> void:
	star_sound.play()

# --- Oplaad & Loop Functies (WAV + OGG) ---
func play_charge() -> void:
	if not charge_sound.playing:
		charge_sound.play()

func stop_charge() -> void:
	charge_sound.stop()

func play_charge_loop() -> void:
	if not charge_loop_sound.playing:
		charge_loop_sound.play()

func stop_charge_loop() -> void:
	charge_loop_sound.stop()

# --- Achtergrondmuziek (OGG) ---
func play_music() -> void:
	if not background_music.playing:
		background_music.play()

func stop_music() -> void:
	background_music.stop()