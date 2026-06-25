extends Control

var chassis_id: String = ""

const PREVIEW_COLOR := Color(0.2, 0.4, 0.6, 0.45)


func set_chassis(id: String) -> void:
	chassis_id = id
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if chassis_id.is_empty():
		return
	var chassis := GameData.get_chassis(chassis_id)
	if chassis.is_empty():
		return
	var color: Color = chassis.get("color", Color.GRAY)
	var center := size * 0.5
	var s := 40.0
	var points := PackedVector2Array([
		Vector2(0, -s), Vector2(s * 0.85, -s * 0.3),
		Vector2(s * 0.7, s * 0.7), Vector2(-s * 0.7, s * 0.7),
		Vector2(-s * 0.85, -s * 0.3),
	])
	var draw_points := PackedVector2Array()
	for p in points:
		draw_points.append(p + center)
	draw_colored_polygon(draw_points, color)
	var outline := draw_points.duplicate()
	outline.append(draw_points[0])
	draw_polyline(outline, color.lightened(0.35), 2.0)
