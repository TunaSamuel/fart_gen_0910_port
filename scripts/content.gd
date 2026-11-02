class_name Content
extends RefCounted

## Resolves the folder where user content lives.
##
## The original game reads images, background overlays and sounds from folders
## next to the executable:
##
##   img/            main images         (jpg / png / bmp / jpeg)
##   background/     optional overlay image used in foreground mode
##   sound/small|medium|big|huge|sneaky|special/*.wav
##   sound/voice1..N/*.wav
##   sound/original1..5/*.wav
##
## This port keeps the same layout inside `assets/`. When exported, the game
## also accepts an `assets` folder placed next to the executable, so players can
## keep dropping files in without rebuilding.

const IMAGE_EXT := ["png", "jpg", "jpeg", "bmp"]

static var _root := ""
static var _exe_candidates: Array[String] = []


static func root() -> String:
	if _root != "":
		return _root
	var candidates: Array[String] = []
	var exe_dir := OS.get_executable_path().get_base_dir()
	candidates.append(exe_dir.path_join("assets"))
	candidates.append(exe_dir.path_join("..").path_join("assets"))
	candidates.append("res://assets")
	for c in candidates:
		if DirAccess.open(c) != null:
			_root = c
			return _root
	_root = "res://assets"
	return _root


static func path(relative: String) -> String:
	return root().path_join(relative)


static func dir_exists(path: String) -> bool:
	return DirAccess.open(path) != null


static func list_files(dir: String, extensions: Array, recursive: bool = false) -> Array[String]:
	var out: Array[String] = []
	_walk(dir, extensions, recursive, out, 0)
	out.sort()
	return out


static func _walk(dir: String, extensions: Array, recursive: bool, out: Array[String], depth: int) -> void:
	if depth > 8:
		return
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if name.begins_with("."):
			name = d.get_next()
			continue
		var full := dir.path_join(name)
		if d.current_is_dir():
			if recursive:
				_walk(full, extensions, recursive, out, depth + 1)
		else:
			var ext := name.get_extension().to_lower()
			if extensions.has(ext):
				out.append(full)
		name = d.get_next()
	d.list_dir_end()


static func list_dirs(dir: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if not name.begins_with(".") and d.current_is_dir():
			out.append(dir.path_join(name))
		name = d.get_next()
	d.list_dir_end()
	out.sort()
	return out


## Directory part of a path, in the same spirit as GameMaker's filename_path.
static func dirname(path: String) -> String:
	return path.get_base_dir()


static func basename(path: String) -> String:
	return path.get_file()
