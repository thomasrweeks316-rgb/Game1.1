extends Control

@onready var _gems_label: Label = $TopBar/GemsLabel
@onready var _trophies_label: Label = $TopBar/TrophiesLabel
@onready var _tab_weapons: Button = $TabBar/TabWeapons
@onready var _tab_chassis: Button = $TabBar/TabChassis
@onready var _tab_gems: Button = $TabBar/TabGems
@onready var _item_list: ItemList = $HBox/ItemList
@onready var _detail_label: Label = $HBox/DetailPanel/VBox/DetailLabel
@onready var _detail_icon: TextureRect = $HBox/DetailPanel/VBox/DetailIcon
@onready var _buy_btn: Button = $HBox/DetailPanel/VBox/BuyBtn
@onready var _back_btn: Button = $TopBar/BackBtn

var _current_tab: String = "weapons"


func _ready() -> void:
	if not AccountManager.is_logged_in:
		get_tree().change_scene_to_file("res://scenes/auth/login.tscn")
		return
	UIHelpers.style_button(_back_btn, Vector2(100, 40))
	UIHelpers.style_button(_buy_btn)
	for btn in [_tab_weapons, _tab_chassis, _tab_gems]:
		UIHelpers.style_button(btn, Vector2(140, 40))
	_tab_weapons.pressed.connect(func(): _switch_tab("weapons"))
	_tab_chassis.pressed.connect(func(): _switch_tab("chassis"))
	_tab_gems.pressed.connect(func(): _switch_tab("gems"))
	_item_list.item_selected.connect(_on_item_selected)
	_buy_btn.pressed.connect(_on_buy)
	_back_btn.pressed.connect(_leave_shop)
	AccountManager.progress_updated.connect(_refresh_currency)
	_refresh_currency()
	_switch_tab("weapons")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_leave_shop()
		get_viewport().set_input_as_handled()


func _leave_shop() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main_menu/main_menu.tscn")


func _refresh_currency() -> void:
	_gems_label.text = "Gems: %d" % AccountManager.get_gems()
	_trophies_label.text = "Trophies: %d" % AccountManager.get_trophies()


func _switch_tab(tab: String) -> void:
	_current_tab = tab
	_item_list.clear()
	_detail_label.text = ""
	_detail_icon.texture = null
	_buy_btn.visible = true
	_buy_btn.disabled = false
	_item_list.fixed_icon_size = Vector2i(40, 40)
	match tab:
		"weapons":
			for wid in GameData.WEAPONS:
				var w := GameData.get_weapon(wid)
				var owned := AccountManager.owns_weapon(wid)
				var prefix := "[OWNED] " if owned else "[%d gems] " % w.get("gem_cost", 0)
				_item_list.add_item(prefix + w.get("name", wid))
				var idx := _item_list.item_count - 1
				_item_list.set_item_metadata(idx, wid)
				_item_list.set_item_icon(idx, BotArt.get_weapon_icon(wid))
		"chassis":
			for cid in GameData.CHASSIS:
				var c := GameData.get_chassis(cid)
				var owned := AccountManager.owns_chassis(cid)
				var prefix := "[OWNED] " if owned else "[%d gems] " % c.get("gem_cost", 0)
				_item_list.add_item(prefix + c.get("name", cid))
				var idx := _item_list.item_count - 1
				_item_list.set_item_metadata(idx, cid)
				_item_list.set_item_icon(idx, BotArt.get_chassis_icon(cid))
		"gems":
			for pack in GameData.GEM_PACKS:
				if pack.get("daily", false) or pack.get("battle_pass", false):
					continue
				var trophy_cost: int = int(pack.get("cost_trophies", 0))
				_item_list.add_item("%s: %d gems for %d trophies" % [
					pack.get("label", "Pack"), pack.get("gems", 0), trophy_cost,
				])
				_item_list.set_item_metadata(_item_list.item_count - 1, pack)


func _on_item_selected(index: int) -> void:
	var meta = _item_list.get_item_metadata(index)
	match _current_tab:
		"weapons":
			var w := GameData.get_weapon(meta)
			_detail_icon.texture = BotArt.get_weapon_icon(meta)
			_detail_label.text = "%s\n%s\nDamage: %d | Rate: %.1fs | Range: %d\nCost: %d gems" % [
				w.get("name", meta), w.get("description", ""),
				w.get("damage", 0), w.get("fire_rate", 1.0), w.get("range", 0), w.get("gem_cost", 0),
			]
			_buy_btn.disabled = AccountManager.owns_weapon(meta)
			_buy_btn.text = "Buy for %d Gems" % w.get("gem_cost", 0)
		"chassis":
			var c := GameData.get_chassis(meta)
			_detail_icon.texture = BotArt.get_chassis_icon(meta)
			_detail_label.text = "%s\nHP: %d | Speed: %d | Armor: %d\nCost: %d gems" % [
				c.get("name", meta), c.get("hp", 0), c.get("speed", 0), c.get("armor", 0), c.get("gem_cost", 0),
			]
			_buy_btn.disabled = AccountManager.owns_chassis(meta)
			_buy_btn.text = "Buy for %d Gems" % c.get("gem_cost", 0)
		"gems":
			_detail_icon.texture = null
			var pack: Dictionary = meta
			var trophy_cost: int = int(pack.get("cost_trophies", 0))
			var gem_amount: int = int(pack.get("gems", 0))
			_detail_label.text = "%s\n\nReceive %d gems.\nCost: %d trophies" % [
				pack.get("label", "Gem Pack"), gem_amount, trophy_cost,
			]
			_buy_btn.disabled = AccountManager.get_trophies() < trophy_cost
			_buy_btn.text = "Buy for %d Trophies" % trophy_cost


func _on_buy() -> void:
	var selected := _item_list.get_selected_items()
	if selected.is_empty():
		return
	var meta = _item_list.get_item_metadata(selected[0])
	var err := ""
	match _current_tab:
		"weapons":
			err = AccountManager.buy_weapon(meta)
		"chassis":
			err = AccountManager.buy_chassis(meta)
		"gems":
			var pack: Dictionary = meta
			err = AccountManager.buy_gem_pack(int(pack.get("gems", 0)), int(pack.get("cost_trophies", 0)))
	if err.is_empty():
		_switch_tab(_current_tab)
	else:
		_detail_label.text = err
