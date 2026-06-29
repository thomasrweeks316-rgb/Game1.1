extends Node2D

signal battle_ended(win: bool, gems: int, trophies: int, is_boss: bool)

var _player: BattleBot
var _enemies: Array[BattleBot] = []
var _arena_id: int = 0
var _is_boss_fight: bool = false
var _battle_over: bool = false

@onready var _arena_bg: Node2D = $ArenaBG
@onready var _arena_terrain: Node2D = $ArenaTerrain
@onready var _player_hp_label: Label = $HUD/TopBar/PlayerHP
@onready var _enemy_hp_label: Label = $HUD/TopBar/EnemyHP
@onready var _weapon_label: Label = $HUD/TopBar/WeaponLabel
@onready var _info_label: Label = $HUD/InfoLabel
@onready var _result_panel: PanelContainer = $HUD/ResultPanel
@onready var _result_label: Label = $HUD/ResultPanel/VBox/ResultLabel
@onready var _continue_btn: Button = $HUD/ResultPanel/VBox/ContinueBtn


func _ready() -> void:
	if not AccountManager.is_logged_in:
		get_tree().change_scene_to_file("res://scenes/auth/login.tscn")
		return
	var pending := AccountManager.pending_battle
	_arena_id = int(pending.get("arena_id", AccountManager.get_current_arena()))
	_is_boss_fight = bool(pending.get("boss", false))
	AccountManager.pending_battle = {}
	var arena := GameData.get_arena(_arena_id)
	if arena.is_empty():
		push_error("Battle started with invalid arena id: %s" % str(_arena_id))
		get_tree().call_deferred("change_scene_to_file", "res://scenes/arena/arena_select.tscn")
		return
	_arena_bg.setup(arena)
	if _arena_terrain.has_method("setup"):
		_arena_terrain.setup(arena)
	_info_label.text = "%s - %s" % [arena.get("name", "Arena"), "BOSS FIGHT" if _is_boss_fight else "Battle"]
	UIHelpers.style_button(_continue_btn)
	_result_panel.visible = false
	_continue_btn.pressed.connect(_on_continue)
	_spawn_combatants()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _spawn_combatants() -> void:
	var loadout := AccountManager.get_loadout()
	var weapons: Array = loadout.get("weapons", [GameData.STARTING_WEAPON])
	_player = preload("res://scenes/battle/battle_bot.tscn").instantiate()
	_player.setup(str(loadout.get("chassis", GameData.STARTING_CHASSIS)), weapons, true)
	_player.position = Vector2(200, 360)
	_player.set_battle_scene(self)
	add_child(_player)
	_player.died.connect(_on_player_died)
	_player.health_changed.connect(_on_player_health_changed)
	_on_player_health_changed(_player.current_hp, _player.max_hp)

	if _is_boss_fight:
		_spawn_boss()
	else:
		_spawn_ai_opponent()


func _spawn_boss() -> void:
	var arena := GameData.get_arena(_arena_id)
	var boss_data: Dictionary = arena.get("boss", {})
	if boss_data.is_empty():
		push_error("Missing boss data for arena %d" % _arena_id)
		return
	var weapons: Array = boss_data.get("weapons", ["minigun"])
	var boss := preload("res://scenes/battle/battle_bot.tscn").instantiate()
	boss.setup("heavy", weapons, false, true, boss_data)
	boss.position = Vector2(1080, 360)
	boss.set_battle_scene(self)
	boss.set_target(_player)
	add_child(boss)
	_enemies.append(boss)
	_player.set_target(boss)
	boss.died.connect(_on_enemy_died)
	boss.health_changed.connect(_on_enemy_health_changed.bind(boss))
	if boss._name_label:
		boss._name_label.text = str(boss_data.get("name", "BOSS"))
	_on_enemy_health_changed(boss, boss.current_hp, boss.max_hp)


func _spawn_ai_opponent() -> void:
	var loadout := GameData.random_ai_loadout(_arena_id)
	var enemy := preload("res://scenes/battle/battle_bot.tscn").instantiate()
	enemy.setup(str(loadout.get("chassis", "light")), loadout.get("weapons", ["minigun"]), false)
	enemy.position = Vector2(1080, 360)
	enemy.set_battle_scene(self)
	enemy.set_target(_player)
	add_child(enemy)
	_enemies.append(enemy)
	_player.set_target(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.health_changed.connect(_on_enemy_health_changed.bind(enemy))
	_on_enemy_health_changed(enemy, enemy.current_hp, enemy.max_hp)


func _process(_delta: float) -> void:
	if not _battle_over:
		for i in range(_enemies.size() - 1, -1, -1):
			var enemy := _enemies[i]
			if enemy == null or not is_instance_valid(enemy) or not enemy.is_alive():
				_on_enemy_died(enemy)
	if _player and _player.is_alive():
		var names := _player.get_equipped_weapon_names()
		if not names.is_empty():
			_weapon_label.text = "Weapons: %s (all fire together)" % ", ".join(names)


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
	if _battle_over:
		return
	if enemy == null or not is_instance_valid(enemy):
		_enemies.clear()
		if not _battle_over:
			_end_battle(true)
		return
	if enemy in _enemies:
		_enemies.erase(enemy)
	if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
		enemy.queue_free()
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
			gems = int(arena.get("gem_reward_boss", 0))
			trophies = 30
			_result_label.text = "BOSS DEFEATED!\n+%d Gems  +%d Trophies" % [gems, trophies]
		else:
			gems = int(arena.get("gem_reward_win", 0))
			trophies = 10
			_result_label.text = "VICTORY!\n+%d Gems  +%d Trophies" % [gems, trophies]
		_result_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	else:
		gems = 5
		trophies = 0
		_result_label.text = "DEFEATED\n+5 Gems (consolation)"
		_result_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	AccountManager.record_battle(win, gems, trophies, _is_boss_fight and win, _arena_id)
	battle_ended.emit(win, gems, trophies, _is_boss_fight)


func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/arena/arena_select.tscn")
