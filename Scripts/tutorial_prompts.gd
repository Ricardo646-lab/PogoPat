extends Node2D

func _ready():
	# Check of we op een mobiel apparaat draaien
	var is_mobile = OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android") or OS.has_feature("ios")
	
	if is_mobile:
	
		hide()
	else:
		
		show()