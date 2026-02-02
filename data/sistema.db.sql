BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "usuarios" (
	"id"	INTEGER,
	"username"	TEXT NOT NULL UNIQUE,
	"email"	TEXT NOT NULL UNIQUE,
	"password_hash"	TEXT NOT NULL,
	"nombre_completo"	TEXT NOT NULL,
	"rol"	TEXT DEFAULT 'operador',
	"cargo"	TEXT,
	"departamento"	TEXT,
	"estado_empleado"	TEXT DEFAULT 'activo',
	"ultimo_login"	TEXT,
	"intentos_fallidos"	INTEGER DEFAULT 0,
	"bloqueado_hasta"	TEXT,
	"token_recuperacion"	TEXT,
	"token_expiracion"	TEXT,
	"created_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
	"updated_at"	TEXT DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY("id" AUTOINCREMENT)
);
COMMIT;
