class_name SettingsStore
extends RefCounted

## Persistent settings, replacing the original FartGenerator.ini plus the
## FartGenerator.sav hole-position database. Both now live in one ConfigFile
## under user://.

# Explicit preload: works on a fresh checkout before Godot's editor has
# generated its global class cache.
const Content := preload("res://scripts/content.gd")

const CONFIG_PATH := "user://fart_generator.cfg"

var image_dir: String = ""
var read_recursive: bool = false
var show_osd: bool = true
var slideshow_interval: float = 5.0
var synchro_mode: bool = false
var fart_sound_pitch: bool = true
var voice_pitch: bool = false
var shake: float = 0.0
var shake_speed: float = 1.0
var shake_synchro: bool = true
var foreground_mode: bool = false
var voice_max: int = 5
## Big farts (Huge/Big groups) get bigger particles, wider spread and harder
## shake than small ones.
var rank_scaling: bool = true

var auto_change_image: bool = false
var selection_rule: String = "Random"  # Random | AllRandom | Single
var emit_interval_min: float = 1.0
var emit_interval_max: float = 3.0
var emit_time_min: float = 1.0
var emit_time_max: float = 2.0
var fart_until_changing_img: int = 3

# Graphics (applied by the App autoload; see scripts/app.gd).
var resolution := Vector2i(1280, 720)
var aspect := "Fit image"
var fullscreen := false
var borderless := false
var vsync := true

var _holes: Dictionary = {}
var _cfg := ConfigFile.new()


func load_settings() -> void:
	_cfg.load(CONFIG_PATH)
	image_dir = _cfg.get_value("general", "image_dir", Content.path("img"))
	if image_dir == "" or not Content.dir_exists(image_dir):
		image_dir = Content.path("img")
	read_recursive = bool(_cfg.get_value("general", "read_recursive", false))
	show_osd = bool(_cfg.get_value("general", "show_osd", true))
	slideshow_interval = float(_cfg.get_value("general", "slideshow_interval", 5.0))
	synchro_mode = bool(_cfg.get_value("general", "synchro_mode", false))
	fart_sound_pitch = bool(_cfg.get_value("general", "fart_sound_pitch", true))
	voice_pitch = bool(_cfg.get_value("general", "voice_pitch", false))
	shake = float(_cfg.get_value("general", "shake", 0.0))
	shake_speed = float(_cfg.get_value("general", "shake_speed", 1.0))
	shake_synchro = bool(_cfg.get_value("general", "shake_synchro", true))
	foreground_mode = bool(_cfg.get_value("general", "foreground_mode", false))
	voice_max = int(_cfg.get_value("general", "voice_max", 5))
	rank_scaling = bool(_cfg.get_value("general", "rank_scaling", true))

	resolution = Vector2i(_cfg.get_value("graphics", "width", 1280), _cfg.get_value("graphics", "height", 720))
	aspect = String(_cfg.get_value("graphics", "aspect", "Fit image"))
	fullscreen = bool(_cfg.get_value("graphics", "fullscreen", false))
	borderless = bool(_cfg.get_value("graphics", "borderless", false))
	vsync = bool(_cfg.get_value("graphics", "vsync", true))

	auto_change_image = bool(_cfg.get_value("autofire", "auto_change_image", false))
	selection_rule = String(_cfg.get_value("autofire", "selection_rule", "Random"))
	emit_interval_min = float(_cfg.get_value("autofire", "interval_min", 1.0))
	emit_interval_max = float(_cfg.get_value("autofire", "interval_max", 3.0))
	emit_time_min = float(_cfg.get_value("autofire", "emit_time_min", 1.0))
	emit_time_max = float(_cfg.get_value("autofire", "emit_time_max", 2.0))
	fart_until_changing_img = int(_cfg.get_value("autofire", "count_to_change_image", 3))

	_holes.clear()
	if _cfg.has_section("holes"):
		for key in _cfg.get_section_keys("holes"):
			var value = _cfg.get_value("holes", key)
			if value is Dictionary:
				_holes[key] = value


func save_settings() -> void:
	_cfg.set_value("general", "image_dir", image_dir)
	_cfg.set_value("general", "read_recursive", read_recursive)
	_cfg.set_value("general", "show_osd", show_osd)
	_cfg.set_value("general", "slideshow_interval", slideshow_interval)
	_cfg.set_value("general", "synchro_mode", synchro_mode)
	_cfg.set_value("general", "fart_sound_pitch", fart_sound_pitch)
	_cfg.set_value("general", "voice_pitch", voice_pitch)
	_cfg.set_value("general", "shake", shake)
	_cfg.set_value("general", "shake_speed", shake_speed)
	_cfg.set_value("general", "shake_synchro", shake_synchro)
	_cfg.set_value("general", "foreground_mode", foreground_mode)
	_cfg.set_value("general", "voice_max", voice_max)
	_cfg.set_value("general", "rank_scaling", rank_scaling)

	_cfg.set_value("graphics", "width", resolution.x)
	_cfg.set_value("graphics", "height", resolution.y)
	_cfg.set_value("graphics", "aspect", aspect)
	_cfg.set_value("graphics", "fullscreen", fullscreen)
	_cfg.set_value("graphics", "borderless", borderless)
	_cfg.set_value("graphics", "vsync", vsync)

	_cfg.set_value("autofire", "auto_change_image", auto_change_image)
	_cfg.set_value("autofire", "selection_rule", selection_rule)
	_cfg.set_value("autofire", "interval_min", emit_interval_min)
	_cfg.set_value("autofire", "interval_max", emit_interval_max)
	_cfg.set_value("autofire", "emit_time_min", emit_time_min)
	_cfg.set_value("autofire", "emit_time_max", emit_time_max)
	_cfg.set_value("autofire", "count_to_change_image", fart_until_changing_img)

	if not _cfg.has_section("holes"):
		_cfg.set_value("holes", "_placeholder", {})
		_cfg.erase_section_key("holes", "_placeholder")
	for key in _holes:
		_cfg.set_value("holes", key, _holes[key])
	if _cfg.has_section("holes"):
		for key in _cfg.get_section_keys("holes"):
			if not _holes.has(key):
				_cfg.erase_section_key("holes", key)
	_cfg.save(CONFIG_PATH)


## Returns {"pos": Vector2, "extra": Array[Vector2]} for an image file name.
func hole_for(file_name: String) -> Dictionary:
	var entry = _holes.get(file_name, null)
	if entry == null:
		return {"pos": Vector2.ZERO, "extra": []}
	var extra: Array = []
	for v in entry.get("extra", []):
		if v is Vector2:
			extra.append(v)
	return {"pos": Vector2(entry.get("x", 0.0), entry.get("y", 0.0)), "extra": extra}


func has_hole(file_name: String) -> bool:
	return _holes.has(file_name)


func set_hole(file_name: String, pos: Vector2, extra: Array) -> void:
	var packed: Array = []
	for v in extra:
		if v is Vector2 and v != Vector2.ZERO:
			packed.append(v)
	_holes[file_name] = {"x": pos.x, "y": pos.y, "extra": packed}


func save_now() -> void:
	save_settings()
