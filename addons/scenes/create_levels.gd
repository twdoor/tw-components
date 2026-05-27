@tool
extends EditorScript


func _run() -> void:
	var levels_dir := "res://levels/"
	var output_path := "res://levels.gd"

	var dir := DirAccess.open(levels_dir)
	if dir == null:
		printerr("Failed to open directory: ", levels_dir)
		return

	var entries: Array[Dictionary] = []

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tscn"):
			var full_path := levels_dir + file_name
			var uid := ResourceUID.id_to_text(ResourceLoader.get_resource_uid(full_path))
			var const_name := file_name.get_basename().to_snake_case().to_upper()
			entries.append({"name": const_name, "uid": uid})
		file_name = dir.get_next()
	dir.list_dir_end()

	entries.sort_custom(func(a, b): return a["name"] < b["name"])

	var output := "class_name Levels\n\n"
	for entry in entries:
		output += 'const %s := "%s"\n' % [entry["name"], entry["uid"]]

	# Write the file
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		printerr("Failed to write to: ", output_path)
		return

	file.store_string(output)
	file.close()

	print("Generated %s with %d level(s)." % [output_path, entries.size()])
