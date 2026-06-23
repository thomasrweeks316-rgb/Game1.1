extends Area2D
class_name Projectile

var owner_bot: BattleBot
var weapon_id: String
var weapon_data: Dictionary
var damage: float
var direction: Vector2
var speed: float
var traveled: float = 0.0
var max_range: float
var is_boomerang: bool = false
var returning: bool = false
var _sprite: Polygon2D
var _lifetime: float = 5.0


func setup(bot: BattleBot, wid: String, target_pos: Vector2, dmg: float, wdata: Dictionary, forced_dir: Vector2 = Vector2.ZERO) -> void:
	owner_bot = bot
	weapon_id = wid
	weapon_data = wdata
	damage = dmg
	max_range = wdata.range
	speed = wdata.projectile_speed
	if forced_dir != Vector2.ZERO:
		direction = forced_dir.normalized()
	else:
		direction = (target_pos - bot.global_position).normalized()
	global_position = bot.global_position + direction * 30
	_build_visual(wdata)
	collision_layer = 2
	collision_mask = 1
	monitoring = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _build_visual(wdata: Dictionary) -> void:
	_sprite = Polygon2D.new()
	var col: Color = wdata.get("color", Color.YELLOW)
	match wdata.type:
		"explosive", "mortar":
			_sprite.polygon = PackedVector2Array([Vector2(-6,-4), Vector2(6,-4), Vector2(6,4), Vector2(-6,4)])
		"homing":
			_sprite.polygon = PackedVector2Array([Vector2(0,-8), Vector2(6,6), Vector2(-6,6)])
		_:
			_sprite.polygon = PackedVector2Array([Vector2(-4,-4), Vector2(4,-4), Vector2(4,4), Vector2(-4,4)])
	_sprite.color = col
	add_child(_sprite)
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	_lifetime -= delta
	if _lifetime <= 0:
		queue_free()
		return
	if weapon_data.type == "homing" and owner_bot and owner_bot._target:
		var target_dir := (owner_bot._target.global_position - global_position).normalized()
		direction = direction.lerp(target_dir, 2.0 * delta).normalized()
		rotation = direction.angle()
	if weapon_data.type == "mortar":
		var arc_speed := speed * 0.7
		position += direction * arc_speed * delta
		position.y += sin(traveled * 0.01) * 2.0
	else:
		position += direction * speed * delta
	traveled += speed * delta
	if is_boomerang:
		if not returning and traveled > max_range * 0.5:
			returning = true
			direction = -direction
		if returning and owner_bot:
			var to_owner := (owner_bot.global_position - global_position).normalized()
			direction = direction.lerp(to_owner, 3.0 * delta).normalized()
			if global_position.distance_to(owner_bot.global_position) < 30:
				queue_free()
	elif traveled >= max_range:
		if weapon_data.type in ["explosive", "mortar", "vortex"]:
			_explode()
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == owner_bot:
		return
	if body is BattleBot:
		var bot := body as BattleBot
		_hit_bot(bot)
		if weapon_data.type not in ["piercing"]:
			if weapon_data.type in ["explosive", "mortar"]:
				_explode()
			queue_free()


func _hit_bot(bot: BattleBot) -> void:
	var bypass := weapon_data.type == "piercing"
	bot.take_damage(damage, bypass)
	match weapon_data.type:
		"slow":
			bot.apply_slow(weapon_data.get("slow_factor", 0.5), weapon_data.get("slow_duration", 2.0))
		"poison":
			bot.apply_poison(weapon_data.get("dot_damage", 4), weapon_data.get("dot_duration", 3.0))
		"emp":
			bot.apply_disable(weapon_data.get("disable_duration", 2.0))
		"flame":
			bot.apply_burn(weapon_data.get("dot_damage", 3), weapon_data.get("dot_duration", 2.0))


func _explode() -> void:
	var radius: float = weapon_data.get("blast_radius", 50)
	var parent := get_parent()
	if parent == null:
		return
	for node in parent.get_children():
		if node is BattleBot and node != owner_bot:
			var bot := node as BattleBot
			if global_position.distance_to(bot.global_position) < radius:
				bot.take_damage(damage * 0.8)
	_create_explosion_effect(radius)


func _create_explosion_effect(radius: float) -> void:
	var circle := Polygon2D.new()
	var points: PackedVector2Array = []
	for i in 16:
		var angle := i * TAU / 16
		points.append(Vector2.from_angle(angle) * radius * 0.5)
	circle.polygon = points
	circle.color = Color(1, 0.5, 0.1, 0.6)
	circle.global_position = global_position
	get_parent().add_child(circle)
	var tween := create_tween()
	tween.tween_property(circle, "modulate:a", 0.0, 0.4)
	tween.tween_callback(circle.queue_free)
