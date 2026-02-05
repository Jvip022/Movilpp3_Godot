# res://scripts/UserSession.gd
extends Node

signal session_changed

var current_user: Dictionary = {}
var permissions: Array = []

func login(user_data: Dictionary) -> void:
	current_user = user_data
	permissions = _get_permissions_for_role(user_data.role)
	session_changed.emit()

func logout() -> void:
	current_user = {}
	permissions = []
	session_changed.emit()

func has_permission(permission: String) -> bool:
	return permission in permissions

func _get_permissions_for_role(role: String) -> Array:
	var role_permissions = {
		"admin": ["all"],
		"quality_manager": ["approve", "classify", "close"],
		"analyst": ["register", "view"]
	}
	return role_permissions.get(role, [])
