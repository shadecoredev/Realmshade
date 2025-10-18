extends Node
class_name MaterialTest

@export var material : ShaderMaterial

var _time : float

func _process(delta):
	_time += delta * 0.25
	material.set_shader_parameter("progress", fmod(_time, 1.0))
