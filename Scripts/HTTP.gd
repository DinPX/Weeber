extends HTTPRequest

# Request url & api
export (int, 1, 100) var request_list_size := 20

const BASE_URL := "https://gelbooru.com/index.php"
var request_api := "?page=dapi&s=post&q=index"

# rating: safe, explicit, questionable, sensitive, or general
var request_options := "&limit="+str(request_list_size)+"&pid=0&json=1&rating:safe"
var user_key := ""

var request_url : String = BASE_URL+request_api+request_options+user_key

# Download queue
var download_list := []
var index := 0

onready var thumbnail : PackedScene = preload("res://Scenes/Thumbnail.tscn")

onready var tags_field := $"%Tags"
onready var grid_panel := $"%Grid"


func _ready() -> void:
	_items_request()


func _set_thumbnail_data(data: Dictionary) -> void:
	var new_thumbnail : VBoxContainer = thumbnail.instance(PackedScene.GEN_EDIT_STATE_DISABLED)

	new_thumbnail.set_data(data)
	new_thumbnail.set_image(ProjectSettings.globalize_path("user://"+get_file_name()))
	grid_panel.add_child(new_thumbnail, true)


func _parse_tags(txt: String) -> String:
	txt = "&tags=" + txt.replace(" ", "+")
	return txt


func _parse_JSON(body: PoolByteArray) -> Dictionary:
	var string_body_result : String = body.get_string_from_utf8()
	var json_parse_result : JSONParseResult = JSON.parse(string_body_result)
	var object : Dictionary = json_parse_result.get_result()
	return object


func _on_items_request_completed(_result, _response_code, _headers, body) -> void:
	cancel_request()

	disconnect("request_completed", self, "_on_items_request_completed")

	var object: Dictionary = _parse_JSON(body)

	#print(object)

	if object.has("post") and not object["post"].empty():
		for i in object["post"]:
			download_list.append(i)

	else:
		print("No results found.")

	if not download_list.empty(): _get_preview()


func _items_request() -> void:
	if not download_list.empty():
		cancel_request()
		download_list.clear()
		index = 0

	var signal_connection : int = connect("request_completed", self, "_on_items_request_completed")
	if signal_connection != OK: push_error("An error occurred in signal connection.")
	else: set_use_threads(true)

	if not tags_field.text.empty():
		request_url += _parse_tags(tags_field.text)

	var request_json_status : int = request(request_url, PoolStringArray(["text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"]), true, HTTPClient.METHOD_GET)

	if request_json_status != OK: push_error("An error occurred in the HTTP request.")


func get_file_name() -> String:
	var file_name := ""
	if download_list[index]["title"].empty():
		file_name = String(download_list[index]["id"])+"."+download_list[index]["preview_url"].get_extension()
	else:
		file_name = download_list[index]["title"]+"."+download_list[index]["preview_url"].get_extension()

	return file_name


func _get_preview() -> void:
	var signal_connection : int = connect("request_completed", self, "_on_get_preview_completed")
	if signal_connection != OK: push_error("An error occurred in signal connection.")
	else: set_use_threads(true)

	# "file_url" actual file | "preview_url" 160x250 thumbnail
	request(
		download_list[index]["preview_url"],
		PoolStringArray([
			"Accept: image/avif,image/webp,*/*",
			"Accept: video/webm,video/ogg,video/*;q=0.9,application/ogg;q=0.7,audio/*;q=0.6,*/*;q=0.5"
		]), true, HTTPClient.METHOD_GET)

	set_download_file("user://"+get_file_name())


func _on_get_preview_completed(_result, _response_code, _headers, _body) -> void:
	cancel_request()

	disconnect("request_completed", self, "_on_get_preview_completed")

	_set_thumbnail_data(download_list[index])

	index += 1

	if index < download_list.size():
		_get_preview()
	else:
		print("Download previews completed.")
		index = 0
		download_list.clear()


func _print_stuff(headers) -> void:
	# Content-Length key-value pair
	var content_length_result : String = headers[3]
	content_length_result.erase(0, 16)

	var file_size : int = int(content_length_result)
	var file_size_string : String = String.humanize_size(file_size)

	if OS.is_debug_build() == true:
		print(headers[3])
		print("Removed string: "+content_length_result)
		print("Integer: "+str(file_size))
		print(file_size_string)


func _on_Search_pressed() -> void:
	_items_request()
