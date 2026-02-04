extends Control

"""
Módulo para procesar expedientes de No Conformidades (NC).

Esta escena permite a los usuarios especialistas de calidad:
1. Cargar documentos a expedientes de NC existentes
2. Visualizar información de NC (tipo, estado, fecha, descripción)
3. Cerrar expedientes cuando la NC está en estado 'cerrada'
4. Gestionar documentos asociados a cada NC

El módulo se integra con el sistema de base de datos SQLite mediante
la clase singleton Bd para persistencia de datos.
"""

# ============================================================
# CONSTANTES Y ENUMS
# ============================================================

enum LogLevel { DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3 }

# ============================================================
# VARIABLES Y REFERENCIAS A NODOS
# ============================================================

@onready var label_id: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/ScrollInfo/InfoExpediente/IDExpediente
@onready var label_tipo: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/ScrollInfo/InfoExpediente/TipoNC
@onready var label_estado: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/ScrollInfo/InfoExpediente/EstadoNC
@onready var label_fecha: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/ScrollInfo/InfoExpediente/FechaRegistro
@onready var label_desc: Label = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/ScrollInfo/InfoExpediente/Descripcion
@onready var lista_documentos: ItemList = $ContentContainer/PanelIzquierdo/PanelInfoExpediente/ScrollInfo/InfoExpediente/ListaDocumentos
@onready var boton_cargar: Button = $ContentContainer/PanelDerecho/PanelAcciones/Acciones/BotonCargarDoc
@onready var boton_cerrar: Button = $ContentContainer/PanelDerecho/PanelAcciones/Acciones/BotonCerrarExp
@onready var mensaje_estado: Label = $ContentContainer/PanelDerecho/PanelAcciones/Acciones/MensajeEstado
@onready var boton_menu: Button = $Footer/FooterHBox/BtnVolverMenu
@onready var boton_actualizar: Button = $ContentContainer/PanelDerecho/PanelAcciones/Acciones/BtnActualizarInfo
@onready var dialogo_cargar: FileDialog = $DialogoCargarDoc
@onready var dialogo_confirmar: AcceptDialog = $DialogoConfirmacion
@onready var mensaje_exito: AcceptDialog = $MensajeExito
@onready var mensaje_error: AcceptDialog = $MensajeError

# ============================================================
# VARIABLES DE ESTADO
# ============================================================

"""
ID de la No Conformidad actualmente en proceso.

Este valor se obtiene de la base de datos al cargar la primera NC
en estado 'analizado' o 'cerrada' que no tenga el expediente cerrado.

En una implementación completa, este valor debería recibirse como
parámetro desde el menú principal al seleccionar una NC específica.
"""
var id_nc_actual: int = 0

"""
Diccionario con toda la información de la NC actual.

Contiene los campos de la tabla 'no_conformidades' más información
relacionada de tablas 'clientes' y 'usuarios' (joins en consulta SQL).
"""
var datos_nc: Dictionary = {}

"""
Array de documentos asociados a la NC actual.

Cada elemento es un diccionario con:
- id: ID del documento en tabla 'documentos_nc'
- nombre: Nombre del archivo
- ruta: Ruta completa del archivo
- tipo: Extensión del archivo (pdf, docx, etc.)
- fecha: Fecha de carga
- usuario: Nombre del usuario que cargó el documento
- descripcion: Descripción opcional del documento
"""
var documentos: Array = []

# ============================================================
# FUNCIONES DE INICIALIZACIÓN
# ============================================================

func _ready():
    """
    Inicializa la escena ProcesarExpediente.
    
    Esta función se ejecuta automáticamente cuando la escena se carga.
    Realiza las siguientes operaciones:
    1. Conecta todas las señales de botones y diálogos
    2. Configura los filtros del FileDialog
    3. Carga la información inicial desde la base de datos
    4. Actualiza la interfaz de usuario
    
    Note:
        - La conexión de señales es crítica para la funcionalidad
        - Si la BD no está disponible, se muestran mensajes de error
        - El FileDialog debe estar correctamente configurado para
          permitir la selección de archivos del sistema
    """
    print("=== PROCESAR EXPEDIENTE - INICIO ===")
    
    # DEPURACIÓN: Verificar señales conectadas
    print("🔌 Señales conectadas:")
    print("  - boton_cargar:", boton_cargar.pressed.get_connections())
    print("  - dialogo_cargar.file_selected:", dialogo_cargar.file_selected.get_connections())
    
    # Conexión alternativa con lambda para debug
    dialogo_cargar.file_selected.connect(func(path): 
        print("📁 FILE SELECTED SIGNAL FIRED! Path:", path)
        _on_DialogoCargarDoc_file_selected(path)
    )
    
    # Conectar señales de botones
    boton_cargar.pressed.connect(_on_BotonCargarDoc_pressed)
    boton_cerrar.pressed.connect(_on_BotonCerrarExp_pressed)
    boton_menu.pressed.connect(_on_BtnVolverMenu_pressed)
    boton_actualizar.pressed.connect(_on_BtnActualizarInfo_pressed)
    dialogo_confirmar.confirmed.connect(_on_DialogoConfirmacion_confirmed)
    
    # Configurar filtros de archivo
    dialogo_cargar.filters = PackedStringArray([
        "*.pdf ; Documentos PDF",
        "*.doc, *.docx ; Documentos Word",
        "*.xls, *.xlsx ; Hojas de cálculo",
        "*.jpg, *.jpeg, *.png ; Imágenes",
        "*.txt ; Archivos de texto"
    ])
    
    # Cargar la NC desde la base de datos
    _cargar_nc_desde_bd()
    
    # Actualizar interfaz
    _actualizar_interfaz()

# ============================================================
# FUNCIONES DE CARGA DE DATOS DESDE BD
# ============================================================

func _cargar_nc_desde_bd():
    """
    Carga una No Conformidad desde la base de datos para procesamiento.
    
    Realiza una consulta SQL para encontrar la primera NC en estado
    'analizado' o 'cerrada' que no tenga el expediente cerrado.
    
    La consulta incluye joins con las tablas 'clientes' y 'usuarios'
    para obtener información relacionada.
    
    Returns:
        void: No retorna valor, pero actualiza las variables de clase
        id_nc_actual y datos_nc, y llama a _cargar_documentos_desde_bd()
    
    Raises:
        SQLiteError: Si hay problemas con la base de datos
        TableNotFoundError: Si la tabla 'no_conformidades' no existe
    
    Example:
        _cargar_nc_desde_bd()
        # Si encuentra NC: id_nc_actual = 1, datos_nc = {id_nc:1, ...}
        # Si no encuentra: muestra mensaje de error en interfaz
    """
    print("Buscando NC para procesar desde BD...")
    
    # Verificar si la tabla existe
    if not Bd.table_exists("no_conformidades"):
        print("❌ Tabla 'no_conformidades' no existe")
        mensaje_estado.text = "Error: Tabla de NC no encontrada en BD"
        mensaje_estado.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
        return
    
    # Buscar la primera NC en estado 'analizado' o 'cerrada'
    var sql = """
    SELECT 
        nc.*,
        c.nombre as nombre_cliente,
        u.nombre_completo as nombre_responsable
    FROM no_conformidades nc
    LEFT JOIN clientes c ON nc.cliente_id = c.id
    LEFT JOIN usuarios u ON nc.responsable_id = u.id
    WHERE nc.estado IN ('analizado', 'cerrada')
        AND nc.expediente_cerrado = 0
    ORDER BY nc.prioridad ASC, nc.fecha_registro ASC
    LIMIT 1
    """
    
    var resultado = Bd.select_query(sql)
    
    if resultado and resultado.size() > 0:
        var fila = resultado[0]
        id_nc_actual = fila["id_nc"]
        datos_nc = fila
        print("✅ NC cargada desde BD: ", id_nc_actual)
        
        # Cargar documentos asociados
        _cargar_documentos_desde_bd()
    else:
        print("⚠️ No hay NC para procesar en BD")
        mensaje_estado.text = "No hay expedientes disponibles para procesar"
        mensaje_estado.add_theme_color_override("font_color", Color(0.8, 0.5, 0.1))
        boton_cargar.disabled = true
        boton_cerrar.disabled = true

func _cargar_documentos_desde_bd():
    """
    Carga los documentos asociados a la NC actual desde la base de datos.
    
    Realiza una consulta a la tabla 'documentos_nc' para obtener todos
    los documentos vinculados a id_nc_actual, ordenados por fecha descendente.
    
    Cada documento se añade al array 'documentos' y se muestra en el
    ItemList con un icono según su tipo de archivo.
    
    Returns:
        void: No retorna valor, pero actualiza la lista_documentos
        y el array interno 'documentos'
    
    Notes:
        - Los iconos se asignan según la extensión del archivo
        - La fecha se formatea para mostrar solo año-mes-día
        - Si no hay documentos, el ItemList queda vacío
    """
    print("Cargando documentos de NC desde BD: ", id_nc_actual)
    
    # Verificar si la tabla existe
    if not Bd.table_exists("documentos_nc"):
        print("⚠️ Tabla 'documentos_nc' no existe")
        return
    
    var sql = """
    SELECT 
        dn.*,
        u.nombre_completo as nombre_usuario
    FROM documentos_nc dn
    LEFT JOIN usuarios u ON dn.usuario_carga = u.id
    WHERE dn.id_nc = {id_nc}
    ORDER BY dn.fecha_carga DESC
    """.format({"id_nc": id_nc_actual})
    
    var resultado = Bd.select_query(sql)
    
    documentos.clear()
    lista_documentos.clear()
    
    if resultado:
        for fila in resultado:
            var nombre_archivo = fila["nombre_archivo"]
            var tipo_archivo = fila["tipo_archivo"]
            var fecha_carga = fila["fecha_carga"]
            var usuario = fila["nombre_usuario"] or "Desconocido"
            
            # Agregar a array interno
            documentos.append({
                "id": fila["id"],
                "nombre": nombre_archivo,
                "ruta": fila["ruta_archivo"],
                "tipo": tipo_archivo,
                "fecha": fecha_carga,
                "usuario": usuario,
                "descripcion": fila["descripcion"] or ""
            })
            
            # Agregar a ItemList con icono según tipo
            var icono = ""
            if tipo_archivo:
                match tipo_archivo.to_lower():
                    "pdf": icono = "📄"
                    "doc", "docx": icono = "📝"
                    "xls", "xlsx": icono = "📊"
                    "jpg", "jpeg", "png": icono = "🖼️"
                    _: icono = "📎"
            else:
                icono = "📎"
            
            # Mostrar nombre y fecha
            var fecha_formateada = fecha_carga if fecha_carga else "Sin fecha"
            var texto_item = "{icono} {nombre}\n   📅 {fecha} 👤 {usuario}".format({
                "icono": icono,
                "nombre": nombre_archivo,
                "fecha": fecha_formateada.substr(0, 10) if fecha_formateada.length() >= 10 else fecha_formateada,
                "usuario": usuario
            })
            
            lista_documentos.add_item(texto_item)
    
    print("✅ Documentos cargados desde BD: ", documentos.size())

# ============================================================
# FUNCIONES DE ACTUALIZACIÓN DE INTERFAZ
# ============================================================

func _actualizar_interfaz():
    """
    Actualiza toda la interfaz de usuario con los datos de la NC.
    
    Establece los textos de todos los labels con la información
    de datos_nc y llama a _actualizar_botones_segun_estado() para
    habilitar/deshabilitar botones según corresponda.
    
    Returns:
        void: Solo actualiza elementos visuales
    
    Note:
        - Si datos_nc está vacío, muestra mensaje de advertencia
        - La fecha se formatea para mostrar solo año-mes-día
        - Los botones se actualizan según el estado de la NC
    """
    print("Actualizando interfaz desde BD...")
    
    if datos_nc.size() == 0:
        print("⚠️ No hay datos de NC para mostrar")
        return
    
    # Mostrar información básica
    label_id.text = "ID Expediente: " + datos_nc.get("codigo_expediente", "N/A")
    label_tipo.text = "Tipo No Conformidad: " + datos_nc.get("tipo_nc", "No especificado")
    label_estado.text = "Estado No Conformidad: " + datos_nc.get("estado", "Desconocido")
    
    # Formatear fecha
    var fecha_registro = datos_nc.get("fecha_registro", "")
    if fecha_registro:
        label_fecha.text = "Fecha Registro: " + fecha_registro.substr(0, 10)
    else:
        label_fecha.text = "Fecha Registro: N/A"
    
    label_desc.text = "Descripción: " + datos_nc.get("descripcion", "Sin descripción")
    
    # Actualizar botones según estado
    _actualizar_botones_segun_estado()

func _actualizar_botones_segun_estado():
    """
    Actualiza el estado de los botones según el estado de la NC.
    
    Define tres estados principales:
    1. 'analizado': Permite cargar documentos, no permite cerrar expediente
    2. 'cerrada': No permite cargar documentos, permite cerrar expediente
    3. Otros estados: Ambos botones deshabilitados
    
    Returns:
        void: Solo actualiza estado de botones y mensaje_estado
    
    Example:
        Si estado = "analizado":
            boton_cargar.disabled = false
            boton_cerrar.disabled = true
            mensaje_estado.text = "✅ Puede cargar documentos..."
    """
    var estado = datos_nc.get("estado", "")
    
    match estado:
        "analizado":
            mensaje_estado.text = "✅ Puede cargar documentos al expediente"
            mensaje_estado.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
            boton_cargar.disabled = false
            boton_cerrar.disabled = true
            print("Estado: analizado - Cargar habilitado")
        
        "cerrada":
            mensaje_estado.text = "✅ Puede proceder a cerrar el expediente"
            mensaje_estado.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
            boton_cargar.disabled = true
            boton_cerrar.disabled = false
            print("Estado: cerrada - Cerrar habilitado")
        
        _:
            mensaje_estado.text = "⚠️ Espere a que la NC esté analizada o cerrada"
            mensaje_estado.add_theme_color_override("font_color", Color(0.8, 0.5, 0.1))
            boton_cargar.disabled = true
            boton_cerrar.disabled = true
            print("Estado: ", estado, " - Ambos deshabilitados")

# ============================================================
# FUNCIONES DE SEÑAL (EVENTOS DE BOTONES)
# ============================================================

func _on_BotonCargarDoc_pressed():
    """
    Maneja el evento de clic en el botón 'Cargar Documento'.
    
    Muestra el FileDialog en una posición específica para permitir
    al usuario seleccionar un archivo del sistema.
    
    Returns:
        void: Solo muestra el diálogo
    
    Notes:
        - Usa popup(Rect2i(...)) en lugar de popup_centered() para
          asegurar visibilidad
        - La posición y tamaño están hardcodeados para consistencia
        - El FileDialog debe estar correctamente configurado con filtros
    """
    print("--- Botón Cargar presionado ---")
    dialogo_cargar.popup(Rect2i(100, 100, 800, 500))

func _on_BotonCerrarExp_pressed():
    """
    Maneja el evento de clic en el botón 'Cerrar Expediente'.
    
    Muestra un diálogo de confirmación con los detalles de la NC
    antes de proceder con el cierre definitivo del expediente.
    
    Returns:
        void: Solo muestra el diálogo de confirmación
    
    Note:
        - Esta acción es irreversible una vez confirmada
        - Solo disponible cuando la NC está en estado 'cerrada'
        - Requiere confirmación explícita del usuario
    """
    print("📦 Botón Cerrar expediente presionado")
    
    dialogo_confirmar.dialog_text = """
    ¿Está seguro que desea cerrar este expediente?
    
    📋 ID: {id}
    📄 NC: {nc}
    
    ⚠️ Esta acción no se puede deshacer.
    """.format({
        "id": datos_nc.get("codigo_expediente", ""),
        "nc": datos_nc.get("tipo_nc", "")
    })
    
    dialogo_confirmar.popup_centered()

func _on_BtnVolverMenu_pressed():
    """
    Maneja el evento de clic en el botón 'Volver al Menú'.
    
    Cambia la escena actual al menú principal, permitiendo al usuario
    regresar sin guardar cambios adicionales.
    
    Returns:
        void: Solo cambia de escena
    
    Note:
        - No hay confirmación de salida (cambios se guardan automáticamente)
        - La ruta de la escena debe ser correcta
        - Esta función no verifica si hay operaciones pendientes
    """
    print("🏠 Regresando al menú principal...")
    get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")

func _on_BtnActualizarInfo_pressed():
    """
    Maneja el evento de clic en el botón 'Actualizar Información'.
    
    Vuelve a cargar todos los datos desde la base de datos y actualiza
    la interfaz. Útil si otros usuarios han modificado el expediente.
    
    Returns:
        void: Recarga datos y actualiza interfaz
    
    Note:
        - Esta operación puede ser lenta si hay muchos documentos
        - No hay confirmación de pérdida de cambios locales
        - Siempre muestra mensaje de éxito (aunque no haya cambios)
    """
    print("🔄 Actualizando información desde BD...")
    
    # Recargar datos de la NC
    _cargar_nc_desde_bd()
    
    # Actualizar interfaz
    _actualizar_interfaz()
    
    mensaje_exito.dialog_text = "✅ Información actualizada correctamente"
    mensaje_exito.popup_centered()
    
    print("✅ Información actualizada desde BD")

# ============================================================
# FUNCIONES DE GESTIÓN DE ARCHIVOS
# ============================================================

func _on_DialogoCargarDoc_file_selected(path: String):
    """
    Procesa el archivo seleccionado en el FileDialog.
    
    Esta función se ejecuta cuando el usuario selecciona un archivo
    en el FileDialog. Realiza las siguientes operaciones:
    1. Extrae información del archivo (nombre, extensión, tamaño)
    2. Guarda la información en la tabla 'documentos_nc'
    3. Opcionalmente copia el archivo a una carpeta local
    4. Actualiza la lista de documentos en la interfaz
    5. Muestra mensaje de éxito o error
    
    Parameters:
        path (String): Ruta completa del archivo seleccionado
    
    Returns:
        void: Guarda en BD y actualiza interfaz
    
    Raises:
        FileNotFoundError: Si el archivo no existe en la ruta especificada
        SQLiteError: Si hay problemas al insertar en la base de datos
    
    Notes:
        - El usuario_carga está hardcodeado (debería venir de sesión)
        - El tamaño máximo de archivo no está limitado
        - No se valida el contenido del archivo, solo metadatos
    """
    print("📁 Procesando archivo: ", path)
    
    var nombre_archivo = path.get_file()
    var extension = nombre_archivo.get_extension().to_lower()
    var tamanio_bytes = _obtener_tamanio_archivo(path)
    
    # Determinar tipo de archivo
    var tipo_archivo = extension
    
    # Guardar en la base de datos
    var datos_documento = {
        "id_nc": id_nc_actual,
        "nombre_archivo": nombre_archivo,
        "ruta_archivo": path,
        "tipo_archivo": tipo_archivo,
        "tamanio_bytes": tamanio_bytes,
        "usuario_carga": 1,  # ID del usuario actual (debería obtenerse de la sesión)
        "descripcion": "Documento cargado desde sistema"
    }
    
    var id_insertado = Bd.insert("documentos_nc", datos_documento)
    
    if id_insertado > 0:
        print("✅ Documento guardado en BD con ID: ", id_insertado)
        
        # Copiar archivo a carpeta de documentos (opcional)
        if _copiar_archivo_a_documentos(path, nombre_archivo, id_insertado):
            print("✅ Archivo copiado a carpeta de documentos")
        
        # Actualizar la lista de documentos
        _cargar_documentos_desde_bd()
        
        # Mostrar mensaje de éxito
        mensaje_exito.dialog_text = "✅ Documento '{nombre}' cargado exitosamente".format({"nombre": nombre_archivo})
        mensaje_exito.popup_centered()
        
        # Registrar traza de auditoría
        _registrar_traza("CARGA_DOCUMENTO", "Documento cargado: " + nombre_archivo)
    else:
        print("❌ Error al guardar documento en BD")
        mensaje_error.dialog_text = "Error al guardar el documento en la base de datos"
        mensaje_error.popup_centered()

func _obtener_tamanio_archivo(path: String) -> int:
    """
    Obtiene el tamaño de un archivo en bytes.
    
    Parameters:
        path (String): Ruta completa del archivo
    
    Returns:
        int: Tamaño del archivo en bytes, 0 si no se puede leer
    
    Note:
        - Usa FileAccess.READ para no modificar el archivo
        - Siempre cierra el archivo después de leerlo
        - Retorna 0 si el archivo no existe o no se puede acceder
    """
    var file = FileAccess.open(path, FileAccess.READ)
    if file:
        var tamanio = file.get_length()
        file.close()
        return tamanio
    return 0

func _copiar_archivo_a_documentos(origen: String, nombre_archivo: String, id_documento: int) -> bool:
    """
    Copia un archivo a la carpeta de documentos del sistema.
    
    Crea una carpeta 'documentos_nc' en user:// si no existe y
    copia el archivo con un nombre único que incluye:
    - ID de la NC
    - ID del documento
    - Timestamp actual
    - Nombre original del archivo
    
    Parameters:
        origen (String): Ruta del archivo original
        nombre_archivo (String): Nombre original del archivo
        id_documento (int): ID del documento en la base de datos
    
    Returns:
        bool: True si la copia fue exitosa, False en caso contrario
    
    Note:
        - Si la copia falla, se mantiene la ruta original en BD
        - El timestamp evita colisiones de nombres
        - Actualiza la ruta en BD después de copiar exitosamente
    """
    var _carpeta_docs = "user://documentos_nc/"
    
    # Crear directorio si no existe
    var dir = DirAccess.open("user://")
    if not dir.dir_exists("documentos_nc"):
        var error = dir.make_dir("documentos_nc")
        if error != OK:
            print("❌ Error al crear carpeta documentos_nc: ", error)
            return false
    
    # Generar nombre único para evitar colisiones
    var timestamp = Time.get_unix_time_from_system()
    var nombre_unico = "{id_nc}_{id_doc}_{timestamp}_{nombre}".format({
        "id_nc": id_nc_actual,
        "id_doc": id_documento,
        "timestamp": timestamp,
        "nombre": nombre_archivo
    })
    
    var destino = _carpeta_docs + nombre_unico
    
    # Copiar archivo
    if DirAccess.copy_absolute(origen, destino) == OK:
        print("✅ Archivo copiado a: ", destino)
        
        # Actualizar ruta en la base de datos
        Bd.update("documentos_nc", {"ruta_archivo": destino}, "id = ?", [id_documento])
        return true
    else:
        print("⚠️ No se pudo copiar archivo, usando ruta original")
        return false

# ============================================================
# FUNCIONES DE GESTIÓN DE EXPEDIENTES
# ============================================================

func _on_DialogoConfirmacion_confirmed():
    """
    Cierra definitivamente el expediente en la base de datos.
    
    Se ejecuta cuando el usuario confirma el cierre del expediente.
    Actualiza la tabla 'no_conformidades' estableciendo:
    - expediente_cerrado = 1
    - fecha_cierre = fecha/hora actual
    - usuario_cierre = ID del usuario (hardcodeado temporalmente)
    - estado = 'expediente_cerrado'
    
    Returns:
        void: Actualiza BD e interfaz
    
    Note:
        - Esta acción es irreversible
        - Registra una traza de auditoría
        - Deshabilita todos los botones de acción
    """
    print("🚪 Cerrando expediente en BD...")
    
    var datos_actualizacion = {
        "expediente_cerrado": 1,
        "fecha_cierre": Time.get_datetime_string_from_system(),
        "usuario_cierre": 1,  # ID del usuario actual (debería obtenerse de la sesión)
        "estado": "expediente_cerrado"
    }
    
    var where = "id_nc = ?"
    var params = [id_nc_actual]
    
    if Bd.update("no_conformidades", datos_actualizacion, where, params):
        print("✅ Expediente cerrado en BD")
        
        # Actualizar datos locales
        datos_nc["estado"] = "expediente_cerrado"
        datos_nc["expediente_cerrado"] = 1
        
        # Actualizar interfaz
        _actualizar_interfaz()
        
        # Mostrar mensaje de éxito
        mensaje_exito.dialog_text = "✅ Expediente cerrado exitosamente"
        mensaje_exito.popup_centered()
        
        # Registrar traza de auditoría
        _registrar_traza("CIERRE_EXPEDIENTE", "Expediente cerrado: " + datos_nc.get("codigo_expediente", ""))
    else:
        print("❌ Error al cerrar expediente en BD")
        mensaje_error.dialog_text = "Error al cerrar el expediente en la base de datos"
        mensaje_error.popup_centered()

func _registrar_traza(accion: String, detalles: String):
    """
    Registra una traza de auditoría en la tabla 'trazas_nc'.
    
    Parameters:
        accion (String): Tipo de acción realizada (ej: 'CARGA_DOCUMENTO')
        detalles (String): Descripción detallada de la acción
    
    Returns:
        void: Solo inserta en la base de datos
    
    Note:
        - La IP está hardcodeada para desarrollo
        - El usuario_id está hardcodeado (debería venir de sesión)
        - Si la tabla no existe, solo muestra advertencia
    """
    if not Bd.table_exists("trazas_nc"):
        print("⚠️ Tabla 'trazas_nc' no existe, no se puede registrar traza")
        return
    
    var datos_traza = {
        "id_nc": id_nc_actual,
        "usuario_id": 1,  # ID del usuario actual (debería obtenerse de la sesión)
        "accion": accion,
        "detalles": detalles,
        "ip_address": "127.0.0.1"  # En producción, obtén la IP real
    }
    
    var id_traza = Bd.insert("trazas_nc", datos_traza)
    if id_traza > 0:
        print("✅ Traza registrada con ID: ", id_traza)
