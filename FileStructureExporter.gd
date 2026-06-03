@tool
extends EditorScript

func _run() -> void:
	var output_path = "res://project_structure.txt"
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	
	if file == null:
		print("Failed to create file!")
		return
	
	file.store_line("Project Structure - " + Time.get_datetime_string_from_system())
	file.store_line("=====================================\n")
	
	_scan_directory("res://", file, 0)
	
	file.close()
	print("Project structure saved to: " + output_path)

func _scan_directory(path: String, file: FileAccess, indent_level: int) -> void:
	var dir = DirAccess.open(path)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		
		var full_path = path.path_join(file_name)
		var indent = "    ".repeat(indent_level)
		
		if dir.current_is_dir():
			file.store_line(indent + "📁 " + file_name + "/")
			_scan_directory(full_path, file, indent_level + 1)
		else:
			file.store_line(indent + "📄 " + file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
