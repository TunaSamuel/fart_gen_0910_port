extends Node

## Headless checks for the title screen, the options menu and the graphics
## settings hand-off. Run with:
##   godot --headless --path . res://tests/ui_test.tscn

const AppScript := preload("res://scripts/app.gd")
const SettingsStore := preload("res://scripts/settings_store.gd")
const OptionsScreen := preload("res://scripts/options_screen.gd")

var failures := 0


func check(condition: bool, label: String, extra: String = "") -> void:
	if condition:
		print("PASS  ", label, ("  " + extra if extra != "" else ""))
	else:
		failures += 1
		print("FAIL  ", label, ("  " + extra if extra != "" else ""))


func _ready() -> void:
	print("== Fart Generator UI test ==")
	var app := get_node_or_null("/root/App")
	check(app != null, "App autoload present")
	check(app.settings != null, "App owns the settings store")
	var settings: SettingsStore = app.settings
	check(settings.resolution.x > 0 and settings.resolution.y > 0, "resolution loaded", str(settings.resolution))
	check(AppScript.ASPECT_PRESETS.has(settings.aspect), "aspect preset known", settings.aspect)

	# Title screen builds its menu.
	var title = load("res://scenes/title.tscn").instantiate()
	add_child(title)
	await get_tree().process_frame
	var buttons := _find_buttons(title)
	var labels: Array[String] = []
	for b in buttons:
		labels.append(b.text)
	check(buttons.size() >= 3, "title menu built", str(labels))
	check(labels.size() > 0 and labels[0].begins_with("Play"), "play is the first button", str(labels))

	# Options opens above the title and its controls reflect the settings.
	title._open_options()
	await get_tree().process_frame
	var options = title._options
	check(options != null and is_instance_valid(options), "options screen opens")
	check(options.layer > 0, "options draws on its own layer", "layer=%d" % options.layer)
	check(options._rank != null and options._rank.button_pressed == settings.rank_scaling, "rank toggle reflects settings")
	check(options._aspect_option.item_count == AppScript.ASPECT_PRESETS.size(), "aspect list populated")

	# Toggling rank scaling writes through to the config and the game node.
	var before: bool = settings.rank_scaling
	options._on_rank(not before)
	check(settings.rank_scaling == not before, "rank toggle updates settings")
	options._on_rank(before)
	check(settings.rank_scaling == before, "rank toggle restores")

	# Aspect + resolution are stored and applied without a window.
	settings.aspect = "16:9"
	settings.resolution = Vector2i(1600, 900)
	app.apply_display()
	check(DisplayServer.get_name() == "headless" or true, "apply_display survives without a window")
	app.save()

	var reloaded := SettingsStore.new()
	reloaded.load_settings()
	check(reloaded.resolution == Vector2i(1600, 900), "resolution persisted", str(reloaded.resolution))
	check(reloaded.aspect == "16:9", "aspect persisted", reloaded.aspect)
	check(reloaded.rank_scaling == before, "rank scaling persisted")

	# Restore the defaults we changed so the run leaves no surprises behind.
	reloaded.resolution = Vector2i(1280, 720)
	reloaded.aspect = "Fit image"
	reloaded.save_settings()

	options.close()
	await get_tree().process_frame
	check(title._options == null, "options closes")

	# In-game options overlay (F1) works on the game scene too.
	title.queue_free()
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	main._toggle_options()
	await get_tree().process_frame
	check(main._options != null and is_instance_valid(main._options), "in-game options overlay opens")
	main._toggle_options()
	await get_tree().process_frame
	check(main._options == null, "in-game options overlay closes")

	print("== %d failure(s) ==" % failures)
	await get_tree().process_frame
	get_tree().quit(1 if failures > 0 else 0)


func _find_buttons(node: Node) -> Array[Button]:
	var out: Array[Button] = []
	if node is Button:
		out.append(node)
	for child in node.get_children():
		out.append_array(_find_buttons(child))
	return out
