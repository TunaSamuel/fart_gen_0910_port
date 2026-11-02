class_name GasGenerator
extends Node2D

## Port of obj_gas_generator: particle type setup, the 5x10 fart pattern table
## and the emission loop.

# Explicit preloads: keeps the scripts parseable on a fresh checkout before
# Godot's editor has built its global class cache.
const ParticleSystem := preload("res://scripts/particle_system.gd")
const ParticleType := preload("res://scripts/particle_type.gd")

signal fart_started
signal pattern_changed

const GAS_PATTERN_MAX := 10
const EMIT_MODE_MAX := 5
const EXTRA_HIP_HOLE_MAX := 9

## How big a fart is, taken from its sound group (Small .. Huge). Rank 1 is a
## timid squeak, rank 4 a screen-filling monster.
const RANK_BY_GROUP := {
	"Small": 1,
	"Sneaky": 2,
	"Medium": 2,
	"Big": 3,
	"Special": 3,
	"Huge": 4,
}
const RANK_MIN := 1
const RANK_MAX := 4
const ETERNAL := 360000.0           # frames, ~3.3 hours at 30 Hz
const BURST_THRESH := 3600.0
const FRAME_TIME := 1.0 / 30.0      # original game speed

const MODE_NAMES := ["SHOT", "MIST", "TORNADO", "BURST", "EXPERIMENT"]
const PATTERN_NAMES := [
	["WEAK SHOT", "SINGLE SHOT", "MULTI SHOT", "WEAK MIST", "MIST", "BIG MIST", "WIDE MIST", "FART SMOG", "DEADLY SMOG", "TERRIBLE SMOG"],
	["STORM", "SHOTGUN", "MACHINEGUN", "HELL SHOT", "EXPLOSION", "LITTLE BOMB", "HELL MIST", "SPARKLE MIST", "TEMPEST", "GIANT FART"],
	["BAD DEADLY", "TYPHOON", "TORNADO", "GREAT TORNADO", "HUGE TYPHOON", "POWERFUL SHOT", "BIG FART GUST", "THE ATMOSPHERE", "BIG BOMBER", "GREAT BLAST"],
	["LITTLE WIND", "FART BREATHE", "SHORT SNEAKY", "LASER BURST", "ETERNAL SNEAKY", "GREAT AMOUNT", "FART CLOUD", "HIP BOMB", "GREAT HIP BOMB", "ULTIMATE HIP BOMB"],
	["NO MORE GAS?", "NO POWER?", "SNIPER FART", "INFINITY FART", "SUKASHI", "GIANT BACKFIRE", "STREAMING GAS", "GOD BREATHE", "BIG HIP FIRE", "BIG HIP FRAME"],
]

# Card suits not needed; keep the palette randomiser faithful to set_pt_color.
const PALETTE := [
	[Color8(220, 188, 48), Color8(225, 208, 84), Color8(225, 228, 155)],
	[Color8(202, 198, 85), Color8(178, 174, 70)],
	[Color8(230, 223, 141), Color8(178, 174, 70)],
	[Color8(230, 223, 141), Color8(202, 198, 85), Color8(178, 174, 70)],
	[Color8(200, 168, 48), Color8(215, 178, 54), Color8(215, 188, 55)],
]

var ps: ParticleSystem
var types: Dictionary = {}
var type_size_incr: Dictionary = {}

# Tuning knobs, all from the original's global scales.
var gas_size_scale := 2.0
var gas_num_scale := 2.0
var gas_speed_scale := 2.0
var gas_amount_scale := 1.0
var img_scale := 1.0

## Rank of the pattern being fired (see RANK_BY_GROUP), and whether rank affects
## particle size, growth, spread and shake.
var rank := 2
var rank_scaling := true

## Where the current fart was aimed. Captured when a burst starts so the gas
## keeps flying where you clicked instead of chasing the mouse.
var aim_point := Vector2.ZERO
var aim_valid := false

var farting_time := 0.0
var current_mode := 0
var current_pattern := 1
var reverse_shot := false
var emit_particle: Array[bool] = []
var gas_name := ""

var hole_position := Vector2.ZERO
var extra_holes: Array[Vector2] = []
var target := Vector2.ZERO

var _pending: Array = []          # [[type key, count], ...]
var palette_types: Array[int] = []  # types that participate in colour changes
var _ex_range := 0.0
var _particle_accum: Dictionary = {}
var _accum := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	ps = ParticleSystem.new()
	ps.name = "Particles"
	ps.z_index = 10
	add_child(ps)
	for i in GAS_PATTERN_MAX:
		emit_particle.append(false)
	_build_types()
	set_process(true)


func _any_emit() -> bool:
	for flag in emit_particle:
		if flag:
			return true
	return false


func _process(delta: float) -> void:
	_accum += minf(delta, 0.5)
	var ticks := 0
	while _accum >= FRAME_TIME and ticks < 4:
		_accum -= FRAME_TIME
		_tick()
		ticks += 1


func _tick() -> void:
	var check := _any_emit()
	if check:
		# Lock the aim for the whole burst: the gas flies where you clicked and
		# does not follow the mouse afterwards.
		aim_point = target
		aim_valid = true
	_apply_pattern(check)
	if check:
		fart_started.emit()
		for i in GAS_PATTERN_MAX:
			emit_particle[i] = false
	farting_time = maxf(0.0, farting_time - 1.0)


func set_holes(pos: Vector2, extras: Array[Vector2]) -> void:
	hole_position = pos
	extra_holes = extras


func press_pattern(index: int) -> void:
	if index < 0 or index >= GAS_PATTERN_MAX:
		return
	emit_particle[index] = true
	current_pattern = index
	pattern_changed.emit()


func release_pattern(index: int) -> void:
	if index < 0 or index >= GAS_PATTERN_MAX:
		return
	emit_particle[index] = false
	if farting_time > 0.0:
		farting_time = 1.0


func press_current() -> void:
	emit_particle[clampi(current_pattern, 0, GAS_PATTERN_MAX - 1)] = true


func release_current() -> void:
	emit_particle[clampi(current_pattern, 0, GAS_PATTERN_MAX - 1)] = false
	if farting_time > 0.0:
		farting_time = 1.0


func next_mode() -> void:
	current_mode = (current_mode + 1) % EMIT_MODE_MAX
	pattern_changed.emit()


func step_pattern(direction: int) -> void:
	current_pattern += direction
	if current_pattern >= GAS_PATTERN_MAX:
		current_pattern = 0
		current_mode = (current_mode + 1) % EMIT_MODE_MAX
	elif current_pattern < 0:
		current_pattern = GAS_PATTERN_MAX - 1
		current_mode = (current_mode - 1 + EMIT_MODE_MAX) % EMIT_MODE_MAX
	pattern_changed.emit()


func clear_all() -> void:
	farting_time = 0.0
	ps.clear()


func pattern_label() -> String:
	return PATTERN_NAMES[current_mode][current_pattern]


# ---------------------------------------------------------------------------
# Emission
# ---------------------------------------------------------------------------

func _add(key: String, count: float) -> void:
	_pending.append([key, count])


## 1.0 when rank scaling is off, otherwise a mild size/spread/shake weight.
func rank_factor() -> float:
	if not rank_scaling:
		return 1.0
	return 0.7 + 0.15 * float(clampi(rank, RANK_MIN, RANK_MAX))


func _spread_factor() -> float:
	if not rank_scaling:
		return 1.0
	return 0.9 + 0.05 * float(clampi(rank, RANK_MIN, RANK_MAX))


## Starting particle size. Huge farts spawn fat clouds, small ones thin puffs.
func _base_size() -> float:
	if not rank_scaling:
		return 0.25
	return 0.16 + 0.13 * float(clampi(rank, RANK_MIN, RANK_MAX))


func _growth_factor() -> float:
	if not rank_scaling:
		return 1.0
	return 0.75 + 0.12 * float(clampi(rank, RANK_MIN, RANK_MAX))


func _count_factor() -> float:
	if not rank_scaling:
		return 1.0
	return 0.9 + 0.05 * float(clampi(rank, RANK_MIN, RANK_MAX))


func _dir(key: String, base: float, spread: float) -> void:
	var t: ParticleType = ps.type_at(types[key])
	# Bigger farts (rank) spread a little wider.
	var s := spread * _spread_factor()
	t.dir_min = base - s
	t.dir_max = base + s


func _dir_abs(key: String, dmin: float, dmax: float) -> void:
	var t: ParticleType = ps.type_at(types[key])
	t.dir_min = dmin
	t.dir_max = dmax


func _speed(key: String, smin: float, smax: float, incr: float) -> void:
	var t: ParticleType = ps.type_at(types[key])
	t.speed_min = smin
	t.speed_max = smax
	t.speed_incr = incr


func _apply_pattern(check: bool) -> void:
	_pending.clear()
	_ex_range = 0.0
	# GameMaker directions are counter-clockwise with 0 = right; Godot's y axis
	# points down, hence the negation.
	var aim := aim_point if aim_valid else target
	var g := -rad_to_deg((aim - hole_position).angle())
	if reverse_shot:
		g = fposmod(g + 180.0, 360.0)
	var sp := hole_position.distance_to(aim) * gas_speed_scale * img_scale
	var time := 0.0

	match current_mode:
		0:
			match current_pattern:
				0:
					_dir("weak_shot", g, 30); _speed("weak_shot", sp / 160.0, sp / 100.0, -0.2)
					_add("weak_shot", 1); _ex_range = 30; time = 1
				1:
					_dir("machinegun", g, 5); _speed("machinegun", sp / 240.0, sp / 100.0, -0.2)
					_add("machinegun", 1); _ex_range = 5; time = 1
				2:
					_dir("weak_shot", g, 30); _speed("weak_shot", sp / 130.0, sp / 80.0, -0.2)
					_dir("weak_burst", g, 60); _speed("weak_burst", sp / 160.0, sp / 100.0, -0.2)
					_add("weak_shot", 2); _add("weak_burst", 2); _ex_range = 50; time = 5
				3:
					_dir("weak_mist", g, 30); _speed("weak_mist", sp / 200.0, sp / 100.0, -0.2)
					_add("weak_mist", 1); _ex_range = 30; time = 1
				4:
					_dir("mist", g, 5); _speed("mist", sp / 220.0, sp / 100.0, -0.2)
					_add("mist", 1); time = 1
				5:
					_dir("storm", g, 5); _speed("storm", sp / 240.0, sp / 100.0, -0.2)
					_add("storm", 1); _ex_range = 5; time = 1
				6:
					_dir("mist", g, 45); _speed("mist", sp / 120.0, sp / 70.0, -0.1)
					_add("mist", 3); _ex_range = 45; time = 3
				7:
					_dir("smog", g, 180); _speed("smog", sp / 220.0, sp / 120.0, -0.05)
					_add("smog", 0.1); _ex_range = 180; time = 30
				8:
					_dir("smog_huge", g, 180); _speed("smog_huge", sp / 220.0, sp / 120.0, -0.05)
					_add("smog_huge", 0.1); _ex_range = 180; time = 30
				9:
					_dir("smog_huge", g, 180); _speed("smog_huge", sp / 220.0, sp / 100.0, -0.05)
					_dir("smog", g, 180); _speed("smog", sp / 160.0, sp / 90.0, -0.05)
					_add("smog", 0.05); _add("smog_huge", 0.05); _ex_range = 180; time = 60
		1:
			match current_pattern:
				0:
					_dir("storm", g, 175); _speed("storm", sp / 240.0, sp / 100.0, -0.2)
					_add("storm", 0.3); _ex_range = 175; time = 30
				1:
					_speed("shotgun", sp / 250.0, sp / 50.0, -0.2)
					_add("shotgun", 30); time = 3
				2:
					_dir("machinegun", g, 170); _speed("machinegun", sp / 220.0, sp / 50.0, -0.2)
					_add("machinegun", 2); _ex_range = 170; time = ETERNAL
				3:
					_dir("machinegun", g, 175); _speed("machinegun", sp / 220.0, sp / 50.0, -0.2)
					_dir("ryfle", g, 50); _speed("ryfle", sp / 160.0, sp / 70.0, -0.2)
					_add("machinegun", 20); _add("ryfle", 10); _ex_range = 50; time = 1
				4:
					_add("explode", 1); _add("atmosphere", 0.1); time = 5
				5:
					_dir("weak_atmosphere", g, 180)
					_add("weak_atmosphere", 1); _ex_range = 180; time = 1
				6:
					_dir("mist", g, 25); _speed("mist", sp / 200.0, sp / 100.0, -0.1)
					_add("storm", 1); _add("mist", 1); _add("atmosphere", 1)
					_ex_range = 25; time = 1
				7:
					_dir("weak_mist", g, 145); _speed("weak_mist", sp / 220.0, sp / 100.0, -0.1)
					_add("weak_mist", 2); _ex_range = 145; time = 15
				8:
					_dir("mist", g, 175); _speed("mist", sp / 160.0, sp / 80.0, -0.1)
					_add("mist", 1); _ex_range = 175; time = 20
				9:
					_dir("storm", g, 165); _speed("storm", sp / 240.0, sp / 100.0, -0.2)
					_add("storm", 5); _ex_range = 165; time = 1
		2:
			match current_pattern:
				0:
					_dir("weak_mist", g, 175); _speed("weak_mist", sp / 160.0, sp / 100.0, -0.1)
					_dir("weak_shot", g, 175); _speed("weak_shot", sp / 160.0, sp / 70.0, -0.1)
					_add("weak_mist", 1); _add("weak_shot", 15); _ex_range = 175; time = 20
				1:
					_dir("rolling", g, 180); _speed("rolling", sp / 120.0, sp / 80.0, -0.2)
					_add("rolling", 0.2); _add("explode", 1); time = 40
				2:
					_dir("rolling", g, 180); _speed("rolling", sp / 220.0, sp / 80.0, -0.1)
					_add("rolling", 5); _add("explode", 1); time = 1
				3:
					_dir("rolling", g, 180); _speed("rolling", sp / 160.0, sp / 80.0, -0.1)
					_dir("smog_huge", g, 180); _speed("smog_huge", sp / 120.0, sp / 60.0, -0.05)
					_add("atmosphere", 0.5); _add("explode", 1); _add("rolling", 7)
					_add("smog_huge", 5); time = 1
				4:
					_dir("rolling_fast", g, 45); _speed("rolling_fast", sp / 140.0, sp / 80.0, -0.1)
					_add("rolling_fast", 0.3); _add("explode", 1); _ex_range = 45; time = 60
				5:
					_dir("rolling_fast", g, 180); _speed("rolling_fast", sp / 120.0, sp / 80.0, -0.2)
					_add("rolling_fast", 0.2); _ex_range = 180; time = ETERNAL
				6:
					_dir("rolling_fast", g, 180); _speed("rolling_fast", sp / 220.0, sp / 80.0, -0.2)
					_add("rolling_fast", 3); _add("explode", 1); time = 3
				7:
					_dir_abs("mist", 0.0, 360.0); _speed("mist", sp / 200.0, sp / 100.0, -0.1)
					_add("mist", 8); _add("atmosphere", 1); _ex_range = 180; time = 1
				8:
					_dir("ryfle", g, 160); _speed("ryfle", sp / 160.0, sp / 70.0, -0.2)
					_add("ryfle", 20); _ex_range = 160; time = 3
				9:
					_dir("weak_mist", g, 115); _speed("weak_mist", sp / 180.0, sp / 100.0, -0.2)
					_add("weak_mist", 0.3); _add("weak_atmosphere", 0.05)
					_ex_range = 115; time = ETERNAL
		3:
			match current_pattern:
				0:
					_dir("weak_shot", g, 45); _speed("weak_shot", sp / 240.0, sp / 100.0, -0.4)
					_add("weak_shot", 0.5); _ex_range = 45; time = 15
				1:
					_dir("weak_burst", g, 30); _speed("weak_burst", sp / 200.0, sp / 100.0, -0.1)
					_add("weak_burst", 1); _ex_range = 30; time = 60
				2:
					_dir("weak_burst", g, 30); _speed("weak_burst", sp / 200.0, sp / 70.0, -0.2)
					_add("weak_burst", 1); _ex_range = 30; time = 30
				3:
					_dir("laserburst", g, 5); _speed("laserburst", sp / 200.0, sp / 100.0, -0.05)
					_add("laserburst", 1); _ex_range = 5; time = ETERNAL
				4:
					_dir("starburst1", g, 35.0 * 1.5); _speed("starburst1", sp / 200.0, sp / 100.0, -0.05)
					_dir("starburst2", g, 35.0 * 0.7); _speed("starburst2", sp / 200.0, sp / 100.0, -0.05)
					_add("starburst1", 1); _add("starburst2", 1); _ex_range = 35; time = ETERNAL
				5:
					_dir("burst1", g, 70); _speed("burst1", sp / 150.0, sp / 80.0, -0.1)
					_add("burst1", 2); _ex_range = 70; time = 100
				6:
					_dir("weak_burst", g, 40); _speed("weak_burst", sp / 240.0, sp / 100.0, -0.1)
					_dir("laserburst", g, 5); _speed("laserburst", sp / 200.0, sp / 100.0, -0.05)
					_dir("starburst2", g, 20); _speed("starburst2", sp / 200.0, sp / 100.0, -0.05)
					_add("weak_burst", 1); _add("laserburst", 1); _add("starburst2", 1)
					_ex_range = 50; time = 90
				7:
					_dir("weak_mist", g, 45); _speed("weak_mist", sp / 220.0, sp / 100.0, -0.1)
					_add("weak_mist", 1); _ex_range = 45; time = 45
				8:
					_dir("weak_mist", g, 80); _speed("weak_mist", sp / 180.0, sp / 100.0, -0.2)
					_add("weak_mist", 1); _ex_range = 80; time = 45
				9:
					_dir("mist", g, 110); _speed("mist", sp / 180.0, sp / 100.0, -0.2)
					_add("mist", 1); _ex_range = 110; time = 45
		4:
			match current_pattern:
				0:
					_dir("gaslack", g, 15); _speed("gaslack", sp / 240.0, sp / 100.0, -0.2)
					_add("gaslack", 1); _ex_range = 15; time = 1
				1:
					_dir("gaslack", g, 165); _speed("gaslack", sp / 240.0, sp / 100.0, -0.2)
					_add("gaslack", 2); _ex_range = 165; time = 2
				2:
					_dir("ryfle", g, 5); _speed("ryfle", sp / 140.0, sp / 60.0, -0.2)
					_add("ryfle", 1); _ex_range = 5; time = 85
				3:
					_dir("weak_shot", g, 30); _speed("weak_shot", sp / 180.0, sp / 80.0, -0.2)
					_add("weak_shot", 1); _ex_range = 60; time = ETERNAL
				4:
					_dir("weak_mist", g, 5); _speed("weak_mist", sp / 160.0, sp / 90.0, -0.2)
					_add("weak_mist", 0.2); _ex_range = 5; time = 120
				5:
					_dir("weak_shot", g, 60); _speed("weak_shot", sp / 220.0, sp / 100.0, -0.2)
					_dir("ryfle", g, 60); _speed("ryfle", sp / 150.0, sp / 80.0, -0.2)
					_add("weak_shot", 0.5); _add("ryfle", 0.5); _ex_range = 60; time = 80
				6:
					_dir("ryfle", g, 5); _speed("ryfle", sp / 100.0, sp / 60.0, -0.2)
					_add("ryfle", 0.3); _ex_range = 5; time = 120
				7:
					_dir("weak_shot", g, 45.0 * 0.5); _speed("weak_shot", sp / 150.0, sp / 100.0, -0.1)
					_dir("weak_mist", g, 45); _speed("weak_mist", sp / 220.0, sp / 100.0, -0.1)
					_add("weak_shot", 1); _add("weak_mist", 1); _ex_range = 45; time = 45
				8:
					_dir("fire", g, 45); _speed("fire", sp / 160.0, sp / 100.0, -0.02)
					_add("fire", 2.5); _ex_range = 45; time = 200
				9:
					_dir("fire", g, 25); _speed("fire", sp / 130.0, sp / 70.0, -0.02)
					_add("fire", 2.8); _ex_range = 25; time = 200

	gas_name = pattern_label()
	if check:
		farting_time = time * gas_amount_scale

	if farting_time > 0.0:
		_emit()


func _emit() -> void:
	for entry in _pending:
		var key: String = entry[0]
		var t: ParticleType = ps.type_at(types[key])
		var base_size := _base_size()
		t.size_min = base_size
		t.size_max = base_size
		t.size_incr = float(type_size_incr.get(key, 0.0)) * gas_size_scale * _growth_factor()

		var shot_num: float = float(entry[1]) * gas_num_scale * _count_factor()
		var every := 0
		var count := 0
		if shot_num < 1.0:
			every = int(ceil(1.0 / maxf(shot_num, 0.0001)))
		else:
			count = int(ceil(shot_num))

		if every > 0:
			_particle_accum[key] = int(_particle_accum.get(key, 0)) + 1
			if int(_particle_accum[key]) >= every:
				_particle_accum[key] = 0
				count = 1
			else:
				count = 0
		if count > 0:
			ps.burst(hole_position, types[key], count)

		for i in extra_holes.size():
			var extra := extra_holes[i]
			var g2 := -rad_to_deg((target - extra).angle())
			if reverse_shot:
				g2 = fposmod(g2 + 180.0, 360.0)
			if _ex_range != 0.0:
				_dir(key, g2, _ex_range)
			if count > 0:
				ps.burst(extra, types[key], count)

		# Restore the main direction after the extra-hole pass.
		# (Pattern parameters are re-applied on the next frame anyway.)


# ---------------------------------------------------------------------------
# Particle type construction (the create_*_pt scripts)
# ---------------------------------------------------------------------------

func _new_type(key: String, shape: int) -> ParticleType:
	var idx := ps.add_type()
	var t := ps.type_at(idx)
	t.shape = shape
	types[key] = idx
	return t


func _random_color(t: ParticleType) -> void:
	var p: Array = PALETTE[_rng.randi_range(0, PALETTE.size() - 1)]
	if p.size() >= 3:
		t.set_color3(p[0], p[1], p[2])
	else:
		t.set_color2(p[0], p[1])
	if not palette_types.has(t.index):
		palette_types.append(t.index)


## set_pt_color2(): jitter each channel by +/-10% and assign to every particle
## type that the original kept in global.all_pt_list.
func apply_palette_color(c1: Color, c2: Color) -> void:
	for idx in palette_types:
		var t := ps.type_at(idx)
		if t == null:
			continue
		var a := _jitter(c1)
		var b := _jitter(c2)
		t.set_color2(a, b)


func reset_palette() -> void:
	for idx in palette_types:
		var t := ps.type_at(idx)
		if t != null:
			_random_color(t)


func _jitter(c: Color) -> Color:
	return Color(
		clampf(c.r * _rng.randf_range(0.9, 1.1), 0.0, 1.0),
		clampf(c.g * _rng.randf_range(0.9, 1.1), 0.0, 1.0),
		clampf(c.b * _rng.randf_range(0.9, 1.1), 0.0, 1.0),
		c.a)


func _make_shot(key: String, size: float, incr: float, life: float, speed: float, fric: float, dir: float, rng_deg: float, weak: bool) -> void:
	var t := _new_type(key, ParticleType.Shape.SMOKE)
	type_size_incr[key] = incr
	t.set_orientation(0, 0, 5, 10, true)
	t.set_size(size, size, incr, 0)
	t.set_life(life, life * 1.2)
	t.set_speed(speed, speed * 1.5, fric, 0)
	t.set_direction(dir - rng_deg / 2.0, dir + rng_deg / 2.0, 0, 0)
	_random_color(t)
	if weak:
		t.set_alpha2(0.3, 0.03)
	else:
		t.set_alpha2(0.9, 0.3)

	var shade := _new_type(key + "_shade", ParticleType.Shape.SMOKE)
	t.set_step(1, shade.index)
	var shade_life := 6.0 if weak else 10.0
	shade.set_size(0.5, 0.75, -0.02, 0)
	shade.set_life(shade_life, shade_life * 1.5)
	_random_color(shade)
	if weak:
		shade.set_alpha2(0.1, 0.01)
	else:
		shade.set_alpha2(0.3, 0.1)

	var leave := _new_type(key + "_leave", ParticleType.Shape.CLOUD)
	var leave_size: float = size + incr * life
	leave.set_size(leave_size, leave_size * 2.0, 0.1, 0)
	var leave_life := 6.0 if weak else 10.0
	leave.set_life(leave_life, leave_life * 2.0)
	leave.set_gravity(0.2 if weak else 0.5, 90)
	_random_color(leave)
	if weak:
		leave.set_alpha2(0.2, 0.01)
	else:
		leave.set_alpha2(0.7, 0.4)
	t.set_death(1, leave.index)


func _make_gaslack(key: String, size: float, incr: float, life: float, speed: float, fric: float, dir: float, rng_deg: float) -> void:
	var t := _new_type(key, ParticleType.Shape.EXPLOSION)
	type_size_incr[key] = incr
	t.set_size(size, size, incr, 0)
	t.set_life(life, life * 1.2)
	t.set_speed(speed, speed * 1.2, fric, 0)
	t.set_direction(dir - rng_deg / 2.0, dir + rng_deg / 2.0, 0, 0)
	t.set_alpha2(0.5, 0.3)

	var shade := _new_type(key + "_shade", ParticleType.Shape.SMOKE)
	shade.set_size(0.5, 0.75, -0.02, 0)
	shade.set_life(10, 15)
	shade.set_alpha2(0.2, 0.05)
	t.set_step(1, shade.index)

	var leave := _new_type(key + "_leave", ParticleType.Shape.CLOUD)
	var leave_size: float = size + incr * life
	leave.set_size(leave_size, leave_size * 2.0, 0.1, 0)
	leave.set_life(10, 20)
	leave.set_gravity(0.25, 90)
	leave.set_alpha2(0.4, 0.1)
	t.set_death(1, leave.index)


func _make_mist(key: String, size: float, incr: float, life: float, speed: float, fric: float, dir: float, rng_deg: float, weak: bool) -> void:
	var t := _new_type(key, ParticleType.Shape.EXPLOSION)
	type_size_incr[key] = incr
	t.set_size(size, size, incr, 0)
	t.set_life(life, life * 1.2)
	t.set_speed(speed, speed * 1.5, fric, 0)
	t.set_direction(dir - rng_deg / 2.0, dir + rng_deg / 2.0, 0, 0)
	_random_color(t)
	if weak:
		t.set_alpha3(0.25, 0.05, 0.01)
	else:
		t.set_alpha3(0.7, 0.1, 0.06)

	var shade := _new_type(key + "_shade", ParticleType.Shape.FLARE)
	t.set_step(-5, shade.index)
	var shade_life := 10.0 if weak else 20.0
	shade.set_size(size / 2.0, size / 2.0 * (1.3 if weak else 1.5), incr, 0)
	shade.set_life(shade_life, shade_life * (1.3 if weak else 1.5))
	_random_color(shade)
	if weak:
		shade.set_alpha2(0.1, 0.01)
	else:
		shade.set_alpha2(0.3, 0.1)

	var leave := _new_type(key + "_leave", ParticleType.Shape.CLOUD)
	var leave_size: float = size + incr * life
	leave.set_size(leave_size, leave_size * (1.5 if weak else 2.0), 0.1, 0)
	var leave_life := 40.0 if weak else 80.0
	leave.set_life(leave_life, leave_life * (1.5 if weak else 2.0))
	leave.set_gravity(0.05 if weak else 0.1, 90)
	_random_color(leave)
	if weak:
		leave.set_alpha2(0.2, 0.02)
	else:
		leave.set_alpha2(0.5, 0.2)
	t.set_death(1, leave.index)


func _make_smog(key: String, size: float, incr: float, life: float, speed: float, fric: float, dir: float, rng_deg: float) -> void:
	var t := _new_type(key, ParticleType.Shape.SMOKE)
	type_size_incr[key] = incr
	t.set_size(size, size, incr, 0)
	t.set_life(life, life * 1.2)
	t.set_speed(speed, speed * 1.5, fric, 0)
	t.set_direction(dir - rng_deg / 2.0, dir + rng_deg / 2.0, 0, 0)
	_random_color(t)
	t.set_alpha3(0.05, 0.4, 0.1)


func _make_rolling(key: String, size: float, incr: float, life: float, speed: float, fric: float, dir: float, rng_deg: float) -> void:
	var t := _new_type(key, ParticleType.Shape.EXPLOSION)
	type_size_incr[key] = incr
	t.set_size(size, size, incr, 0)
	t.set_life(life, life * 1.2)
	t.set_speed(speed, speed * 1.5, fric, 0)
	t.set_direction(dir - rng_deg / 2.0, dir + rng_deg / 2.0, 0, 0)
	_random_color(t)
	t.set_alpha2(0.7, 0.5)
	t.set_orientation(0, 0, 16, 10, true)

	var leave := _new_type(key + "_leave", ParticleType.Shape.EXPLOSION)
	var leave_size: float = size + incr * life
	leave.set_size(leave_size, leave_size * 2.0, 0.1, 0)
	leave.set_life(life / 2.0, life / 2.0)
	leave.set_gravity(0.1, 90)
	_random_color(leave)
	leave.set_alpha2(0.5, 0.01)
	t.set_death(1, leave.index)


func _make_burst(key: String, size: float, incr: float, life: float, speed: float, fric: float, dir: float, rng_deg: float, dir_incr: float, weak: bool) -> void:
	var t := _new_type(key, ParticleType.Shape.FLARE if not weak else ParticleType.Shape.EXPLOSION)
	type_size_incr[key] = incr
	t.set_orientation(0, 0, 8, 10, true)
	t.set_size(size, size, incr, 0)
	t.set_life(life, life * 1.2)
	t.set_speed(speed * 0.5, speed * 1.5, fric, 0)
	t.set_direction(dir - rng_deg / 2.0, dir + rng_deg / 2.0, dir_incr, 0)
	_random_color(t)
	t.set_alpha2(0.2 if weak else 0.6, 0.03 if weak else 0.3)

	var shade := _new_type(key + "_shade", ParticleType.Shape.SPHERE)
	var sh_size := 0.32 if weak else 0.4
	shade.set_size(sh_size, sh_size * 1.5, -0.01, 0)
	shade.set_life(5, 7.5)
	_random_color(shade)
	shade.set_alpha2(0.1 if weak else 0.3, 0.01 if weak else 0.1)
	t.set_step(1, shade.index)

	var leave := _new_type(key + "_leave", ParticleType.Shape.CLOUD)
	var leave_size: float = size + incr * life
	leave.set_size(leave_size, leave_size * (1.5 if weak else 2.0), 0.1, 0)
	if weak:
		leave.set_life(2.0, 6.0)
	else:
		leave.set_life(5, 10)
	leave.set_gravity(0.2, 90)
	_random_color(leave)
	leave.set_alpha2(0.2 if weak else 0.7, 0.04 if weak else 0.4)
	t.set_death(1, leave.index)


func _make_fire() -> void:
	var t := _new_type("fire", ParticleType.Shape.LINE)
	type_size_incr["fire"] = 0.04
	t.set_size(0.2, 0.6, 0.04, 0)
	t.set_scale_xy(0.65, 2.5)
	# GameMaker colours are 0xBBGGRR; converted here to RGB.
	t.set_color3(_gm_color(16749459), _gm_color(33023), _gm_color(255))
	t.set_alpha3(0.04, 0.06, 0.07)
	t.set_speed(4, 7, -0.02, 0)
	t.set_direction(-20, 10, 9, 0)
	t.set_gravity(0.08, 90)
	t.set_orientation(0, 0, 10, 20, true)
	t.additive = true
	t.set_life(60, 80)


static func _gm_color(value: int) -> Color:
	return Color8(value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF)


func _build_types() -> void:
	_make_shot("machinegun", 0.1, 0.06, 1.7 * 30.0, 15, -0.2, 10, 360, false)
	_make_shot("shotgun", 0.1, 0.06, 1.0 * 30.0, 15, -0.2, 2, 360, false)
	_make_shot("ryfle", 0.1, 0.06, 2.7 * 30.0, 20, -0.2, 0, 5, false)
	_make_shot("weak_shot", 0.1, 0.06, 1.4 * 30.0, 15, -0.2, 2, 360, true)
	_make_gaslack("gaslack", 0.1, 0.02, 1.4 * 30.0, 10, -0.1, 0, 5)
	_make_mist("mist", 0.1, 0.1, 2.0 * 30.0, 10, -0.1, 0, 30, false)
	_make_mist("storm", 0.1, 0.15, 3.3 * 30.0, 1, -0.2, 0, 30, false)
	_make_mist("atmosphere", 0.1, 0.25, 4.7 * 30.0, 1, -0.2, 0, 30, false)
	_make_mist("explode", 0.1, 0.5, 1.3 * 30.0, 1, -0.2, 0, 30, true)
	_make_mist("weak_mist", 0.1, 0.15, 2.4 * 30.0, 1, -0.2, 0, 30, true)
	_make_mist("weak_atmosphere", 0.1, 0.25, 4.0 * 30.0, 1, -0.2, 0, 180, true)
	_make_rolling("rolling_fast", 0.1, 0.6, 0.3 * 30.0, 1, -0.1, 0, 30)
	_make_rolling("rolling", 0.1, 0.1, 1.0 * 30.0, 1, -0.2, 0, 30)
	_make_smog("smog_huge", 0.1, 0.15, 5.0 * 30.0, 1, -0.2, 0, 30)
	_make_smog("smog", 0.1, 0.2, 3.0 * 30.0, 1, -0.2, 0, 30)
	_make_burst("burst1", 0.1, 0.05, 3.0 * 30.0, 6, -0.25, 0, 3.0 * 30.0, 0, false)
	_make_burst("burst2", 0.1, 0.05, 3.0 * 30.0, 6, -0.15, 0, 360, 0, false)
	_make_burst("weak_burst", 0.1, 0.05, 3.0 * 30.0, 4, -0.05, 0, 80, 0, true)
	_make_burst("laserburst", 0.1, 0.05, 3.0 * 30.0, 10, -0.05, 0, 5, 0, false)
	_make_burst("starburst1", 0.1, 0.05, 3.0 * 30.0, 10, -0.05, 30, 30, 0.3, false)
	_make_burst("starburst2", 0.1, 0.05, 3.0 * 30.0, 10, -0.05, 30, 30, -0.3, false)
	_make_fire()
	ps.type_at(types["burst1"]).set_gravity(0.2, 0)
