class_name WavLoader
extends RefCounted

## Loads WAV files chosen at runtime (from the assets/sound folders) into
## AudioStreamWAV resources. This is the Godot counterpart of GameMaker's
## sound_add(): user supplied files do not need to be imported by the editor.
##
## Supports uncompressed PCM (8/16/24/32 bit) and IEEE float WAV files.

static func load_wav(path: String) -> AudioStreamWAV:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var size := f.get_length()
	if size < 44:
		return null
	var bytes := f.get_buffer(size)
	f.close()

	if bytes.slice(0, 4).get_string_from_ascii() != "RIFF":
		return null
	if bytes.slice(8, 12).get_string_from_ascii() != "WAVE":
		return null

	var channels := 0
	var sample_rate := 0
	var bits := 0
	var fmt_tag := 0
	var data := PackedByteArray()

	var off := 12
	while off + 8 <= bytes.size():
		var id := bytes.slice(off, off + 4).get_string_from_ascii()
		var chunk_size := bytes.decode_u32(off + 4)
		var body := off + 8
		if body + chunk_size > bytes.size():
			chunk_size = bytes.size() - body
		if id == "fmt ":
			if chunk_size >= 16:
				fmt_tag = bytes.decode_u16(body)
				channels = bytes.decode_u16(body + 2)
				sample_rate = bytes.decode_u32(body + 4)
				bits = bytes.decode_u16(body + 14)
				if fmt_tag == 0xFFFE and chunk_size >= 26:
					# WAVE_FORMAT_EXTENSIBLE: the real format follows the guid
					fmt_tag = bytes.decode_u16(body + 24)
		elif id == "data":
			data = bytes.slice(body, body + chunk_size)
		off = body + chunk_size + (chunk_size & 1)

	if channels <= 0 or sample_rate <= 0 or data.is_empty():
		return null
	if bits != 8 and bits != 16 and bits != 24 and bits != 32:
		return null
	if fmt_tag != 1 and fmt_tag != 3:
		return null

	var bytes_per_sample := bits / 8
	var frame_bytes := bytes_per_sample * channels
	if frame_bytes <= 0:
		return null
	var frames := data.size() / frame_bytes
	var out_channels := mini(channels, 2)
	var out := PackedByteArray()
	out.resize(frames * out_channels * 2)

	var is_float := fmt_tag == 3
	for i in frames:
		var base := i * frame_bytes
		for c in out_channels:
			var s := base + c * bytes_per_sample
			var v := 0.0
			if is_float and bits == 32:
				v = data.decode_float(s)
			elif bits == 8:
				v = (float(data[s]) - 128.0) / 128.0
			elif bits == 16:
				v = float(data.decode_s16(s)) / 32768.0
			elif bits == 24:
				var raw := data[s] | (data[s + 1] << 8) | (data[s + 2] << 16)
				if raw & 0x800000:
					raw -= 0x1000000
				v = float(raw) / 8388608.0
			else:
				v = float(data.decode_s32(s)) / 2147483648.0
			var iv := int(clampf(v, -1.0, 1.0) * 32767.0)
			var o := (i * out_channels + c) * 2
			out.encode_s16(o, iv)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = out_channels == 2
	stream.data = out
	return stream
