class_name MineralData
extends Resource

@export var id := "ilmenita"
@export var display_name := "Ilmenita"
@export_multiline var fact := "Se encontró en la mision Apollo 17"
@export var accent := Color(0.45, 0.8, 1.0)
@export var source := "astromat.org"

func to_message() -> InfoMessage:
	var m := InfoMessage.new()
	m.title = "Encontraste: %s" % display_name
	m.body = fact
	m.source = source
	m.accent = accent
	m.duration = 7.0
	m.priority = 1
	m.once_key = "mineral_" + id      # solo la primera vez que lo recoges
	return m
