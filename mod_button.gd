extends Node2D

var mod

func _ready() -> void:
	updateMod(mod)

func updateMod(tmod) -> void:
	mod = tmod
	$nameLabel.text = str(mod["display_name"])
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_load_http_image)
	var error = http_request.request(mod["image"])

func _load_http_image(result, response_code, headers, body):
	var im = Image.new()
	var error = im.load_png_from_buffer(body)
	var texture = ImageTexture.create_from_image(im)
	$TextureRect.texture = texture


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		global.infoMod = mod
		get_tree().change_scene_to_file("res://modInfoScene.tscn")
