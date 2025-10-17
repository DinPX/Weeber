class_name Thumbnail
extends VBoxContainer

var data := {} setget set_data, get_data


func set_data(new_data: Dictionary) -> void:
	data = new_data


func get_data() -> Dictionary:
	return data


func set_image(file_path: String) -> void:
	var file = File.new()
	file.open(file_path, File.READ)

	var image = Image.new()
	var error = image.load(file_path)
	if error != OK: print("Image file failed to load.")
	else: file.close()

	var texture = ImageTexture.new()
	texture.create_from_image(image, 7)

	$Image.texture_normal = texture
