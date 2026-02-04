# backup_restore_db.gd
extends Control

@onready var backup_path = $Panel/MarginContainer/VBoxContainer/BackupSection/BackupPathContainer/BackupPath
@onready var restore_path = $Panel/MarginContainer/VBoxContainer/RestoreSection/RestorePathContainer/RestorePath
@onready var status_message = $Panel/MarginContainer/VBoxContainer/StatusSection/StatusMessage
@onready var progress_bar = $Panel/MarginContainer/VBoxContainer/StatusSection/ProgressBar
@onready var confirmation_dialog = $ConfirmationDialog
@onready var success_dialog = $SuccessDialog
@onready var error_dialog = $ErrorDialog

var backup_dir = "user://backups/"
var selected_backup_file = ""
var bd_instance = null

func _ready():
	# Crear directorio de backups si no existe
	var dir = DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("backups")
	
	# Conectar señales
	$Panel/MarginContainer/VBoxContainer/BackupSection/BackupPathContainer/BtnSelectBackupPath.button_up.connect(_on_select_backup_path)
	$Panel/MarginContainer/VBoxContainer/BackupSection/BackupButtons/BtnBackupNow.button_up.connect(_on_backup_now)
	
	$Panel/MarginContainer/VBoxContainer/RestoreSection/RestorePathContainer/BtnSelectRestoreFile.button_up.connect(_on_select_restore_file)
	$Panel/MarginContainer/VBoxContainer/RestoreSection/RestoreButtons/BtnRestoreNow.button_up.connect(_on_restore_now)
	
	$Panel/MarginContainer/VBoxContainer/ActionButtons/BtnVerLogs.button_up.connect(_on_ver_logs)
	$Panel/MarginContainer/VBoxContainer/ActionButtons/BtnVolver.button_up.connect(_on_volver)
	
	confirmation_dialog.confirmed.connect(_on_confirmation_dialog_confirmed)
	
	# Obtener instancia de BD
	bd_instance = obtener_instancia_bd()
	if bd_instance:
		print("✅ Instancia de BD obtenida correctamente")
	else:
		print("⚠️ No se pudo obtener instancia de BD")

func _on_select_backup_path():
	# Crear ruta por defecto
	var datetime = Time.get_datetime_dict_from_system()
	var timestamp = "%04d-%02d-%02d_%02d-%02d-%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	var default_path = backup_dir + "backup_" + timestamp + ".sql"
	backup_path.text = default_path
	update_status("Ruta de backup configurada")

func _on_backup_now():
	if backup_path.text.strip_edges() == "":
		show_error("Seleccione una ruta para el backup")
		return
	
	update_status("Iniciando backup...")
	progress_bar.visible = true
	progress_bar.value = 10
	
	await get_tree().create_timer(0.5).timeout
	progress_bar.value = 30
	update_status("Conectando a la base de datos...")
	
	# CÓDIGO REAL DE BACKUP
	var backup_success = realizar_backup_real(backup_path.text)
	
	if not backup_success:
		progress_bar.visible = false
		return
	
	await get_tree().create_timer(0.5).timeout
	progress_bar.value = 90
	update_status("Finalizando backup...")
	
	await get_tree().create_timer(0.5).timeout
	progress_bar.value = 100
	
	if backup_success:
		# Escribir en el log
		escribir_log("Backup realizado exitosamente en: " + backup_path.text, "INFO")
		
		update_status("Backup completado exitosamente")
		success_dialog.dialog_text = "Backup creado exitosamente en:\n" + backup_path.text
		success_dialog.popup_centered()
	else:
		update_status("Error en el backup", true)
	
	await get_tree().create_timer(1.0).timeout
	progress_bar.visible = false

# Función para realizar el backup real
func realizar_backup_real(ruta_destino: String) -> bool:
	print("Iniciando backup real en: " + ruta_destino)
	
	# Verificar que tenemos instancia de BD
	if not bd_instance:
		show_error("No se pudo conectar a la base de datos. Verifique la instancia BD.")
		return false
	
	# Crear archivo de backup
	var archivo_backup = FileAccess.open(ruta_destino, FileAccess.WRITE)
	if not archivo_backup:
		show_error("No se pudo crear el archivo de backup")
		return false
	
	# 1. Guardar información del sistema
	var info_sistema = obtener_info_sistema()
	archivo_backup.store_line("-- === BACKUP DEL SISTEMA DE GESTIÓN DE CALIDAD ===")
	archivo_backup.store_line("-- Fecha: " + obtener_fecha_actual())
	archivo_backup.store_line("-- Versión: 1.0")
	archivo_backup.store_line("-- Sistema: " + info_sistema)
	archivo_backup.store_line("")
	
	# 2. Backups de tablas principales
	var tablas_principales = [
		"usuarios", "quejas_reclamaciones", "clientes", "incidencias", 
		"no_conformidades", "trazas", "trazas_nc", "documentos_nc", "backups"
	]
	
	var total_registros = 0
	
	for tabla in tablas_principales:
		# Verificar si la tabla existe
		if bd_instance.has_method("table_exists") and bd_instance.table_exists(tabla):
			update_status("Respaldando tabla: " + tabla)
			
			# Obtener estructura de la tabla
			archivo_backup.store_line("-- === ESTRUCTURA DE TABLA: " + tabla + " ===")
			
			if bd_instance.has_method("get_table_structure"):
				var estructura = bd_instance.get_table_structure(tabla)
				archivo_backup.store_line("CREATE TABLE IF NOT EXISTS " + tabla + " (")
				
				var columnas = []
				for col in estructura:
					var col_def = col.name + " " + col.type
					if col.pk > 0:
						col_def += " PRIMARY KEY"
					if col.notnull > 0:
						col_def += " NOT NULL"
					if col.dflt_value != null:
						col_def += " DEFAULT " + str(col.dflt_value)
					columnas.append(col_def)
				
				archivo_backup.store_line("  " + ",\n  ".join(columnas))
				archivo_backup.store_line(");")
				archivo_backup.store_line("")
			
			# Obtener datos de la tabla
			if bd_instance.has_method("select_query"):
				var sql = "SELECT * FROM " + tabla
				var datos = bd_instance.select_query(sql)
				
				if datos and datos.size() > 0:
					archivo_backup.store_line("-- Datos de tabla: " + tabla + " (" + str(datos.size()) + " registros)")
					
					# Insertar datos
					for registro in datos:
						var keys = []
						var values = []
						
						for key in registro.keys():
							keys.append(key)
							var valor = registro[key]
							
							if valor == null:
								values.append("NULL")
							elif typeof(valor) == TYPE_STRING:
								# Escapar comillas simples para SQL
								var valor_str = str(valor).replace("'", "''")
								values.append("'" + valor_str + "'")
							elif typeof(valor) == TYPE_BOOL:
								values.append("1" if valor else "0")
							else:
								values.append(str(valor))
						
						var insert_sql = "INSERT INTO " + tabla + " (" + ", ".join(keys) + ") VALUES (" + ", ".join(values) + ");"
						archivo_backup.store_line(insert_sql)
					
					total_registros += datos.size()
					archivo_backup.store_line("")
			
			print("Tabla " + tabla + " respaldada")
	
	# 3. Guardar metadatos
	archivo_backup.store_line("-- === METADATOS ===")
	archivo_backup.store_line("-- Total de registros: " + str(total_registros))
	archivo_backup.store_line("-- Total de tablas: " + str(tablas_principales.size()))
	archivo_backup.store_line("-- Fecha de backup: " + obtener_fecha_actual())
	
	# 4. Calcular y guardar hash
	var hash_backup = calcular_hash_archivo(ruta_destino)
	archivo_backup.store_line("-- Hash de verificación: " + hash_backup)
	archivo_backup.store_line("-- === FIN DEL BACKUP ===")
	
	archivo_backup.close()
	
	# 5. Registrar el backup en la tabla de backups (si existe)
	registrar_backup_en_bd(ruta_destino, total_registros, hash_backup)
	
	print("✅ Backup completado exitosamente. Total registros: " + str(total_registros))
	update_status("Backup completado: " + str(total_registros) + " registros")
	return true

func _on_select_restore_file():
	# Crear diálogo para seleccionar archivo
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.sql;Archivos SQL", "*.db;Base de datos", "*.backup;Backup"]
	
	file_dialog.file_selected.connect(func(path):
		selected_backup_file = path
		restore_path.text = path
		update_status("Archivo de backup seleccionado")
		file_dialog.queue_free()
	)
	
	file_dialog.canceled.connect(func():
		file_dialog.queue_free()
	)
	
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_restore_now():
	if restore_path.text.strip_edges() == "":
		show_error("Seleccione un archivo de backup")
		return
	
	if not FileAccess.file_exists(restore_path.text):
		show_error("El archivo de backup no existe")
		return
	
	confirmation_dialog.popup_centered()

func _on_confirmation_dialog_confirmed():
	update_status("Iniciando restauración...")
	progress_bar.visible = true
	progress_bar.value = 10
	
	await get_tree().create_timer(0.5).timeout
	progress_bar.value = 30
	update_status("Verificando backup...")
	
	# Restauración real
	var restore_success = realizar_restore_real(restore_path.text)
	
	await get_tree().create_timer(1.0).timeout
	progress_bar.value = 80
	
	if restore_success:
		progress_bar.value = 100
		update_status("Restauración completada")
		success_dialog.dialog_text = "Base de datos restaurada exitosamente"
		success_dialog.popup_centered()
		
		# Escribir en el log
		escribir_log("Restauración realizada desde: " + restore_path.text, "INFO")
	else:
		progress_bar.value = 0
		update_status("Error en la restauración", true)
	
	await get_tree().create_timer(1.0).timeout
	progress_bar.visible = false

# Función para realizar el restore real
func realizar_restore_real(ruta_backup: String) -> bool:
	print("Iniciando restore desde: " + ruta_backup)
	
	# Verificar que el archivo existe
	if not FileAccess.file_exists(ruta_backup):
		show_error("El archivo de backup no existe")
		return false
	
	# Leer archivo de backup
	var archivo_backup = FileAccess.open(ruta_backup, FileAccess.READ)
	if not archivo_backup:
		show_error("No se pudo abrir el archivo de backup")
		return false
	
	# Verificar formato del backup
	var primera_linea = archivo_backup.get_line()
	if not primera_linea.contains("BACKUP DEL SISTEMA DE GESTIÓN DE CALIDAD"):
		show_error("El archivo no es un backup válido del sistema")
		archivo_backup.close()
		return false
	
	# Verificar que tenemos instancia de BD
	if not bd_instance:
		show_error("No se pudo conectar a la base de datos. Verifique la instancia BD.")
		archivo_backup.close()
		return false
	
	# Limpiar tablas existentes (con confirmación adicional)
	update_status("Preparando base de datos...")
	
	# Volver al inicio del archivo
	archivo_backup.seek(0)
	
	# Ejecutar el script SQL
	var contenido_completo = archivo_backup.get_as_text()
	archivo_backup.close()
	
	# Separar el script en líneas
	var lineas = contenido_completo.split("\n")
	var transaccion_actual = ""
	
	update_status("Ejecutando restauración...")
	
	# Iniciar transacción
	if bd_instance.has_method("query"):
		bd_instance.query("BEGIN TRANSACTION;")
	
	for i in range(lineas.size()):
		var linea = lineas[i].strip_edges()
		
		# Saltar comentarios y líneas vacías
		if linea.begins_with("--") or linea == "":
			continue
		
		# Agregar línea a la transacción actual
		transaccion_actual += linea
		
		# Si la línea termina con punto y coma, ejecutar la transacción
		if linea.ends_with(";"):
			update_status("Ejecutando SQL: línea " + str(i+1) + "/" + str(lineas.size()))
			
			if bd_instance.has_method("query"):
				var exito = bd_instance.query(transaccion_actual)
				
				if not exito:
					# Revertir transacción en caso de error
					bd_instance.query("ROLLBACK;")
					show_error("Error en línea " + str(i+1) + ": " + transaccion_actual)
					return false
			
			transaccion_actual = ""
		
		# Actualizar progreso cada 10 líneas
		if i % 10 == 0:
			var progreso = float(i) / float(lineas.size()) * 100.0
			progress_bar.value = 30 + (progreso * 0.5)  # De 30 a 80%
	
	# Confirmar transacción
	if bd_instance.has_method("query"):
		bd_instance.query("COMMIT;")
	
	# Registrar restore en logs
	registrar_restore_en_bd(ruta_backup)
	
	print("✅ Restore completado exitosamente")
	return true

func _on_ver_logs():
	update_status("Mostrando logs...")
	
	# Crear una ventana de diálogo para mostrar los logs
	var logs_dialog = AcceptDialog.new()
	logs_dialog.title = "Logs de Backup/Restore"
	logs_dialog.size = Vector2(700, 500)
	
	# Crear un contenedor para la ventana
	var container = VBoxContainer.new()
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Crear encabezado con botones de acción
	var header = HBoxContainer.new()
	var btn_refresh = Button.new()
	btn_refresh.text = "🔄 Actualizar"
	var btn_clear = Button.new()
	btn_clear.text = "🗑️ Limpiar"
	var btn_export = Button.new()
	btn_export.text = "💾 Exportar"
	
	header.add_child(btn_refresh)
	header.add_child(btn_clear)
	header.add_child(btn_export)
	
	# Crear TextEdit para mostrar los logs
	var text_edit = TextEdit.new()
	text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.editable = false
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	
	# Crear pie de página con estadísticas
	var footer = HBoxContainer.new()
	var stats_label = Label.new()
	footer.add_child(stats_label)
	
	container.add_child(header)
	container.add_child(text_edit)
	container.add_child(footer)
	
	logs_dialog.add_child(container)
	
	# Conectar botones
	btn_refresh.pressed.connect(_cargar_logs.bind(logs_dialog, text_edit, stats_label))
	btn_clear.pressed.connect(_limpiar_logs.bind(logs_dialog, text_edit, stats_label))
	btn_export.pressed.connect(_exportar_logs.bind(logs_dialog))
	
	# Cargar logs inicialmente
	_cargar_logs(logs_dialog, text_edit, stats_label)
	
	# Mostrar la ventana
	add_child(logs_dialog)
	logs_dialog.popup_centered()
	
	# Conectar el cierre del diálogo
	logs_dialog.close_requested.connect(func():
		logs_dialog.queue_free()
	)

func _cargar_logs(logs_dialog: AcceptDialog, text_edit: TextEdit, stats_label: Label):
	var logs_dir = "user://backups/logs/"
	var logs_file = logs_dir + "backup_logs.txt"
	
	# Asegurarse de que el directorio existe
	var dir = DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("backups/logs")
	
	# Leer logs existentes
	var logs_content = ""
	if FileAccess.file_exists(logs_file):
		var file = FileAccess.open(logs_file, FileAccess.READ)
		if file:
			logs_content = file.get_as_text()
			file.close()
			
			# Contar líneas y calcular estadísticas
			var lines = logs_content.split("\n")
			var total_lines = lines.size()
			var backup_count = 0
			var restore_count = 0
			var error_count = 0
			
			for line in lines:
				if line.contains("Backup realizado"):
					backup_count += 1
				elif line.contains("Restauración realizada"):
					restore_count += 1
				elif line.contains("ERROR") or line.contains("Error"):
					error_count += 1
			
			stats_label.text = "Total: %d | Backups: %d | Restauraciones: %d | Errores: %d" % [
				total_lines, backup_count, restore_count, error_count
			]
		else:
			logs_content = "No se pudieron leer los logs."
			stats_label.text = "No hay logs disponibles"
	else:
		logs_content = "No hay logs disponibles.\nLos logs aparecerán aquí después de realizar operaciones de backup/restore."
		stats_label.text = "No hay logs disponibles"
	
	text_edit.text = logs_content
	# Desplazar al final para ver los logs más recientes
	text_edit.set_caret_line(text_edit.get_line_count() - 1)

func _limpiar_logs(logs_dialog: AcceptDialog, text_edit: TextEdit, stats_label: Label):
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "Confirmar Limpieza"
	confirm_dialog.dialog_text = "¿Está seguro que desea limpiar todos los logs?\nEsta acción no se puede deshacer."
	
	confirm_dialog.confirmed.connect(func():
		var logs_dir = "user://backups/logs/"
		var logs_file = logs_dir + "backup_logs.txt"
		
		if FileAccess.file_exists(logs_file):
			var file = FileAccess.open(logs_file, FileAccess.WRITE)
			if file:
				file.store_string("=== LOGS LIMPIADOS EL: " + obtener_fecha_actual() + " ===\n")
				file.close()
				update_status("Logs limpiados exitosamente")
				_cargar_logs(logs_dialog, text_edit, stats_label)
			else:
				show_error("No se pudieron limpiar los logs")
	)
	
	logs_dialog.add_child(confirm_dialog)
	confirm_dialog.popup_centered()

func _exportar_logs(logs_dialog: AcceptDialog):
	var export_dir = "user://backups/export/"
	var export_file = export_dir + "backup_logs_export_" + obtener_fecha_actual().replace(":", "-").replace(" ", "_") + ".txt"
	
	# Asegurarse de que el directorio existe
	var dir = DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("backups/export")
	
	# Copiar el archivo de logs
	var logs_file = "user://backups/logs/backup_logs.txt"
	if FileAccess.file_exists(logs_file):
		var source_file = FileAccess.open(logs_file, FileAccess.READ)
		var dest_file = FileAccess.open(export_file, FileAccess.WRITE)
		
		if source_file and dest_file:
			var content = source_file.get_as_text()
			# Añadir encabezado de exportación
			dest_file.store_string("=== EXPORTACIÓN DE LOGS - " + obtener_fecha_actual() + " ===\n")
			dest_file.store_string("=== SISTEMA DE GESTIÓN DE CALIDAD - HAVANATUR ===\n\n")
			dest_file.store_string(content)
			source_file.close()
			dest_file.close()
			
			# Mostrar mensaje de éxito
			var success_dialog = AcceptDialog.new()
			success_dialog.title = "Exportación Exitosa"
			success_dialog.dialog_text = "Logs exportados exitosamente a:\n" + export_file
			logs_dialog.add_child(success_dialog)
			success_dialog.popup_centered()
			
			update_status("Logs exportados exitosamente")
		else:
			show_error("No se pudo exportar los logs")
	else:
		show_error("No hay logs para exportar")

func _on_volver():
	# Volver al menú principal usando SceneManager
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").change_scene_to("menu_principal")
	else:
		# Fallback si SceneManager no está disponible
		get_tree().change_scene_to_file("res://scenes/menu_principal.tscn")

func update_status(message: String, is_error: bool = false):
	status_message.text = message
	if is_error:
		# CORRECCIÓN: Sintaxis correcta para Godot 4
		status_message.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2, 1))
	else:
		status_message.add_theme_color_override("font_color", Color(0.2, 0.4, 0.2, 1))

func show_error(message: String):
	error_dialog.dialog_text = message
	error_dialog.popup_centered()
	update_status("Error: " + message, true)
	
	# También escribir en el log
	escribir_log("ERROR: " + message, "ERROR")

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

# Función para obtener instancia de BD
func obtener_instancia_bd():
	var bd = null
	
	# Método 1: Buscar el nodo BD en el árbol
	if has_node("/root/BD"):
		bd = get_node("/root/BD")
		print("BD encontrada en /root/BD")
	elif has_node("/root/Bd"):
		bd = get_node("/root/Bd")
		print("BD encontrada en /root/Bd")
	elif has_node("/root/bd"):
		bd = get_node("/root/bd")
		print("BD encontrada en /root/bd")
	
	# Método 2: Si está como singleton/Autoload con otro nombre
	if not bd:
		# Buscar nodos que tengan métodos de BD
		for child in get_tree().root.get_children():
			if child.has_method("query") or child.has_method("select_query"):
				bd = child
				print("BD encontrada por métodos: " + child.name)
				break
	
	# Método 3: Crear instancia temporal si existe el script
	if not bd:
		print("Intentando cargar script de BD...")
		var bd_script = load("res://scripts/bd.gd")
		if bd_script:
			bd = bd_script.new()
			# Inicializar si tiene método _ready
			if bd.has_method("_ready"):
				bd.call_deferred("_ready")
			print("Instancia temporal de BD creada")
	
	return bd

# Función para obtener información del sistema
func obtener_info_sistema() -> String:
	var info = []
	
	# Información del sistema operativo
	info.append("SO: " + OS.get_name())
	info.append("Versión: " + OS.get_version())
	
	return " | ".join(info)

# Función para obtener fecha actual formateada
func obtener_fecha_actual() -> String:
	var tiempo = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		tiempo.year, tiempo.month, tiempo.day,
		tiempo.hour, tiempo.minute, tiempo.second
	]

# Función para calcular hash del archivo (simple)
func calcular_hash_archivo(ruta: String) -> String:
	var archivo = FileAccess.open(ruta, FileAccess.READ)
	if not archivo:
		return "ERROR"
	
	var contenido = archivo.get_as_text()
	archivo.close()
	
	# Hash simple MD5 (para producción usar Crypto más robusto)
	var hash = 0
	for i in range(contenido.length()):
		hash = (hash * 31 + contenido.unicode_at(i)) & 0xFFFFFFFF
	
	# Convertir a hexadecimal
	var hex_string = "%08x" % hash
	return "HASH_" + hex_string

# Función para registrar el backup en la BD
func registrar_backup_en_bd(ruta: String, total_registros: int, hash_backup: String) -> bool:
	if not bd_instance:
		print("⚠️ No se pudo registrar backup en BD (instancia no disponible)")
		return false
	
	# Verificar si existe la tabla de backups
	if bd_instance.has_method("table_exists") and not bd_instance.table_exists("backups"):
		print("⚠️ Tabla 'backups' no existe, no se puede registrar")
		return false
	
	# Obtener usuario actual (simulado para ahora)
	var usuario_id = 1
	
	# Obtener tamaño del archivo
	var tamano_bytes = 0
	var archivo_info = FileAccess.open(ruta, FileAccess.READ)
	if archivo_info:
		tamano_bytes = archivo_info.get_length()
		archivo_info.close()
	
	# Crear datos del backup
	var datos_backup = {
		"nombre_archivo": ruta.get_file(),
		"ruta": ruta,
		"tamano_bytes": tamano_bytes,
		"usuario_id": usuario_id,
		"tipo": "manual",
		"estado": "completado",
		"total_registros": total_registros,
		"hash_verificacion": hash_backup,
		"observaciones": "Backup manual del sistema"
	}
	
	# Insertar en tabla de backups
	if bd_instance.has_method("insert"):
		var id_backup = bd_instance.insert("backups", datos_backup)
		if id_backup > 0:
			print("✅ Backup registrado en BD con ID: " + str(id_backup))
			return true
	
	print("⚠️ No se pudo registrar backup en BD")
	return false

# Función para registrar restore en la BD
func registrar_restore_en_bd(ruta_backup: String) -> bool:
	if not bd_instance:
		print("⚠️ No se pudo registrar restore en BD")
		return false
	
	# Aquí podrías registrar el restore en una tabla específica
	# Por ahora solo escribimos en el log
	
	print("✅ Restore registrado en logs")
	return true

# Función para escribir en el log
func escribir_log(mensaje: String, tipo: String = "INFO"):
	var timestamp = obtener_fecha_actual()
	var log_entry = "[" + timestamp + "] [" + tipo + "] " + mensaje
	
	print(log_entry)
	
	# Crear directorio de logs si no existe
	var dir = DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("backups/logs")
	
	# Escribir en archivo de log
	var archivo_log = FileAccess.open("user://backups/logs/backup_logs.txt", FileAccess.READ_WRITE)
	if archivo_log:
		archivo_log.seek_end()
		archivo_log.store_string(log_entry + "\n")
		archivo_log.close()
	else:
		# Si no existe, crear nuevo
		archivo_log = FileAccess.open("user://backups/logs/backup_logs.txt", FileAccess.WRITE)
		if archivo_log:
			archivo_log.store_string(log_entry + "\n")
			archivo_log.close()

# Función para obtener tamaño de archivo
func obtener_tamano_archivo(ruta: String) -> int:
	if FileAccess.file_exists(ruta):
		var archivo = FileAccess.open(ruta, FileAccess.READ)
		if archivo:
			var tamano = archivo.get_length()
			archivo.close()
			return tamano
	return 0

# Función para formatear tamaño en bytes a formato legible
func formatear_tamano(bytes: int) -> String:
	var unidades = ["B", "KB", "MB", "GB"]
	var tamano = float(bytes)
	var unidad = 0
	
	while tamano >= 1024 and unidad < unidades.size() - 1:
		tamano /= 1024
		unidad += 1
	
	return "%.2f %s" % [tamano, unidades[unidad]]
