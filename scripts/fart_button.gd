class_name FartButton
extends Button

## The original's window-sprite button: left click activates, right click
## decrements, middle click opens a value prompt and the wheel nudges.

signal right_pressed
signal middle_pressed
signal wheeled(direction: int)

var _sb_white: StyleBox
var _sb_red: StyleBox
var _sb_blue: StyleBox
var _active := false


func _ready() -> void:
	custom_minimum_size = Vector2(0, 30)
	focus_mode = Control.FOCUS_NONE
	clip_text = true
	add_theme_font_size_override("font_size", 13)
	add_theme_color_override("font_color", Color(0.08, 0.08, 0.1))
	add_theme_color_override("font_hover_color", Color(0.05, 0.05, 0.05))
	add_theme_color_override("font_pressed_color", Color(0.05, 0.05, 0.05))
	add_theme_constant_override("outline_size", 0)

	_sb_white = _make_style("res://assets/ui/window_white.png", Color(0.95, 0.95, 0.96))
	_sb_red = _make_style("res://assets/ui/window_red.png", Color(0.98, 0.72, 0.72))
	_sb_blue = _make_style("res://assets/ui/window_blue.png", Color(0.78, 0.85, 0.98))
	add_theme_stylebox_override("normal", _sb_white)
	add_theme_stylebox_override("hover", _sb_blue)
	add_theme_stylebox_override("pressed", _sb_blue)
	add_theme_stylebox_override("disabled", _sb_white)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _make_style(path: String, tint: Color) -> StyleBox:
	var tex := load(path) as Texture2D
	if tex != null:
		var sb := StyleBoxTexture.new()
		sb.texture = tex
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		return sb
	# Fallback when the original window sprites are unavailable.
	var flat := StyleBoxFlat.new()
	flat.bg_color = tint
	flat.set_corner_radius_all(6)
	flat.set_content_margin_all(4)
	return flat


func set_active(on: bool) -> void:
	if _active == on:
		return
	_active = on
	add_theme_stylebox_override("normal", _sb_red if on else _sb_white)
	add_theme_color_override("font_color", Color(0.35, 0.0, 0.0) if on else Color(0.08, 0.08, 0.1))


func is_active() -> bool:
	return _active


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_RIGHT:
				right_pressed.emit()
				accept_event()
			elif mb.button_index == MOUSE_BUTTON_MIDDLE:
				middle_pressed.emit()
				accept_event()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				wheeled.emit(1)
				accept_event()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				wheeled.emit(-1)
				accept_event()
