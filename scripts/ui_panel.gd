class_name UiPanel
extends CanvasLayer

## The button strip from the original (which used a second viewport at negative
## coordinates) rebuilt as a normal overlay panel.

signal color_changed(col1: Color, col2: Color)

# Explicit preload: keeps the script parseable on a fresh checkout before
# Godot's editor has built its global class cache.
const FartButton := preload("res://scripts/fart_button.gd")

const DEFAULT_COLOR_1 := Color8(220, 188, 48)
const DEFAULT_COLOR_2 := Color8(225, 228, 155)

var panel: PanelContainer
var buttons: Dictionary = {}
var status_label: Label
var image_label: Label
var pick1: ColorPickerButton
var pick2: ColorPickerButton

var _vbox: VBoxContainer
var _status_left := 0.0


func _ready() -> void:
	layer = 10
	panel = PanelContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(10, 10)
	panel.custom_minimum_size = Vector2(248, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.06, 0.72)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 3)
	panel.add_child(_vbox)

	var title := Label.new()
	title.text = "FART GENERATOR"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1, 0.93, 0.45))
	_vbox.add_child(title)

	image_label = Label.new()
	image_label.text = "No image"
	image_label.add_theme_font_size_override("font_size", 11)
	image_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
	image_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	image_label.custom_minimum_size = Vector2(230, 0)
	_vbox.add_child(image_label)
	_vbox.add_child(HSeparator.new())

	_add_button("set_hole", "Set Hole [S]")
	_add_button("slideshow", "Slideshow [C]")
	_add_button("auto_fire", "Auto Fire [A]")
	_add_button("hide", "Hide Buttons [H]")
	_add_button("fart_id", "Fart ID: 1-1")
	_add_button("se", "SE: Small")
	_add_button("voice", "Voice: Off")
	_add_button("size", "Size  x2.00")
	_add_button("num", "Num   x2.00")
	_add_button("speed", "Speed x2.00")
	_add_button("amnt", "Amnt  x1.00")
	_add_button("shake", "Shake: Off")
	_add_button("synchro", "Synchro: Off")
	_add_button("foreground", "Foreground: Off")
	_add_button("folder", "Image Folder...")
	_add_button("color", "Color")

	var color_row := HBoxContainer.new()
	color_row.add_theme_constant_override("separation", 4)
	var color_label := Label.new()
	color_label.text = "Color"
	color_label.add_theme_font_size_override("font_size", 12)
	color_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.9))
	color_label.custom_minimum_size = Vector2(52, 0)
	color_row.add_child(color_label)
	pick1 = ColorPickerButton.new()
	pick1.color = DEFAULT_COLOR_1
	pick1.custom_minimum_size = Vector2(0, 24)
	pick1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_row.add_child(pick1)
	pick2 = ColorPickerButton.new()
	pick2.color = DEFAULT_COLOR_2
	pick2.custom_minimum_size = Vector2(0, 24)
	pick2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_row.add_child(pick2)
	_vbox.add_child(color_row)
	pick1.color_changed.connect(_on_color_changed)
	pick2.color_changed.connect(_on_color_changed)

	var clear := _add_button("clear", "Clear Fart [Del]")
	clear.add_theme_color_override("font_color", Color(0.55, 0.15, 0.15))

	var hint := Label.new()
	hint.text = "0-9: fart  |  Space/Click: repeat  |  Shift: mode\nWheel: image  Ctrl+Wheel: zoom  Middle-drag: pan\nB: blend  R: reverse  W: shake  K: rank size\nF8: foreground  F2: folder  F1: options  Esc: title"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(230, 0)
	_vbox.add_child(hint)

	status_label = Label.new()
	status_label.name = "Status"
	status_label.anchor_left = 1.0
	status_label.anchor_right = 1.0
	status_label.offset_left = -420
	status_label.offset_right = -18
	status_label.offset_top = 16
	status_label.offset_bottom = 46
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	status_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.5))
	status_label.add_theme_constant_override("shadow_offset_x", 1)
	status_label.add_theme_constant_override("shadow_offset_y", 1)
	status_label.modulate.a = 0.0
	add_child(status_label)
	set_process(true)


func _add_button(key: String, text: String) -> FartButton:
	var b := FartButton.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_child(b)
	buttons[key] = b
	return b


func _on_color_changed(_c: Color) -> void:
	color_changed.emit(pick1.color, pick2.color)


func button(key: String) -> FartButton:
	return buttons.get(key, null)


func set_button_text(key: String, text: String) -> void:
	var b: FartButton = buttons.get(key, null)
	if b != null:
		b.text = text


func set_button_active(key: String, on: bool) -> void:
	var b: FartButton = buttons.get(key, null)
	if b != null:
		b.set_active(on)


func set_image_text(text: String) -> void:
	image_label.text = text


func show_status(text: String, seconds: float = 1.6) -> void:
	status_label.text = text
	status_label.modulate.a = 1.0
	_status_left = seconds


func _process(delta: float) -> void:
	if _status_left > 0.0:
		_status_left -= delta
		if _status_left <= 0.0:
			status_label.modulate.a = 0.0
		elif _status_left < 0.5:
			status_label.modulate.a = _status_left / 0.5


func set_visible_buttons(visible_buttons: bool) -> void:
	panel.visible = visible_buttons


func mouse_over_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	var node: Node = hovered
	while node != null:
		if node == panel:
			return true
		node = node.get_parent()
	return false
