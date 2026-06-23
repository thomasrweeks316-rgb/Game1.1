extends Control

@onready var _chassis_list: ItemList = $HBox/Left/ChassisList
@onready var _weapon_list: ItemList = $HBox/Right/WeaponList
@onready var _equipped_label: Label = $HBox/Center/EquippedLabel
@onready var _save_btn: Button = $HBox/Center/SaveBtn
@onready var _back_btn: Button = $TopBar/BackBtn
@onready var _preview: Control = $HBox/Center/PreviewPanel/BotPreview

var _selected_chassis: String = ""
var _selected_weapons: Array[String] = []

const WEAPON_SELECTED_COLOR := Color(0.2, 0.4, 0.6, 0.45)


func _ready() -> void:
	if not AccountManager.is_logged_in:
		get_tree().change_scene_to_file("res://scenes/auth/login.tscn")
		return
	UIHelpers.style_button(_save_btn)
	UIHelpers.style_button(_back_btn)
	_chassis_list.item_selected.connect(_on_chassis_selected)
	_weapon_list.item_clicked.connect(_on_weapon_clicked)
	_save_btn.pressed.connect(_on_save)
	_back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn"))
	_populate_lists()
	_load_saved_loadout()
	_sync_list_selections()
	_update_preview()
	_update_equipped_label()


func _populate_lists() -> void:
	_chassis_list.clear()
	for cid in GameData.CHASSIS:
		if AccountManager.owns_chassis(cid):
			var c := GameData.get_chassis(cid)
			_chassis_list.add_item("%s (HP:%d SPD:%d)" % [c.name, c.hp, c.speed])
			_chassis_list.set_item_metadata(_chassis_list.item_count - 1, cid)
	_weapon_list.clear()
	for wid in GameData.WEAPONS:
		if AccountManager.owns_weapon(wid):
			var w := GameData.get_weapon(wid)
			_weapon_list.add_item("%s (DMG:%d)" % [w.name, w.damage])
			_weapon_list.set_item_metadata(_weapon_list.item_count - 1, wid)


func _load_saved_loadout() -> void:
	var loadout := AccountManager.get_loadout()
	_selected_chassis = str(loadout.get("chassis", GameData.STARTING_CHASSIS))
	_selected_weapons.clear()
	var saved_weapons: Array = loadout.get("weapons", [GameData.STARTING_WEAPON])
	for w in saved_weapons:
		_selected_weapons.append(str(w))
	if _selected_chassis.is_empty() and _chassis_list.item_count > 0:
		_selected_chassis = _chassis_list.get_item_metadata(0)
	if _selected_weapons.is_empty() and _weapon_list.item_count > 0:
		_selected_weapons.append(_weapon_list.get_item_metadata(0))


func _sync_list_selections() -> void:
	for i in _chassis_list.item_count:
		var cid: String = _chassis_list.get_item_metadata(i)
		if cid == _selected_chassis:
			_chassis_list.select(i)
			break
	if _chassis_list.get_selected_items().is_empty() and _chassis_list.item_count > 0:
		_chassis_list.select(0)
		_selected_chassis = _chassis_list.get_item_metadata(0)
	_refresh_weapon_highlights()


func _refresh_weapon_highlights() -> void:
	for i in _weapon_list.item_count:
		var wid: String = _weapon_list.get_item_metadata(i)
		if wid in _selected_weapons:
			_weapon_list.set_item_custom_bg_color(i, WEAPON_SELECTED_COLOR)
		else:
			_weapon_list.set_item_custom_bg_color(i, Color(0, 0, 0, 0))


func _on_chassis_selected(index: int) -> void:
	_selected_chassis = _chassis_list.get_item_metadata(index)
	_update_preview()
	_update_equipped_label()


func _on_weapon_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	var wid: String = _weapon_list.get_item_metadata(index)
	if wid in _selected_weapons:
		_selected_weapons.erase(wid)
	else:
		if _selected_weapons.size() >= GameData.MAX_WEAPON_SLOTS:
			_equipped_label.text = "Maximum %d weapons! Click a selected weapon to remove it." % GameData.MAX_WEAPON_SLOTS
			return
		_selected_weapons.append(wid)
	_refresh_weapon_highlights()
	_update_equipped_label()


func _update_preview() -> void:
	if _preview.has_method("set_chassis"):
		_preview.set_chassis(_selected_chassis)


func _update_equipped_label() -> void:
	if _selected_chassis.is_empty():
		_equipped_label.text = "Select a chassis."
		return
	var chassis := GameData.get_chassis(_selected_chassis)
	var chassis_name: String = chassis.get("name", "?")
	var weapon_names: PackedStringArray = []
	for w in _selected_weapons:
		weapon_names.append(GameData.get_weapon(w).get("name", w))
	var weapons_text := ", ".join(weapon_names) if not weapon_names.is_empty() else "(none selected)"
	_equipped_label.text = "Chassis: %s\nWeapons: %s" % [chassis_name, weapons_text]


func _on_save() -> void:
	if _selected_chassis.is_empty():
		_equipped_label.text = "Select a chassis!"
		return
	if _selected_weapons.is_empty():
		_equipped_label.text = "Select at least 1 weapon!"
		return
	AccountManager.set_loadout(_selected_chassis, _selected_weapons.duplicate())
	_equipped_label.text = "Loadout saved!"
