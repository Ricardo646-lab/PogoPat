extends Control

@onready var star_holders: Array[Control] = [
	%StarHolder,
	%StarHolder2,
	%StarHolder3,
]

var active_star_tweens: Array[Tween] = []


func _ready() -> void:
	await get_tree().process_frame


	play_star_intro()


func play_star_intro() -> void:
	_stop_existing_star_tweens()
	_reset_stars()

	for index in star_holders.size():
		_animate_star(
			star_holders[index],
			index
		)


func _reset_stars() -> void:
	for index in star_holders.size():
		var holder := star_holders[index]

		holder.pivot_offset = holder.size * 0.5
		holder.scale = Vector2.ZERO
		holder.modulate.a = 0.0

		if index == 0:
			holder.rotation = deg_to_rad(-22.0)
		elif index == 1:
			holder.rotation = deg_to_rad(14.0)
		else:
			holder.rotation = deg_to_rad(22.0)


func _animate_star(
	holder: Control,
	index: int
) -> void:
	var delay := 0.18 + index * 0.14

	var tween := create_tween()
	active_star_tweens.append(tween)

	tween.tween_interval(delay)

	tween.tween_property(
		holder,
		"scale",
		Vector2.ONE,
		0.46
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	tween.parallel().tween_property(
		holder,
		"rotation",
		0.0,
		0.38
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	tween.parallel().tween_property(
		holder,
		"modulate:a",
		1.0,
		0.16
	)


func _stop_existing_star_tweens() -> void:
	for tween in active_star_tweens:
		if tween and tween.is_valid():
			tween.kill()

	active_star_tweens.clear()
