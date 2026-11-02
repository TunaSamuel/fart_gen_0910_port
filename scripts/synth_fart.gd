class_name SynthFart
extends RefCounted

## The decompiled project ships no fart samples (its sound folders are filled
## with the player's own WAVs). So that a fresh checkout is not silent, a few
## fart noises are synthesised as a fallback. Real files in assets/sound/*
## always take priority.

const RATE := 22050


static func make(seed_value: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var duration := rng.randf_range(0.55, 1.35)
	var frames := int(duration * RATE)
	var data := PackedByteArray()
	data.resize(frames * 2)

	var base_freq := rng.randf_range(62.0, 128.0)
	var wobble_rate := rng.randf_range(7.0, 19.0)
	var wobble_depth := rng.randf_range(0.02, 0.09)
	var noise_mix := rng.randf_range(0.35, 0.7)
	var bubbles := rng.randf_range(11.0, 34.0)

	var phase := 0.0
	var lp := 0.0
	var lp2 := 0.0
	for i in frames:
		var t := float(i) / RATE
		var p := t / duration
		var env := pow(clampf(1.0 - p, 0.0, 1.0), 1.35)
		env *= 0.65 + 0.35 * sin(t * wobble_rate * TAU)
		env *= clampf(p * 40.0, 0.0, 1.0)  # tiny attack
		var freq := base_freq * (1.0 - 0.32 * p)
		freq *= 1.0 + wobble_depth * sin(t * wobble_rate * TAU * 0.5)
		phase += TAU * freq / RATE
		var tone := sin(phase) * 0.6 + sin(phase * 2.0) * 0.25 + sin(phase * 3.0) * 0.12
		var nz := rng.randf_range(-1.0, 1.0)
		lp += (nz - lp) * 0.16
		lp2 += (lp - lp2) * clampf(0.06 + 0.12 * absf(sin(t * bubbles * TAU)), 0.01, 0.4)
		var wet := lp2 * 3.0 * (1.0 - 0.4 * p)
		var sample := (tone * (1.0 - noise_mix) + wet * noise_mix) * env * 0.85
		var iv := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, iv)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
