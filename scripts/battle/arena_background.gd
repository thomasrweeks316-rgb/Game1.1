extends Node2D

const VIEW_SIZE := Vector2(1280, 720)

var _bg_color := Color(0.2, 0.18, 0.15)
var _accent := Color(0.7, 0.5, 0.3)
var _arena_id := 0
var _preview_mode := false
var _time := 0.0
var _particles: Array[Dictionary] = []
var _decor: Array[Dictionary] = []


func setup(arena: Dictionary, preview_mode: bool = false) -> void:
	_bg_color = arena.get("bg_color", _bg_color)
	_accent = arena.get("accent", _accent)
	_arena_id = int(arena.get("id", 0))
	_preview_mode = preview_mode
	_particles.clear()
	_decor.clear()
	_spawn_particles()
	_spawn_decor()
	queue_redraw()


func _ready() -> void:
	z_index = -100


func _process(delta: float) -> void:
	_time += delta
	_animate_particles(delta)
	queue_redraw()


func _draw() -> void:
	_draw_gradient_sky()
	if not _preview_mode:
		_draw_floor()
	_draw_arena_theme()
	_draw_decor()
	_draw_particles()
	_draw_vignette()
	if not _preview_mode:
		_draw_arena_border()


func _draw_gradient_sky() -> void:
	var horizon := VIEW_SIZE.y if _preview_mode else VIEW_SIZE.y * 0.55
	var bands := 16
	for i in bands:
		var t0 := float(i) / float(bands)
		var t1 := float(i + 1) / float(bands)
		var y0 := horizon * t0
		var y1 := horizon * t1
		var col := _bg_color.darkened(0.35).lerp(_bg_color.lightened(0.08).lerp(_accent, 0.18), t0)
		draw_rect(Rect2(0, y0, VIEW_SIZE.x, y1 - y0 + 1.0), col)


func _draw_floor() -> void:
	var floor_y := VIEW_SIZE.y * 0.55
	var floor_col := _bg_color.darkened(0.2)
	draw_rect(Rect2(0, floor_y, VIEW_SIZE.x, VIEW_SIZE.y - floor_y), floor_col)

	# Perspective grid
	var grid_col := _accent
	grid_col.a = 0.18
	var vanish := Vector2(VIEW_SIZE.x * 0.5, floor_y - 40)
	for i in range(-8, 9):
		var x := VIEW_SIZE.x * 0.5 + i * 90
		draw_line(vanish, Vector2(x, VIEW_SIZE.y + 20), grid_col, 1.0)
	for row in range(6):
		var t := float(row + 1) / 7.0
		var y := lerpf(floor_y + 20, VIEW_SIZE.y - 10, t)
		var spread := lerpf(80, VIEW_SIZE.x * 0.55, t)
		draw_line(Vector2(VIEW_SIZE.x * 0.5 - spread, y), Vector2(VIEW_SIZE.x * 0.5 + spread, y), grid_col, 1.0)

	# Center battle circle
	var ring_col := _accent
	ring_col.a = 0.22
	draw_arc(Vector2(VIEW_SIZE.x * 0.5, VIEW_SIZE.y * 0.62), 280, 0, TAU, 64, ring_col, 2.0)
	draw_arc(Vector2(VIEW_SIZE.x * 0.5, VIEW_SIZE.y * 0.62), 180, 0, TAU, 48, ring_col, 1.0)


func _draw_arena_theme() -> void:
	match _arena_id:
		0:
			_draw_scrap_theme()
		1:
			_draw_factory_theme()
		2:
			_draw_volcano_theme()
		3:
			_draw_ice_theme()
		4:
			_draw_toxic_theme()
		5:
			_draw_neon_theme()
		6:
			_draw_space_theme()
		7:
			_draw_ruins_theme()
		_:
			_draw_void_theme()


func _draw_scrap_theme() -> void:
	var rust := Color(0.55, 0.35, 0.2, 0.35)
	for i in 4:
		var x := 80 + i * 280
		draw_rect(Rect2(x, VIEW_SIZE.y * 0.58, 60, 90), rust)
		draw_rect(Rect2(x + 20, VIEW_SIZE.y * 0.52, 40, 30), rust.darkened(0.1))


func _draw_factory_theme() -> void:
	var belt_col := Color(0.35, 0.38, 0.42, 0.5)
	var offset := fmod(_time * 60.0, 40.0)
	for x in range(-1, 18):
		var bx := x * 80.0 - offset
		draw_rect(Rect2(bx, VIEW_SIZE.y * 0.72, 50, 16), belt_col)


func _draw_volcano_theme() -> void:
	var lava := Color(1.0, 0.35, 0.05, 0.35 + sin(_time * 2.0) * 0.1)
	for i in 5:
		var x := 120 + i * 230
		var wobble := sin(_time * 1.5 + i) * 6.0
		draw_rect(Rect2(x, VIEW_SIZE.y * 0.78 + wobble, 90, 14), lava)
	# Heat glow
	draw_circle(Vector2(VIEW_SIZE.x * 0.5, VIEW_SIZE.y * 0.9), 200, Color(1.0, 0.3, 0.0, 0.08))


func _draw_ice_theme() -> void:
	var ice := Color(0.75, 0.9, 1.0, 0.25)
	for i in 3:
		var x := 200 + i * 340
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, VIEW_SIZE.y * 0.55), Vector2(x + 40, VIEW_SIZE.y * 0.9),
			Vector2(x - 40, VIEW_SIZE.y * 0.9),
		]), ice)


func _draw_toxic_theme() -> void:
	var pool := Color(0.3, 0.85, 0.15, 0.25 + sin(_time * 1.2) * 0.05)
	draw_circle(Vector2(300, VIEW_SIZE.y * 0.82), 70, pool)
	draw_circle(Vector2(900, VIEW_SIZE.y * 0.78), 90, pool)
	draw_circle(Vector2(640, VIEW_SIZE.y * 0.88), 55, pool.darkened(0.1))


func _draw_neon_theme() -> void:
	var pulse := 0.5 + sin(_time * 3.0) * 0.5
	var neon := _accent
	neon.a = 0.25 * pulse
	for i in 6:
		var y := 120 + i * 90
		draw_line(Vector2(0, y), Vector2(VIEW_SIZE.x, y), neon, 2.0)
	draw_line(Vector2(100, 0), Vector2(100, VIEW_SIZE.y), _accent * Color(1, 1, 1, 0.2 * pulse), 3.0)
	draw_line(Vector2(VIEW_SIZE.x - 100, 0), Vector2(VIEW_SIZE.x - 100, VIEW_SIZE.y), _accent * Color(1, 1, 1, 0.2 * pulse), 3.0)


func _draw_space_theme() -> void:
	# Distant planet
	draw_circle(Vector2(1050, 130), 80, Color(0.25, 0.35, 0.6, 0.35))
	draw_arc(Vector2(1050, 130), 95, -0.5, 2.0, 32, Color(0.4, 0.6, 1.0, 0.15), 8.0)


func _draw_ruins_theme() -> void:
	var stone := Color(0.5, 0.45, 0.38, 0.35)
	for i in 4:
		var x := 100 + i * 300
		draw_rect(Rect2(x, VIEW_SIZE.y * 0.48, 24, VIEW_SIZE.y * 0.42), stone)
		draw_rect(Rect2(x - 18, VIEW_SIZE.y * 0.46, 60, 12), stone.lightened(0.1))


func _draw_void_theme() -> void:
	var void_col := Color(0.5, 0.0, 0.8, 0.12 + sin(_time) * 0.04)
	draw_circle(Vector2(VIEW_SIZE.x * 0.5, VIEW_SIZE.y * 0.65), 240, void_col)
	draw_arc(Vector2(VIEW_SIZE.x * 0.5, VIEW_SIZE.y * 0.65), 260, _time, _time + TAU * 0.6, 48, _accent * Color(1, 1, 1, 0.2), 3.0)


func _draw_decor() -> void:
	for item in _decor:
		var pos: Vector2 = item.get("pos", Vector2.ZERO)
		var col: Color = item.get("color", Color.WHITE)
		var kind: String = str(item.get("kind", ""))
		var scale: float = float(item.get("scale", 1.0))
		match kind:
			"crate":
				draw_rect(Rect2(pos, Vector2(36, 36) * scale), col)
				draw_line(pos, pos + Vector2(36, 36) * scale, col.lightened(0.2), 1.5)
			"pipe":
				draw_rect(Rect2(pos, Vector2(50, 14) * scale), col)
			"pillar":
				draw_rect(Rect2(pos, Vector2(18, 80) * scale), col)
			"beam":
				draw_line(pos, pos + Vector2(120, 0), col, 4.0)


func _draw_particles() -> void:
	for p in _particles:
		var col: Color = p.get("color", Color.WHITE)
		col.a = float(p.get("alpha", 1.0))
		var pos: Vector2 = p.get("pos", Vector2.ZERO)
		var kind: String = str(p.get("kind", "spark"))
		var psize: float = float(p.get("size", 2.0))
		match kind:
			"spark":
				draw_circle(pos, psize, col)
			"ember":
				draw_circle(pos, psize, col)
				draw_circle(pos, psize * 2.0, col * Color(1, 1, 1, 0.25))
			"snow":
				draw_circle(pos, psize, col)
			"star":
				draw_circle(pos, psize, col)
			"bubble":
				draw_arc(pos, psize, 0, TAU, 12, col, 1.2)
			_:
				draw_circle(pos, psize, col)


func _draw_vignette() -> void:
	var edge := Color(0, 0, 0, 0.35)
	draw_rect(Rect2(0, 0, VIEW_SIZE.x, 30), edge)
	draw_rect(Rect2(0, VIEW_SIZE.y - 30, VIEW_SIZE.x, 30), edge)
	draw_rect(Rect2(0, 0, 30, VIEW_SIZE.y), edge)
	draw_rect(Rect2(VIEW_SIZE.x - 30, 0, 30, VIEW_SIZE.y), edge)


func _draw_arena_border() -> void:
	var border := _accent
	border.a = 0.35
	draw_rect(Rect2(8, 8, VIEW_SIZE.x - 16, VIEW_SIZE.y - 16), border, false, 2.0)


func _spawn_particles() -> void:
	var count := 24 if _preview_mode else 40
	match _arena_id:
		2:
			count = 35 if _preview_mode else 55
		3:
			count = 40 if _preview_mode else 65
		6:
			count = 50 if _preview_mode else 80
	for i in count:
		_particles.append(_make_particle())


func _make_particle() -> Dictionary:
	var kind := _particle_kind()
	var col := _accent
	match kind:
		"ember":
			col = Color(1.0, 0.45, 0.1)
		"snow":
			col = Color(0.9, 0.95, 1.0)
		"star":
			col = Color(1, 1, 1, 0.9)
		"bubble":
			col = _accent.lightened(0.3)
			col.a = 0.45
		"spark":
			col = _accent.lightened(0.2)
	return {
		"pos": Vector2(randf_range(0, VIEW_SIZE.x), randf_range(0, VIEW_SIZE.y)),
		"vel": Vector2(randf_range(-20, 20), randf_range(10, 50)),
		"size": randf_range(1.5, 4.5),
		"alpha": randf_range(0.25, 0.85),
		"color": col,
		"kind": kind,
		"phase": randf() * TAU,
	}


func _particle_kind() -> String:
	match _arena_id:
		0:
			return "spark" if randf() > 0.4 else "ember"
		1:
			return "spark"
		2:
			return "ember"
		3:
			return "snow"
		4:
			return "bubble"
		5:
			return "spark"
		6:
			return "star"
		7:
			return "spark"
		_:
			return "spark"


func _animate_particles(delta: float) -> void:
	for p in _particles:
		var vel: Vector2 = p.get("vel", Vector2.ZERO)
		var kind: String = str(p.get("kind", "spark"))
		var phase: float = float(p.get("phase", 0.0))
		match kind:
			"snow":
				vel.x += sin(_time * 2.0 + phase) * 15.0 * delta
				vel.y = absf(vel.y)
			"ember":
				vel.y -= 25.0 * delta
				p["alpha"] = 0.4 + sin(_time * 4.0 + phase) * 0.3
			"star":
				p["alpha"] = 0.3 + sin(_time * 1.5 + phase) * 0.5
			"bubble":
				vel.y -= 12.0 * delta
				vel.x += sin(_time + phase) * 20.0 * delta
		var pos: Vector2 = p.get("pos", Vector2.ZERO) + vel * delta
		pos.x = wrapf(pos.x, -10.0, VIEW_SIZE.x + 10.0)
		pos.y = wrapf(pos.y, -10.0, VIEW_SIZE.y + 10.0)
		p["pos"] = pos
		p["vel"] = vel


func _spawn_decor() -> void:
	match _arena_id:
		0:
			_add_decor("crate", Vector2(60, 420), Color(0.45, 0.32, 0.22, 0.5), 1.2)
			_add_decor("crate", Vector2(1150, 480), Color(0.4, 0.3, 0.2, 0.45), 0.9)
			_add_decor("pipe", Vector2(540, 500), Color(0.35, 0.35, 0.38, 0.4), 1.0)
		1:
			_add_decor("pipe", Vector2(80, 390), Color(0.5, 0.52, 0.55, 0.45), 1.4)
			_add_decor("pipe", Vector2(1000, 410), Color(0.45, 0.48, 0.5, 0.4), 1.0)
		5:
			_add_decor("beam", Vector2(200, 200), _accent * Color(1, 1, 1, 0.35), 1.0)
			_add_decor("beam", Vector2(760, 320), _accent * Color(1, 1, 1, 0.3), 1.0)
		7:
			_add_decor("pillar", Vector2(90, 340), Color(0.55, 0.5, 0.42, 0.4), 1.0)
			_add_decor("pillar", Vector2(1160, 360), Color(0.5, 0.45, 0.38, 0.4), 1.1)


func _add_decor(kind: String, pos: Vector2, color: Color, scale: float) -> void:
	_decor.append({"kind": kind, "pos": pos, "color": color, "scale": scale})
