# res://scripts/DecisionPanelController.gd
extends Panel

signal decision_made(result, context)

@onready var title_label: Label = $VBoxContainer/Title
@onready var options_container: HBoxContainer = $VBoxContainer/HBoxContainer

var _context: String = ""
var _decision_type: String = ""

func setup(decision_type: String, question: String, options: Array, context: String = "") -> void:
	_decision_type = decision_type
	_context = context
	title_label.text = question
	
	# Limpiar botones anteriores
	for child in options_container.get_children():
		child.queue_free()
	
	# Crear botones dinámicos
	for option in options:
		var button = Button.new()
		button.text = option
		button.pressed.connect(_on_option_selected.bind(option))
		options_container.add_child(button)

func _on_option_selected(option: String) -> void:
	var result = {
		"type": _decision_type,
		"value": option,
		"context": _context,
		"timestamp": Time.get_datetime_string_from_system(),
		"user": UserSession.current_user.get("username", "")
	}
	decision_made.emit(result, _context)
	queue_free()

func _on_cancel_pressed() -> void:
	queue_free()
