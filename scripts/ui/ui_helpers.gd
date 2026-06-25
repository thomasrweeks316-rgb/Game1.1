extends Node

const BASE_WIDTH := 1280
const BASE_HEIGHT := 720

static func style_button(btn: Button) -> void:
	btn.custom_minimum_size = Vector2(200, 44)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.18, 0.28)
	style.border_color = Color(0.4, 0.6, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.2, 0.25, 0.38)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.1, 0.12, 0.2)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(0.9, 0.92, 1.0))
	btn.add_theme_font_size_override("font_size", 18)


static func style_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.16, 0.92)
	style.border_color = Color(0.3, 0.45, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)


static func style_line_edit(le: LineEdit) -> void:
	le.custom_minimum_size = Vector2(260, 40)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.2)
	style.border_color = Color(0.35, 0.5, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	le.add_theme_stylebox_override("normal", style)
	le.add_theme_color_override("font_color", Color.WHITE)
	le.add_theme_font_size_override("font_size", 16)


static func make_title(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	return lbl


static func make_label(text: String, size: int = 16) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	return lbl


static func make_error_label() -> Label:
	var lbl := Label.new()
	lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl
