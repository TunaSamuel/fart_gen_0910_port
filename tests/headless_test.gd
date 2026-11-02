extends Node

## Headless smoke test for the Godot port. Run with:
##   godot --headless --path . res://tests/headless_test.tscn
## It boots the real main scene, fires every pattern and checks the systems.

# Explicit preloads: resolution does not depend on the editor's class cache.
const GasGenerator := preload("res://scripts/gas_generator.gd")
const ParticleSystem := preload("res://scripts/particle_system.gd")
const SettingsStore := preload("res://scripts/settings_store.gd")
const WavLoader := preload("res://scripts/wav_loader.gd")

var failures := 0
var main: Node


func check(condition: bool, label: String, extra: String = "") -> void:
	if condition:
		print("PASS  ", label, ("  " + extra if extra != "" else ""))
	else:
		failures += 1
		print("FAIL  ", label, ("  " + extra if extra != "" else ""))


func _ready() -> void:
	print("== Fart Generator headless test ==")
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame

	check(main.library != null, "image library created")
	check(main.library.count() > 0, "images discovered", "count=%d dir=%s" % [main.library.count(), main.settings.image_dir])
	check(main.texture != null, "first image texture loaded")
	check(main.image_size.x > 0 and main.image_size.y > 0, "image size", str(main.image_size))
	check(main.gas.ps.type_count() > 40, "particle types built", "types=%d" % main.gas.ps.type_count())

	# WAV loader against the two original sound files.
	var wav := WavLoader.load_wav("res://assets/sound/sfx/snd_hip_press.wav")
	check(wav != null, "wav loader reads original sfx")
	if wav != null:
		check(wav.mix_rate == 22050, "wav sample rate preserved", str(wav.mix_rate))
		check(wav.data.size() > 1000, "wav sample data present", "bytes=%d" % wav.data.size())

	# Settings + hole database round trip.
	main.settings.set_hole("unit_test.png", Vector2(123, 456), [Vector2(7, 8)])
	main.settings.save_settings()
	var store := SettingsStore.new()
	store.load_settings()
	var entry := store.hole_for("unit_test.png")
	check(entry["pos"] == Vector2(123, 456), "hole position persisted", str(entry["pos"]))
	check(entry["extra"].size() == 1, "extra holes persisted")

	# Camera fit sanity.
	main._update_camera()
	var vp: Vector2 = main.get_viewport().get_visible_rect().size
	check(main.camera.zoom.x > 0.0, "camera zoom valid", "zoom=%s viewport=%s" % [str(main.camera.zoom), str(vp)])

	# Every one of the 5 x 10 patterns must produce particles.
	var patterns_ok := 0
	for mode in GasGenerator.EMIT_MODE_MAX:
		for pattern in GasGenerator.GAS_PATTERN_MAX:
			main.gas.clear_all()
			main.gas.current_mode = mode
			main.gas.current_pattern = pattern
			main.gas.press_pattern(pattern)
			for i in 40:
				await get_tree().process_frame
			var alive: int = main.gas.ps.alive_count()
			if alive > 0:
				patterns_ok += 1
			else:
				print("      no particles for mode %d pattern %d" % [mode, pattern])
			main.gas.release_pattern(pattern)
	check(patterns_ok == GasGenerator.EMIT_MODE_MAX * GasGenerator.GAS_PATTERN_MAX,
		"all patterns emit particles", "%d/%d" % [patterns_ok, GasGenerator.EMIT_MODE_MAX * GasGenerator.GAS_PATTERN_MAX])

	# Reverse direction, blend toggle and colour changes must not crash.
	main.gas.reverse_shot = true
	main.gas.clear_all()
	main.gas.press_pattern(0)
	for i in 10:
		await get_tree().process_frame
	main.gas.release_pattern(0)
	main.gas.ps.set_all_additive(true)
	main._on_color_changed(Color(0.4, 0.9, 0.2), Color(1, 0.8, 0.1))
	main._randomize_colors()
	main._reset_colors()
	check(main.gas.ps.alive_count() > 0, "emits while reversed with blend")

	# Auto fire and slideshow state machines.
	main._toggle_auto_fire()
	main._toggle_auto_change_image()
	for i in 130:
		await get_tree().process_frame
	check(main.auto_emit, "auto fire stays on")
	main._toggle_slideshow()
	main._toggle_auto_fire()
	check(not main.auto_emit, "auto fire stops")

	# Particle cap must hold even for an eternal pattern.
	main.gas.clear_all()
	main.gas.current_mode = 1
	main.gas.current_pattern = 2
	main.gas.press_pattern(2)
	for i in 600:
		await get_tree().process_frame
	check(main.gas.ps.alive_count() <= ParticleSystem.MAX_PARTICLES, "particle cap respected",
		"alive=%d" % main.gas.ps.alive_count())
	main.gas.clear_all()
	check(main.gas.ps.alive_count() == 0, "clear removes all particles")

	# Image switching + foreground toggle.
	main.next_image(1)
	check(main.texture != null, "image switch works")
	main._toggle_foreground()
	main._toggle_foreground()

	# Sound bank with empty folders must not break; synth fallback exists.
	check(main.sound.groups.size() >= 11, "sound groups registered", "groups=%d" % main.sound.groups.size())
	var player: AudioStreamPlayer = main.sound.play_group("Small", 0.3)
	check(player != null, "sound playback returns a player")

	print("== %d failure(s) ==" % failures)
	get_tree().quit(1 if failures > 0 else 0)
