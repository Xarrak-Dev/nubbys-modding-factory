extends Node2D

var mods = {}
var dataFile
var dataa
var dataSaved

signal forgerySetup
signal gotMods

#TODO: move this code to elsewhere so that it isnt trying to connect immediately,
#probably have it connect to a button or something
func _ready() -> void:
	#TODO: change the ip and port to the server ip and port
	if !FileAccess.file_exists("user://data.json"):
		dataa = {}
		dataInFile()
	dataFile = FileAccess.open("user://data.json", FileAccess.READ)
	dataa = global.get_json("user://data.json")
	#TODO: make the connection to server error better
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 8080)
	multiplayer.multiplayer_peer = peer
	await multiplayer.connection_failed
	checkCompleted()

func failToConnect():
	$Label.visible = true
	$Label.text = "Failed to connect to server."

func checkCompleted():
	print("help")
	if dataa.get("game_dir") != null && dataa.get("mod_dir") != null && dataa.get("forgery_install") != null:
		global.mod_path = dataa["mod_dir"]
		global.game_path = dataa["game_dir"]
		get_mods.rpc_id(1)
		await gotMods
		dataFile.flush()
		get_tree().change_scene_to_file("res://modsScene.tscn")

#download mod button
#TODO: just change this system entirely man
func _on_button_2_pressed() -> void:
	get_mods.rpc_id(1)
	global.download_mod($TextEdit.text)

#downloads and installs/updates nubby's forgery, deletes unneeded files after
#TODO: install custom forgery versions
func setupForgery():
	var file = global.get_json(global.mod_path + "/mods.json")
	var httpp : HTTPRequest = $HTTPRequest3
	var http2 : HTTPRequest = $HTTPRequest2
	httpp.download_file = global.game_path + "/patch.xdelta"
	httpp.request(file["forgery-versions"]["0.1.3a"]["url"])
	await $HTTPRequest3.request_completed
	print("nubbys forgery downloaded")
	http2.download_file = global.game_path + "/xdelta.exe"
	http2.request("https://github.com/Moodkiller/xdelta3-gui-2.0/raw/refs/heads/master/Code/xdelta3%20GUI/xdelta3.exe")
	await $HTTPRequest2.request_completed
	if FileAccess.file_exists(global.game_path + "/clean_data.win"):
		DirAccess.copy_absolute(global.game_path + "/clean_data.win", global.game_path + "/temp_data.win")
		DirAccess.remove_absolute(global.game_path + "/data.win")
	else:
		DirAccess.copy_absolute(global.game_path + "/data.win", global.game_path + "/clean_data.win")
		DirAccess.rename_absolute(global.game_path + "/data.win", global.game_path + "/temp_data.win")
	OS.execute("CMD.exe", ["/C", "\"" + global.game_path + "/xdelta.exe\"" + " -d" + " -s" + " \"" + global.game_path + "/temp_data.win\"" + " \"" + global.game_path + "/patch.xdelta\"" + " \"" + global.game_path + "/data.win\""], [], false, true)
	print("xdelta patched")
	DirAccess.remove_absolute(global.game_path + "/xdelta.exe")
	print("xdelta3 removed")
	DirAccess.remove_absolute(global.game_path + "/patch.xdelta")
	print("nubby's forgery xdelta removed")
	DirAccess.remove_absolute(global.game_path + "/temp_data.win")
	print("temp data.win removed")
	dataInFile("forgery_install", "0.1.3a")
	while !dataSaved:
		pass
	dataSaved = false
	forgerySetup.emit()

#after the second file dialog prompt, it sets up the game path and installs/updates forgery
func _on_file_dialog_dir_selected(dir: String) -> void:
	global.game_path = dir
	dataInFile("game_dir", global.game_path)
	while !dataSaved:
		pass
	dataSaved = false
	setupForgery()
	#TODO: add loading anim here
	$Button3.visible = false
	await forgerySetup
	dataFile.flush()
	get_tree().change_scene_to_file("res://modsScene.tscn")

#when the local app data folder is selected, it sets up the directories
func _on_file_dialog_2_dir_selected(dir: String) -> void:
	global.mod_path = dir + "/nubbys_forgery/mods"
	DirAccess.make_dir_recursive_absolute(global.mod_path + "/")
	get_mods.rpc_id(1)
	await gotMods
	dataInFile("mod_dir", global.mod_path)
	while !dataSaved:
		pass
	dataSaved = false
	$Button3.visible = true
	$Button.visible = false

#gets the list of mods from the server
@rpc("any_peer", "call_remote", "reliable")
func get_mods(data):
	var file = FileAccess.open(global.mod_path + "/mods.json", FileAccess.WRITE_READ)
	file.store_line(str(data))
	for mod in data["mods"].values():
		var modData = mod["info"]
		global.mods[modData["mod_id"]] = modData
	file.close()
	gotMods.emit()

#second button visible, prompts to select game exe folder
func _on_button_pressed() -> void:
	$FileDialog2.visible = true

#first button shown, prompts to select localappdata directory
func _on_button_3_pressed() -> void:
	$FileDialog.visible = true

func dataInFile(key = "", value = ""):
	dataFile = FileAccess.open("user://data.json", FileAccess.WRITE)
	if key != "" && value != "":
		dataa[key] = value
	dataFile.store_string(str(dataa))
	dataFile.close()
	dataSaved = true

func array_to_string(arr: Array) -> String:
	var s = ""
	for i in arr:
		s += str(i)
	return s
