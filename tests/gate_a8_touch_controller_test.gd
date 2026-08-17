extends SceneTree

const TOUCH_SCENE := preload("res://scenes/interactive_match/input/dual_touch_controller.tscn")

var controller: Node
var strikes := 0
var last_move := Vector2.ZERO
var last_aim := Vector2.RIGHT
var last_charge := 0.0

func _init() -> void:
	ProjectSettings.set_setting("display/window/size/viewport_width", 2400)
	ProjectSettings.set_setting("display/window/size/viewport_height", 1080)
	controller = TOUCH_SCENE.instantiate()
	root.add_child(controller)
	controller.movement_changed.connect(func(v: Vector2) -> void: last_move = v)
	controller.aim_changed.connect(func(v: Vector2, c: float) -> void:
		last_aim = v
		last_charge = c
	)
	controller.strike_released.connect(func(_v: Vector2, _c: float) -> void: strikes += 1)
	await process_frame
	_test_movement_ownership()
	_test_aim_ownership()
	_test_simultaneous_move_aim()
	_test_third_finger_and_cancel()
	print("GATE A8 TOUCH CONTROLLER TEST PASSED")
	quit(0)

func _test_movement_ownership() -> void:
	var center: Vector2 = controller.joystick_center
	_touch(0, center, true)
	_drag(0, center + Vector2(controller.joystick_radius * 0.8, 0))
	assert(controller.movement_touch_id == 0, "finger 0 owns movement")
	assert(last_move.x > 0.45, "movement drag creates vector")
	_touch(2, center + Vector2(8, 8), true)
	_drag(2, center + Vector2(-controller.joystick_radius, 0))
	assert(controller.movement_touch_id == 0, "third finger cannot steal movement")
	assert(last_move.x > 0.45, "third finger does not overwrite movement vector")
	_touch(2, center, false)
	assert(last_move.x > 0.45, "releasing non-owner does not stop movement")
	_touch(0, center, false)
	assert(controller.movement_touch_id == -1, "movement release clears owner")
	assert(last_move == Vector2.ZERO, "movement release stops movement")

func _test_aim_ownership() -> void:
	var size := root.get_viewport().get_visible_rect().size
	var start := Vector2(size.x * 0.72, size.y * 0.74)
	_touch(1, start, true)
	_drag(1, start + Vector2(220, -80))
	assert(controller.aim_touch_id == 1, "finger 1 owns aim")
	assert(controller.is_aiming, "aim is active")
	assert(last_charge > 0.4, "aim drag creates charge")
	_touch(0, controller.joystick_center, false)
	assert(strikes == 0, "movement release does not strike")
	_touch(1, start + Vector2(220, -80), false)
	assert(strikes == 1, "aim release strikes")
	assert(controller.aim_touch_id == -1, "aim release clears owner")

func _test_simultaneous_move_aim() -> void:
	var center: Vector2 = controller.joystick_center
	var size := root.get_viewport().get_visible_rect().size
	var aim_start := Vector2(size.x * 0.75, size.y * 0.76)
	_touch(0, center, true)
	_drag(0, center + Vector2(controller.joystick_radius, 0))
	_touch(1, aim_start, true)
	_drag(1, aim_start + Vector2(180, -120))
	assert(last_move.x > 0.55, "movement continues while aiming")
	assert(controller.is_aiming, "aim continues while moving")
	_touch(1, aim_start + Vector2(180, -120), false)
	assert(last_move.x > 0.55, "right release does not stop movement")
	_touch(0, center, false)

func _test_third_finger_and_cancel() -> void:
	var size := root.get_viewport().get_visible_rect().size
	var aim_start := Vector2(size.x * 0.76, size.y * 0.78)
	_touch(1, aim_start, true)
	_touch(3, aim_start + Vector2(60, 0), true)
	assert(controller.aim_touch_id == 1, "third finger cannot steal aim")
	controller.reset_all()
	assert(controller.movement_touch_id == -1 and controller.aim_touch_id == -1, "cancel/reset clears owners")
	assert(controller.movement_vector == Vector2.ZERO, "cancel/reset clears movement")

func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = pos
	event.pressed = pressed
	controller._input(event)

func _drag(index: int, pos: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = pos
	controller._input(event)
