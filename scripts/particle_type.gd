class_name ParticleType
extends RefCounted

## One particle type, mirroring the GameMaker 8 "part_type_*" settings.
##
## All values are given in the *original GameMaker units*: speed is pixels per
## 30 Hz game frame, life is measured in frames, size increments are per frame.
## ParticleSystem converts them to its fixed 60 Hz simulation step.

enum Shape {
	SMOKE,
	CLOUD,
	FLARE,
	SPHERE,
	EXPLOSION,
	LINE,
}

var index: int = -1
var shape: int = Shape.SMOKE

# part_type_size(size_min, size_max, size_incr, size_wiggle)
var size_min: float = 1.0
var size_max: float = 1.0
var size_incr: float = 0.0
var size_wiggle: float = 0.0

# part_type_scale(xscale, yscale)
var scale_x: float = 1.0
var scale_y: float = 1.0

# part_type_life(life_min, life_max)
var life_min: float = 100.0
var life_max: float = 100.0

# part_type_speed(speed_min, speed_max, speed_incr, speed_wiggle)
var speed_min: float = 0.0
var speed_max: float = 0.0
var speed_incr: float = 0.0
var speed_wiggle: float = 0.0

# part_type_direction(dir_min, dir_max, dir_incr, dir_wiggle)
var dir_min: float = 0.0
var dir_max: float = 360.0
var dir_incr: float = 0.0
var dir_wiggle: float = 0.0

# part_type_gravity(amount, direction)
var gravity: float = 0.0
var gravity_dir: float = 270.0

# part_type_color1/2/3 and part_type_alpha1/2/3
var color1: Color = Color.WHITE
var color2: Color = Color.WHITE
var color3: Color = Color.WHITE
var alpha1: float = 1.0
var alpha2: float = 1.0
var alpha3: float = 1.0

# part_type_orientation(angle_min, angle_max, incr, wiggle, relative)
var orientation_min: float = 0.0
var orientation_max: float = 0.0
var orientation_incr: float = 0.0
var orientation_wiggle: float = 0.0
var orientation_relative: bool = false

# part_type_blend(additive)
var additive: bool = false

# part_type_step(step_number, step_type)
var step_number: int = 0
var step_type: int = -1

# part_type_death(death_number, death_type)
var death_number: int = 0
var death_type: int = -1


func set_shape(new_shape: int) -> void:
	shape = new_shape


func set_scale_xy(x: float, y: float) -> void:
	scale_x = x
	scale_y = y


func set_size(smin: float, smax: float, incr: float, wiggle: float) -> void:
	size_min = smin
	size_max = smax
	size_incr = incr
	size_wiggle = wiggle


func set_life(lmin: float, lmax: float) -> void:
	life_min = lmin
	life_max = lmax


func set_speed(smin: float, smax: float, incr: float, wiggle: float) -> void:
	speed_min = smin
	speed_max = smax
	speed_incr = incr
	speed_wiggle = wiggle


func set_direction(dmin: float, dmax: float, incr: float, wiggle: float) -> void:
	dir_min = dmin
	dir_max = dmax
	dir_incr = incr
	dir_wiggle = wiggle


func set_gravity(amount: float, direction: float) -> void:
	gravity = amount
	gravity_dir = direction


func set_color2(col1: Color, col2: Color) -> void:
	color1 = col1
	color2 = col2
	color3 = col2


func set_color3(col1: Color, col2: Color, col3: Color) -> void:
	color1 = col1
	color2 = col2
	color3 = col3


func set_alpha2(a1: float, a2: float) -> void:
	alpha1 = a1
	alpha2 = a2
	alpha3 = a2


func set_alpha3(a1: float, a2: float, a3: float) -> void:
	alpha1 = a1
	alpha2 = a2
	alpha3 = a3


func set_orientation(amin: float, amax: float, incr: float, wiggle: float, relative: bool) -> void:
	orientation_min = amin
	orientation_max = amax
	orientation_incr = incr
	orientation_wiggle = wiggle
	orientation_relative = relative


func set_step(number: int, next_type: int) -> void:
	step_number = number
	step_type = next_type


func set_death(number: int, next_type: int) -> void:
	death_number = number
	death_type = next_type


## Colour of the particle at `progress` (0 = birth, 1 = death), matching the
## GameMaker 3-colour interpolation.
func color_at(progress: float) -> Color:
	var c1: Color
	var c2: Color
	var t: float
	if progress < 0.5:
		c1 = color1
		c2 = color2
		t = progress * 2.0
	else:
		c1 = color2
		c2 = color3
		t = (progress - 0.5) * 2.0
	return c1.lerp(c2, clampf(t, 0.0, 1.0))


func alpha_at(progress: float) -> float:
	if progress < 0.5:
		return lerpf(alpha1, alpha2, clampf(progress * 2.0, 0.0, 1.0))
	return lerpf(alpha2, alpha3, clampf((progress - 0.5) * 2.0, 0.0, 1.0))
