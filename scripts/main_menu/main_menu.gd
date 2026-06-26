extends Control

@onready var _welcome: Label = $VBox/Welcome
@onready var _stats: Label = $VBox/Stats
@onready var _arena_btn: Button = $VBox/ArenaBtn
@onready var _garage_btn: Button = $VBox/GarageBtn
@onready var _shop_btn: Button = $VBox/ShopBtn
@onready var _daily_btn: Button = $VBox/DailyBtn
@onready var _logout_btn: Button = $VBox/LogoutBtn


func _ready() -> void:
	if not AccountManager.is_logged_in:
		get_tree().change_scene_to_file("res://scenes/auth/login.tscn")
		return
	for btn in [_arena_btn, _garage_btn, _shop_btn, _daily_btn, _logout_btn]:
		UIHelpers.style_button(btn)
	_arena_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/arena/arena_select.tscn"))
	_garage_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/garage/garage.tscn"))
	_shop_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/shop/shop.tscn"))
	_daily_btn.pressed.connect(_on_daily)
	_logout_btn.pressed.connect(_on_logout)
	AccountManager.progress_updated.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_welcome.text = "Welcome, %s!" % AccountManager.current_username
	var p := AccountManager.progress
	_stats.text = "Gems: %d  |  Trophies: %d  |  Wins: %d/%d" % [
		AccountManager.get_gems(),
		AccountManager.get_trophies(),
		p.get("battles_won", 0),
		p.get("battles_played", 0),
	]
	if AccountManager.can_claim_daily():
		_daily_btn.text = "Claim Daily Gems (100)"
		_daily_btn.disabled = false
	else:
		_daily_btn.text = "Daily Reward Claimed"
		_daily_btn.disabled = true


func _on_daily() -> void:
	var amount := AccountManager.claim_daily()
	if amount > 0:
		_refresh()


func _on_logout() -> void:
	AccountManager.logout()
	get_tree().change_scene_to_file("res://scenes/auth/login.tscn")
