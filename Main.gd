extends Node

const DIR_ERR = 'ERROR: Failed to create directory "%s". Error code %s.'

# '~/.local/share/Weeber' to store temporary files
var temp_path := OS.get_user_data_dir()

# '~/Documents/Weeber' for downloaded files
var export_path := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)+"/Weeber"


func _ready() -> void:
	_init_directory(Directory.new(), temp_path)
	_init_directory(Directory.new(), export_path)


func _init_directory(directory, path) -> bool:
	var exists := false
	if not directory.dir_exists(path):
		var error_code = directory.make_dir_recursive(path)
		exists = true
		if error_code != OK:
			printerr(DIR_ERR % [path, error_code])
			exists = false
	else:
		exists = true
	return exists
