extends Node2D

## Fart Generator - main controller.
##
## Handles image browsing, hole placement, the camera (the original's variable
## size view), auto fire / slideshow, sound selection and the UI wiring.

# Preloaded explicitly so a fresh checkout runs before Godot's editor has
# generated its global class cache (.godot/global_script_class_cache.cfg).
const GasGenerator := preload("res://scripts/gas_generator.gd")
const ImageLibrary := preload("res://scripts/image_library.gd")
const SettingsStore := preload("res://scripts/settings_store.gd")
const SoundBank := preload("res://scripts/sound_bank.gd")
const UiPanel := preload("res://scripts/ui_panel.gd")

const IMAGE_SCALE_MIN := 0.8
const IMAGE_SCALE_MAX := 4.0
const EXTRA_HIP_HOLE_MAX := 9
const GAS_PATTERN_MAX := 10
const EMIT_MODE_MAX := 5
const TIME_MIN := 0.01
const TIME_MAX := 600.0
const SCALE_MIN := 0.1
const SCALE_MAX := 20.0

const SOUND_MAP := [
	["Small", "Small", "Medium", "Medium", "Medium", "Big", "Huge", "Sneaky", "Sneaky", "Sneaky"],
	["Medium", "Big", "Small", "Huge", "Huge", "Medium", "Huge", "Sneaky", "Sneaky", "Big"],
	["Sneaky", "Huge", "Medium", "Big", "Huge", "Medium", "Big", "Sneaky", "Huge", "Sneaky"],
	["Medium", "Sneaky", "Sneaky", "Sneaky", "Sneaky", "Sneaky", "Sneaky", "Sneaky", "Huge", "Huge"],
	["Special", "Special", "Sneaky", "Sneaky", "Sneaky", "Huge", "Sneaky", "Huge", "Sneaky", "Sneaky"],
]

var settings: SettingsStore
var library: ImageLibrary
var sound: SoundBank
var ui: UiPanel
var gas: GasGenerator

var world: Node2D
var bg_sprite: Sprite2D
var overlay_sprite: Sprite2D
var camera: Camera2D

var texture: Texture2D
var image_size := Vector2(1024, 768)
var marker_tex: Texture2D

var cur_index := 0
var img_scale := 1.0
var super_zoom := 0
var pan := Vector2.ZERO

var hole := Vector2.ZERO
var extra_holes: Array[Vector2] = []
var now_setting := false

var slideshow_timer := -1.0
var shake_mode := 0
var shake_timer := 0.0
var shake_phase := 0.0

var prev_fart_player: AudioStreamPlayer = null

var auto_emit := false
var auto_emitting := false
var auto_timer := -1.0
var auto_pending_change := false
var fart_count := 3
var selection_rule := "Random"

var current_voice := 0
var blend_on := false
var foreground := false

var sound_map: Array = []
var palette1 := UiPanel.DEFAULT_COLOR_1
var palette2 := UiPanel.DEFAULT_COLOR_2

var _overlay_files: Array[String] = []
var _overlay_index := 0
var _dragging := false
var _drag_from := Vector2.ZERO
var _prompt: AcceptDialog
var _prompt_edit: LineEdit
var _prompt_cb: Callable
var _file_dialog: FileDialog
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	settings = SettingsStore.new()
	settings.load_settings()

	for i in EMIT_MODE_MAX:
		sound_map.append((SOUND_MAP[i] as Array).duplicate())
	fart_count = settings.fart_until_changing_img
	selection_rule = settings.selection_rule
	shake_mode = 0
	foreground = settings.foreground_mode

	world = Node2D.new()
	world.name = "World"
	add_child(world)

	# The overlay (assets/background) sits behind the main image: in foreground
	# mode the main PNG is transparent and this plate shows through.
	overlay_sprite = Sprite2D.new()
	overlay_sprite.name = "OverlayImage"
	overlay_sprite.centered = false
	overlay_sprite.visible = false
	world.add_child(overlay_sprite)

	bg_sprite = Sprite2D.new()
	bg_sprite.name = "BackgroundImage"
	bg_sprite.centered = false
	world.add_child(bg_sprite)

	gas = GasGenerator.new()
	gas.name = "GasGenerator"
	world.add_child(gas)

	camera = Camera2D.new()
	camera.name = "Camera"
	add_child(camera)
	camera.enabled = true
	camera.make_current()

	sound = SoundBank.new()
	sound.name = "SoundBank"
	add_child(sound)
	sound.load_content(settings.voice_max)

	ui = UiPanel.new()
	ui.name = "UI"
	add_child(ui)
	_connect_ui()

	marker_tex = _load_optional_texture("res://assets/ui/marker.png")

	library = ImageLibrary.new(settings.image_dir, settings.read_recursive)
	gas.fart_started.connect(_on_fart_started)
	gas.pattern_changed.connect(_refresh_ui)

	get_viewport().size_changed.connect(_update_camera)
	_update_palette_ui()
	_refresh_ui()

	if library.count() == 0:
		_make_placeholder()
		ui.show_status("No images in " + settings.image_dir, 6.0)
	else:
		load_image(0)

	if sound.total_sounds() == 0:
		ui.show_status("No WAV files found - using synth fallback", 5.0)

	_update_camera()


func _make_placeholder() -> void:
	var img := Image.create(1024, 768, false, Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			var v := 0.10 + 0.05 * (float(x) / w) + 0.03 * (float(y) / h)
			img.set_pixel(x, y, Color(v, v + 0.015, v + 0.03))
	texture = ImageTexture.create_from_image(img)
	image_size = Vector2(w, h)
	bg_sprite.texture = texture
	ui.set_image_text("No images found.\nDrop jpg/png/bmp files in:\n" + settings.image_dir)


func _load_optional_texture(path: String) -> Texture2D:
	# Decoded from the raw PNG at runtime, so the UI sprites work even when the
	# project has not been opened in the editor (no imported .ctex yet).
	return ImageLibrary.load_texture(path)


func _connect_ui() -> void:
	ui.button("set_hole").pressed.connect(_toggle_set_hole)
	ui.button("set_hole").right_pressed.connect(_show_hole_markers)
	ui.button("set_hole").middle_pressed.connect(_prompt_shake_power)

	ui.button("slideshow").pressed.connect(_toggle_slideshow)
	ui.button("slideshow").middle_pressed.connect(_prompt_slideshow_interval)

	ui.button("auto_fire").pressed.connect(_toggle_auto_fire)
	ui.button("auto_fire").right_pressed.connect(_toggle_auto_change_image)
	ui.button("auto_fire").middle_pressed.connect(_prompt_fart_interval)

	ui.button("hide").pressed.connect(_toggle_buttons)
	ui.button("fart_id").pressed.connect(func() -> void: _step_pattern(1))
	ui.button("fart_id").right_pressed.connect(func() -> void: _step_pattern(-1))
	ui.button("fart_id").middle_pressed.connect(_cycle_selection_rule)

	ui.button("se").pressed.connect(func() -> void: _cycle_sound(1))
	ui.button("se").right_pressed.connect(func() -> void: _cycle_sound(-1))
	ui.button("se").middle_pressed.connect(_toggle_fart_pitch)

	ui.button("voice").pressed.connect(func() -> void: _cycle_voice(1))
	ui.button("voice").right_pressed.connect(func() -> void: _cycle_voice(-1))
	ui.button("voice").middle_pressed.connect(_toggle_voice_pitch)

	ui.button("size").pressed.connect(func() -> void: _nudge("size", 0.1))
	ui.button("size").right_pressed.connect(func() -> void: _nudge("size", -0.1))
	ui.button("size").wheeled.connect(func(d: int) -> void: _nudge("size", 0.05 * d))
	ui.button("size").middle_pressed.connect(func() -> void: _prompt_scale("size"))

	ui.button("num").pressed.connect(func() -> void: _nudge("num", 0.1))
	ui.button("num").right_pressed.connect(func() -> void: _nudge("num", -0.1))
	ui.button("num").wheeled.connect(func(d: int) -> void: _nudge("num", 0.05 * d))
	ui.button("num").middle_pressed.connect(func() -> void: _prompt_scale("num"))

	ui.button("speed").pressed.connect(func() -> void: _nudge("speed", 0.1))
	ui.button("speed").right_pressed.connect(func() -> void: _nudge("speed", -0.1))
	ui.button("speed").wheeled.connect(func(d: int) -> void: _nudge("speed", 0.05 * d))
	ui.button("speed").middle_pressed.connect(func() -> void: _prompt_scale("speed"))

	ui.button("amnt").pressed.connect(func() -> void: _nudge("amnt", 0.1))
	ui.button("amnt").right_pressed.connect(func() -> void: _nudge("amnt", -0.1))
	ui.button("amnt").wheeled.connect(func(d: int) -> void: _nudge("amnt", 0.05 * d))
	ui.button("amnt").middle_pressed.connect(func() -> void: _prompt_scale("amnt"))

	ui.button("shake").pressed.connect(func() -> void: _cycle_shake(1))
	ui.button("shake").right_pressed.connect(func() -> void: _cycle_shake(-1))

	ui.button("color").pressed.connect(_randomize_colors)
	ui.button("color").right_pressed.connect(_reset_colors)

	ui.button("synchro").pressed.connect(_toggle_synchro)
	ui.button("foreground").pressed.connect(_toggle_foreground)
	ui.button("folder").pressed.connect(_open_folder_dialog)
	ui.button("clear").pressed.connect(_clear_fart)

	ui.color_changed.connect(_on_color_changed)


# ---------------------------------------------------------------------------
# Images
# ---------------------------------------------------------------------------

func load_image(index: int) -> void:
	if library.count() == 0:
		return
	cur_index = posmod(index, library.count())
	var path := library.path_at(cur_index)
	var tex := ImageLibrary.load_texture(path)
	if tex == null:
		ui.show_status("Cannot load " + path.get_file(), 4.0)
		return
	texture = tex
	image_size = Vector2(tex.get_width(), tex.get_height())
	bg_sprite.texture = tex
	pan = Vector2.ZERO
	img_scale = 1.0
	super_zoom = 0
	var name := path.get_file()
	get_window().title = "Fart Generator - %s [%dx%d]" % [name, int(image_size.x), int(image_size.y)]

	var entry := settings.hole_for(name)
	hole = entry["pos"]
	if not settings.has_hole(name):
		hole = image_size * 0.5
	extra_holes = []
	for v in entry["extra"]:
		extra_holes.append(v)
	now_setting = false

	_load_overlay()
	_refresh_ui()
	_update_camera()
	ui.set_image_text(name + "\n%d x %d  (%d/%d)" % [int(image_size.x), int(image_size.y), cur_index + 1, library.count()])
	if settings.show_osd:
		ui.show_status(name, 1.5)


func _load_overlay() -> void:
	_overlay_files = ImageLibrary.background_files()
	if _overlay_files.is_empty():
		overlay_sprite.visible = false
		overlay_sprite.texture = null
		return
	_set_overlay(_overlay_index)


func _set_overlay(index: int) -> void:
	if _overlay_files.is_empty():
		return
	_overlay_index = posmod(index, _overlay_files.size())
	var tex := ImageLibrary.load_texture(_overlay_files[_overlay_index])
	overlay_sprite.texture = tex
	overlay_sprite.visible = foreground and tex != null
	if tex != null:
		overlay_sprite.scale = Vector2(image_size.x / tex.get_width(), image_size.y / tex.get_height())


func _cycle_overlay() -> void:
	if _overlay_files.is_empty():
		ui.show_status("No images in assets/background", 1.6)
		return
	_set_overlay(_overlay_index + 1)
	ui.show_status("Background: " + _overlay_files[_overlay_index].get_file(), 1.4)


func next_image(direction: int) -> void:
	if library.count() == 0:
		return
	_save_hole()
	load_image(cur_index + direction)


func reload_images() -> void:
	_save_hole()
	library.refresh()
	cur_index = 0
	if library.count() == 0:
		_make_placeholder()
	else:
		load_image(0)
	ui.show_status("Reloaded %d file(s)" % library.count(), 2.0)


func _open_folder_dialog() -> void:
	if _file_dialog == null:
		_file_dialog = FileDialog.new()
		_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_file_dialog.use_native_dialog = false
		_file_dialog.size = Vector2i(720, 480)
		_file_dialog.dir_selected.connect(_on_folder_selected)
		add_child(_file_dialog)
	if settings.image_dir.begins_with("/") or settings.image_dir.contains(":"):
		_file_dialog.current_dir = settings.image_dir
	_file_dialog.popup_centered()


func _on_folder_selected(dir: String) -> void:
	settings.image_dir = dir
	library = ImageLibrary.new(settings.image_dir, settings.read_recursive)
	settings.save_settings()
	cur_index = 0
	if library.count() == 0:
		_make_placeholder()
		ui.show_status("No images in that folder", 3.0)
	else:
		load_image(0)


# ---------------------------------------------------------------------------
# Hole placement
# ---------------------------------------------------------------------------

func _toggle_set_hole() -> void:
	if now_setting:
		now_setting = false
		_refresh_ui()
		return
	now_setting = true
	extra_holes.clear()
	ui.show_status("Please click the HOLE!", 2.0)
	_refresh_ui()


func _place_hole(pos: Vector2) -> void:
	if Input.is_key_pressed(KEY_X) and extra_holes.size() < EXTRA_HIP_HOLE_MAX:
		extra_holes.append(pos)
		ui.show_status("Extra hole %d" % extra_holes.size(), 1.4)
	else:
		hole = pos
		extra_holes.clear()
		now_setting = false
		ui.show_status("Hole set", 1.2)
	_save_hole()
	_refresh_ui()


func _save_hole() -> void:
	if library == null or library.count() == 0:
		return
	settings.set_hole(library.display_name(library.path_at(cur_index)), hole, extra_holes)


func _show_hole_markers() -> void:
	ui.show_status("Hole: %d, %d" % [int(hole.x), int(hole.y)], 2.0)


# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------

func _update_camera() -> void:
	if camera == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var fit := minf(vp.x / maxf(image_size.x, 1.0), vp.y / maxf(image_size.y, 1.0))
	var focus := image_size * 0.5
	if img_scale > 1.0:
		focus = focus.lerp(hole, 1.0 - 1.0 / img_scale)
	var pos := focus + pan
	var shake_off := Vector2.ZERO
	var zoom_mul := 1.0
	if shake_timer > 0.0 and shake_mode != 0 and settings.shake > 0.0:
		var t := shake_phase
		var amp := settings.shake * 0.6
		var s := sin(t * settings.shake_speed * 22.0)
		var s2 := sin(t * settings.shake_speed * 17.0 + 1.7)
		match shake_mode:
			1:
				shake_off.y = s * amp
			2:
				shake_off.x = s * amp
			3:
				zoom_mul = 1.0 + s * settings.shake / 300.0
			4:
				shake_off = Vector2(s, s2) * amp
	camera.position = pos + shake_off
	var z := fit * img_scale * zoom_mul
	camera.zoom = Vector2(z, z)


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if _handle_key(event as InputEventKey):
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed and not ui.mouse_over_ui():
				_dragging = true
				_drag_from = get_global_mouse_position()
			elif not mb.pressed:
				_dragging = false
			return
		if ui.mouse_over_ui():
			return
		if mb.pressed and now_setting and mb.button_index == MOUSE_BUTTON_LEFT:
			_place_hole(get_global_mouse_position())
			get_viewport().set_input_as_handled()
			return
		if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT and now_setting:
			now_setting = false
			_refresh_ui()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed and not now_setting:
				gas.press_current()
			elif not mb.pressed:
				gas.release_current()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var dir := 1 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -1
			if Input.is_key_pressed(KEY_CTRL):
				img_scale = clampf(img_scale + 0.2 * dir, IMAGE_SCALE_MIN, IMAGE_SCALE_MAX)
				if dir < 0 and img_scale < IMAGE_SCALE_MAX:
					super_zoom = 0
			else:
				next_image(dir)
			_update_camera()
			return

	if event is InputEventMouseMotion and _dragging:
		var now := get_global_mouse_position()
		pan -= now - _drag_from
		_drag_from = now
		_update_camera()


func _handle_key(event: InputEventKey) -> bool:
	var code := event.keycode
	if code >= KEY_0 and code <= KEY_9:
		gas.press_pattern(code - KEY_0)
		return true
	if code >= KEY_KP_0 and code <= KEY_KP_9:
		gas.press_pattern(code - KEY_KP_0)
		return true
	match code:
		KEY_SPACE:
			gas.press_current()
			return true
		KEY_SHIFT:
			gas.next_mode()
			ui.show_status(GasGenerator.MODE_NAMES[gas.current_mode], 1.2)
			return true
		KEY_DELETE:
			_clear_fart()
			return true
		KEY_B:
			blend_on = not blend_on
			gas.ps.set_all_additive(blend_on)
			ui.show_status("Fart Effect [Blend]" if blend_on else "Fart Effect [Normal]", 1.4)
			return true
		KEY_R:
			gas.reverse_shot = not gas.reverse_shot
			ui.show_status("Fart Direction [Reverse]" if gas.reverse_shot else "Fart Direction [Normal]", 1.4)
			return true
		KEY_W:
			_cycle_shake(1)
			return true
		KEY_S:
			_toggle_set_hole()
			return true
		KEY_C:
			_toggle_slideshow()
			return true
		KEY_A:
			_toggle_auto_fire()
			return true
		KEY_H:
			_toggle_buttons()
			return true
		KEY_F2:
			_open_folder_dialog()
			return true
		KEY_F8:
			_toggle_foreground()
			return true
		KEY_UP:
			next_image(1)
			return true
		KEY_DOWN:
			next_image(-1)
			return true
		KEY_Z:
			if img_scale >= IMAGE_SCALE_MAX:
				super_zoom = -1
			else:
				super_zoom = 1
			return true
		KEY_BACKSPACE:
			pan = Vector2.ZERO
			_update_camera()
			return true
		KEY_V:
			if Input.is_key_pressed(KEY_CTRL):
				_cycle_voice(1)
			else:
				_play_voice()
			return true
		KEY_T:
			_cycle_overlay()
			return true
		KEY_EQUAL, KEY_KP_ADD:
			_zoom_step(0.1 if not Input.is_key_pressed(KEY_CTRL) else 0.05)
			return true
		KEY_MINUS, KEY_KP_SUBTRACT:
			_zoom_step(-0.1 if not Input.is_key_pressed(KEY_CTRL) else -0.05)
			return true
		KEY_ESCAPE:
			_quit()
			return true
	return false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.pressed and not event.echo:
		var code := (event as InputEventKey).keycode
		if code >= KEY_0 and code <= KEY_9:
			gas.release_pattern(code - KEY_0)
		elif code >= KEY_KP_0 and code <= KEY_KP_9:
			gas.release_pattern(code - KEY_KP_0)
		elif code == KEY_SPACE:
			gas.release_current()


func _zoom_step(amount: float) -> void:
	if amount > 0.0:
		img_scale = minf(img_scale + amount, IMAGE_SCALE_MAX)
	else:
		img_scale = maxf(img_scale + amount, IMAGE_SCALE_MIN)
		if img_scale < IMAGE_SCALE_MAX:
			super_zoom = 0
	_update_camera()


# ---------------------------------------------------------------------------
# Frame update
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if texture != null:
		gas.target = get_global_mouse_position()
		gas.set_holes(hole, extra_holes)
		gas.img_scale = img_scale

	if super_zoom != 0:
		img_scale += 3.0 * delta * (1.0 if super_zoom > 0 else -1.0)
		if img_scale >= IMAGE_SCALE_MAX:
			img_scale = IMAGE_SCALE_MAX
			if super_zoom > 0:
				sound.play_sfx("hip_press")
			super_zoom = 0
		elif img_scale <= 1.0:
			img_scale = 1.0
			super_zoom = 0

	# Sound keeps the gas alive in synchro mode (obj_gas_generator Step).
	if settings.synchro_mode and gas.farting_time <= 0.0 and prev_fart_player != null and prev_fart_player.playing:
		gas.farting_time = 2.0

	_update_shake_timer(delta)
	_update_slideshow(delta)
	_update_auto_fire(delta)
	_update_camera()
	queue_redraw()


func _update_shake_timer(delta: float) -> void:
	if shake_mode == 0 or settings.shake <= 0.0:
		shake_timer = 0.0
		return
	shake_timer = maxf(0.0, shake_timer - delta)
	# Keep shaking while gas is being produced, then let it fade out.
	if gas.farting_time > 0.0 and shake_timer < 0.12:
		shake_timer = 0.35
	shake_phase += delta


func _update_slideshow(delta: float) -> void:
	if auto_emit:
		if slideshow_timer > 0.0:
			slideshow_timer = -1.0
			_refresh_ui()
		return
	if slideshow_timer > 0.0:
		slideshow_timer -= delta
		if slideshow_timer <= 0.0:
			next_image(1)
			slideshow_timer = settings.slideshow_interval
		ui.set_button_text("slideshow", "Slideshow %.1f [C]" % slideshow_timer)
		ui.set_button_active("slideshow", true)


func _update_auto_fire(delta: float) -> void:
	if not auto_emit:
		return
	if auto_timer < 0.0:
		return
	auto_timer -= delta
	if auto_timer > 0.0:
		return

	if not auto_emitting:
		if auto_pending_change:
			auto_pending_change = false
			next_image(1)
			auto_timer = _rand_interval()
			return
		if selection_rule == "AllRandom":
			gas.current_mode = _rng.randi_range(0, EMIT_MODE_MAX - 1)
			gas.current_pattern = _rng.randi_range(0, GAS_PATTERN_MAX - 1)
		elif selection_rule == "Random":
			gas.current_pattern = _rng.randi_range(0, GAS_PATTERN_MAX - 1)
		if settings.auto_change_image:
			fart_count -= 1
		gas.press_pattern(gas.current_pattern)
		auto_emitting = true
		auto_timer = clampf(_rng.randf_range(settings.emit_time_min, settings.emit_time_max), TIME_MIN, TIME_MAX)
		_refresh_ui()
	else:
		gas.farting_time = 0.0
		gas.emit_particle[clampi(gas.current_pattern, 0, GAS_PATTERN_MAX - 1)] = false
		auto_emitting = false
		if settings.auto_change_image and fart_count <= 0:
			fart_count = settings.fart_until_changing_img
			auto_pending_change = true
			auto_timer = settings.emit_interval_min
		else:
			auto_timer = _rand_interval()
		_refresh_ui()


func _rand_interval() -> float:
	var lo := minf(settings.emit_interval_min, settings.emit_interval_max)
	var hi := maxf(settings.emit_interval_min, settings.emit_interval_max)
	return maxf(_rng.randf_range(lo, hi), TIME_MIN)


func _draw() -> void:
	if marker_tex == null:
		return
	var size := Vector2(40, 40)
	if hole != Vector2.ZERO:
		draw_texture_rect(marker_tex, Rect2(hole - size * 0.5, size), false, Color(1, 1, 1, 0.85))
	for extra in extra_holes:
		draw_texture_rect(marker_tex, Rect2(extra - size * 0.35, size * 0.7), false, Color(1, 0.5, 0.5, 0.8))


# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------

func _clear_fart() -> void:
	gas.clear_all()
	sound.stop_all()
	ui.show_status("Clear", 1.2)


func _toggle_slideshow() -> void:
	if auto_emit:
		ui.show_status("Slideshow disabled during Auto Fire", 1.6)
		return
	if slideshow_timer > 0.0:
		slideshow_timer = -1.0
		ui.show_status("Slideshow End", 1.2)
	else:
		slideshow_timer = settings.slideshow_interval
		ui.show_status("Slideshow Start", 1.2)
	_refresh_ui()


func _toggle_auto_fire() -> void:
	if auto_emit:
		auto_emit = false
		auto_emitting = false
		auto_timer = -1.0
		auto_pending_change = false
		gas.farting_time = 0.0
		slideshow_timer = -1.0
		ui.show_status("Auto Fire End...", 1.2)
	else:
		auto_emit = true
		auto_emitting = false
		auto_pending_change = false
		fart_count = settings.fart_until_changing_img
		auto_timer = 5.0 / 30.0
		ui.show_status("Auto Fire Start!!", 1.4)
	_refresh_ui()


func _cycle_selection_rule() -> void:
	var rules := ["Random", "AllRandom", "Single"]
	selection_rule = rules[posmod(rules.find(selection_rule) + 1, rules.size())]
	settings.selection_rule = selection_rule
	ui.show_status("Auto Fire selection: " + selection_rule, 1.6)


func _toggle_auto_change_image() -> void:
	settings.auto_change_image = not settings.auto_change_image
	fart_count = settings.fart_until_changing_img
	ui.show_status("Auto image change " + ("ON" if settings.auto_change_image else "OFF"), 1.4)
	_refresh_ui()


func _toggle_buttons() -> void:
	ui.set_visible_buttons(not ui.panel.visible)


func _toggle_foreground() -> void:
	foreground = not foreground
	settings.foreground_mode = foreground
	overlay_sprite.visible = foreground and overlay_sprite.texture != null
	ui.show_status("Foreground Mode " + ("ON" if foreground else "OFF"), 1.4)
	_refresh_ui()


func _toggle_synchro() -> void:
	settings.synchro_mode = not settings.synchro_mode
	ui.show_status("Synchro Mode " + ("ON" if settings.synchro_mode else "OFF"), 1.4)
	_refresh_ui()


func _cycle_shake(direction: int) -> void:
	shake_mode = posmod(shake_mode + direction, 5)
	var names := ["Off", "Vertical", "Horizontal", "Zoom", "Random"]
	if shake_mode != 0:
		gas.farting_time = maxf(gas.farting_time, 3.0)
	ui.show_status("Shake: " + names[shake_mode], 1.4)
	_refresh_ui()


func _cycle_sound(direction: int) -> void:
	var order := sound.group_order
	if order.is_empty():
		return
	var current: String = sound_map[gas.current_mode][gas.current_pattern]
	var idx := order.find(current)
	if idx == -1:
		idx = 0
	else:
		idx = posmod(idx + direction, order.size())
	sound_map[gas.current_mode][gas.current_pattern] = order[idx]
	ui.show_status("SE: " + order[idx] + (" (empty)" if sound.group_is_empty(order[idx]) else ""), 1.4)
	_refresh_ui()


func _cycle_voice(direction: int) -> void:
	current_voice = posmod(current_voice + direction, sound.voice_count + 1)
	_refresh_ui()


func _play_voice() -> void:
	if current_voice <= 0:
		return
	var variation := 0.05 if settings.voice_pitch else 0.0
	sound.play_voice(current_voice - 1, variation)


func _on_fart_started() -> void:
	if settings.show_osd:
		ui.show_status(gas.pattern_label(), 1.2)
	var group: String = sound_map[gas.current_mode][gas.current_pattern]
	var pitch := 0.3 if settings.fart_sound_pitch else 0.0
	prev_fart_player = sound.play_group(group, pitch)
	if current_voice > 0:
		_play_voice()
	shake_phase = 0.0


func _step_pattern(direction: int) -> void:
	gas.step_pattern(direction)
	ui.show_status(gas.pattern_label(), 1.2)


func _nudge(what: String, amount: float) -> void:
	match what:
		"size":
			gas.gas_size_scale = clampf(gas.gas_size_scale + amount, SCALE_MIN, SCALE_MAX)
		"num":
			gas.gas_num_scale = clampf(gas.gas_num_scale + amount, SCALE_MIN, SCALE_MAX)
		"speed":
			gas.gas_speed_scale = clampf(gas.gas_speed_scale + amount, SCALE_MIN, SCALE_MAX)
		"amnt":
			gas.gas_amount_scale = clampf(gas.gas_amount_scale + amount, SCALE_MIN, SCALE_MAX)
	_refresh_ui()


func _prompt_scale(what: String) -> void:
	var value := 1.0
	var title := "Value:"
	match what:
		"size":
			value = gas.gas_size_scale
			title = "Gas Size:"
		"num":
			value = gas.gas_num_scale
			title = "The number of Gas Effect:"
		"speed":
			value = gas.gas_speed_scale
			title = "Gas Speed:"
		"amnt":
			value = gas.gas_amount_scale
			title = "The Amount of Gas:"
	_prompt_value(title, value, func(v: float) -> void:
		var clamped := clampf(v, SCALE_MIN, SCALE_MAX)
		match what:
			"size": gas.gas_size_scale = clamped
			"num": gas.gas_num_scale = clamped
			"speed": gas.gas_speed_scale = clamped
			"amnt": gas.gas_amount_scale = clamped
		_refresh_ui()
	)


func _prompt_shake_power() -> void:
	_prompt_value("Shake Power [0 - 50]:", settings.shake, func(v: float) -> void:
		settings.shake = clampf(v, 0.0, 50.0)
		_refresh_ui()
	)


func _prompt_fart_interval() -> void:
	_prompt_value("Fart Interval MAX [sec]:", settings.emit_interval_max, func(v: float) -> void:
		settings.emit_interval_max = clampf(v, TIME_MIN, TIME_MAX)
		if settings.emit_interval_min > settings.emit_interval_max:
			settings.emit_interval_min = settings.emit_interval_max
	)


func _prompt_slideshow_interval() -> void:
	_prompt_value("Slideshow Interval [sec]:", settings.slideshow_interval, func(v: float) -> void:
		settings.slideshow_interval = clampf(v, TIME_MIN, TIME_MAX)
	)


func _toggle_fart_pitch() -> void:
	settings.fart_sound_pitch = not settings.fart_sound_pitch
	ui.show_status("Fart pitch random " + ("ON" if settings.fart_sound_pitch else "OFF"), 1.4)


func _toggle_voice_pitch() -> void:
	settings.voice_pitch = not settings.voice_pitch
	ui.show_status("Voice pitch random " + ("ON" if settings.voice_pitch else "OFF"), 1.4)


func _on_color_changed(c1: Color, c2: Color) -> void:
	palette1 = c1
	palette2 = c2
	gas.apply_palette_color(c1, c2)


func _randomize_colors() -> void:
	palette1 = UiPanel.DEFAULT_COLOR_1
	palette2 = UiPanel.DEFAULT_COLOR_2
	_update_palette_ui()
	gas.reset_palette()
	ui.show_status("Random Fart Color", 1.2)


func _reset_colors() -> void:
	palette1 = UiPanel.DEFAULT_COLOR_1
	palette2 = UiPanel.DEFAULT_COLOR_2
	_update_palette_ui()
	gas.apply_palette_color(palette1, palette2)
	ui.show_status("Reset Fart Color", 1.2)


func _update_palette_ui() -> void:
	ui.pick1.set_block_signals(true)
	ui.pick2.set_block_signals(true)
	ui.pick1.color = palette1
	ui.pick2.color = palette2
	ui.pick1.set_block_signals(false)
	ui.pick2.set_block_signals(false)


# ---------------------------------------------------------------------------
# UI refresh
# ---------------------------------------------------------------------------

func _refresh_ui() -> void:
	ui.set_button_text("set_hole", "Click Hole! [S]" if now_setting else "Set Hole [S]")
	ui.set_button_active("set_hole", now_setting)
	ui.set_button_active("auto_fire", auto_emit)
	ui.set_button_active("synchro", settings.synchro_mode)
	ui.set_button_active("foreground", foreground)
	ui.set_button_active("slideshow", slideshow_timer > 0.0)
	ui.set_button_text("slideshow", "Slideshow [C]" if slideshow_timer <= 0.0 else "Slideshow ... [C]")
	ui.set_button_text("auto_fire", "Auto Fire! [A]" if auto_emit else "Auto Fire [A]")
	if settings.auto_change_image:
		ui.set_button_text("auto_fire", ui.button("auto_fire").text + " (SS)")
	ui.set_button_text("fart_id", "Fart ID: %d-%d" % [gas.current_mode + 1, gas.current_pattern])
	var group: String = sound_map[gas.current_mode][gas.current_pattern]
	ui.set_button_text("se", "SE: " + group + (" (empty)" if sound.group_is_empty(group) else ""))
	ui.set_button_text("voice", "Voice: " + ("Off" if current_voice == 0 else str(current_voice)))
	ui.set_button_text("size", "Size  x%.2f" % gas.gas_size_scale)
	ui.set_button_text("num", "Num   x%.2f" % gas.gas_num_scale)
	ui.set_button_text("speed", "Speed x%.2f" % gas.gas_speed_scale)
	ui.set_button_text("amnt", "Amnt  x%.2f" % gas.gas_amount_scale)
	var names := ["Off", "Vertical", "Horizontal", "Zoom", "Random"]
	ui.set_button_text("shake", "Shake: " + names[shake_mode])
	ui.set_button_active("shake", shake_mode != 0)
	ui.set_button_text("synchro", "Synchro: " + ("On" if settings.synchro_mode else "Off"))
	ui.set_button_text("foreground", "Foreground: " + ("On" if foreground else "Off"))
	ui.set_button_text("slideshow", "Slideshow [C]" if slideshow_timer <= 0.0 else "Slideshow %.1f [C]" % slideshow_timer)


# ---------------------------------------------------------------------------
# Small dialogs
# ---------------------------------------------------------------------------

func _prompt_value(title: String, value: float, callback: Callable) -> void:
	if _prompt == null:
		_prompt = AcceptDialog.new()
		_prompt_edit = LineEdit.new()
		_prompt_edit.custom_minimum_size = Vector2(260, 0)
		_prompt.add_child(_prompt_edit)
		_prompt.confirmed.connect(_on_prompt_confirmed)
		_prompt_edit.text_submitted.connect(func(_text: String) -> void:
			_on_prompt_confirmed()
			_prompt.hide()
		)
		add_child(_prompt)
	_prompt.title = title
	_prompt_edit.text = str(value)
	_prompt_cb = callback
	_prompt.popup_centered(Vector2i(320, 110))
	_prompt_edit.grab_focus()
	_prompt_edit.select_all()


func _on_prompt_confirmed() -> void:
	if _prompt_cb.is_valid():
		_prompt_cb.call(_prompt_edit.text.to_float())


func _quit() -> void:
	_save_hole()
	settings.save_settings()
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if settings != null:
			_save_hole()
			settings.save_settings()
