extends Node

## Application-level state shared by the title screen and the game: the settings
## file, the display / graphics setup and quitting. Registered as the `App`
## autoload in project.godot.

const SettingsStore := preload("res://scripts/settings_store.gd")

signal display_changed

## Window sizes offered in the options menu.
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1024, 768),
	Vector2i(1280, 720),
	Vector2i(1280, 800),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

## Design resolution used for each aspect. "Fit image" leaves the game in native
## pixels and lets the camera fit the picture, which is what the original did.
const ASPECT_PRESETS := {
	"Fit image": Vector2i.ZERO,
	"16:9": Vector2i(1600, 900),
	"16:10": Vector2i(1600, 1000),
	"4:3": Vector2i(1024, 768),
	"21:9": Vector2i(1680, 720),
}

var settings: SettingsStore


func _ready() -> void:
	settings = SettingsStore.new()
	settings.load_settings()
	apply_display()


func apply_display() -> void:
	# Headless runs (the test suite) have no window to resize.
	if DisplayServer.get_name() == "headless":
		display_changed.emit()
		return

	if settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, settings.borderless)
		var size: Vector2i = settings.resolution
		DisplayServer.window_set_size(size)
		var screen := DisplayServer.window_get_current_screen()
		var usable := DisplayServer.screen_get_usable_rect(screen)
		DisplayServer.window_set_position(usable.position + (usable.size - size) / 2)

	var win := get_window()
	var base: Vector2i = ASPECT_PRESETS.get(settings.aspect, Vector2i.ZERO)
	if base == Vector2i.ZERO:
		# Native pixels: main.gd's camera fits the image, like the original.
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	else:
		win.content_scale_size = base
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED
	)
	display_changed.emit()


func save() -> void:
	if settings != null:
		settings.save_settings()


func go_to_title() -> void:
	save()
	get_tree().change_scene_to_file("res://scenes/title.tscn")
