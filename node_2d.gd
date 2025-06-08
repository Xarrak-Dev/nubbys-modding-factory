extends Node2D

var game_path = ""
var mod_path = ""
var mods = {}

#TODO: move this code to elsewhere so that it isnt trying to connect immediately,
#probably have it connect to a button or something
func _ready() -> void:
	#TODO: change the ip and port to the server ip and port
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 8080)
	multiplayer.multiplayer_peer = peer

#download mod button
#TODO: just change this system entirely man
func _on_button_2_pressed() -> void:
	get_mods.rpc_id(1)
	download_mod($TextEdit.text)

#get a dictionary from a json file
func get_json(path):
	var file = FileAccess.open(path, FileAccess.READ).get_as_text()
	var json = JSON.new()
	return JSON.parse_string(file)

#download a mod using the id from the mods.json
#TODO: add error checking because there is none
#TODO: check for mods already installed and stuff like that
func download_mod(mod):
	var file = get_json(mod_path + "/mods.json")
	var link = file["mods"][mod]["download"]
	var id = file["mods"][mod]["id"]
	var http : HTTPRequest = $HTTPRequest
	http.download_file = mod_path + "/" + id + ".zip"
	http.request(link)
	await $HTTPRequest.request_completed
	print("example mod downloaded")
	extract_all_from_zip(mod_path + "/" + id + ".zip")
	DirAccess.remove_absolute(mod_path + "/" + id + ".zip")

#downloads and installs nubby's forgery, deletes it after/ updates nubby's forgery
#TODO: install custom forgery versions
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

#some code i ripped from the godot tutorials page to unzip the mod file
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

#gets the list of mods from the server
@rpc("any_peer", "call_remote", "reliable")
func get_mods(data):
	var file = FileAccess.open(mod_path + "/mods.json", FileAccess.WRITE_READ)
	file.store_line(str(data))
	for dir in DirAccess.get_directories_at(mod_path):
		var modData = get_json(mod_path + "/" + dir + "/mod.json")
		mods[modData["mod_id"]] = modData
	print(mods)
	file.close()

#after the second file dialog prompt, it sets up the game path and installs/updates forgery
func _on_file_dialog_dir_selected(dir: String) -> void:
	print(dir)
	game_path = dir
	setupForgery()
	$Button2.visible = true
	$Button3.visible = false
	$TextEdit.visible = true

#when the local app data folder is selected, it sets up the directories
func _on_file_dialog_2_dir_selected(dir: String) -> void:
	print(dir)
	mod_path = dir + "/nubbys_forgery/mods"
	DirAccess.make_dir_recursive_absolute(mod_path + "/")
	get_mods.rpc_id(1)
	$Button3.visible = true
	$Button.visible = false

#second button visible, prompts to select game exe folder
func _on_button_pressed() -> void:
	$FileDialog2.visible = true

#first button shown, prompts to select localappdata directory
func _on_button_3_pressed() -> void:
	$FileDialog.visible = true

#intended for testing 
func _on_text_edit_text_changed() -> void:
	for mod in mods.values():
		if mod["mod_id"] == $TextEdit.text:
			$Label.text = str(mod)
