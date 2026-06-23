extends Node2D

signal battle_ended(win: bool, gems: int, trophies: int, is_boss: bool)

var _player: BattleBot
var _enemies: Array[BattleBot] = []
var _arena_id: int = 0
var _is_boss_fight: bool = false
var _battle_over: bool = false

@onready var _arena_bg: ColorRect = $ArenaBG
@onready var _hud: CanvasLayer = $HUD
@onready var _player_hp_label: Label = $HUD/TopBar/PlayerHP
@onready var _enemy_hp_label: Label = $HUD/TopBar/EnemyHP
@onready var _weapon_label: Label = $HUD/TopBar/WeaponLabel
@onready var _info_label: Label = $HUD/InfoLabel
@onready var _result_panel: PanelContainer = $HUD/ResultPanel
@onready var _result_label: Label = $HUD/ResultPanel/VBox/ResultLabel
@onready var _continue_btn: Button = $HUD/ResultPanel/VBox/ContinueBtn


func _ready() -> void:
	var pending := AccountManager.pending_battle
	_arena_id = pending.get("arena_id", AccountManager.get_current_arena())
	_is_boss_fight = pending.get("boss", false)
	AccountManager.pending_battle = {}
	var arena := GameData.get_arena(_arena_id)
	if not arena.is_empty():
		_arena_bg.color = arena.bg_color
		_info_label.text = arena.name + (" - BOSS FIGHT" if _is_boss_fight else " - Battle")
	UIHelpers.style_button(_continue_btn)
	_result_panel.visible = false
	_continue_btn.pressed.connect(_on_continue)
	_spawn_combatants()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _spawn_combatants() -> void:
	var loadout := AccountManager.get_loadout()
	_player = preload("res://scenes/battle/battle_bot.tscn").instantiate()
	_player.setup(loadout.chassis, loadout.weapons, true)
	_player.position = Vector2(200, 360)
	_player.set_battle_scene(self)
	add_child(_player)
	_player.died.connect(_on_player_died)
	_player.health_changed.connect(_on_player_health_changed)

	if _is_boss_fight:
		_spawn_boss()
	else:
		_spawn_ai_opponent()


func _spawn_boss() -> void:
	var arena := GameData.get_arena(_arena_id)
	var boss_data: Dictionary = arena.boss
	var boss := preload("res://scenes/battle/battle_bot.tscn").instantiate()
	boss.setup("heavy", boss_data.weapons, false, true, boss_data)
	boss.position = Vector2(1080, 360)
	boss.set_battle_scene(self)
	boss.set_target(_player)
	add_child(boss)
	_enemies.append(boss)
	_player.set_target(boss)
	boss.died.connect(_on_enemy_died.bind(boss))
	boss.health_changed.connect(_on_enemy_health_changed.bind(boss))
	if boss._name_label:
		boss._name_label.text = boss_data.name


func _spawn_ai_opponent() -> void:
	var loadout := GameData.random_ai_loadout(_arena_id)
	var enemy := preload("res://scenes/battle/battle_bot.tscn").instantiate()
	enemy.setup(loadout.chassis, loadout.weapons, false)
	enemy.position = Vector2(1080, 360)
	enemy.set_battle_scene(self)
	enemy.set_target(_player)
	add_child(enemy)
	_enemies.append(enemy)
	_player.set_target(enemy)
	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy.health_changed.connect(_on_enemy_health_changed.bind(enemy))


func _process(_delta: float) -> void:
	if _player and _player.current_hp > 0:
		var wid := _player.get_active_weapon()
		var wdata := GameData.get_weapon(wid)
		if not wdata.is_empty():
			_weapon_label.text = "Weapon: %s (scroll/RClick to switch)" % wdata.name


func _on_player_health_changed(current: float, maximum: float) -> void:
	_player_hp_label.text = "HP: %d / %d" % [int(current), int(maximum)]


func _on_enemy_health_changed(enemy: BattleBot, current: float, maximum: float) -> void:
	if _is_boss_fight:
		_enemy_hp_label.text = "BOSS: %d / %d" % [int(current), int(maximum)]
	else:
		_enemy_hp_label.text = "Enemy: %d / %d" % [int(current), int(maximum)]


func _on_player_died(_bot: BattleBot) -> void:
	if _battle_over:
		return
	_end_battle(false)


func _on_enemy_died(enemy: BattleBot) -> void:
	enemy.queue_free()
	_enemies.erase(enemy)
	if _enemies.is_empty():
		_end_battle(true)


func _end_battle(win: bool) -> void:
	_battle_over = true
	_result_panel.visible = true
	var arena := GameData.get_arena(_arena_id)
	var gems := 0
	var trophies := 0
	if win:
		if _is_boss_fight:
			gems = arena.gem_reward_boss
			trophies = 30
			_result_label.text = "BOSS DEFEATED!\n+%d Gems  +%d Trophies" % [gems, trophies]
		else:
			gems = arena.gem_reward_win
			trophies = 10
			_result_label.text = "VICTORY!\n+%d Gems  +%d Trophies" % [gems, trophies]
		_result_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	else:
		gems = 5
		trophies = 0
		_result_label.text = "DEFEATED\n+5 Gems (consolation)"
		_result_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	AccountManager.record_battle(win, gems, trophies, _is_boss_fight and win)
	battle_ended.emit(win, gems, trophies, _is_boss_fight)


func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/arena/arena_select.tscn")
