extends Node

@onready var bgm_player = AudioStreamPlayer.new()

var current_bgm: AudioStream = null

func _ready():
	add_child(bgm_player)
	bgm_player.bus = "BGM"

func play_bgm(stream: AudioStream):
	# 🔒 Prevent restarting same music
	if current_bgm == stream and bgm_player.playing:
		return
	
	bgm_player.stop()
	bgm_player.stream = stream
	bgm_player.play()
	current_bgm = stream

func stop_bgm():
	bgm_player.stop()
	current_bgm = null
