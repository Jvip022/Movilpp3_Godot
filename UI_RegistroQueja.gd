# UI_RegistroQueja.gd - Formulario inteligente
extends Control

@onready var campos_dinamicos = $ScrollContainer/VBoxContainer/CamposDinamicos
@onready var boton_adjuntar = $PanelInferior/BotonAdjuntar
@onready var vista_previa = $PanelDerecho/VistaPrevia

var archivos_adjuntos = []
var tipo_reclamante_actual = "cliente"

func _ready():
	configurar_validadores()
	cargar_opciones_desde_bd()
	conectar_eventos()

func configurar_validadores():
	# Validar email
	$Email.text_changed.connect(_validar_email)
	# Validar teléfono
	$Telefono.text_changed.connect(_validar_telefono)
	# Validar monto
	$MontoReclamado.text_changed.connect(_validar_monto)

func _on_tipo_reclamante_selected(index):
	tipo_reclamante_actual = $TipoReclamante.get_item_text(index)
	mostrar_campos_relevantes()

func mostrar_campos_relevantes():
	# Mostrar/ocultar campos según tipo de reclamante
	match tipo_reclamante_actual:
		"cliente":
			$CamposCliente.visible = true
			$CamposProveedor.visible = false
			$CamposEmpleado.visible = false
		"proveedor":
			$CamposCliente.visible = false
			$CamposProveedor.visible = true
			$CamposEmpleado.visible = false
		"empleado":
			$CamposCliente.visible = false
			$CamposProveedor.visible = false
			$CamposEmpleado.visible = true

func _on_adjuntar_archivo_pressed():
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = ["*.png, *.jpg, *.jpeg ; Imágenes", "*.pdf ; Documentos PDF", "*.txt ; Texto"]
	
	dialog.files_selected.connect(_archivos_seleccionados)
	add_child(dialog)
	dialog.popup_centered(Vector2(800, 600))

func _archivos_seleccionados(rutas: PackedStringArray):
	for ruta in rutas:
		var nombre_archivo = ruta.get_file()
		archivos_adjuntos.append({
			"ruta": ruta,
			"nombre": nombre_archivo,
			"tipo": nombre_archivo.get_extension()
		})
	
	actualizar_lista_adjuntos()
	$PanelInferior/LabelAdjuntos.text = str(archivos_adjuntos.size()) + " archivos adjuntos"

func _on_enviar_queja_pressed():
	if not validar_formulario():
		mostrar_error("Complete todos los campos obligatorios")
		return
	
	var datos_queja = recopilar_datos_formulario()
	
	# Mostrar resumen antes de enviar
	$DialogoConfirmacion.mostrar_resumen(datos_queja)
	
func recopilar_datos_formulario():
	return {
		"tipo_reclamante": $TipoReclamante.get_item_text($TipoReclamante.selected),
		"nombres": $Nombres.text,
		"identificacion": $Identificacion.text,
		"telefono": $Telefono.text,
		"email": $Email.text,
		
		"asunto": $Asunto.text,
		"descripcion_detallada": $Descripcion.text,
		"producto_servicio": $ProductoServicio.text,
		"numero_factura": $NumeroFactura.text,
		"fecha_incidente": $FechaIncidente.text,
		
		"categoria": $Categoria.get_item_text($Categoria.selected),
		"monto_reclamado": float($MontoReclamado.text) if $MontoReclamado.text else 0,
		"tipo_compensacion": $TipoCompensacion.get_item_text($TipoCompensacion.selected),
		
		"archivos_adjuntos": archivos_adjuntos,
		"prioridad": calcular_prioridad_automatica()
	}
