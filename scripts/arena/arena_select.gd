extends Control

@onready var _arena_list: ItemList = $HBox/ArenaList
@onready var _detail: Label = $HBox/DetailPanel/VBox/Detail
@onready var _fight_btn: Button = $HBox/DetailPanel/VBox/FightBtn
@onready var _boss_btn: Button = $HBox/DetailPanel/VBox/BossBtn
@onready var _back_btn: Button = $TopBar/BackBtn
@onready var _trophies_label: Label = $TopBar/TrophiesLabel

var _selected_arena: int = 0


func _ready() -> void:
	if not AccountManager.is_logged_in:
		get_tree().change_scene_to_file("res://scenes/auth/login.tscn")
		return
	for btn in [_fight_btn, _boss_btn, _back_btn]:
		UIHelpers.style_button(btn)
	_arena_list.item_selected.connect(_on_arena_selected)
	_fight_btn.pressed.connect(_on_fight)
	_boss_btn.pressed.connect(_on_boss)
	_back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn"))
	_populate_arenas()
	_trophies_label.text = "Trophies: %d" % AccountManager.get_trophies()


func _populate_arenas() -> void:
	_arena_list.clear()
	var trophies := AccountManager.get_trophies()
	var beaten: Array = AccountManager.progress.get("bosses_beaten", [])
	for arena in GameData.ARENAS:
		var locked := trophies < arena.trophy_required
		var boss_beaten := arena.id in beaten
		var prefix := ""
		if locked:
			prefix = "[LOCKED] "
		elif boss_beaten:
			prefix = "[CLEARED] "
		_arena_list.add_item(prefix + arena.name)
		_arena_list.set_item_metadata(_arena_list.item_count - 1, arena.id)
		if locked:
			_arena_list.set_item_custom_fg_color(_arena_list.item_count - 1, Color(0.5, 0.5, 0.5))


func _on_arena_selected(index: int) -> void:
	_selected_arena = _arena_list.get_item_metadata(index)
	var arena := GameData.get_arena(_selected_arena)
	var trophies := AccountManager.get_trophies()
	var locked := trophies < arena.trophy_required
	_detail.text = "%s\n%s\nTrophies needed: %d\nWin reward: %d gems | Boss reward: %d gems\n\nAI opponents use gear from this arena." % [
		arena.name, arena.description, arena.trophy_required,
		arena.gem_reward_win, arena.gem_reward_boss,
	]
	_fight_btn.disabled = locked
	_boss_btn.disabled = locked
	AccountManager.set_current_arena(_selected_arena)


func _on_fight() -> void:
	_start_battle(false)


func _on_boss() -> void:
	_start_battle(true)


func _start_battle(boss: bool) -> void:
	AccountManager.queue_battle(_selected_arena, boss)
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")
