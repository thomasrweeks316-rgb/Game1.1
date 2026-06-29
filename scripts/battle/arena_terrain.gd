extends Node2D

const TERRAIN_LAYER := 4


func setup(arena: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	var bg: Color = arena.get("bg_color", Color(0.2, 0.2, 0.2))
	var accent: Color = arena.get("accent", Color.GRAY)
	for block in arena.get("terrain", []):
		_spawn_obstacle(block, bg, accent)


func _ready() -> void:
	z_index = -5


func _spawn_obstacle(data: Dictionary, bg: Color, accent: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = TERRAIN_LAYER
	body.collision_mask = 0
	body.add_to_group("arena_terrain")
	body.position = data.get("pos", Vector2.ZERO)

	var col: Color = data.get("color", bg.lightened(0.12).lerp(accent, 0.25))
	var shape_type := str(data.get("shape", "rect"))

	var collision := CollisionShape2D.new()
	var visual := Polygon2D.new()

	match shape_type:
		"circle":
			var radius: float = float(data.get("radius", 40.0))
			var circle_shape := CircleShape2D.new()
			circle_shape.radius = radius
			collision.shape = circle_shape
			visual.polygon = _circle_points(radius, 18)
		_:
			var size: Vector2 = data.get("size", Vector2(60, 60))
			var rect_shape := RectangleShape2D.new()
			rect_shape.size = size
			collision.shape = rect_shape
			var half := size * 0.5
			visual.polygon = PackedVector2Array([
				Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
				Vector2(half.x, half.y), Vector2(-half.x, half.y),
			])

	visual.color = col
	body.add_child(collision)
	body.add_child(visual)

	var outline := Line2D.new()
	outline.points = visual.polygon
	outline.closed = true
	outline.width = 2.0
	outline.default_color = col.lightened(0.2)
	body.add_child(outline)

	var shade := Polygon2D.new()
	shade.color = Color(0, 0, 0, 0.15)
	var shade_poly := visual.polygon.duplicate()
	for i in shade_poly.size():
		shade_poly[i] = shade_poly[i] * 0.85 + Vector2(0, 4)
	shade.polygon = shade_poly
	body.add_child(shade)
	body.move_child(shade, 0)

	add_child(body)


func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var angle := i * TAU / float(segments)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts
