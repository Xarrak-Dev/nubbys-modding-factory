extends Node

var mods: Dictionary = {}
var mod_path = ""
var game_path = ""
var infoMod = {}

#some code i ripped from the godot tutorials page to unzip the mod file
func extract_all_from_zip(path):
	var reader = ZIPReader.new()
	reader.open(path)
	# Destination directory for the extracted files (this folder must exist before extraction).
	# Not all ZIP archives put everything in a single root folder,
	# which means several files/folders may be created in `root_dir` after extraction.
	var root_dir = DirAccess.open(global.mod_path)
	var files = reader.get_files()
	for file_path in files:
		# If the current entry is a directory.
		if file_path.ends_with("/"):
			root_dir.make_dir_recursive(file_path)
			continue
		# Write file contents, creating folders automatically when needed.
		# Not all ZIP archives are strictly ordered, so we need to do this in case
		# the file entry comes before the folder entry.
		root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
		var file = FileAccess.open(root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
		var buffer = reader.read_file(file_path)
		file.store_buffer(buffer)

#download a mod using the id from the mods.json
#TODO: add error checking because there is none
#TODO: check for mods already installed and stuff like that
func download_mod(mod):
	var file = get_json(global.mod_path + "/mods.json")
	var link = file["mods"][mod]["download"]
	var id = file["mods"][mod]["id"]
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	http.download_file = global.mod_path + "/" + id + ".zip"
	http.request(link)
	await http.request_completed
	print("example mod downloaded")
	global.extract_all_from_zip(global.mod_path + "/" + id + ".zip")
	DirAccess.remove_absolute(global.mod_path + "/" + id + ".zip")

#get a dictionary from a json file
func get_json(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text().find("\\'")
	if text != -1:
		text = file.get_as_text().erase(text)
	else:
		text = file.get_as_text()
	var data = JSON.parse_string(text)
	print(text)
	file.close()
	return data
