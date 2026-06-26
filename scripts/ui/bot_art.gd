extends Node

const ICON_SIZE := 40

var _weapon_icons: Dictionary = {}
var _chassis_icons: Dictionary = {}


func get_weapon_icon(weapon_id: String) -> Texture2D:
	if _weapon_icons.has(weapon_id):
		return _weapon_icons[weapon_id]
	var wdata := GameData.get_weapon(weapon_id)
	var tex := _texture_from_draw(func(canvas: Vector2i, draw: Callable) -> void:
		_draw_weapon_icon(draw, canvas, wdata)
	)
	_weapon_icons[weapon_id] = tex
	return tex


func get_chassis_icon(chassis_id: String) -> Texture2D:
	if _chassis_icons.has(chassis_id):
		return _chassis_icons[chassis_id]
	var cdata := GameData.get_chassis(chassis_id)
	var tex := _texture_from_draw(func(canvas: Vector2i, draw: Callable) -> void:
		_draw_chassis_icon(draw, canvas, chassis_id, cdata)
	)
	_chassis_icons[chassis_id] = tex
	return tex


func build_battle_visual(
	chassis_id: String,
	weapon_ids: Array,
	body_color: Color,
	visual_size: float,
	is_player: bool,
	is_boss: bool,
) -> Node2D:
	var root := Node2D.new()
	var s := visual_size

	# Ground shadow
	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.25)
	shadow.polygon = PackedVector2Array([
		Vector2(-s * 0.9, s * 0.55), Vector2(s * 0.9, s * 0.55),
		Vector2(s * 0.7, s * 0.75), Vector2(-s * 0.7, s * 0.75),
	])
	shadow.position.y = s * 0.35
	root.add_child(shadow)

	# Team ring
	var ring := Line2D.new()
	ring.closed = true
	ring.width = 2.5
	ring.default_color = Color(0.25, 0.85, 1.0, 0.75) if is_player else Color(1.0, 0.35, 0.3, 0.75)
	var ring_pts := PackedVector2Array()
	for i in 24:
		var a := i * TAU / 24.0
		ring_pts.append(Vector2(cos(a), sin(a)) * s * 1.15)
	ring.points = ring_pts
	root.add_child(ring)

	# Tracks / base
	var tread_color := body_color.darkened(0.35)
	for side in [-1, 1]:
		var tread := Polygon2D.new()
		tread.color = tread_color
		var tw := s * 0.22
		var th := s * 0.55
		tread.polygon = PackedVector2Array([
			Vector2(side * s * 0.55, th * 0.2), Vector2(side * (s * 0.55 + tw), th * 0.1),
			Vector2(side * (s * 0.55 + tw), th), Vector2(side * s * 0.55, th * 0.9),
		])
		root.add_child(tread)

	# Main hull
	var hull := Polygon2D.new()
	hull.polygon = _chassis_body_polygon(chassis_id, s, is_boss)
	hull.color = body_color
	root.add_child(hull)

	var hull_shine := Polygon2D.new()
	hull_shine.polygon = _chassis_shine_polygon(chassis_id, s, is_boss)
	hull_shine.color = body_color.lightened(0.22)
	root.add_child(hull_shine)

	var hull_outline := Line2D.new()
	hull_outline.points = hull.polygon
	hull_outline.closed = true
	hull_outline.width = 2.0
	hull_outline.default_color = body_color.lightened(0.4)
	root.add_child(hull_outline)

	# Cockpit / sensor
	var cockpit := Polygon2D.new()
	cockpit.color = Color(0.15, 0.2, 0.28, 0.9)
	cockpit.polygon = PackedVector2Array([
		Vector2(-s * 0.12, -s * 0.35), Vector2(s * 0.12, -s * 0.35),
		Vector2(s * 0.08, -s * 0.15), Vector2(-s * 0.08, -s * 0.15),
	])
	root.add_child(cockpit)

	var sensor := Polygon2D.new()
	sensor.color = Color(0.3, 1.0, 0.9, 0.9) if is_player else Color(1.0, 0.45, 0.2, 0.9)
	sensor.polygon = _circle_polygon(Vector2(0, -s * 0.25), s * 0.06, 8)
	root.add_child(sensor)

	# Weapon mounts
	var mount_count := mini(weapon_ids.size(), 3)
	for i in mount_count:
		var wid: String = str(weapon_ids[i])
		var wdata := GameData.get_weapon(wid)
		var wcol: Color = wdata.get("color", Color.GRAY)
		var angle := -0.55 + float(i) * 0.55
		var mount_pos := Vector2(sin(angle), -cos(angle)) * s * 0.72
		_add_weapon_mount(root, mount_pos, wcol, wdata, s * 0.2)

	if is_boss:
		var spike_color := body_color.lightened(0.15)
		for i in 4:
			var a := i * TAU / 4.0 + PI * 0.25
			var spike := Polygon2D.new()
			spike.color = spike_color
			var base := Vector2(cos(a), sin(a)) * s * 0.75
			spike.polygon = PackedVector2Array([
				base,
				base + Vector2(cos(a - 0.2), sin(a - 0.2)) * s * 0.35,
				base + Vector2(cos(a), sin(a)) * s * 0.55,
				base + Vector2(cos(a + 0.2), sin(a + 0.2)) * s * 0.35,
			])
			root.add_child(spike)

	return root


func _chassis_body_polygon(chassis_id: String, s: float, is_boss: bool) -> PackedVector2Array:
	var scale := 1.15 if is_boss else 1.0
	match chassis_id:
		"light":
			return PackedVector2Array([
				Vector2(0, -s * 0.95 * scale), Vector2(s * 0.55 * scale, -s * 0.15 * scale),
				Vector2(s * 0.45 * scale, s * 0.65 * scale), Vector2(-s * 0.45 * scale, s * 0.65 * scale),
				Vector2(-s * 0.55 * scale, -s * 0.15 * scale),
			])
		"heavy", "titan":
			return PackedVector2Array([
				Vector2(-s * 0.7 * scale, -s * 0.45 * scale), Vector2(s * 0.7 * scale, -s * 0.45 * scale),
				Vector2(s * 0.75 * scale, s * 0.2 * scale), Vector2(s * 0.55 * scale, s * 0.7 * scale),
				Vector2(-s * 0.55 * scale, s * 0.7 * scale), Vector2(-s * 0.75 * scale, s * 0.2 * scale),
			])
		"stealth":
			return PackedVector2Array([
				Vector2(0, -s * 0.85 * scale), Vector2(s * 0.75 * scale, 0),
				Vector2(0, s * 0.55 * scale), Vector2(-s * 0.75 * scale, 0),
			])
		_:
			return PackedVector2Array([
				Vector2(0, -s * 0.85 * scale), Vector2(s * 0.65 * scale, -s * 0.25 * scale),
				Vector2(s * 0.6 * scale, s * 0.6 * scale), Vector2(-s * 0.6 * scale, s * 0.6 * scale),
				Vector2(-s * 0.65 * scale, -s * 0.25 * scale),
			])


func _chassis_shine_polygon(chassis_id: String, s: float, is_boss: bool) -> PackedVector2Array:
	var scale := 1.15 if is_boss else 1.0
	match chassis_id:
		"stealth":
			return PackedVector2Array([
				Vector2(0, -s * 0.45 * scale), Vector2(s * 0.28 * scale, -s * 0.05 * scale),
				Vector2(0, s * 0.15 * scale), Vector2(-s * 0.28 * scale, -s * 0.05 * scale),
			])
		_:
			return PackedVector2Array([
				Vector2(-s * 0.15 * scale, -s * 0.55 * scale), Vector2(s * 0.15 * scale, -s * 0.55 * scale),
				Vector2(s * 0.1 * scale, -s * 0.2 * scale), Vector2(-s * 0.1 * scale, -s * 0.2 * scale),
			])


func _add_weapon_mount(parent: Node2D, pos: Vector2, color: Color, wdata: Dictionary, size: float) -> void:
	var wtype := str(wdata.get("type", "bullet"))
	var mount := Node2D.new()
	mount.position = pos
	mount.rotation = pos.angle() + PI * 0.5
	parent.add_child(mount)

	var base := Polygon2D.new()
	base.color = color.darkened(0.25)
	base.polygon = PackedVector2Array([
		Vector2(-size * 0.35, -size * 0.2), Vector2(size * 0.35, -size * 0.2),
		Vector2(size * 0.25, size * 0.2), Vector2(-size * 0.25, size * 0.2),
	])
	mount.add_child(base)

	match wtype:
		"melee", "boomerang":
			var blade := Polygon2D.new()
			blade.color = color
			blade.polygon = _circle_polygon(Vector2(0, -size * 0.35), size * 0.45, 10)
			mount.add_child(blade)
		"explosive", "mortar", "homing":
			var barrel := Polygon2D.new()
			barrel.color = color
			barrel.polygon = PackedVector2Array([
				Vector2(-size * 0.15, -size * 0.55), Vector2(size * 0.15, -size * 0.55),
				Vector2(size * 0.1, -size * 0.1), Vector2(-size * 0.1, -size * 0.1),
			])
			mount.add_child(barrel)
		"flame":
			for i in 3:
				var flame := Polygon2D.new()
				flame.color = color.lightened(0.1 * i)
				var fx := (i - 1) * size * 0.12
				flame.polygon = PackedVector2Array([
					Vector2(fx, -size * 0.1), Vector2(fx + size * 0.1, -size * 0.55),
					Vector2(fx - size * 0.1, -size * 0.55),
				])
				mount.add_child(flame)
		_:
			var gun := Polygon2D.new()
			gun.color = color
			gun.polygon = PackedVector2Array([
				Vector2(-size * 0.12, -size * 0.15), Vector2(size * 0.12, -size * 0.15),
				Vector2(size * 0.08, -size * 0.65), Vector2(-size * 0.08, -size * 0.65),
			])
			mount.add_child(gun)


func _circle_polygon(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := i * TAU / float(segments)
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts


func _texture_from_draw(drawer: Callable) -> ImageTexture:
	var size := ICON_SIZE
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.12, 0.14, 0.2, 1.0))
	drawer.call(Vector2i(size, size), func(x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				if x >= 0 and y >= 0 and x < size and y < size:
					img.set_pixel(x, y, col)
	)
	var tex := ImageTexture.create_from_image(img)
	return tex


func _draw_weapon_icon(draw: Callable, canvas: Vector2i, wdata: Dictionary) -> void:
	var col: Color = wdata.get("color", Color.WHITE)
	var cx := canvas.x / 2
	var cy := canvas.y / 2
	var wtype := str(wdata.get("type", "bullet"))
	match wtype:
		"spread":
			for i in 5:
				var a := -0.4 + i * 0.2
				_draw_line(draw, cx, cy + 8, cx + int(sin(a) * 14), cy - int(cos(a) * 14), col, 2)
		"melee", "boomerang":
			_draw_circle(draw, cx, cy, 12, col)
			_draw_circle(draw, cx, cy, 6, col.lightened(0.3))
		"explosive", "mortar", "homing":
			_draw_rect(draw, cx - 4, cy - 14, cx + 4, cy + 6, col.darkened(0.2))
			_draw_triangle(draw, cx, cy - 16, cx - 6, cy - 6, cx + 6, cy - 6, col)
		"chain":
			_draw_line(draw, cx - 10, cy - 8, cx, cy, col, 2)
			_draw_line(draw, cx, cy, cx + 10, cy + 8, col.lightened(0.2), 2)
		"flame":
			_draw_triangle(draw, cx, cy - 14, cx - 8, cy + 8, cx + 8, cy + 8, col)
			_draw_triangle(draw, cx, cy - 10, cx - 4, cy + 4, cx + 4, cy + 4, col.lightened(0.25))
		"shield":
			_draw_circle(draw, cx, cy, 13, Color(col.r, col.g, col.b, 0.35))
			_draw_rect(draw, cx - 10, cy - 4, cx + 10, cy + 10, col)
		"gravity", "vortex":
			_draw_circle(draw, cx, cy, 11, col.darkened(0.15))
			_draw_circle(draw, cx, cy, 5, col.lightened(0.2))
		_:
			_draw_rect(draw, cx - 3, cy - 12, cx + 3, cy + 10, col.darkened(0.15))
			_draw_rect(draw, cx - 2, cy - 14, cx + 2, cy - 8, col)


func _draw_chassis_icon(draw: Callable, canvas: Vector2i, chassis_id: String, cdata: Dictionary) -> void:
	var col: Color = cdata.get("color", Color.GRAY)
	var cx := canvas.x / 2
	var cy := canvas.y / 2 + 2
	var pts: PackedVector2Array
	match chassis_id:
		"light":
			pts = PackedVector2Array([Vector2(cx, cy - 14), Vector2(cx + 12, cy + 10), Vector2(cx - 12, cy + 10)])
		"heavy", "titan":
			pts = PackedVector2Array([
				Vector2(cx - 14, cy - 8), Vector2(cx + 14, cy - 8),
				Vector2(cx + 12, cy + 12), Vector2(cx - 12, cy + 12),
			])
		"stealth":
			pts = PackedVector2Array([Vector2(cx, cy - 12), Vector2(cx + 14, cy), Vector2(cx, cy + 12), Vector2(cx - 14, cy)])
		_:
			pts = PackedVector2Array([
				Vector2(cx, cy - 13), Vector2(cx + 11, cy - 2),
				Vector2(cx + 9, cy + 11), Vector2(cx - 9, cy + 11), Vector2(cx - 11, cy - 2),
			])
	_fill_polygon(draw, pts, col)
	_draw_rect(draw, cx - 14, cy + 10, cx + 14, cy + 14, col.darkened(0.4))


func _fill_polygon(draw: Callable, points: PackedVector2Array, col: Color) -> void:
	if points.size() < 3:
		return
	var min_x := int(points[0].x)
	var max_x := int(points[0].x)
	var min_y := int(points[0].y)
	var max_y := int(points[0].y)
	for p in points:
		min_x = mini(min_x, int(p.x))
		max_x = maxi(max_x, int(p.x))
		min_y = mini(min_y, int(p.y))
		max_y = maxi(max_y, int(p.y))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if _point_in_polygon(Vector2(x, y), points):
				draw.call(x, y, x, y, col)


func _point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var inside := false
	var j := polygon.size() - 1
	for i in polygon.size():
		var pi := polygon[i]
		var pj := polygon[j]
		if ((pi.y > point.y) != (pj.y > point.y)) and \
				(point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y + 0.00001) + pi.x):
			inside = not inside
		j = i
	return inside


func _draw_rect(draw: Callable, x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
	draw.call(mini(x0, x1), mini(y0, y1), maxi(x0, x1), maxi(y0, y1), col)


func _draw_circle(draw: Callable, cx: int, cy: int, radius: int, col: Color) -> void:
	for y in range(cy - radius, cy + radius + 1):
		for x in range(cx - radius, cx + radius + 1):
			if Vector2(x - cx, y - cy).length() <= radius:
				draw.call(x, y, x, y, col)


func _draw_line(draw: Callable, x0: int, y0: int, x1: int, y1: int, col: Color, thickness: int) -> void:
	var dist := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in dist + 1:
		var t := float(i) / float(maxi(dist, 1))
		var x := int(lerpf(float(x0), float(x1), t))
		var y := int(lerpf(float(y0), float(y1), t))
		_draw_circle(draw, x, y, thickness, col)


func _draw_triangle(draw: Callable, x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, col: Color) -> void:
	_fill_polygon(draw, PackedVector2Array([Vector2(x0, y0), Vector2(x1, y1), Vector2(x2, y2)]), col)
