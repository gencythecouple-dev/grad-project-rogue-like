extends Node

@onready var hit_sfx: AudioStreamPlayer = $HitSFX
@onready var knife_sfx: AudioStreamPlayer = $KnifeSFX
@onready var explosion_sfx: AudioStreamPlayer = $ExplosionSFX
@onready var power_up_sfx: AudioStreamPlayer = $PowerUpSFX
@onready var holy_smite_sfx: AudioStreamPlayer = $HolySmiteSFX
@onready var hammer_swing_sfx: AudioStreamPlayer = $HammerSwingSFX
@onready var hammer_spike_sfx: AudioStreamPlayer = $HammerSpikeSFX
@onready var game_over_sfx: AudioStreamPlayer = $GameOver
@onready var sword_sfx: AudioStreamPlayer = $SwordSwingSFX
@onready var sword_aura_sfx: AudioStreamPlayer = $SwordAuraSFX
@onready var throw_sfx: AudioStreamPlayer = $ThrowSFX
@onready var star_sfx: AudioStreamPlayer = $StarFallSFX
@onready var magic_bullet_sfx: AudioStreamPlayer = $MagicBulletSFX
@onready var lightning_ball_sfx: AudioStreamPlayer =$LightningBallSFX
@onready var gold_pick_up_sfx: AudioStreamPlayer =$GoldPickUpSFX
@onready var damage_up_vfx: AudioStreamPlayer = $DamageUpSFX
@onready var level_up_sfx: AudioStreamPlayer = $LevelUpSFX
@onready var ui_hover_sfx: AudioStreamPlayer = $UIHoverSFX
@onready var ui_click_sfx: AudioStreamPlayer = $UIClickSFX
@onready var ui_buy_sfx: AudioStreamPlayer = $UIBuySFX
@onready var menu_bgm: AudioStreamPlayer = $MenuBGM
@onready var exp_sfx: AudioStreamPlayer = $EXPSFX


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var master = config.get_value("audio", "master", 100)
		var sfx = config.get_value("audio", "sfx", 100)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("Master"),
			linear_to_db(master / 100.0)
		)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("SFX"),
			linear_to_db(sfx / 100.0)
		)
	hit_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Enemy_Hit.wav")
	explosion_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Explosion.wav")
	game_over_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Game_Over.mp3")
	hammer_spike_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Hammer_Spike.mp3")
	hammer_swing_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Hammer_swing.mp3")
	holy_smite_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Holy_Smite.wav")
	knife_sfx.stream = preload("res://Assets/BGM_SFX/SFX/knife.mp3")
	power_up_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Power_Up.wav")
	sword_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Sword.mp3")
	sword_aura_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Sword.mp3")
	throw_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Throw.wav")
	star_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Star_Fall.wav")
	magic_bullet_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Magic_bullet.wav")
	lightning_ball_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Lightning_Ball.wav")
	gold_pick_up_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Coin.wav")
	damage_up_vfx.stream = preload("res://Assets/BGM_SFX/SFX/Damage_Up.wav")
	level_up_sfx.stream = preload("res://Assets/BGM_SFX/SFX/Level_Up.wav")
	ui_hover_sfx.stream = preload("res://Assets/BGM_SFX/UI/ui_hover.wav")
	ui_click_sfx.stream = preload("res://Assets/BGM_SFX/UI/ui_click.wav")
	ui_buy_sfx.stream = preload("res://Assets/BGM_SFX/UI/ui_buy.wav")
	menu_bgm.stream = preload("res://Assets/BGM_SFX/BGM/Menu_BGM.ogg")
	menu_bgm.autoplay = true
	menu_bgm.stream.loop = true
	exp_sfx.stream = preload("res://Assets/BGM_SFX/SFX/EXP.wav")

func play_hit() -> void:
	hit_sfx.pitch_scale = randf_range(0.9, 1.1)
	hit_sfx.play()

func play_explosion() -> void:
	explosion_sfx.pitch_scale = randf_range(0.9, 1.1)
	explosion_sfx.play()

func play_game_over() -> void:
	game_over_sfx.play()

func play_hammer_spike() -> void:
	hammer_spike_sfx.pitch_scale = randf_range(0.9, 1.1)
	hammer_spike_sfx.play()

func play_hammer_swing() -> void:
	hammer_swing_sfx.pitch_scale = randf_range(0.9, 1.1)
	hammer_swing_sfx.play()

func play_holy_smite() -> void:
	holy_smite_sfx.pitch_scale = randf_range(0.95, 1.05)
	holy_smite_sfx.play()

func play_knife() -> void:
	knife_sfx.pitch_scale = randf_range(0.9, 1.1)
	knife_sfx.play()

func play_power_up() -> void:
	power_up_sfx.play()

func play_sword() -> void:
	sword_sfx.pitch_scale = randf_range(0.9, 1.1)
	sword_sfx.play()

func play_sword_aura() -> void:
	sword_aura_sfx.pitch_scale = randf_range(0.9, 1.1)
	sword_aura_sfx.play()

func play_throw() -> void:
	throw_sfx.pitch_scale = randf_range(0.9, 1.1)
	throw_sfx.play()
	
func play_star() -> void:
	star_sfx.pitch_scale = randf_range(0.9 , 1.1)
	star_sfx.play()
	
func play_magic_bullet() -> void:
	magic_bullet_sfx.pitch_scale = randf_range(0.9 , 1.1)
	magic_bullet_sfx.play()

func play_lightning_ball() -> void:
	lightning_ball_sfx.pitch_scale = randf_range (0.9 , 1.1)
	lightning_ball_sfx.play()

func play_gold_pick_up() -> void:
	gold_pick_up_sfx.pitch_scale = randf_range (0.9 , 1.1)
	gold_pick_up_sfx.play()

func play_damage_up() -> void:
	damage_up_vfx.pitch_scale = randf_range (0.9 , 1.1)
	damage_up_vfx.play()

func play_level_up() -> void:
	level_up_sfx.pitch_scale = randf_range (0.9 , 1.1)
	level_up_sfx.play()

func play_ui_hover() -> void:
	ui_hover_sfx.pitch_scale = randf_range(0.9, 1.1)
	ui_hover_sfx.play()

func play_ui_click() -> void:
	ui_click_sfx.play()

func play_ui_buy() -> void:
	ui_buy_sfx.play()


func play_menu_bgm() -> void:
	if menu_bgm.playing:
		return
	menu_bgm.play()

func stop_menu_bgm() -> void:
	menu_bgm.stop()

func play_exp_sfx() -> void:
	exp_sfx.pitch_scale = randf_range(0.9 , 1.1)
	exp_sfx.play()
