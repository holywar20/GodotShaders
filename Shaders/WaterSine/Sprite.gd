tool
extends Node2D

func _ready():
	calcAspectRatio()

func calcAspectRatio():
	print( scale.y / scale.x )
	material.set_shader_param( "aspectRatio" , scale.y / scale.x)

func _on_Sprite_item_rect_changed():
	calcAspectRatio()
