class_name HudStyle
## Placeholder look for the HUD (dark stone panels, gold trim) and small widget builders.
## Replaced when the art direction exists.

const PANEL := Color(0.10, 0.10, 0.12, 0.92)
const PANEL_LIGHT := Color(0.17, 0.16, 0.18, 0.95)
const BORDER := Color(0.62, 0.50, 0.28)
const TEXT := Color(0.93, 0.90, 0.82)
const TEXT_DIM := Color(0.62, 0.60, 0.55)
const GOLD := Color(0.95, 0.80, 0.40)
const HP_GOOD := Color(0.30, 0.78, 0.30)
const HP_MID := Color(0.90, 0.75, 0.20)
const HP_LOW := Color(0.85, 0.22, 0.18)
const PROGRESS := Color(0.35, 0.62, 0.95)
const BUTTON_SIZE := Vector2(64, 64)


static func panel_box(colour := PANEL, border := 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.border_color = BORDER
	box.set_border_width_all(border)
	box.set_corner_radius_all(3)
	box.set_content_margin_all(8)
	return box


## A panel container with the HUD frame.
static func panel(name: String) -> PanelContainer:
	var container := PanelContainer.new()
	container.name = name
	container.add_theme_stylebox_override("panel", panel_box())
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	return container


static func label(text := "", size := 14, colour := TEXT) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", colour)
	return lbl


static func header(text: String) -> Label:
	var lbl := label(text.to_upper(), 12, GOLD)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl


static func button(text: String, tooltip := "", toggle := false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.tooltip_text = tooltip
	btn.toggle_mode = toggle
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 13)
	var normal := panel_box(PANEL_LIGHT, 1)
	normal.set_content_margin_all(4)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = PANEL_LIGHT.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = BORDER.darkened(0.35)
	pressed.border_color = GOLD
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = PANEL.darkened(0.2)
	disabled.border_color = BORDER.darkened(0.5)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("hover_pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_disabled_color", TEXT_DIM.darkened(0.3))
	return btn


static func bar(colour: Color, height := 14.0) -> ProgressBar:
	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(0, height)
	progress.show_percentage = false
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0, 0, 0, 0.6)
	back.border_color = BORDER.darkened(0.4)
	back.set_border_width_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = colour
	progress.add_theme_stylebox_override("background", back)
	progress.add_theme_stylebox_override("fill", fill)
	return progress


## Colours an HP bar by how full it is.
static func set_hp(progress: ProgressBar, hp: float, max_hp: float) -> void:
	progress.max_value = max_hp
	progress.value = hp
	var ratio := hp / max_hp if max_hp > 0.0 else 0.0
	var fill := progress.get_theme_stylebox("fill") as StyleBoxFlat
	fill.bg_color = HP_GOOD if ratio > 0.6 else (HP_MID if ratio > 0.3 else HP_LOW)
