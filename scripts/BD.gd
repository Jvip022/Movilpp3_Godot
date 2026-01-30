extends Node
class_name BD

var db = SQLite.new()
var database_path = "res://data/quejas.db"

func _ready():
	# Crear directorio de datos si no existe
	var dir = DirAccess.open("res://")
	dir.make_dir("res://data")
	
	# Abrir conexión a la base de datos
	db.path = database_path
	db.open_db()
	
	# Crear tablas
	crear_tablas_quejas()

func crear_tablas_quejas():
	# Tabla principal de QUEJAS y RECLAMACIONES
	db.query("""
		CREATE TABLE IF NOT EXISTS quejas_reclamaciones (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
            
            -- Identificación única
			numero_caso TEXT UNIQUE,  -- Q-2024-001
			tipo_caso TEXT CHECK(tipo_caso IN ('queja', 'reclamacion', 'sugerencia', 'felicitacion')),
			canal_entrada TEXT CHECK(canal_entrada IN ('presencial', 'telefonico', 'email', 'web', 'redes_sociales', 'app', 'carta')),
            
            -- Datos del reclamante
			tipo_reclamante TEXT CHECK(tipo_reclamante IN ('cliente', 'proveedor', 'empleado', 'ciudadano', 'otro')),
			identificacion TEXT,  -- DNI/RUC/Cédula
			nombres TEXT NOT NULL,
			apellidos TEXT,
			telefono TEXT,
			email TEXT,
			direccion TEXT,
            
            -- Datos de la queja
			asunto TEXT NOT NULL,
			descripcion_detallada TEXT NOT NULL,
			producto_servicio TEXT,  -- Producto/Servicio afectado
			numero_contrato TEXT,
			numero_factura TEXT,
			fecha_incidente DATE,
			lugar_incidente TEXT,
            
            -- Categorización
			categoria TEXT CHECK(categoria IN ('calidad_producto', 'atencion_cliente', 'plazos_entrega', 'facturacion', 'garantia', 'daños', 'perdidas', 'publicidad_enganosa', 'privacidad')),
			subcategoria TEXT,
            
            -- Valoración económica
			monto_reclamado REAL DEFAULT 0,
			moneda TEXT DEFAULT 'USD',
			tipo_compensacion TEXT CHECK(tipo_compensacion IN ('dinero', 'reemplazo', 'reparacion', 'descuento', 'servicio_gratis', 'disculpas', 'ninguna')),
            
            -- Estado y prioridad
			prioridad TEXT CHECK(prioridad IN ('baja', 'media', 'alta', 'urgente')),
			estado TEXT CHECK(estado IN ('recibida', 'en_revision', 'investigando', 'negociacion', 'resuelta', 'rechazada', 'escalada', 'judicial', 'archivada')),
			nivel_escalamiento INTEGER DEFAULT 1,  -- 1=Operador, 2=Supervisor, 3=Gerente, 4=Legal
            
            -- Responsables
			recibido_por TEXT,
			asignado_a TEXT,
			equipo_responsable TEXT,
            
            -- Fechas del proceso
			fecha_recepcion DATETIME DEFAULT CURRENT_TIMESTAMP,
			fecha_limite_respuesta DATE,
			fecha_respuesta_cliente DATE,
			fecha_cierre DATETIME,
            
            -- Proceso de investigación
			hechos_constatados TEXT,
			pruebas_adjuntas TEXT,  -- JSON con rutas de archivos
			testigos TEXT,
			responsable_interno TEXT,  -- Empleado responsable del problema
            
            -- Resolución
			decision TEXT CHECK(decision IN ('aceptada_parcial', 'aceptada_total', 'rechazada', 'mediacion')),
			solucion_propuesta TEXT,
			compensacion_otorgada REAL DEFAULT 0,
			descripcion_compensacion TEXT,
            
            -- Seguimiento post-resolución
			satisfaccion_cliente INTEGER,  -- 1-5 estrellas
			comentarios_finales TEXT,
			reincidente BOOLEAN DEFAULT FALSE,
            
            -- Datos legales
			requiere_legal BOOLEAN DEFAULT FALSE,
			numero_expediente_legal TEXT,
			asesor_legal TEXT,
            
            -- Auditoría
			creado_por TEXT,
			fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
			modificado_por TEXT,
			fecha_modificacion DATETIME,
            
            -- Metadatos
			tiempo_respuesta_horas INTEGER,  -- SLA medido
			tags TEXT  -- JSON para búsquedas: ["cliente_vip", "producto_nuevo", "urgente"]
		)
	""")
	
	# Tabla de SEGUIMIENTO de comunicación con cliente
	db.query("""
		CREATE TABLE IF NOT EXISTS seguimiento_comunicacion (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			queja_id INTEGER NOT NULL,
			fecha_contacto DATETIME DEFAULT CURRENT_TIMESTAMP,
			medio_contacto TEXT CHECK(medio_contacto IN ('llamada', 'email', 'carta', 'presencial', 'videollamada')),
			tipo_contacto TEXT CHECK(tipo_contacto IN ('inicial', 'seguimiento', 'propuesta', 'confirmacion', 'recordatorio')),
            
            -- Detalles del contacto
			contacto_con TEXT,  -- Persona contactada
			resumen TEXT NOT NULL,
			acuerdos TEXT,
			proxima_accion TEXT,
			fecha_proximo_contacto DATE,
            
            -- Estado anímico del cliente
			estado_animo TEXT CHECK(estado_animo IN ('enojado', 'frustrado', 'tranquilo', 'cooperativo', 'indiferente')),
			compromiso_cliente BOOLEAN DEFAULT FALSE,
            
            -- Responsable
			realizado_por TEXT,
			duracion_minutos INTEGER,
            
			FOREIGN KEY (queja_id) REFERENCES quejas_reclamaciones(id) ON DELETE CASCADE
		)
	""")
	
	# Tabla de DOCUMENTOS de la queja
	db.query("""
		CREATE TABLE IF NOT EXISTS documentos_queja (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			queja_id INTEGER NOT NULL,
			tipo_documento TEXT CHECK(tipo_documento IN (
				'identificacion', 'factura', 'contrato', 'foto', 'video',
				'audio', 'carta', 'informe_tecnico', 'dictamen_legal',
				'acuerdo_firmado', 'comprobante_pago'
			)),
			nombre_archivo TEXT NOT NULL,
			descripcion TEXT,
			ruta_almacenamiento TEXT,
			hash_archivo TEXT,  -- Para integridad
			fecha_subida DATETIME DEFAULT CURRENT_TIMESTAMP,
			subido_por TEXT,
			verificado BOOLEAN DEFAULT FALSE,
            
			FOREIGN KEY (queja_id) REFERENCES quejas_reclamaciones(id) ON DELETE CASCADE
		)
	""")
	
	# Tabla de COMPENSACIONES
	db.query("""
		CREATE TABLE IF NOT EXISTS compensaciones (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			queja_id INTEGER NOT NULL,
			tipo_compensacion TEXT CHECK(tipo_compensacion IN (
				'devolucion_dinero', 'voucher_descuento', 'producto_reemplazo',
				'servicio_gratis', 'puntos_fidelidad', 'disculpas_publicas',
				'donacion', 'otro'
			)),
			descripcion TEXT NOT NULL,
			monto REAL,
			moneda TEXT DEFAULT 'USD',
			estado TEXT CHECK(estado IN ('pendiente', 'aprobada', 'rechazada', 'entregada')),
            
            -- Proceso de aprobación
			aprobado_por TEXT,
			fecha_aprobacion DATE,
			nivel_aprobacion INTEGER,  -- Nivel gerencial requerido
            
            -- Entrega
			metodo_entrega TEXT,
			fecha_entrega DATE,
			recibido_por TEXT,
			comprobante_entrega TEXT,
            
			FOREIGN KEY (queja_id) REFERENCES quejas_reclamaciones(id) ON DELETE CASCADE
		)
	""")
	
	# Tabla de ANÁLISIS de tendencias
	db.query("""
		CREATE TABLE IF NOT EXISTS analisis_tendencias (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			periodo TEXT,  -- 2024-01
			categoria TEXT,
			total_quejas INTEGER DEFAULT 0,
			quejas_resueltas INTEGER DEFAULT 0,
			tiempo_promedio_respuesta REAL,
			costo_total_compensaciones REAL DEFAULT 0,
			indice_satisfaccion REAL,
			principales_problemas TEXT  -- JSON
		)
	""")

func query(sql: String, params = []):
	return db.query_with_bindings(sql, params)

func insert(table: String, data: Dictionary) -> int:
	var keys = []
	var values = []
	var placeholders = []
	
	for key in data.keys():
		keys.append(key)
		values.append(data[key])
		placeholders.append("?")
	
	var sql = "INSERT INTO %s (%s) VALUES (%s)" % [
		table, 
		", ".join(keys), 
		", ".join(placeholders)
	]
	
	db.query_with_args(sql, values)
	return db.last_insert_rowid

# Helper function para simplificar las consultas
func query_with_args(sql: String, args = []):
	return db.query_with_args(sql, args)
