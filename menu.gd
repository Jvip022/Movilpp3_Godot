extends Control
var usr:String
var pwd:String

func _on_salir_pressed() -> void:
	get_tree().quit(1)


func _on_button_pressed() -> void:
	get_tree().quit()


func _on_aceptar_pressed() -> void:
	usr=$Nombre.text
	$Password.text="cero"
	pwd=$Password.text
	pass # Replace with function body.
