extends Node

var db = SQLite.new()

func _ready():
	var table_name: String = "players"
	var table_dict: Dictionary = {
		"id": {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true},
		"name": {"data_type":"text", "not_null": true},
		"portrait": {"data_type":"blob", "not_null": true}
	}

	db.path = "res://my_database"
	db.verbosity_level = SQLite.VerbosityLevel.NORMAL
	db.open_db()

	# Check if the table already exists or not.
	db.query_with_bindings("SELECT name FROM sqlite_master WHERE type='table' AND name=?;", [table_name])
	if not db.query_result.is_empty():
		db.drop_table(table_name)
	db.create_table(table_name, table_dict)

  
   
	var row_dict: Dictionary = {
		"name": "Doomguy",
	   
	}
	db.insert_row(table_name, row_dict)

	db.select_rows(table_name, "name = 'Doomguy'", ["id", "name"])
	print(db.query_result)
