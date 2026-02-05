# res://scripts/NotificationService.gd
extends Node

signal notification_added(message: String, type: String)
signal client_notification_sent(to: String, subject: String)

func notify_internal(message: String, type: String = "info") -> void:
	notification_added.emit(message, type)
	print("[Notification] %s: %s" % [type, message])

func notify_client(email: String, subject: String, _body: String) -> void:
	# Aquí integrarías con un servicio de email real
	client_notification_sent.emit(email, subject)
	print("[Client Notification] To: %s - %s" % [email, subject])
