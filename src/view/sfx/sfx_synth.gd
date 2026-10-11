class_name SfxSynth
## Placeholder sound effects synthesized in code (no audio assets yet): short 16-bit mono
## clips built from noise, sines and decay envelopes. Replaced when real SFX exist.

const MIX_RATE := 22050


## A sound: `seconds` long; `tone` Hz at the start sliding to `tone_end` (0 = no tone);
## `noise` 0..1 share of white noise; `smooth` 0..1 low-pass on the noise; `decay` how fast
## it fades (higher = shorter).
static func make(seconds: float, tone: float, tone_end: float, noise: float, smooth: float, decay: float,
		volume := 0.8, seed_value := 1) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var count := int(seconds * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	var filtered := 0.0
	for i in count:
		var progress := float(i) / count
		var envelope := exp(-decay * progress) * minf(1.0, i / (0.004 * MIX_RATE))
		var frequency := lerpf(tone, tone_end, progress)
		phase += TAU * frequency / MIX_RATE
		var sample := sin(phase) * (1.0 - noise) if tone > 0.0 else 0.0
		filtered = lerpf(rng.randf_range(-1.0, 1.0), filtered, smooth)
		sample += filtered * noise * (1.0 + smooth * 2.0)
		data.encode_s16(i * 2, int(clampf(sample * envelope * volume, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
