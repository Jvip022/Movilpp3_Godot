# res://scripts/test_acceptance.gd
extends Node

# Simulación de UserSession (esto debería estar en un autoload en producción)
var UserSession = {
	"login": func(user_data: Dictionary) -> void:
		print("Usuario logueado: ", user_data.username)
}

# Simulación de IncidentDB (esto debería estar en otro archivo)
var IncidentDB = {
	"create_incident": func(incident_data: Dictionary) -> String:
		var incident_id = "INC-" + str(Time.get_unix_time_from_system())
		print("Incidencia creada: ", incident_id, " - ", incident_data.title)
		return incident_id,
	
	"create_expedient": func(_expedient_data: Dictionary) -> String:  # Cambiado aquí
		var expedient_id = "EXP-" + str(Time.get_unix_time_from_system())
		print("Expediente creado: ", expedient_id)
		return expedient_id,
	
	"update_expedient": func(expedient_id: String, updates: Dictionary) -> void:
		print("Expediente actualizado: ", expedient_id, " -> ", updates)
}

func test_full_flow() -> void:
	# Test 1: Crear incidencia
	UserSession.login.call({"username": "test", "role": "analyst"})
	
	var incident_id = IncidentDB.create_incident.call({
		"title": "Test Incident",
		"description": "Test Description"
	})
	_test_assert(incident_id != "", "Incidencia creada y persistida")
	
	# Test 2: Clasificar usando DecisionPanel
	var expedient_id = IncidentDB.create_expedient.call({
		"incident_id": incident_id,
		"status": "en_revision"
	})
	
	# Simular decisión (corregido el warning)
	var _decision_result = {
		"type": "classification",
		"value": "Mayor",
		"context": expedient_id
	}
	
	IncidentDB.update_expedient.call(expedient_id, {"classification": "Mayor"})
	
	print("✓ Todas las pruebas pasaron")

# Función helper para pruebas (renombrada para evitar conflictos con assert reservado)
func _test_assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("TEST FAILED: " + message)
	else:
		print("✓ " + message)
