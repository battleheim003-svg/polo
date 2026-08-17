class_name DualTouchController
extends CanvasLayer

signal movement_changed(vector: Vector2)
signal aim_started()
signal aim_changed(vector: Vector2, charge: float)
signal strike_released(vector: Vector2, charge: float)
signal aim_cancelled()

const TURQUOISE := Color(0.03, 0.63, 0.68)
const GOLD := Color(0.86, 0.66, 0.25)
const LAPIS := Color(0.04, 0.11, 0.23)
const PARCHMENT := Color(0.91, 0.84, 0.64)
const INK := Color(0.04, 0.04, 0.05)

var movement_touch_id: int = -1
var aim_touch_id: int = -1
var movement_origin: Vector2 = Vector2.ZERO
var movement_vector: Vector2 = Vector2.ZERO
var aim_origin: Vector2 = Vector2.ZERO
var aim_current: Vector2 = Vector2.ZERO
var aim_vector: Vector2 = Vector2.RIGHT
var charge: float = 0.0
var is_aiming: bool = false
var last_strike: Dictionary = {}

var joystick_center := Vector2.ZERO
var joystick_radius := 96.0
var joystick_deadzone := 14.0
var aim_zone_min_y := 0.45
var min_strike_charge := 0.12
var mouse_aiming := false
var draw_surface: Control

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	draw_surface = Control.new()
	draw_surface.name = "TouchDrawSurface"
	draw_surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(draw_surface)
	draw_surface.draw.connect(_draw_touch_ui)
	_layout()
	get_viewport().size_changed.connect(_layout)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var base := minf(size.x, size.y)
	joystick_radius = clampf(base * 0.105, 72.0, 118.0)
	joystick_deadzone = joystick_radius * 0.16
	joystick_center = Vector2(maxf(joystick_radius + 34.0, size.x * 0.095), size.y - joystick_radius - 38.0)
	if movement_touch_id == -1:
		movement_origin = joystick_center
	draw_surface.queue_redraw()

func get_input_state() -> Dictionary:
	return {
		"move": movement_vector,
		"aim": aim_vector,
		"charge": charge,
		"is_aiming": is_aiming
	}

func consume_strike() -> Dictionary:
	var result := last_strike.duplicate()
	last_strike.clear()
	return result

func reset_all() -> void:
	movement_touch_id = -1
	aim_touch_id = -1
	movement_vector = Vector2.ZERO
	aim_vector = Vector2.RIGHT
	charge = 0.0
	is_aiming = false
	mouse_aiming = false
	last_strike.clear()
	movement_changed.emit(movement_vector)
	aim_cancelled.emit()
	draw_surface.queue_redraw()

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if movement_touch_id == -1 and _in_movement_zone(event.position):
			movement_touch_id = event.index
			movement_origin = joystick_center
			_update_movement(event.position)
		elif aim_touch_id == -1 and event.index != movement_touch_id and _in_aim_zone(event.position):
			aim_touch_id = event.index
			aim_origin = event.position
			aim_current = event.position
			is_aiming = true
			charge = 0.0
			aim_started.emit()
			aim_changed.emit(aim_vector, charge)
			draw_surface.queue_redraw()
	else:
		if event.index == movement_touch_id:
			movement_touch_id = -1
			movement_vector = Vector2.ZERO
			movement_changed.emit(movement_vector)
			draw_surface.queue_redraw()
		elif event.index == aim_touch_id:
			_release_aim()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == movement_touch_id:
		_update_movement(event.position)
	elif event.index == aim_touch_id:
		_update_aim(event.position)

func _update_movement(pos: Vector2) -> void:
	var delta := pos - movement_origin
	var len := delta.length()
	if len <= joystick_deadzone:
		movement_vector = Vector2.ZERO
	else:
		movement_vector = delta.normalized() * clampf((len - joystick_deadzone) / (joystick_radius - joystick_deadzone), 0.0, 1.0)
	movement_changed.emit(movement_vector)
	draw_surface.queue_redraw()

func _update_aim(pos: Vector2) -> void:
	aim_current = pos
	var delta := pos - aim_origin
	if delta.length() > 4.0:
		aim_vector = delta.normalized()
	charge = clampf(delta.length() / (joystick_radius * 1.55), 0.0, 1.0)
	is_aiming = true
	aim_changed.emit(aim_vector, charge)
	draw_surface.queue_redraw()

func _release_aim() -> void:
	var released_vector := aim_vector
	var released_charge := charge
	aim_touch_id = -1
	is_aiming = false
	charge = 0.0
	if released_charge >= min_strike_charge:
		last_strike = {"aim": released_vector, "charge": released_charge}
		strike_released.emit(released_vector, released_charge)
	else:
		aim_cancelled.emit()
	draw_surface.queue_redraw()

func _in_movement_zone(pos: Vector2) -> bool:
	var size := get_viewport().get_visible_rect().size
	return pos.x <= size.x * 0.42 and pos.y >= size.y * 0.48 and pos.distance_to(joystick_center) <= joystick_radius * 1.65

func _in_aim_zone(pos: Vector2) -> bool:
	var size := get_viewport().get_visible_rect().size
	return pos.x >= size.x * 0.48 and pos.y >= size.y * aim_zone_min_y

func _draw_touch_ui() -> void:
	var active := movement_touch_id != -1
	var ring_alpha := 0.42 if active else 0.20
	var knob := movement_origin + movement_vector * joystick_radius * 0.72
	draw_surface.draw_circle(joystick_center, joystick_radius, Color(LAPIS.r, LAPIS.g, LAPIS.b, ring_alpha))
	draw_surface.draw_arc(joystick_center, joystick_radius, 0, TAU, 64, Color(GOLD.r, GOLD.g, GOLD.b, 0.58 if active else 0.34), 3.5)
	draw_surface.draw_circle(knob, joystick_radius * 0.33, Color(TURQUOISE.r, TURQUOISE.g, TURQUOISE.b, 0.78 if active else 0.42))
	draw_surface.draw_arc(knob, joystick_radius * 0.34, 0, TAU, 32, Color(PARCHMENT.r, PARCHMENT.g, PARCHMENT.b, 0.32), 2.0)
	_draw_charge_arc()

func _draw_charge_arc() -> void:
	var size := get_viewport().get_visible_rect().size
	var center := Vector2(size.x - maxf(150.0, size.x * 0.12), size.y - maxf(132.0, size.y * 0.14))
	var radius := clampf(minf(size.x, size.y) * 0.16, 118.0, 190.0)
	var start := deg_to_rad(126.0)
	var end := deg_to_rad(230.0)
	draw_surface.draw_arc(center, radius, start, end, 40, Color(GOLD.r, GOLD.g, GOLD.b, 0.20), 8.0)
	if is_aiming:
		var fill_end := lerpf(start, end, charge)
		var col := TURQUOISE.lerp(GOLD, charge)
		draw_surface.draw_arc(center, radius, start, fill_end, 40, Color(col.r, col.g, col.b, 0.88), 11.0)
		draw_surface.draw_line(aim_origin, aim_current, Color(col.r, col.g, col.b, 0.36), 4.0)
