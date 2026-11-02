class_name ParticleSystem
extends Node2D

## A small CPU particle engine that reproduces the GameMaker 8 particle
## functions used by Fart Generator: particle types with size/speed/direction
## ranges and per-frame increments, gravity, 3-colour fades, step (trail) types,
## death types, orientation and additive blending.
##
## GameMaker's parameters are expressed per 30 Hz frame. This engine simulates
## at a fixed 60 Hz so motion stays smooth on modern displays; conversion
## happens when a particle is spawned (see SPAWN_* constants).

const MAX_PARTICLES := 14000
const STEPS_PER_SECOND := 60.0
const STEP_TIME := 1.0 / STEPS_PER_SECOND

## Native pixel size of a shape texture at particle size 1.0 (GameMaker's
## built-in particle shapes are roughly this size on a 1024x768 room).
const NATIVE_SIZE := 32.0

# GameMaker frame units -> simulation step units.
const LIFE_TO_SEC := 1.0 / 30.0
const SPEED_TO_STEP := 0.5
const INC_TO_STEP := 0.25
const SIZE_INC_TO_STEP := 0.5
const ROT_INC_TO_STEP := 0.5

var _types: Array[ParticleType] = []

# Structure of arrays for the live particles.
var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _life := PackedFloat32Array()
var _life0 := PackedFloat32Array()
var _size := PackedFloat32Array()
var _size_incr := PackedFloat32Array()
var _size_wiggle := PackedFloat32Array()
var _rot := PackedFloat32Array()
var _rot_incr := PackedFloat32Array()
var _rot_wiggle := PackedFloat32Array()
var _type := PackedInt32Array()
var _step_acc := PackedInt32Array()
var _dir_wiggle := PackedFloat32Array()
var _scale_x := PackedFloat32Array()
var _scale_y := PackedFloat32Array()

var _rng := RandomNumberGenerator.new()
var _accum := 0.0

# shape/additive buckets: key -> MultiMeshInstance2D
var _buckets: Dictionary = {}
var _counts: Dictionary = {}


func _ready() -> void:
	_rng.randomize()
	_build_buckets()
	set_process(true)


func _build_buckets() -> void:
	for shape in ParticleType.Shape.values():
		for additive in [false, true]:
			var key := _bucket_key(shape, additive)
			var quad := QuadMesh.new()
			quad.size = Vector2(NATIVE_SIZE, NATIVE_SIZE)
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_2D
			mm.use_colors = true
			mm.mesh = quad
			var mmi := MultiMeshInstance2D.new()
			mmi.multimesh = mm
			mmi.texture = ShapeTextures.get_texture(shape)
			var mat := CanvasItemMaterial.new()
			if additive:
				mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			else:
				mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
			mmi.material = mat
			mmi.visible = false
			add_child(mmi)
			_buckets[key] = mmi
			_counts[key] = 0


static func _bucket_key(shape: int, additive: bool) -> int:
	return int(shape) * 2 + (1 if additive else 0)


## Create and register a new particle type. Returns its index.
func add_type() -> int:
	var t := ParticleType.new()
	t.index = _types.size()
	_types.append(t)
	return t.index


func type_at(index: int) -> ParticleType:
	if index < 0 or index >= _types.size():
		return null
	return _types[index]


func type_count() -> int:
	return _types.size()


func alive_count() -> int:
	return _life.size()


func clear() -> void:
	for arr in [_pos, _vel, _life, _life0, _size, _size_incr, _size_wiggle,
			_rot, _rot_incr, _rot_wiggle, _step_acc, _dir_wiggle, _scale_x, _scale_y]:
		arr.clear()
	_type.clear()


func _process(delta: float) -> void:
	_accum += minf(delta, 0.25)
	var steps := 0
	while _accum >= STEP_TIME and steps < 8:
		_step()
		_accum -= STEP_TIME
		steps += 1
	_draw_particles()


## Spawn `count` particles of `type_index` at `pos`.
func burst(pos: Vector2, type_index: int, count: int) -> void:
	var t := type_at(type_index)
	if t == null:
		return
	for i in maxi(count, 0):
		if _life.size() >= MAX_PARTICLES:
			return
		_spawn(pos, t)


func _spawn(pos: Vector2, t: ParticleType) -> void:
	var life_frames := _rng.randf_range(t.life_min, t.life_max)
	if life_frames <= 0.0:
		life_frames = 1.0
	var life := life_frames * LIFE_TO_SEC
	var speed := _rng.randf_range(t.speed_min, t.speed_max) * SPEED_TO_STEP
	var dir := _rng.randf_range(t.dir_min, t.dir_max)
	var size := _rng.randf_range(t.size_min, t.size_max)
	_size.append(size)
	_size_incr.append(t.size_incr * SIZE_INC_TO_STEP)
	_size_wiggle.append(t.size_wiggle * SPEED_TO_STEP)
	_life.append(life)
	_life0.append(life)
	_pos.append(pos)
	_vel.append(Vector2(cos(deg_to_rad(dir)), -sin(deg_to_rad(dir))) * speed)
	_rot.append(_rng.randf_range(t.orientation_min, t.orientation_max))
	_rot_incr.append(t.orientation_incr * ROT_INC_TO_STEP)
	_rot_wiggle.append(t.orientation_wiggle * SPEED_TO_STEP)
	_type.append(t.index)
	_step_acc.append(0)
	_dir_wiggle.append(t.dir_wiggle * SPEED_TO_STEP)
	_scale_x.append(t.scale_x)
	_scale_y.append(t.scale_y)


func _step() -> void:
	# Iterate backwards so swap-removal never skips a particle. Particles spawned
	# as trails during the step land at the end of the arrays; because they are
	# only visited if their index is still below the cursor they start moving on
	# the next step.
	var i := _life.size() - 1
	while i >= 0:
		if i >= _life.size():
			i -= 1
			continue
		_life[i] -= STEP_TIME
		if _life[i] <= 0.0:
			_emit_death(i)
			_remove_at(i)
			i -= 1
			continue

		var t := _types[_type[i]]
		var v := _vel[i]
		var speed := v.length()
		if speed > 0.0001:
			speed = maxf(0.0, speed + t.speed_incr * INC_TO_STEP)
			v = v / v.length() * speed
			if _dir_wiggle[i] != 0.0:
				v = v.rotated(deg_to_rad(_rng.randf_range(-_dir_wiggle[i], _dir_wiggle[i])))
		elif t.speed_min > 0.0 or t.speed_max > 0.0:
			var d := _rng.randf_range(t.dir_min, t.dir_max)
			speed = _rng.randf_range(t.speed_min, t.speed_max) * SPEED_TO_STEP
			v = Vector2(cos(deg_to_rad(d)), -sin(deg_to_rad(d))) * speed
		if t.gravity != 0.0:
			var gdir := deg_to_rad(t.gravity_dir)
			v += Vector2(cos(gdir), -sin(gdir)) * t.gravity * INC_TO_STEP
		_vel[i] = v
		_pos[i] += v

		_size[i] = maxf(0.0, _size[i] + _size_incr[i])
		if _size_wiggle[i] != 0.0:
			_size[i] = maxf(0.0, _size[i] + _rng.randf_range(-_size_wiggle[i], _size_wiggle[i]))
		_rot[i] += _rot_incr[i]
		if _rot_wiggle[i] != 0.0:
			_rot[i] += _rng.randf_range(-_rot_wiggle[i], _rot_wiggle[i])

		# part_type_step: a positive number emits N particles per 30 Hz frame, a
		# negative number emits one particle every |N| frames.
		if t.step_type >= 0 and t.step_number != 0:
			_step_acc[i] += 1
			var every := 2 if t.step_number > 0 else absi(t.step_number) * 2
			if _step_acc[i] >= every:
				_step_acc[i] = 0
				var amount := t.step_number if t.step_number > 0 else 1
				for k in amount:
					if _life.size() >= MAX_PARTICLES:
						break
					_spawn(_pos[i], _types[t.step_type])
		i -= 1


func pos_at(i: int) -> Vector2:
	return _pos[i]


func _emit_death(i: int) -> void:
	var t := _types[_type[i]]
	if t.death_type >= 0 and t.death_number > 0:
		var nt := _types[t.death_type]
		for k in t.death_number:
			if _life.size() >= MAX_PARTICLES:
				return
			_spawn(_pos[i], nt)


func _remove_at(i: int) -> void:
	var last := _life.size() - 1
	if i != last:
		_pos[i] = _pos[last]
		_vel[i] = _vel[last]
		_life[i] = _life[last]
		_life0[i] = _life0[last]
		_size[i] = _size[last]
		_size_incr[i] = _size_incr[last]
		_size_wiggle[i] = _size_wiggle[last]
		_rot[i] = _rot[last]
		_rot_incr[i] = _rot_incr[last]
		_rot_wiggle[i] = _rot_wiggle[last]
		_type[i] = _type[last]
		_step_acc[i] = _step_acc[last]
		_dir_wiggle[i] = _dir_wiggle[last]
		_scale_x[i] = _scale_x[last]
		_scale_y[i] = _scale_y[last]
	_pos.resize(last)
	_vel.resize(last)
	_life.resize(last)
	_life0.resize(last)
	_size.resize(last)
	_size_incr.resize(last)
	_size_wiggle.resize(last)
	_rot.resize(last)
	_rot_incr.resize(last)
	_rot_wiggle.resize(last)
	_type.resize(last)
	_step_acc.resize(last)
	_dir_wiggle.resize(last)
	_scale_x.resize(last)
	_scale_y.resize(last)


func _draw_particles() -> void:
	for key in _counts:
		_counts[key] = 0
	# First pass: count instances per shape/blend bucket.
	for i in _life.size():
		var t := _types[_type[i]]
		var key := _bucket_key(t.shape, t.additive)
		_counts[key] = int(_counts.get(key, 0)) + 1

	for key in _counts:
		var n := int(_counts[key])
		var mmi: MultiMeshInstance2D = _buckets[key]
		var mm := mmi.multimesh
		if n == 0:
			mmi.visible = false
			if mm.instance_count != 0:
				mm.instance_count = 0
			continue
		mmi.visible = true
		if mm.instance_count != n:
			mm.instance_count = n
		mm.visible_instance_count = n
		_counts[key] = 0

	# Second pass: fill transforms and colours. Newest particles are drawn
	# first, which matches part_system_draw_order(ps, false).
	for i in range(_life.size() - 1, -1, -1):
		var t := _types[_type[i]]
		var key := _bucket_key(t.shape, t.additive)
		var slot := int(_counts[key])
		_counts[key] = slot + 1
		var progress := clampf(1.0 - _life[i] / maxf(_life0[i], 0.0001), 0.0, 1.0)
		var col := t.color_at(progress)
		col.a = t.alpha_at(progress)
		var rot := deg_to_rad(_rot[i])
		var sx := maxf(_size[i], 0.0) * _scale_x[i]
		var sy := maxf(_size[i], 0.0) * _scale_y[i]
		if t.orientation_relative and _vel[i].length_squared() > 0.000001:
			rot += atan2(-_vel[i].y, _vel[i].x)
		var xf := Transform2D()
		xf.x = Vector2(cos(rot), sin(rot)) * sx
		xf.y = Vector2(-sin(rot), cos(rot)) * sy
		xf.origin = _pos[i]
		var mmi: MultiMeshInstance2D = _buckets[key]
		var mm := mmi.multimesh
		mm.set_instance_transform_2d(slot, xf)
		mm.set_instance_color(slot, col)


## Set additive blending on every particle type (the "B" toggle).
func set_all_additive(enabled: bool) -> void:
	for t in _types:
		t.additive = enabled
