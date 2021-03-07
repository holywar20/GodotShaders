extends Node2D

onready var sprite : Sprite = $Sprite

func _ready():
	calcAspectRatio()


func calcAspectRatio():
	sprite.material.set_shader_param( "aspectRatio" , sprite.scale.y / sprite.scale.x)
