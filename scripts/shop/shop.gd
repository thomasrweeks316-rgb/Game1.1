extends Control

@onready var _gems_label: Label = $TopBar/GemsLabel
@onready var _tab_weapons: Button = $TopBar/TabWeapons
@onready var _tab_chassis: Button = $TopBar/TabChassis
@onready var _tab_gems: Button = $TopBar/TabGems
@onready var _item_list: ItemList = $HBox/ItemList
@onready var _detail_label: Label = $HBox/DetailPanel/VBox/DetailLabel
@onready var _buy_btn: Button = $HBox/DetailPanel/VBox/BuyBtn
@onready var _back_btn: Button = $TopBar/BackBtn

var _current_tab: String = "weapons"


func _ready() -> void:
	if not AccountManager.is_logged_in:
		get_tree().change_scene_to_file("res://scenes/auth/login.tscn")
		return
	for btn in [_tab_weapons, _tab_chassis, _tab_gems, _buy_btn, _back_btn]:
		UIHelpers.style_button(btn)
	_tab_weapons.pressed.connect(func(): _switch_tab("weapons"))
	_tab_chassis.pressed.connect(func(): _switch_tab("chassis"))
	_tab_gems.pressed.connect(func(): _switch_tab("gems"))
	_item_list.item_selected.connect(_on_item_selected)
	_buy_btn.pressed.connect(_on_buy)
	_back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn"))
	AccountManager.progress_updated.connect(_refresh_gems)
	_refresh_gems()
	_switch_tab("weapons")


func _refresh_gems() -> void:
	_gems_label.text = "Gems: %d" % AccountManager.get_gems()


func _switch_tab(tab: String) -> void:
	_current_tab = tab
	_item_list.clear()
	_detail_label.text = ""
	_buy_btn.visible = tab != "gems"
	match tab:
		"weapons":
			for wid in GameData.WEAPONS:
				var w := GameData.get_weapon(wid)
				var owned := AccountManager.owns_weapon(wid)
				var prefix := "[OWNED] " if owned else "[%d gems] " % w.gem_cost
				_item_list.add_item(prefix + w.name)
				_item_list.set_item_metadata(_item_list.item_count - 1, wid)
		"chassis":
			for cid in GameData.CHASSIS:
				var c := GameData.get_chassis(cid)
				var owned := AccountManager.owns_chassis(cid)
				var prefix := "[OWNED] " if owned else "[%d gems] " % c.gem_cost
				_item_list.add_item(prefix + c.name)
				_item_list.set_item_metadata(_item_list.item_count - 1, cid)
		"gems":
			_buy_btn.visible = false
			for pack in GameData.GEM_PACKS:
				if pack.get("daily", false) or pack.get("battle_pass", false):
					continue
				_item_list.add_item("%s: %d gems for %d gems" % [pack.label, pack.gems, pack.cost_gems])
				_item_list.set_item_metadata(_item_list.item_count - 1, pack)


func _on_item_selected(index: int) -> void:
	var meta = _item_list.get_item_metadata(index)
	match _current_tab:
		"weapons":
			var w := GameData.get_weapon(meta)
			_detail_label.text = "%s\n%s\nDamage: %d | Rate: %.1fs | Range: %d\nCost: %d gems" % [
				w.name, w.description, w.damage, w.fire_rate, w.range, w.gem_cost
			]
			_buy_btn.disabled = AccountManager.owns_weapon(meta)
			_buy_btn.text = "Buy for %d Gems" % w.gem_cost
		"chassis":
			var c := GameData.get_chassis(meta)
			_detail_label.text = "%s\nHP: %d | Speed: %d | Armor: %d\nCost: %d gems" % [
				c.name, c.hp, c.speed, c.armor, c.gem_cost
			]
			_buy_btn.disabled = AccountManager.owns_chassis(meta)
			_buy_btn.text = "Buy for %d Gems" % c.gem_cost
		"gems":
			var pack: Dictionary = meta
			_detail_label.text = "Exchange %d gems for %d gems.\n(Net gain: %d gems)" % [
				pack.cost_gems, pack.gems, pack.gems - pack.cost_gems
			]


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
			if AccountManager.spend_gems(pack.cost_gems):
				AccountManager.add_gems(pack.gems)
				err = ""
			else:
				err = "Not enough gems."
	if err.is_empty():
		_switch_tab(_current_tab)
	else:
		_detail_label.text = err
