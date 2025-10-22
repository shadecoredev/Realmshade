@abstract
extends Node
class_name EffectColor

static var _colors : Dictionary[String, Color] = {
	"health" : Color("d6202a"),
	"damage" : Color("73172d"),
	"acid" : Color("9cdb43"),
	"fire" : Color("fa6a0a"),
	"poison" : Color("1a7a3e"),
	"shock" : Color("fef3c0"),
	"absorption" : Color("ffd541"),
	"barrier" : Color("a6fcdb"),
	"block" : Color("8b93af"),
	"doom" : Color("403353"),
	"fury" : Color("df3e23"),
	"maximum_barrier" : Color("a6fcdb"),
	"purity" : Color("20d6c7"),
	"regeneration" : Color("e86a73"),
	"thorns" : Color("5a4e44"),
	"resistance" : Color("c7b08b"),
	"power" : Color("477d85"),
}

static func get_by_name(effect_name : String) -> Color:
	if effect_name not in _colors:
		return Color.WHITE
	return _colors[effect_name]
