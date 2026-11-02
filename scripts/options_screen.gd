extends CanvasLayer

## Options menu, shared by the title screen and the game (F1). A CanvasLayer so
## it draws above the in-game button panel. Built in code like the rest of the
## UI; changes apply immediately and are written to the config.

signal closed

const AppScript := preload("res://scripts/app.gd")
const SettingsStore := preload("res://scripts/settings_store.gd")

var settings: SettingsStore

var _res_option: OptionButton
var _aspect_option: OptionButton
var _fullscreen: CheckButton
var _borderless: CheckButton
var _vsync: CheckButton
var _rank: CheckButton
var _applied_note: Label
var _note_left := 0.0
var _root: Control


func _ready() -> void:
	layer = 100
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var app := get_node_or_null("/root/App")
	if app != null:
		settings = app.settings
	else:
		settings = SettingsStore.new()
		settings.load_settings()

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.09, 0.97)
	sb.border_color = Color(0.35, 0.32, 0.18, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "OPTIONS"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1, 0.93, 0.45))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_section(vbox, "Graphics")

	_res_option = OptionButton.new()
	for size in AppScript.RESOLUTIONS:
		_res_option.add_item("%d x %d" % [size.x, size.y])
	_res_option.selected = _resolution_index()
	_res_option.item_selected.connect(_on_resolution)
	_row(vbox, "Resolution", _res_option)

	_aspect_option = OptionButton.new()
	var aspects: Array = AppScript.ASPECT_PRESETS.keys()
	for a in aspects:
		_aspect_option.add_item(a)
	_aspect_option.selected = maxi(0, aspects.find(settings.aspect))
	_aspect_option.item_selected.connect(_on_aspect)
	_row(vbox, "Aspect ratio", _aspect_option)

	_fullscreen = _check(vbox, "Fullscreen", settings.fullscreen, _on_fullscreen)
	_borderless = _check(vbox, "Borderless window", settings.borderless, _on_borderless)
	_vsync = _check(vbox, "V-Sync", settings.vsync, _on_vsync)

	var aspect_hint := Label.new()
	aspect_hint.text = "\"Fit image\" keeps the original behaviour: the window fits the picture\nand the camera letterboxes it. Fixed ratios letterbox the whole game instead."
	aspect_hint.add_theme_font_size_override("font_size", 11)
	aspect_hint.add_theme_color_override("font_color", Color(0.62, 0.66, 0.7))
	vbox.add_child(aspect_hint)

	_section(vbox, "Gameplay")
	_rank = _check(vbox, "Bigger farts are bigger (size follows the fart rank)", settings.rank_scaling, _on_rank)

	_applied_note = Label.new()
	_applied_note.text = "Changes are saved immediately."
	_applied_note.add_theme_font_size_override("font_size", 11)
	_applied_note.add_theme_color_override("font_color", Color(0.5, 0.75, 0.55))
	_applied_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_applied_note.modulate.a = 0.0
	vbox.add_child(_applied_note)

	var back := Button.new()
	back.text = "Back  [Esc]"
	back.custom_minimum_size = Vector2(0, 36)
	back.pressed.connect(close)
	vbox.add_child(back)


func _resolution_index() -> int:
	var best := 0
	for i in AppScript.RESOLUTIONS.size():
		if AppScript.RESOLUTIONS[i] == settings.resolution:
			return i
		if AppScript.RESOLUTIONS[i].x <= settings.resolution.x:
			best = i
	return best


func _section(parent: VBoxContainer, text: String) -> void:
	var row := HSeparator.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
	parent.add_child(label)


func _row(parent: VBoxContainer, text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(210, 0)
	label.add_theme_font_size_override("font_size", 14)
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	parent.add_child(row)


func _check(parent: VBoxContainer, text: String, value: bool, callback: Callable) -> CheckButton:
	var check := CheckButton.new()
	check.text = text
	check.button_pressed = value
	check.add_theme_font_size_override("font_size", 14)
	check.toggled.connect(callback)
	parent.add_child(check)
	return check


func _apply() -> void:
	var app := get_node_or_null("/root/App")
	if app != null:
		app.apply_display()
		app.save()
	else:
		settings.save_settings()
	_applied_note.modulate.a = 1.0
	_note_left = 1.2


func _on_resolution(index: int) -> void:
	settings.resolution = AppScript.RESOLUTIONS[index]
	_apply()


func _on_aspect(index: int) -> void:
	settings.aspect = _aspect_option.get_item_text(index)
	_apply()


func _on_fullscreen(on: bool) -> void:
	settings.fullscreen = on
	_fullscreen.button_pressed = on
	_apply()


func _on_borderless(on: bool) -> void:
	settings.borderless = on
	_apply()


func _on_vsync(on: bool) -> void:
	settings.vsync = on
	_apply()


func _on_rank(on: bool) -> void:
	settings.rank_scaling = on
	var game := get_tree().current_scene
	if game != null and game.get("gas") != null:
		game.gas.rank_scaling = on
		game._refresh_ui()
	_apply()


func open() -> void:
	visible = true
	_applied_note.modulate.a = 0.0


func close() -> void:
	closed.emit()
	queue_free()


func _process(delta: float) -> void:
	if _note_left > 0.0:
		_note_left -= delta
		if _note_left <= 0.0:
			_applied_note.modulate.a = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
