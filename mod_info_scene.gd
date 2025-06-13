extends Node2D

var mod

func _ready() -> void:
	updateMod(global.infoMod)

func updateMod(tmod) -> void:
	mod = tmod
	$"name label".text = str(mod["display_name"])
	$"description label".text = str(mod["description"])
	var authorString = "By "
	var i = 0
	for author in mod["credits"]:
		authorString += author
		if i != mod["credits"].size() - 1:
			authorString += ", "
		i += 1
	$"authors label".text = authorString
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_load_http_image)
	var error = http_request.request(mod["image"])

func _load_http_image(result, response_code, headers, body):
	var im = Image.new()
	var error = im.load_png_from_buffer(body)
	var texture = ImageTexture.create_from_image(im)
	$TextureRect.texture = texture

#TODO: make it await a signal for the download_mod to be completed so you can't back out before its done
func _on_button_pressed() -> void:
	global.download_mod(mod["mod_id"])


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://modsScene.tscn")
