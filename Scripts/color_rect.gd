extends ColorRect

func _ready():
  
	var hitbox = get_parent().get_node("CollisionShape2D")
	
   
	if hitbox and hitbox.shape is RectangleShape2D:
		var hitbox_size = hitbox.shape.size
	   
		self.size = hitbox_size

		self.position = hitbox.position - (hitbox_size / 2.0)
