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


func spend_trophies(amount: int) -> bool:
	if get_trophies() < amount:
		return false
	progress["trophies"] = get_trophies() - amount
	save_progress()
	return true


func buy_gem_pack(gems: int, trophy_cost: int) -> String:
	if gems <= 0 or trophy_cost <= 0:
		return "Invalid gem pack."
	if not spend_trophies(trophy_cost):
		return "Not enough trophies."
	add_gems(gems)
	return ""


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
	if not is_arena_unlocked(w.arena_unlock):
		return GameData.get_arena_unlock_requirement(w.arena_unlock)
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
	if not is_arena_unlocked(c.arena_unlock):
		return GameData.get_arena_unlock_requirement(c.arena_unlock)
	if not spend_gems(c.gem_cost):
		return "Not enough gems."
	var owned: Array = progress.get("owned_chassis", [])
	owned.append(chassis_id)
	progress["owned_chassis"] = owned
	save_progress()
	return ""


func set_loadout(chassis_id: String, weapons: Array) -> void:
	progress["equipped_chassis"] = chassis_id
	progress["equipped_weapons"] = GameData.trim_weapons_for_chassis(weapons, chassis_id)
	save_progress()


func get_loadout() -> Dictionary:
	var chassis := str(progress.get("equipped_chassis", GameData.STARTING_CHASSIS))
	if GameData.get_chassis(chassis).is_empty():
		chassis = GameData.STARTING_CHASSIS
	var weapons: Array[String] = []
	var raw_weapons = progress.get("equipped_weapons", [GameData.STARTING_WEAPON])
	if raw_weapons is Array:
		for w in raw_weapons:
			var wid := str(w)
			if not wid.is_empty() and not GameData.get_weapon(wid).is_empty() and wid not in weapons:
				weapons.append(wid)
	elif raw_weapons is String and not str(raw_weapons).is_empty():
		var wid := str(raw_weapons)
		if not GameData.get_weapon(wid).is_empty():
			weapons.append(wid)
	if weapons.is_empty():
		weapons.append(GameData.STARTING_WEAPON)
	weapons = GameData.trim_weapons_for_chassis(weapons, chassis)
	return {"chassis": chassis, "weapons": weapons}


func get_current_arena() -> int:
	return progress.get("current_arena", 0)


func is_arena_unlocked(arena_id: int) -> bool:
	return GameData.is_arena_unlocked(arena_id, progress.get("bosses_beaten", []))


func get_highest_unlocked_arena() -> int:
	var highest := 0
	for arena in GameData.ARENAS:
		var arena_id: int = int(arena.get("id", 0))
		if is_arena_unlocked(arena_id):
			highest = maxi(highest, arena_id)
	return highest


func set_current_arena(arena_id: int) -> void:
	progress["current_arena"] = arena_id
	save_progress()


func queue_battle(arena_id: int, boss_fight: bool) -> void:
	pending_battle = {"arena_id": arena_id, "boss": boss_fight}


func record_battle(win: bool, gems_earned: int, trophies_earned: int, boss: bool = false, arena_id: int = -1) -> void:
	progress["battles_played"] = progress.get("battles_played", 0) + 1
	if win:
		progress["battles_won"] = progress.get("battles_won", 0) + 1
		add_gems(gems_earned)
		add_trophies(trophies_earned)
		if boss:
			var beaten: Array = progress.get("bosses_beaten", [])
			var cleared_arena: int = arena_id if arena_id >= 0 else get_current_arena()
			if cleared_arena not in beaten:
				beaten.append(cleared_arena)
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
	progress = _normalize_progress(json.data)
	return true


func _normalize_progress(data: Variant) -> Dictionary:
	if not data is Dictionary:
		return _create_new_progress()
	var normalized: Dictionary = data.duplicate(true)
	if not normalized.has("equipped_chassis"):
		normalized["equipped_chassis"] = GameData.STARTING_CHASSIS
	if not normalized.has("equipped_weapons"):
		normalized["equipped_weapons"] = [GameData.STARTING_WEAPON]
	elif normalized["equipped_weapons"] is String:
		normalized["equipped_weapons"] = [normalized["equipped_weapons"]]
	elif not normalized["equipped_weapons"] is Array:
		normalized["equipped_weapons"] = [GameData.STARTING_WEAPON]
	if not normalized.has("current_arena"):
		normalized["current_arena"] = 0
	else:
		normalized["current_arena"] = int(normalized["current_arena"])
	var beaten: Array = []
	for entry in normalized.get("bosses_beaten", []):
		beaten.append(int(entry))
	normalized["bosses_beaten"] = beaten
	return normalized


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
