extends Camera2D

@export var player: Node2D
@export var finish_target: Node2D
@export var pan_speed: float = 0.8     # Duration (in seconds) to pan to the finish and back
@export var hold_time: float = 0.6     # Time (in seconds) to hold camera focus on the finish

var is_previewing: bool = false

func _ready() -> void:
	if player:
		global_position = player.global_position

func play_finish_preview(on_complete_callback: Callable) -> void:
	if is_previewing or not player or not finish_target:
		on_complete_callback.call()
		return

	is_previewing = true

	# Temporarily disable position smoothing during manual tween pan
	var original_smoothing = position_smoothing_enabled
	position_smoothing_enabled = false

	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# 1. Pan camera to the finish target position
	tween.tween_property(self, "global_position", finish_target.global_position, pan_speed)

	# 2. Pause at the finish
	tween.tween_interval(hold_time)

	# 3. Pan camera back to the player
	tween.tween_property(self, "global_position", player.global_position, pan_speed)

	# 4. Finish preview and restore camera settings
	tween.tween_callback(func():
		is_previewing = false
		position_smoothing_enabled = original_smoothing
		on_complete_callback.call()
	)

func _process(_delta: float) -> void:
	# Follow the player continuously when preview animation is not active
	if not is_previewing and player:
		global_position = player.global_position