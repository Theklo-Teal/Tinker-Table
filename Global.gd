extends Node

@onready var sett := ConfigFile.new()

func _ready() -> void:
	sett.load("res://settings.ini")
	set_architecture(sett.get_value("Foobar", "architecture", ""))

func _exit_tree() -> void:
	sett.save("res://settings.ini")

var CPU : CpuCore
var lue : Node  # «G.lue» reads as "glue"! The interface between CpuCore and all the UI stuff.

func set_architecture(pack:String) -> void:
	if pack.is_empty():
		CPU = CpuCore.new()
	else:
		CPU = load("res://Architectures/"+pack+"/core.gd").new(pack)
		sett.set_value("Foobar", "architecture", pack)
	
	get_tree().call_group("responds_archie", "_on_archie_changed")
