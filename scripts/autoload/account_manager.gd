extends Node

signal account_logged_in(username: String)
signal account_logged_out
signal progress_updated

const ACCOUNTS_DIR := "user://accounts/"
const SESSION_FILE := "user://session.cfg"

var current_username: String = ""
var is_logged_in: bool = false

var progress: Dictionary = {}
var pending_battle: Dictionary = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ACCOUNTS_DIR)
	_try_restore_session()


func _try_restore_session() -> void:
	if not FileAccess.file_exists(SESSION_FILE):
		return
	var cfg := ConfigFile.new()
	if cfg.load(SESSION_FILE) != OK:
		return
	var username: String = cfg.get_value("session", "username", "")
	if username.is_empty():
		return
	if _load_account(username):
		current_username = username
		is_logged_in = true


func register(username: String, password: String) -> String:
	username = username.strip_edges()
	if username.length() < 3:
		return "Username must be at least 3 characters."
	if password.length() < 4:
		return "Password must be at least 4 characters."
	if not _is_valid_username(username):
		return "Username can only contain letters, numbers, and underscores."
	var path := _account_path(username)
	if FileAccess.file_exists(path):
		return "Account already exists."
	var data := _create_new_progress()
	data["password_hash"] = password.sha256_text()
	data["created_at"] = Time.get_datetime_string_from_system()
	_save_account_file(username, data)
	return ""


func login(username: String, password: String) -> String:
	username = username.strip_edges()
	if not _load_account(username):
		return "Account not found."
	if progress.get("password_hash", "") != password.sha256_text():
		return "Incorrect password."
	current_username = username
	is_logged_in = true
	_save_session()
	account_logged_in.emit(username)
	return ""


func logout() -> void:
	current_username = ""
	is_logged_in = false
	progress = {}
	if FileAccess.file_exists(SESSION_FILE):
		DirAccess.remove_absolute(SESSION_FILE)
	account_logged_out.emit()


func save_progress() -> void:
	if not is_logged_in:
		return
	progress["last_saved"] = Time.get_datetime_string_from_system()
	_save_account_file(current_username, progress)
	progress_updated.emit()


func get_gems() -> int:
	return progress.get("gems", 0)


func add_gems(amount: int) -> void:
	progress["gems"] = get_gems() + amount
	save_progress()


func spend_gems(amount: int) -> bool:
	if get_gems() < amount:
		return false
	progress["gems"] = get_gems() - amount
	save_progress()
	return true


func get_trophies() -> int:
	return progress.get("trophies", 0)


func add_trophies(amount: int) -> void:
	progress["trophies"] = get_trophies() + amount
	save_progress()


func owns_weapon(weapon_id: String) -> bool:
	return weapon_id in progress.get("owned_weapons", [])


func owns_chassis(chassis_id: String) -> bool:
	return chassis_id in progress.get("owned_chassis", [])


func buy_weapon(weapon_id: String) -> String:
	var w := GameData.get_weapon(weapon_id)
	if w.is_empty():
		return "Invalid weapon."
	if owns_weapon(weapon_id):
		return "Already owned."
	if get_trophies() < _arena_trophy_req(w.arena_unlock):
		return "Unlock a higher arena first."
	if not spend_gems(w.gem_cost):
		return "Not enough gems."
	var owned: Array = progress.get("owned_weapons", [])
	owned.append(weapon_id)
	progress["owned_weapons"] = owned
	save_progress()
	return ""


func buy_chassis(chassis_id: String) -> String:
	var c := GameData.get_chassis(chassis_id)
	if c.is_empty():
		return "Invalid chassis."
	if owns_chassis(chassis_id):
		return "Already owned."
	if get_trophies() < _arena_trophy_req(c.arena_unlock):
		return "Unlock a higher arena first."
	if not spend_gems(c.gem_cost):
		return "Not enough gems."
	var owned: Array = progress.get("owned_chassis", [])
	owned.append(chassis_id)
	progress["owned_chassis"] = owned
	save_progress()
	return ""


func set_loadout(chassis_id: String, weapons: Array) -> void:
	progress["equipped_chassis"] = chassis_id
	progress["equipped_weapons"] = weapons
	save_progress()


func get_loadout() -> Dictionary:
	return {
		"chassis": progress.get("equipped_chassis", GameData.STARTING_CHASSIS),
		"weapons": progress.get("equipped_weapons", [GameData.STARTING_WEAPON]),
	}


func get_current_arena() -> int:
	return progress.get("current_arena", 0)


func set_current_arena(arena_id: int) -> void:
	progress["current_arena"] = arena_id
	save_progress()


func queue_battle(arena_id: int, boss_fight: bool) -> void:
	pending_battle = {"arena_id": arena_id, "boss": boss_fight}


func record_battle(win: bool, gems_earned: int, trophies_earned: int, boss: bool = false) -> void:
	progress["battles_played"] = progress.get("battles_played", 0) + 1
	if win:
		progress["battles_won"] = progress.get("battles_won", 0) + 1
		add_gems(gems_earned)
		add_trophies(trophies_earned)
		if boss:
			var beaten: Array = progress.get("bosses_beaten", [])
			var arena_id: int = get_current_arena()
			if arena_id not in beaten:
				beaten.append(arena_id)
				progress["bosses_beaten"] = beaten
	save_progress()


func can_claim_daily() -> bool:
	var last: String = progress.get("last_daily", "")
	if last.is_empty():
		return true
	var last_time := Time.get_unix_time_from_datetime_string(last)
	var now := Time.get_unix_time_from_system()
	return now - last_time >= 86400


func claim_daily() -> int:
	if not can_claim_daily():
		return 0
	progress["last_daily"] = Time.get_datetime_string_from_system()
	add_gems(100)
	return 100


func _create_new_progress() -> Dictionary:
	return {
		"password_hash": "",
		"gems": GameData.STARTING_GEMS,
		"trophies": 0,
		"owned_weapons": [GameData.STARTING_WEAPON],
		"owned_chassis": [GameData.STARTING_CHASSIS],
		"equipped_chassis": GameData.STARTING_CHASSIS,
		"equipped_weapons": [GameData.STARTING_WEAPON],
		"current_arena": 0,
		"battles_played": 0,
		"battles_won": 0,
		"bosses_beaten": [],
		"last_daily": "",
	}


func _load_account(username: String) -> bool:
	var path := _account_path(username)
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return false
	progress = json.data
	return true


func _save_account_file(username: String, data: Dictionary) -> void:
	var path := _account_path(username)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))


func _save_session() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("session", "username", current_username)
	cfg.save(SESSION_FILE)


func _account_path(username: String) -> String:
	return ACCOUNTS_DIR + username.to_lower() + ".json"


func _is_valid_username(username: String) -> bool:
	var allowed := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
	for i in username.length():
		if not username[i] in allowed:
			return false
	return true


func _arena_trophy_req(arena_index: int) -> int:
	var arena := GameData.get_arena(arena_index)
	if arena.is_empty():
		return 0
	return arena.trophy_required
