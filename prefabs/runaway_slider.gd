extends Control
class_name RunawaySlider

signal value_changed(new_value: float)

var min_value: float = 0.0
var max_value: float = 100.0
var value: float = 50.0
var handle_pos: float = 0.5

const FLEE_RADIUS: float = 80.0
const FLEE_SPEED: float = 300.0
const TRACK_HEIGHT: float = 6.0
const HANDLE_RADIUS: float = 10.0

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	set_value(value)

func set_value(new_value: float) -> void:
	value = clamp(new_value, min_value, max_value)
	if max_value != min_value:
		handle_pos = (value - min_value) / (max_value - min_value)
	queue_redraw()

func _process(delta: float) -> void:
	if size.x <= 0:
		return
	var mouse := get_local_mouse_position()
	var handle_x := handle_pos * size.x
	var handle_center := Vector2(handle_x, size.y * 0.5)
	var dist := mouse.distance_to(handle_center)
	if dist < FLEE_RADIUS:
		var flee_dir := (handle_center - mouse).normalized()
		if flee_dir.is_zero_approx():
			flee_dir = Vector2(1, 0)
		handle_x += flee_dir.x * FLEE_SPEED * delta
		handle_x = clamp(handle_x, HANDLE_RADIUS, size.x - HANDLE_RADIUS)
		handle_pos = clamp(handle_x / size.x, 0.0, 1.0)
		value = lerp(min_value, max_value, handle_pos)
		value_changed.emit(value)
		queue_redraw()

func _draw() -> void:
	var mid_y := size.y * 0.5
	var handle_x := handle_pos * size.x
	draw_rect(Rect2(0, mid_y - TRACK_HEIGHT * 0.5, size.x, TRACK_HEIGHT), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(0, mid_y - TRACK_HEIGHT * 0.5, handle_x, TRACK_HEIGHT), Color(0.5, 0.5, 0.5))
	draw_circle(Vector2(handle_x, mid_y), HANDLE_RADIUS, Color(1, 1, 1))
