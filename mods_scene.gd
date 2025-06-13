extends Node2D

const xMov = 250
const yMov = 150
const size = Vector2(1152, 648)
var modNode = preload("res://modButton.tscn")

func _ready() -> void:
	var x = 0
	var y = 0
	const maxX = round(size.x / xMov)
	print(global.mods)
	for mod in global.mods.values():
		var mB = modNode.instantiate()
		mB.mod = mod
		mB.position = Vector2(xMov * x + 50, yMov * y + 50)
		if x > maxX:
			y += 1
			x = 0
		else:
			x += 1
		add_child(mB)
