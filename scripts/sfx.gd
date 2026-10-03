extends Node

## Sonidos generados por código (sin archivos de audio): tonos simples con
## envolvente de caída. Es un autoload, así que se usa como `Sfx.ding()`.

const RATE := 22050


## "Ding" ascendente: se usa al completar un edificio.
func ding() -> void:
	_play(_tone(660.0, 0.25))


## "Coin": tono corto y brillante al vender (suena a moneda).
func coin() -> void:
	_play(_tone(1180.0, 0.1))


## "Upgrade": acorde ascendente (do + mi) al mejorar una construcción.
func upgrade() -> void:
	_play(_tone(523.0, 0.18))
	_play(_tone(659.0, 0.22))


## Reproduce `wav` y libera el reproductor cuando termina.
func _play(wav: AudioStreamWAV) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = wav
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


## Genera una onda senoidal de 16 bits (mono) con fade-out.
func _tone(freq: float, dur: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var pcm := PackedByteArray()
	pcm.resize(n * 2)
	for i in n:
		var t := float(i) / float(RATE)
		var env := 1.0 - float(i) / float(n)
		var s := int(sin(TAU * freq * t) * env * 12000.0)
		pcm.encode_s16(i * 2, s)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = pcm
	return wav
