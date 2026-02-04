extends Control

func _ready():
	$Panel/MarginContainer/VBoxContainer/VolverButton.pressed.connect(_on_volver_pressed)

func _on_volver_pressed():
	get_tree().change_scene_to_file("res://escenas/menu_Principal.tscn")
