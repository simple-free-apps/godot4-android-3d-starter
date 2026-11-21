class_name TouchOrbitCamera
extends Node3D
## Mobile-friendly 3D orbit camera supporting single-finger drag, two-finger pinch zoom,
## smooth damping, and desktop mouse preview.

@export var target_offset: Vector3 = Vector3(0.0, 0.4, 0.0)
@export var default_distance: float = 5.4
@export var min_distance: float = 2.6
@export var max_distance: float = 10.5
@export var default_yaw_deg: float = 28.0
@export var default_pitch_deg: float = -24.0
@export var min_pitch_deg: float = -72.0
@export var max_pitch_deg: float = -6.0
@export var drag_sensitivity: float = 0.28
@export var zoom_sensitivity: float = 0.014
@export var smoothing: float = 10.0

var _target_yaw: float = 0.0
var _target_pitch: float = 0.0
var _target_distance: float = 5.4
var _current_yaw: float = 0.0
var _current_pitch: float = 0.0
var _current_distance: float = 5.4
var _touches: Dictionary = {}
var _prev_pinch_dist: float = -1.0
var _mouse_dragging: bool = false

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	reset_view(true)


func reset_view(immediate: bool = false) -> void:
	_target_yaw = default_yaw_deg
	_target_pitch = clampf(default_pitch_deg, min_pitch_deg, max_pitch_deg)
	_target_distance = clampf(default_distance, min_distance, max_distance)
	if immediate:
		_current_yaw = _target_yaw
		_current_pitch = _target_pitch
		_current_distance = _target_distance
		_apply_transform()


func apply_orbit_delta(delta_px: Vector2) -> void:
	_target_yaw -= delta_px.x * drag_sensitivity
	_target_pitch = clampf(_target_pitch - delta_px.y * drag_sensitivity, min_pitch_deg, max_pitch_deg)


func apply_zoom_delta(delta_distance: float) -> void:
	_target_distance = clampf(_target_distance + delta_distance, min_distance, max_distance)


func get_state() -> Dictionary:
	return {
		"yaw": _target_yaw,
		"pitch": _target_pitch,
		"distance": _target_distance,
	}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		if _touches.size() < 2:
			_prev_pinch_dist = -1.0
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() == 1:
			apply_orbit_delta(event.relative)
		elif _touches.size() >= 2:
			var keys := _touches.keys()
			var p0: Vector2 = _touches[keys[0]]
			var p1: Vector2 = _touches[keys[1]]
			var dist := p0.distance_to(p1)
			if _prev_pinch_dist > 0.0:
				apply_zoom_delta((_prev_pinch_dist - dist) * zoom_sensitivity)
			_prev_pinch_dist = dist
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			apply_zoom_delta(-0.45)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			apply_zoom_delta(0.45)
	elif event is InputEventMouseMotion and _mouse_dragging:
		apply_orbit_delta(event.relative)


func _process(delta: float) -> void:
	var t := clampf(delta * smoothing, 0.0, 1.0)
	_current_yaw = lerpf(_current_yaw, _target_yaw, t)
	_current_pitch = lerpf(_current_pitch, _target_pitch, t)
	_current_distance = lerpf(_current_distance, _target_distance, t)
	_apply_transform()


func _apply_transform() -> void:
	position = target_offset
	rotation_degrees = Vector3(_current_pitch, _current_yaw, 0.0)
	if _camera != null:
		_camera.position = Vector3(0.0, 0.0, _current_distance)
		_camera.look_at(target_offset, Vector3.UP)
