extends Control

var _visual: Node2D


func set_chassis(id: String) -> void:
	set_loadout(id, [])


func set_loadout(chassis: String, weapons: Array) -> void:
	if _visual:
		_visual.queue_free()
		_visual = null
	var cdata := GameData.get_chassis(chassis)
	if cdata.is_empty():
		return
	var weapon_list: Array[String] = []
	for w in weapons:
		weapon_list.append(str(w))
	_visual = BotArt.build_battle_visual(
		chassis, weapon_list, cdata.get("color", Color.GRAY), 42.0, true, false
	)
	add_child(_visual)
	_center_visual()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_center_visual()


func _center_visual() -> void:
	if _visual:
		_visual.position = size * 0.5
