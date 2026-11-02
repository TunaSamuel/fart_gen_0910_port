class_name ShapeTextures
extends RefCounted

## GameMaker 8 ships a set of built-in particle shapes (pt_shape_smoke,
## pt_shape_cloud, ...). Those bitmaps are not part of the decompiled project,
## so equivalent white sprites are generated procedurally here. They are tinted
## per particle, exactly like the originals.

const SIZE := 64

static var _cache: Dictionary = {}


static func get_texture(shape: int) -> Texture2D:
	if _cache.has(shape):
		return _cache[shape]
	var img := _make(shape)
	var tex := ImageTexture.create_from_image(img)
	_cache[shape] = tex
	return tex


static func _hash2(x: int, y: int) -> float:
	var h := x * 374761393 + y * 668265263
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(h & 0xFFFF) / 65535.0


static func _value_noise(x: float, y: float) -> float:
	var xi := int(floor(x))
	var yi := int(floor(y))
	var xf := x - xi
	var yf := y - yi
	var u := xf * xf * (3.0 - 2.0 * xf)
	var v := yf * yf * (3.0 - 2.0 * yf)
	var a := _hash2(xi, yi)
	var b := _hash2(xi + 1, yi)
	var c := _hash2(xi, yi + 1)
	var d := _hash2(xi + 1, yi + 1)
	return lerpf(lerpf(a, b, u), lerpf(c, d, u), v)


static func _fbm(x: float, y: float) -> float:
	var total := 0.0
	var amp := 0.5
	var freq := 1.0
	for i in 3:
		total += _value_noise(x * freq, y * freq) * amp
		freq *= 2.03
		amp *= 0.5
	return total


static func _make(shape: int) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var half := float(SIZE) * 0.5
	for py in SIZE:
		for px in SIZE:
			var nx := (float(px) + 0.5 - half) / half
			var ny := (float(py) + 0.5 - half) / half
			var r := sqrt(nx * nx + ny * ny)
			var angle := atan2(ny, nx)
			var noise := _fbm(nx * 3.0 + 11.0, ny * 3.0 + 7.0)
			var a := 0.0
			match shape:
				ParticleType.Shape.SMOKE:
					var edge := 0.62 + 0.22 * (noise - 0.5)
					a = 1.0 - smoothstep(edge * 0.35, edge, r)
					a *= 0.55 + 0.45 * noise
				ParticleType.Shape.CLOUD:
					var edge2 := 0.78 + 0.16 * (noise - 0.5)
					a = pow(clampf(1.0 - r / edge2, 0.0, 1.0), 1.6)
					a *= 0.6 + 0.4 * noise
				ParticleType.Shape.FLARE:
					a = exp(-r * r * 26.0)
					var spikes := pow(abs(cos(angle * 2.0)), 28.0) + pow(abs(sin(angle * 2.0)), 28.0)
					a += spikes * exp(-r * 3.2) * 0.75
					a = clampf(a, 0.0, 1.0)
				ParticleType.Shape.SPHERE:
					a = 1.0 - smoothstep(0.72, 1.0, r)
					a *= 0.35 + 0.65 * exp(-r * r * 4.0)
					a += (1.0 - smoothstep(0.55, 0.75, r)) * 0.0
				ParticleType.Shape.EXPLOSION:
					var spikes2 := 0.55 + 0.45 * (0.5 + 0.5 * sin(angle * 11.0 + noise * 4.0))
					var edge3 := 0.55 + 0.4 * spikes2
					a = 1.0 - smoothstep(edge3 * 0.2, edge3, r)
					a *= 0.5 + 0.5 * noise
				ParticleType.Shape.LINE:
					var band := exp(-pow(nx * 5.0, 2.0))
					var fall := 1.0 - smoothstep(0.75, 1.0, abs(ny))
					a = band * fall
			a = clampf(a, 0.0, 1.0)
			img.set_pixel(px, py, Color(1, 1, 1, a))
	return img
