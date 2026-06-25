extends CharacterBody2D
class_name BattleBot

signal died(bot: BattleBot)
signal health_changed(current: float, maximum: float)

@export var is_player: bool = false
@export var is_boss: bool = false

var chassis_id: String = "light"
var weapon_ids: Array[String] = []
var max_hp: float = 100.0
var current_hp: float = 100.0
var armor: float = 0.0
var move_speed: float = 180.0
var bot_color: Color = Color.GRAY
var bot_size: float = 1.0
var damage_mult: float = 1.0

var _fire_cooldowns: Dictionary = {}
var _shield_amount: float = 0.0
var _shield_timer: float = 0.0
var _slow_timer: float = 0.0
var _slow_factor: float = 1.0
var _disabled_timer: float = 0.0
var _burn_timer: float = 0.0
var _burn_dps: float = 0.0
var _poison_timer: float = 0.0
var _poison_dps: float = 0.0
var _active_weapon_index: int = 0

var _visual: CanvasItem
var _model_path: String = ""
var _model_scale: float = 1.0
var _model_viewport: SubViewport
var _model_root: Node3D
var _visual_size: float = 28.0
var _hp_bar_bg: ColorRect
var _hp_bar: ColorRect
var _name_label: Label
var _battle_scene: Node2D
var _target: BattleBot = null
var _ai_timer: float = 0.0
var _ai_move_target: Vector2 = Vector2.ZERO
var _rclick_was_pressed: bool = false


func setup(chassis: String, weapons: Array, player: bool, boss: bool = false, boss_data: Dictionary = {}) -> void:
	is_player = player
	is_boss = boss
	chassis_id = chassis
	weapon_ids.clear()
	for w in weapons:
		weapon_ids.append(w)
	var chassis_data := GameData.get_chassis(chassis)
	max_hp = chassis_data.get("hp", 100)
	if boss:
		max_hp = boss_data.get("hp", max_hp)
		damage_mult = boss_data.get("damage_mult", 1.0)
		move_speed = boss_data.get("speed", move_speed)
		bot_size = boss_data.get("size", 2.0)
		bot_color = boss_data.get("color", Color.RED)
		_model_path = boss_data.get("model", "")
		_model_scale = boss_data.get("model_scale", 1.0)
	else:
		armor = chassis_data.get("armor", 0)
		move_speed = chassis_data.get("speed", 180)
		bot_color = chassis_data.get("color", Color.GRAY)
		bot_size = 1.0
	current_hp = max_hp
	_build_visuals()
	for wid in weapon_ids:
		_fire_cooldowns[wid] = 0.0


func _build_visuals() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			continue
		child.queue_free()
	_visual = null
	_model_viewport = null
	_model_root = null
	if is_boss and not _model_path.is_empty():
		_build_model_visual()
	else:
		_build_polygon_visual()
	_add_hud_visuals()


func _build_polygon_visual() -> void:
	_visual_size = bot_size * 28.0
	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([
		Vector2(0, -_visual_size), Vector2(_visual_size * 0.85, -_visual_size * 0.3),
		Vector2(_visual_size * 0.7, _visual_size * 0.7), Vector2(-_visual_size * 0.7, _visual_size * 0.7),
		Vector2(-_visual_size * 0.85, -_visual_size * 0.3),
	])
	polygon.color = bot_color
	add_child(polygon)
	_visual = polygon
	var outline := Line2D.new()
	outline.points = polygon.polygon
	outline.closed = true
	outline.width = 2.0
	outline.default_color = bot_color.lightened(0.3)
	add_child(outline)


func _build_model_visual() -> void:
	var viewport_size := 512
	_visual_size = bot_size * 70.0
	_model_viewport = SubViewport.new()
	_model_viewport.size = Vector2i(viewport_size, viewport_size)
	_model_viewport.transparent_bg = true
	_model_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_model_viewport)
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.45, 0.45, 0.5)
	environment.ambient_light_energy = 0.8
	world_env.environment = environment
	_model_viewport.add_child(world_env)
	var camera := Camera3D.new()
	camera.position = Vector3(2.4, 2.2, 4.2)
	camera.look_at(Vector3(0.0, 0.6, 0.0))
	_model_viewport.add_child(camera)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-50, 35, 0)
	key_light.light_energy = 1.2
	_model_viewport.add_child(key_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-2.5, 2.5, 2.0)
	fill_light.light_energy = 0.5
	_model_viewport.add_child(fill_light)
	var scene: PackedScene = load(_model_path)
	if scene:
		_model_root = scene.instantiate() as Node3D
		if _model_root:
			var scale_factor := _model_scale * bot_size * 0.35
			_model_root.scale = Vector3.ONE * scale_factor
			_model_root.position.y = 0.0
			_model_viewport.add_child(_model_root)
	if _model_root == null:
		_model_viewport.queue_free()
		_model_viewport = null
		_model_path = ""
		_build_polygon_visual()
		return
	var sprite := Sprite2D.new()
	sprite.texture = _model_viewport.get_texture()
	sprite.centered = true
	var display_scale := _visual_size * 2.0 / float(viewport_size)
	sprite.scale = Vector2(display_scale, display_scale)
	sprite.position.y = _visual_size * 0.15
	add_child(sprite)
	_visual = sprite


func _add_hud_visuals() -> void:
	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.size = Vector2(60 * bot_size, 6)
	_hp_bar_bg.position = Vector2(-30 * bot_size, -_visual_size - 16)
	_hp_bar_bg.color = Color(0.2, 0.2, 0.2)
	add_child(_hp_bar_bg)
	_hp_bar = ColorRect.new()
	_hp_bar.size = Vector2(60 * bot_size, 6)
	_hp_bar.position = _hp_bar_bg.position
	_hp_bar.color = Color(0.2, 0.9, 0.3) if is_player else Color(0.9, 0.2, 0.2)
	add_child(_hp_bar)
	if is_boss:
		_name_label = Label.new()
		_name_label.text = "BOSS"
		_name_label.position = Vector2(-40, -_visual_size - 36)
		_name_label.add_theme_font_size_override("font_size", 14)
		_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		add_child(_name_label)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	for child in get_children():
		if child is CollisionShape2D:
			var circle := child.shape as CircleShape2D
			if circle:
				circle.radius = 28.0 * bot_size


func _physics_process(delta: float) -> void:
	_process_status(delta)
	_update_cooldowns(delta)
	_update_hp_bar()
	if is_player:
		_player_move(delta)
	else:
		_ai_behavior(delta)
	if _fire_cooldowns.is_empty() and weapon_ids.size() > 0:
		for w in weapon_ids:
			_fire_cooldowns[w] = 0.0


func _process_status(delta: float) -> void:
	if _burn_timer > 0:
		_burn_timer -= delta
		take_damage(_burn_dps * delta, true)
	if _poison_timer > 0:
		_poison_timer -= delta
		take_damage(_poison_dps * delta, true)
	if _slow_timer > 0:
		_slow_timer -= delta
		if _slow_timer <= 0:
			_slow_factor = 1.0
	if _disabled_timer > 0:
		_disabled_timer -= delta
	if _shield_timer > 0:
		_shield_timer -= delta
		if _shield_timer <= 0:
			_shield_amount = 0.0


func set_battle_scene(scene: Node2D) -> void:
	_battle_scene = scene


func set_target(target: BattleBot) -> void:
	_target = target


func _player_move(delta: float) -> void:
	if _battle_scene == null:
		return
	var mouse_pos: Vector2 = _battle_scene.get_global_mouse_position()
	var dir := (mouse_pos - global_position)
	if dir.length() > 20:
		velocity = dir.normalized() * move_speed * _slow_factor
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	global_position.x = clampf(global_position.x, 40.0, 1240.0)
	global_position.y = clampf(global_position.y, 60.0, 660.0)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		fire_at(mouse_pos)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if not _rclick_was_pressed and weapon_ids.size() > 1:
			_cycle_weapon()
		_rclick_was_pressed = true
	else:
		_rclick_was_pressed = false
	# Weapon hotkeys via mouse wheel
	if Input.is_action_just_pressed("weapon_next"):
		_cycle_weapon()
	if Input.is_action_just_pressed("weapon_prev"):
		_active_weapon_index = (_active_weapon_index - 1 + weapon_ids.size()) % weapon_ids.size()


func _cycle_weapon() -> void:
	if weapon_ids.size() <= 1:
		return
	_active_weapon_index = (_active_weapon_index + 1) % weapon_ids.size()


func get_active_weapon() -> String:
	if weapon_ids.is_empty():
		return ""
	return weapon_ids[_active_weapon_index]


func fire_at(target_pos: Vector2) -> void:
	if _disabled_timer > 0 or weapon_ids.is_empty() or _battle_scene == null:
		return
	var wid := get_active_weapon()
	if _fire_cooldowns.get(wid, 0.0) > 0:
		return
	var wdata := GameData.get_weapon(wid)
	if wdata.is_empty():
		return
	_fire_cooldowns[wid] = wdata.fire_rate
	var dmg := wdata.damage * damage_mult
	match wdata.type:
		"bullet", "piercing", "slow", "poison", "homing":
			_spawn_projectile(wid, target_pos, dmg, wdata)
		"spread":
			var base_angle := (target_pos - global_position).angle()
			var pellets: int = wdata.get("pellets", 5)
			for i in pellets:
				var spread := base_angle + randf_range(-0.3, 0.3)
				var dir := Vector2.from_angle(spread)
				_spawn_projectile(wid, global_position + dir * 200, dmg, wdata, dir)
		"explosive", "mortar":
			_spawn_projectile(wid, target_pos, dmg, wdata)
		"melee":
			_melee_attack(wid, wdata, target_pos)
		"flame":
			_flame_attack(wdata, target_pos)
		"chain":
			_chain_attack(wdata, target_pos)
		"shield":
			_activate_shield(wdata)
		"emp":
			_spawn_projectile(wid, target_pos, dmg, wdata)
		"gravity":
			_gravity_attack(wdata, target_pos)
		"boomerang":
			_spawn_boomerang(wid, target_pos, dmg, wdata)
		"vortex":
			_spawn_projectile(wid, target_pos, dmg, wdata)


func _spawn_projectile(wid: String, target_pos: Vector2, dmg: float, wdata: Dictionary, forced_dir: Vector2 = Vector2.ZERO) -> void:
	var proj := preload("res://scenes/battle/projectile.tscn").instantiate()
	proj.setup(self, wid, target_pos, dmg, wdata, forced_dir)
	_battle_scene.add_child(proj)


func _spawn_boomerang(wid: String, target_pos: Vector2, dmg: float, wdata: Dictionary) -> void:
	var proj := preload("res://scenes/battle/projectile.tscn").instantiate()
	proj.setup(self, wid, target_pos, dmg, wdata)
	proj.is_boomerang = true
	_battle_scene.add_child(proj)


func _melee_attack(wid: String, wdata: Dictionary, target_pos: Vector2) -> void:
	var range: float = wdata.range
	if _target and global_position.distance_to(_target.global_position) <= range:
		var dmg := wdata.damage * damage_mult
		_target.take_damage(dmg)
		if wdata.get("armor_break", false):
			_target.armor = maxf(0, _target.armor - 10)


func _flame_attack(wdata: Dictionary, target_pos: Vector2) -> void:
	if _target == null:
		return
	var dir := (target_pos - global_position).normalized()
	var to_target := (_target.global_position - global_position).normalized()
	if dir.dot(to_target) > 0.5 and global_position.distance_to(_target.global_position) < wdata.range:
		_target.take_damage(wdata.damage * damage_mult)
		_target.apply_burn(wdata.get("dot_damage", 3), wdata.get("dot_duration", 2.0))


func _chain_attack(wdata: Dictionary, target_pos: Vector2) -> void:
	if _target == null:
		return
	var hit: Array[BattleBot] = [_target]
	_target.take_damage(wdata.damage * damage_mult)
	var chain_count: int = wdata.get("chain_count", 2)
	var current_pos := _target.global_position
	for _i in chain_count:
		var nearest: BattleBot = null
		var nearest_dist := 150.0
		for node in _battle_scene.get_children():
			if node is BattleBot and node != self and node not in hit and node.current_hp > 0:
				var d := current_pos.distance_to(node.global_position)
				if d < nearest_dist:
					nearest = node
					nearest_dist = d
		if nearest:
			hit.append(nearest)
			nearest.take_damage(wdata.damage * damage_mult * 0.7)
			current_pos = nearest.global_position
			_draw_lightning(_target.global_position if hit.size() == 1 else hit[-2].global_position, nearest.global_position)


func _draw_lightning(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(0.3, 0.7, 1.0)
	var points: PackedVector2Array = [from]
	var segments := 5
	for i in range(1, segments):
		var t := float(i) / segments
		var p := from.lerp(to, t) + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		points.append(p)
	points.append(to)
	line.points = points
	_battle_scene.add_child(line)
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.3)
	tween.tween_callback(line.queue_free)


func _activate_shield(wdata: Dictionary) -> void:
	_shield_amount = wdata.get("shield_amount", 50)
	_shield_timer = wdata.get("shield_duration", 3.0)


func _gravity_attack(wdata: Dictionary, target_pos: Vector2) -> void:
	var radius: float = wdata.get("pull_radius", 100)
	for node in _battle_scene.get_children():
		if node is BattleBot and node != self and node.current_hp > 0:
			var dist := global_position.distance_to(node.global_position)
			if dist < radius:
				var pull := (global_position - node.global_position).normalized() * 200
				node.velocity += pull * 0.05
				node.take_damage(wdata.damage * damage_mult * 0.1)


func _ai_behavior(delta: float) -> void:
	if _target == null or _target.current_hp <= 0:
		return
	_ai_timer -= delta
	var dist := global_position.distance_to(_target.global_position)
	if _ai_timer <= 0:
		_ai_timer = randf_range(0.5, 1.5)
		if dist > 250:
			_ai_move_target = _target.global_position
		elif dist < 100:
			var away := (global_position - _target.global_position).normalized()
			_ai_move_target = global_position + away * 150
		else:
			_ai_move_target = _target.global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))
	var dir := (_ai_move_target - global_position)
	if dir.length() > 15:
		velocity = dir.normalized() * move_speed * _slow_factor * 0.85
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	global_position.x = clampf(global_position.x, 40.0, 1240.0)
	global_position.y = clampf(global_position.y, 60.0, 660.0)
	_update_model_facing()
	if _disabled_timer <= 0 and weapon_ids.size() > 0:
		var aim_pos := _target.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		if randf() < 0.03 * weapon_ids.size():
			_active_weapon_index = randi() % weapon_ids.size()
		fire_at(aim_pos)


func take_damage(amount: float, bypass_armor: bool = false) -> void:
	if current_hp <= 0:
		return
	var actual := amount
	if not bypass_armor:
		actual = maxf(1.0, amount - armor * 0.5)
	if _shield_amount > 0:
		var absorbed := mini(actual, _shield_amount)
		_shield_amount -= absorbed
		actual -= absorbed
	current_hp -= actual
	health_changed.emit(current_hp, max_hp)
	_flash_damage()
	if current_hp <= 0:
		current_hp = 0
		died.emit(self)


func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = factor
	_slow_timer = duration


func apply_burn(dps: float, duration: float) -> void:
	_burn_dps = dps
	_burn_timer = duration


func apply_poison(dps: float, duration: float) -> void:
	_poison_dps = maxf(_poison_dps, dps)
	_poison_timer = maxf(_poison_timer, duration)


func apply_disable(duration: float) -> void:
	_disabled_timer = duration


func _update_model_facing() -> void:
	if _model_root == null or _target == null or _target.current_hp <= 0:
		return
	var dir := _target.global_position - global_position
	if dir.length_squared() > 1.0:
		_model_root.rotation.y = atan2(dir.x, dir.y)


func _flash_damage() -> void:
	if _visual:
		_visual.modulate = Color(1, 0.3, 0.3)
		var tween := create_tween()
		tween.tween_property(_visual, "modulate", Color.WHITE, 0.15)


func _update_cooldowns(delta: float) -> void:
	for key in _fire_cooldowns:
		if _fire_cooldowns[key] > 0:
			_fire_cooldowns[key] -= delta


func _update_hp_bar() -> void:
	if _hp_bar and max_hp > 0:
		var ratio := current_hp / max_hp
		_hp_bar.size.x = 60 * bot_size * ratio
