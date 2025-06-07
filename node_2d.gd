extends Node2D

var game_path = ""
var mod_path = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 8080)
	multiplayer.multiplayer_peer = peer

func _on_button_2_pressed() -> void:
	get_mods.rpc_id(1)
	download_mod($TextEdit.text)

func get_json(path):
	var file = FileAccess.open(path, FileAccess.READ).get_as_text()
	var json = JSON.new()
	return JSON.parse_string(file)

func download_mod(mod):
	var file = get_json(mod_path + "/mods.json")
	var link = file["mods"][mod]["download"]
	var http : HTTPRequest = $HTTPRequest
	http.download_file = mod_path + "/" + file["mods"][mod]["id"] + ".zip"
	http.request(link)
	await $HTTPRequest.request_completed
	print("example mod downloaded")
	extract_all_from_zip(mod_path + "/" + file["mods"][mod]["id"] + ".zip")
	DirAccess.remove_absolute(mod_path + "/" + file["mods"][mod]["id"] + ".zip")

func setupForgery():
	var file = get_json(mod_path + "/mods.json")
	var httpp : HTTPRequest = $HTTPRequest3
	var http2 : HTTPRequest = $HTTPRequest2
	httpp.download_file = game_path + "/patch.xdelta"
	httpp.request(file["forgery-versions"]["0.1.3a"]["url"])
	await $HTTPRequest3.request_completed
	print("nubbys forgery downloaded")
	http2.download_file = game_path + "/xdelta.exe"
	http2.request("https://github.com/Moodkiller/xdelta3-gui-2.0/raw/refs/heads/master/Code/xdelta3%20GUI/xdelta3.exe")
	await $HTTPRequest2.request_completed
	if FileAccess.file_exists(game_path + "/clean_data.win"):
		DirAccess.copy_absolute(game_path + "/clean_data.win", game_path + "/temp_data.win")
		DirAccess.remove_absolute(game_path + "/data.win")
	else:
		DirAccess.copy_absolute(game_path + "/data.win", game_path + "/clean_data.win")
		DirAccess.rename_absolute(game_path + "/data.win", game_path + "/temp_data.win")
	OS.execute("CMD.exe", ["/C", "\"" + game_path + "/xdelta.exe\"" + " -d" + " -s" + " \"" + game_path + "/temp_data.win\"" + " \"" + game_path + "/patch.xdelta\"" + " \"" + game_path + "/data.win\""], [], false, true)
	print("xdelta patched")
	DirAccess.remove_absolute(game_path + "/xdelta.exe")
	print("xdelta3 removed")
	DirAccess.remove_absolute(game_path + "/patch.xdelta")
	print("nubby's forgery xdelta removed")
	DirAccess.remove_absolute(game_path + "/temp_data.win")
	print("temp data.win removed")

func extract_all_from_zip(path):
	var reader = ZIPReader.new()
	reader.open(path)

	# Destination directory for the extracted files (this folder must exist before extraction).
	# Not all ZIP archives put everything in a single root folder,
	# which means several files/folders may be created in `root_dir` after extraction.
	var root_dir = DirAccess.open(mod_path)

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

@rpc("any_peer", "call_remote", "reliable")
func get_mods(data):
	var file = FileAccess.open(mod_path + "/mods.json", FileAccess.WRITE_READ)
	file.store_line(str(data))
	file.close()


func _on_file_dialog_dir_selected(dir: String) -> void:
	print(dir)
	game_path = dir
	setupForgery()
	$Button2.visible = true
	$Button3.visible = false
	$TextEdit.visible = true


func _on_file_dialog_2_dir_selected(dir: String) -> void:
	print(dir)
	mod_path = dir + "/nubbys_forgery/mods"
	DirAccess.make_dir_recursive_absolute(mod_path + "/")
	get_mods.rpc_id(1)
	$Button3.visible = true
	$Button.visible = false


func _on_button_pressed() -> void:
	$FileDialog2.visible = true


func _on_button_3_pressed() -> void:
	$FileDialog.visible = true
