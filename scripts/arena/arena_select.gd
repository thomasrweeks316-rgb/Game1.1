extends Control

@onready var _arena_list: ItemList = $HBox/ArenaList
@onready var _detail: Label = $HBox/DetailPanel/VBox/Detail
@onready var _fight_btn: Button = $HBox/DetailPanel/VBox/FightBtn
@onready var _boss_btn: Button = $HBox/DetailPanel/VBox/BossBtn
@onready var _back_btn: Button = $TopBar/BackBtn
@onready var _trophies_label: Label = $TopBar/TrophiesLabel
@onready var _arena_backdrop: Node2D = $ArenaBackdropLayer/ArenaBackdrop

var _selected_arena: int = 0


func _ready() -> void:
	if not AccountManager.is_logged_in:
		get_tree().change_scene_to_file("res://scenes/auth/login.tscn")
		return
	$BG.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for btn in [_fight_btn, _boss_btn, _back_btn]:
		UIHelpers.style_button(btn)
	_arena_list.item_selected.connect(_on_arena_selected)
	_fight_btn.pressed.connect(_on_fight)
	_boss_btn.pressed.connect(_on_boss)
	_back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn"))
	_populate_arenas()
	_sync_arena_selection()
	_trophies_label.text = "Trophies: %d" % AccountManager.get_trophies()


func _populate_arenas() -> void:
	_arena_list.clear()
	var beaten: Array = AccountManager.progress.get("bosses_beaten", [])
	for arena in GameData.ARENAS:
		var arena_id: int = int(arena.get("id", -1))
		var locked := not AccountManager.is_arena_unlocked(arena_id)
		var boss_beaten := arena_id in beaten
		var prefix := ""
		if locked:
			prefix = "[LOCKED] "
		elif boss_beaten:
			prefix = "[CLEARED] "
		_arena_list.add_item(prefix + str(arena.get("name", "Arena")))
		_arena_list.set_item_metadata(_arena_list.item_count - 1, arena_id)
		if locked:
			_arena_list.set_item_custom_fg_color(_arena_list.item_count - 1, Color(0.5, 0.5, 0.5))


func _sync_arena_selection() -> void:
	if _arena_list.item_count == 0:
		return
	var target_id := AccountManager.get_current_arena()
	if not AccountManager.is_arena_unlocked(target_id):
		target_id = AccountManager.get_highest_unlocked_arena()
	var index := 0
	for i in _arena_list.item_count:
		if _arena_list.get_item_metadata(i) == target_id:
			index = i
			break
	_arena_list.select(index)
	_on_arena_selected(index)


func _on_arena_selected(index: int) -> void:
	if index < 0 or index >= _arena_list.item_count:
		return
	_selected_arena = int(_arena_list.get_item_metadata(index))
	var arena := GameData.get_arena(_selected_arena)
	if arena.is_empty():
		_detail.text = "Arena data unavailable."
		_fight_btn.disabled = true
		_boss_btn.disabled = true
		return
	var locked := not AccountManager.is_arena_unlocked(_selected_arena)
	var beaten: Array = AccountManager.progress.get("bosses_beaten", [])
	var boss_beaten := _selected_arena in beaten
	var boss_name: String = str(arena.get("boss", {}).get("name", "Boss"))
	var unlock_text := ""
	if locked:
		unlock_text = "\n\n%s" % GameData.get_arena_unlock_requirement(_selected_arena)
	elif not boss_beaten:
		unlock_text = "\n\nBoss not defeated yet: %s" % boss_name
	else:
		unlock_text = "\n\nBoss defeated: %s" % boss_name
	_detail.text = "%s\n%s\nWin reward: %d gems | Boss reward: %d gems\n\nAI opponents use gear from this arena.%s" % [
		arena.get("name", "Arena"), arena.get("description", ""),
		int(arena.get("gem_reward_win", 0)), int(arena.get("gem_reward_boss", 0)),
		unlock_text,
	]
	_fight_btn.disabled = locked
	_boss_btn.disabled = locked
	AccountManager.set_current_arena(_selected_arena)
	if _arena_backdrop.has_method("setup"):
		_arena_backdrop.setup(arena, true)


func _on_fight() -> void:
	_start_battle(false)


func _on_boss() -> void:
	_start_battle(true)


func _start_battle(boss: bool) -> void:
	var arena := GameData.get_arena(_selected_arena)
	if arena.is_empty():
		return
	if not AccountManager.is_arena_unlocked(_selected_arena):
		_detail.text = GameData.get_arena_unlock_requirement(_selected_arena)
		return
	AccountManager.set_current_arena(_selected_arena)
	AccountManager.queue_battle(_selected_arena, boss)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/battle/battle.tscn")
