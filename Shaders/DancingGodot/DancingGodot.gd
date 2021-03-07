extends Node2D

onready var targetNode : Sprite = $icon
onready var label : Label = $Label

const NAME = "Dancing Godot"

var amplitudeVal : float = 10.0 setget set_amplitude # Interface value

func _ready():
	var amplitude = targetNode.material.get_shader_param("amplitude")
	self.set_amplitude( amplitude.x )

func _on_HSlider_value_changed(value):
	self.amplitudeVal = value
	
func set_amplitude( value ):
	amplitudeVal = value
	label.set_text( NAME + "( " + str(value) + " )" )
	targetNode.material.set_shader_param( "amplitude" , Vector2(amplitudeVal, amplitudeVal) )
