BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "historial_quejas" (
	"id"	INTEGER,
	"queja_id"	INTEGER NOT NULL,
	"fecha"	DATETIME DEFAULT CURRENT_TIMESTAMP,
	"evento"	TEXT NOT NULL,
	"descripcion"	TEXT,
	"usuario"	TEXT,
	FOREIGN KEY("queja_id") REFERENCES "quejas_reclamaciones"("id") ON DELETE CASCADE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "quejas_reclamaciones" (
	"id"	INTEGER,
	"numero_caso"	TEXT UNIQUE,
	"tipo_caso"	TEXT CHECK("tipo_caso" IN ('queja', 'reclamacion', 'sugerencia', 'felicitacion')),
	"canal_entrada"	TEXT CHECK("canal_entrada" IN ('presencial', 'telefonico', 'email', 'web', 'redes_sociales', 'app', 'carta')),
	"tipo_reclamante"	TEXT CHECK("tipo_reclamante" IN ('cliente', 'proveedor', 'empleado', 'ciudadano', 'otro')),
	"identificacion"	TEXT,
	"nombres"	TEXT NOT NULL,
	"apellidos"	TEXT,
	"telefono"	TEXT,
	"email"	TEXT,
	"direccion"	TEXT,
	"asunto"	TEXT NOT NULL,
	"descripcion_detallada"	TEXT NOT NULL,
	"producto_servicio"	TEXT,
	"numero_contrato"	TEXT,
	"numero_factura"	TEXT,
	"fecha_incidente"	DATE,
	"lugar_incidente"	TEXT,
	"categoria"	TEXT CHECK("categoria" IN ('calidad_producto', 'atencion_cliente', 'plazos_entrega', 'facturacion', 'garantia', 'daños', 'perdidas', 'publicidad_enganosa', 'privacidad')),
	"subcategoria"	TEXT,
	"monto_reclamado"	REAL DEFAULT 0,
	"moneda"	TEXT DEFAULT 'USD',
	"tipo_compensacion"	TEXT CHECK("tipo_compensacion" IN ('dinero', 'reemplazo', 'reparacion', 'descuento', 'servicio_gratis', 'disculpas', 'ninguna')),
	"prioridad"	TEXT CHECK("prioridad" IN ('baja', 'media', 'alta', 'urgente')),
	"estado"	TEXT CHECK("estado" IN ('recibida', 'en_revision', 'investigando', 'negociacion', 'resuelta', 'rechazada', 'escalada', 'judicial', 'archivada')),
	"nivel_escalamiento"	INTEGER DEFAULT 1,
	"recibido_por"	TEXT,
	"asignado_a"	TEXT,
	"equipo_responsable"	TEXT,
	"fecha_recepcion"	DATETIME DEFAULT CURRENT_TIMESTAMP,
	"fecha_limite_respuesta"	DATE,
	"fecha_respuesta_cliente"	DATE,
	"fecha_cierre"	DATETIME,
	"hechos_constatados"	TEXT,
	"pruebas_adjuntas"	TEXT,
	"testigos"	TEXT,
	"responsable_interno"	TEXT,
	"decision"	TEXT CHECK("decision" IN ('aceptada_parcial', 'aceptada_total', 'rechazada', 'mediacion')),
	"solucion_propuesta"	TEXT,
	"compensacion_otorgada"	REAL DEFAULT 0,
	"descripcion_compensacion"	TEXT,
	"satisfaccion_cliente"	INTEGER,
	"comentarios_finales"	TEXT,
	"reincidente"	BOOLEAN DEFAULT FALSE,
	"requiere_legal"	BOOLEAN DEFAULT FALSE,
	"numero_expediente_legal"	TEXT,
	"asesor_legal"	TEXT,
	"creado_por"	TEXT,
	"fecha_creacion"	DATETIME DEFAULT CURRENT_TIMESTAMP,
	"modificado_por"	TEXT,
	"fecha_modificacion"	DATETIME,
	"tiempo_respuesta_horas"	INTEGER,
	"tags"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "seguimiento_comunicacion" (
	"id"	INTEGER,
	"queja_id"	INTEGER NOT NULL,
	"fecha_contacto"	DATETIME DEFAULT CURRENT_TIMESTAMP,
	"medio_contacto"	TEXT CHECK("medio_contacto" IN ('llamada', 'email', 'carta', 'presencial', 'videollamada')),
	"tipo_contacto"	TEXT CHECK("tipo_contacto" IN ('inicial', 'seguimiento', 'propuesta', 'confirmacion', 'recordatorio')),
	"contacto_con"	TEXT,
	"resumen"	TEXT NOT NULL,
	"acuerdos"	TEXT,
	"proxima_accion"	TEXT,
	"fecha_proximo_contacto"	DATE,
	"estado_animo"	TEXT CHECK("estado_animo" IN ('enojado', 'frustrado', 'tranquilo', 'cooperativo', 'indiferente')),
	"compromiso_cliente"	BOOLEAN DEFAULT FALSE,
	"realizado_por"	TEXT,
	"duracion_minutos"	INTEGER,
	FOREIGN KEY("queja_id") REFERENCES "quejas_reclamaciones"("id") ON DELETE CASCADE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "documentos_queja" (
	"id"	INTEGER,
	"queja_id"	INTEGER NOT NULL,
	"tipo_documento"	TEXT CHECK("tipo_documento" IN ('identificacion', 'factura', 'contrato', 'foto', 'video', 'audio', 'carta', 'informe_tecnico', 'dictamen_legal', 'acuerdo_firmado', 'comprobante_pago')),
	"nombre_archivo"	TEXT NOT NULL,
	"descripcion"	TEXT,
	"ruta_almacenamiento"	TEXT,
	"hash_archivo"	TEXT,
	"fecha_subida"	DATETIME DEFAULT CURRENT_TIMESTAMP,
	"subido_por"	TEXT,
	"verificado"	BOOLEAN DEFAULT FALSE,
	FOREIGN KEY("queja_id") REFERENCES "quejas_reclamaciones"("id") ON DELETE CASCADE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "compensaciones" (
	"id"	INTEGER,
	"queja_id"	INTEGER NOT NULL,
	"tipo_compensacion"	TEXT CHECK("tipo_compensacion" IN ('devolucion_dinero', 'voucher_descuento', 'producto_reemplazo', 'servicio_gratis', 'puntos_fidelidad', 'disculpas_publicas', 'donacion', 'otro')),
	"descripcion"	TEXT NOT NULL,
	"monto"	REAL,
	"moneda"	TEXT DEFAULT 'USD',
	"estado"	TEXT CHECK("estado" IN ('pendiente', 'aprobada', 'rechazada', 'entregada')),
	"aprobado_por"	TEXT,
	"fecha_aprobacion"	DATE,
	"nivel_aprobacion"	INTEGER,
	"metodo_entrega"	TEXT,
	"fecha_entrega"	DATE,
	"recibido_por"	TEXT,
	"comprobante_entrega"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT),
	FOREIGN KEY("queja_id") REFERENCES "quejas_reclamaciones"("id") ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS "analisis_tendencias" (
	"id"	INTEGER,
	"periodo"	TEXT,
	"categoria"	TEXT,
	"total_quejas"	INTEGER DEFAULT 0,
	"quejas_resueltas"	INTEGER DEFAULT 0,
	"tiempo_promedio_respuesta"	REAL,
	"costo_total_compensaciones"	REAL DEFAULT 0,
	"indice_satisfaccion"	REAL,
	"principales_problemas"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "usuarios" (
	"id"	INTEGER,
	"username"	TEXT NOT NULL UNIQUE,
	"password_hash"	TEXT NOT NULL,
	"email"	TEXT NOT NULL UNIQUE,
	"nombre_completo"	TEXT NOT NULL,
	"avatar"	TEXT DEFAULT 'default.png',
	"telefono"	TEXT,
	"departamento"	TEXT,
	"cargo"	TEXT,
	"fecha_contratacion"	DATE,
	"estado_empleado"	TEXT DEFAULT 'activo' CHECK("estado_empleado" IN ('activo', 'inactivo', 'suspendido', 'vacaciones')),
	"rol"	TEXT DEFAULT 'operador' CHECK("rol" IN ('admin', 'supervisor', 'operador', 'analista', 'legal', 'gerente')),
	"permisos"	TEXT,
	"tema_preferido"	TEXT DEFAULT 'claro',
	"idioma"	TEXT DEFAULT 'es',
	"zona_horaria"	TEXT DEFAULT 'America/Lima',
	"notificaciones_email"	BOOLEAN DEFAULT TRUE,
	"notificaciones_push"	BOOLEAN DEFAULT TRUE,
	"ultimo_login"	DATETIME,
	"intentos_fallidos"	INTEGER DEFAULT 0,
	"bloqueado_hasta"	DATETIME,
	"requiere_cambio_password"	BOOLEAN DEFAULT FALSE,
	"token_recuperacion"	TEXT,
	"token_expiracion"	DATETIME,
	"fecha_creacion"	DATETIME DEFAULT CURRENT_TIMESTAMP,
	"creado_por"	INTEGER,
	"fecha_modificacion"	DATETIME,
	"modificado_por"	INTEGER,
	"sesiones_activas"	INTEGER DEFAULT 0,
	"preferencias"	TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "historial_usuarios" (
	"id"	INTEGER,
	"usuario_id"	INTEGER NOT NULL,
	"fecha_hora"	DATETIME DEFAULT CURRENT_TIMESTAMP,
	"tipo_evento"	TEXT CHECK("tipo_evento" IN ('login', 'logout', 'cambio_password', 'actualizacion_perfil', 'creacion_queja', 'modificacion_queja', 'cierre_caso', 'acceso_denegado', 'error_sistema')),
	"descripcion"	TEXT NOT NULL,
	"ip_address"	TEXT,
	"user_agent"	TEXT,
	"detalles"	TEXT,
	FOREIGN KEY("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "sesiones_activas" (
	"id"	INTEGER,
	"usuario_id"	INTEGER NOT NULL,
	"session_token"	TEXT NOT NULL UNIQUE,
	"fecha_inicio"	DATETIME DEFAULT CURRENT_TIMESTAMP,
	"fecha_ultima_actividad"	DATETIME DEFAULT CURRENT_TIMESTAMP,
	"ip_address"	TEXT,
	"user_agent"	TEXT,
	"dispositivo"	TEXT,
	"expiracion"	DATETIME NOT NULL,
	"activa"	BOOLEAN DEFAULT TRUE,
	PRIMARY KEY("id" AUTOINCREMENT),
	FOREIGN KEY("usuario_id") REFERENCES "usuarios"("id") ON DELETE CASCADE
);
INSERT INTO "historial_quejas" ("id","queja_id","fecha","evento","descripcion","usuario") VALUES (1,1,'2026-01-31T11:21:57','queja_registrada','Queja registrada por sistema','sistema');
INSERT INTO "historial_quejas" ("id","queja_id","fecha","evento","descripcion","usuario") VALUES (2,2,'2026-02-01T17:28:28','queja_registrada','Queja registrada por sistema','sistema');
INSERT INTO "historial_quejas" ("id","queja_id","fecha","evento","descripcion","usuario") VALUES (3,3,'2026-02-01T21:12:47','queja_registrada','Queja registrada por sistema','sistema');
INSERT INTO "historial_quejas" ("id","queja_id","fecha","evento","descripcion","usuario") VALUES (4,3,'2026-02-01T21:12:47','notificacion_nueva_queja','Notificación enviada al equipo - Prioridad: baja','sistema');
INSERT INTO "quejas_reclamaciones" ("id","numero_caso","tipo_caso","canal_entrada","tipo_reclamante","identificacion","nombres","apellidos","telefono","email","direccion","asunto","descripcion_detallada","producto_servicio","numero_contrato","numero_factura","fecha_incidente","lugar_incidente","categoria","subcategoria","monto_reclamado","moneda","tipo_compensacion","prioridad","estado","nivel_escalamiento","recibido_por","asignado_a","equipo_responsable","fecha_recepcion","fecha_limite_respuesta","fecha_respuesta_cliente","fecha_cierre","hechos_constatados","pruebas_adjuntas","testigos","responsable_interno","decision","solucion_propuesta","compensacion_otorgada","descripcion_compensacion","satisfaccion_cliente","comentarios_finales","reincidente","requiere_legal","numero_expediente_legal","asesor_legal","creado_por","fecha_creacion","modificado_por","fecha_modificacion","tiempo_respuesta_horas","tags") VALUES (1,'','queja','presencial','cliente','','Cliente','','','',NULL,'Asunto de ejemplo','','',NULL,'','',NULL,'atencion_cliente',NULL,0.0,'USD','ninguna','baja','recibida',1,'sistema',NULL,NULL,'2026-01-31 16:21:57','2026-02-07',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.0,NULL,NULL,NULL,0,0,NULL,NULL,'sistema','2026-01-31 16:21:57',NULL,NULL,NULL,'[]');
INSERT INTO "quejas_reclamaciones" ("id","numero_caso","tipo_caso","canal_entrada","tipo_reclamante","identificacion","nombres","apellidos","telefono","email","direccion","asunto","descripcion_detallada","producto_servicio","numero_contrato","numero_factura","fecha_incidente","lugar_incidente","categoria","subcategoria","monto_reclamado","moneda","tipo_compensacion","prioridad","estado","nivel_escalamiento","recibido_por","asignado_a","equipo_responsable","fecha_recepcion","fecha_limite_respuesta","fecha_respuesta_cliente","fecha_cierre","hechos_constatados","pruebas_adjuntas","testigos","responsable_interno","decision","solucion_propuesta","compensacion_otorgada","descripcion_compensacion","satisfaccion_cliente","comentarios_finales","reincidente","requiere_legal","numero_expediente_legal","asesor_legal","creado_por","fecha_creacion","modificado_por","fecha_modificacion","tiempo_respuesta_horas","tags") VALUES (2,'Q-2026-001','queja','presencial','cliente','','Cliente','','','',NULL,'Asunto de ejemplo','','',NULL,'','',NULL,'atencion_cliente',NULL,0.0,'USD','ninguna','baja','recibida',1,'sistema',NULL,NULL,'2026-02-01 22:28:28','2026-02-08',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.0,NULL,NULL,NULL,0,0,NULL,NULL,'sistema','2026-02-01 22:28:28',NULL,NULL,NULL,'[]');
INSERT INTO "quejas_reclamaciones" ("id","numero_caso","tipo_caso","canal_entrada","tipo_reclamante","identificacion","nombres","apellidos","telefono","email","direccion","asunto","descripcion_detallada","producto_servicio","numero_contrato","numero_factura","fecha_incidente","lugar_incidente","categoria","subcategoria","monto_reclamado","moneda","tipo_compensacion","prioridad","estado","nivel_escalamiento","recibido_por","asignado_a","equipo_responsable","fecha_recepcion","fecha_limite_respuesta","fecha_respuesta_cliente","fecha_cierre","hechos_constatados","pruebas_adjuntas","testigos","responsable_interno","decision","solucion_propuesta","compensacion_otorgada","descripcion_compensacion","satisfaccion_cliente","comentarios_finales","reincidente","requiere_legal","numero_expediente_legal","asesor_legal","creado_por","fecha_creacion","modificado_por","fecha_modificacion","tiempo_respuesta_horas","tags") VALUES (3,'Q-2026-003','queja','presencial','cliente','','Cliente','','','',NULL,'Asunto de ejemplo','','',NULL,'','',NULL,'atencion_cliente',NULL,0.0,'USD','ninguna','baja','recibida',1,'sistema',NULL,NULL,'2026-02-02 02:12:47','2026-02-08',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0.0,NULL,NULL,NULL,0,0,NULL,NULL,'<null>','2026-02-02 02:12:47',NULL,NULL,NULL,'[]');
INSERT INTO "usuarios" ("id","username","password_hash","email","nombre_completo","avatar","telefono","departamento","cargo","fecha_contratacion","estado_empleado","rol","permisos","tema_preferido","idioma","zona_horaria","notificaciones_email","notificaciones_push","ultimo_login","intentos_fallidos","bloqueado_hasta","requiere_cambio_password","token_recuperacion","token_expiracion","fecha_creacion","creado_por","fecha_modificacion","modificado_por","sesiones_activas","preferencias") VALUES (1,'admin','admin123','admin@sistema.com','Administrador del Sistema','default.png',NULL,'TI','Administrador',NULL,'activo','admin','["todos_permisos"]','claro','es','America/Lima',1,1,'CURRENT_TIMESTAMP',0,NULL,0,NULL,NULL,'2026-01-31 06:58:43',NULL,NULL,NULL,0,NULL);
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (1,1,'2026-01-31 07:55:47','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (2,1,'2026-01-31 07:58:07','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (3,1,'2026-01-31 08:03:27','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (4,1,'2026-01-31 08:21:10','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (5,1,'2026-01-31 09:25:52','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (6,1,'2026-01-31 09:29:19','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (7,1,'2026-01-31 10:18:19','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (8,1,'2026-01-31 10:21:22','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (9,1,'2026-01-31 10:29:57','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (10,1,'2026-01-31 10:31:52','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (11,1,'2026-01-31 16:17:52','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (12,1,'2026-01-31 16:22:03','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (13,1,'2026-02-01 22:23:28','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (14,1,'2026-02-01 22:27:06','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (15,1,'2026-02-01 22:28:26','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (16,1,'2026-02-01 22:32:39','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (17,1,'2026-02-01 22:46:17','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (18,1,'2026-02-01 23:49:32','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
INSERT INTO "historial_usuarios" ("id","usuario_id","fecha_hora","tipo_evento","descripcion","ip_address","user_agent","detalles") VALUES (19,1,'2026-02-02 00:09:28','login','Inicio de sesión exitoso','127.0.0.1','Godot/4.5-stable (official) (Linux)','');
COMMIT;
