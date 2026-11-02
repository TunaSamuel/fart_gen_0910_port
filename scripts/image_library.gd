class_name ImageLibrary
extends RefCounted

## Scans the image folders and loads textures at runtime, mirroring
## load_image_names() / load_new_image() from the original.

var directory: String = ""
var recursive: bool = false
var files: Array[String] = []

static var _cache: Dictionary = {}


func _init(dir: String = "", read_recursive: bool = false) -> void:
	directory = dir if dir != "" else Content.path("img")
	recursive = read_recursive
	refresh()


func refresh() -> int:
	files = Content.list_files(directory, Content.IMAGE_EXT, recursive)
	return files.size()


func count() -> int:
	return files.size()


func path_at(index: int) -> String:
	if files.is_empty():
		return ""
	return files[posmod(index, files.size())]


static func display_name(path: String) -> String:
	return path.get_file()


## Loads an image from disk without requiring it to be imported by the editor.
static func load_image(path: String) -> Image:
	if path == "":
		return null
	# Decode the raw file bytes ourselves: this works for folders the user drops
	# images into at runtime, both in the editor and in an export that ships the
	# raw asset folders next to the executable.
	var bytes := FileAccess.get_file_as_bytes(path)
	if not bytes.is_empty():
		var img := Image.new()
		var err := ERR_FILE_UNRECOGNIZED
		match path.get_extension().to_lower():
			"png": err = img.load_png_from_buffer(bytes)
			"jpg", "jpeg": err = img.load_jpg_from_buffer(bytes)
			"bmp": err = img.load_bmp_from_buffer(bytes)
			"webp": err = img.load_webp_from_buffer(bytes)
		if err == OK:
			return img
	var from_file = Image.load_from_file(path)
	if from_file != null and not from_file.is_empty():
		return from_file
	var res = ResourceLoader.load(path)
	if res is Texture2D:
		return res.get_image()
	return null


static func load_texture(path: String) -> ImageTexture:
	if _cache.has(path):
		return _cache[path]
	var img := load_image(path)
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var tex := ImageTexture.create_from_image(img)
	_cache[path] = tex
	return tex


## Extra images in assets/background are shown *behind* the main image when
## foreground mode is active (the original's "[F8]" png overlay trick).
static func background_files() -> Array[String]:
	return Content.list_files(Content.path("background"), Content.IMAGE_EXT, false)
