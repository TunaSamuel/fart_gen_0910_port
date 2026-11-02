extends Control

## Title screen: shows the first picture in the image folder as a dimmed
## backdrop, then Play / Options / Quit. Built in code like the rest of the UI.

const ImageLibrary := preload("res://scripts/image_library.gd")
const OptionsScreen := preload("res://scripts/options_screen.gd")
const SettingsStore := preload("res://scripts/settings_store.gd")

const GAME_SCENE := "res://scenes/main.tscn"

var _options: CanvasLayer
var _play_button: Button


func _ready() -> void:
	var app := get_node_or_null("/root/App")
	var settings: SettingsStore
	if app != null:
		settings = app.settings
	else:
		settings = SettingsStore.new()
		settings.load_settings()

	_build_backdrop(settings)
	_build_menu()


func _build_backdrop(settings: SettingsStore) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.07, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var library := ImageLibrary.new(settings.image_dir, settings.read_recursive)
	if library.count() > 0:
		var tex := ImageLibrary.load_texture(library.path_at(0))
		if tex != null:
			var pic := TextureRect.new()
			pic.texture = tex
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			pic.modulate = Color(0.55, 0.55, 0.55, 1.0)
			pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(pic)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _build_menu() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.custom_minimum_size = Vector2(340, 0)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "FART GENERATOR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1, 0.93, 0.45))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Load a picture. Pick the hole. Let it rip."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.88, 0.9))
	vbox.add_child(subtitle)

	vbox.add_child(HSeparator.new())

	_play_button = _menu_button(vbox, "Play  [Enter]", _play)
	_menu_button(vbox, "Options  [O]", _open_options)
	_menu_button(vbox, "Quit  [Esc]", _quit)

	var hint := Label.new()
	hint.text = "0-9: fart   Space: repeat   Shift: mode   Wheel: image   F1: options"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.64, 0.68))
	vbox.add_child(hint)

	_play_button.grab_focus()


func _menu_button(parent: VBoxContainer, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 40)
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _play() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _open_options() -> void:
	if _options != null and is_instance_valid(_options):
		_options.queue_free()
		_options = null
		return
	_options = OptionsScreen.new()
	_options.name = "Options"
	_options.closed.connect(func() -> void: _options = null)
	add_child(_options)


func _quit() -> void:
	var app := get_node_or_null("/root/App")
	if app != null:
		app.save()
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_play()
			KEY_O, KEY_F1:
				_open_options()
			KEY_ESCAPE:
				_quit()
			_:
				return
		get_viewport().set_input_as_handled()
