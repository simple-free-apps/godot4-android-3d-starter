extends Node3D
## Procedural PBR 3D stage and Android HUD controller with zero external binary assets.

var _orbit_ring: Node3D
var _crystal: MeshInstance3D
var _satellites: Array[MeshInstance3D] = []
var _pulse_count: int = 0
var _spin_boost: float = 0.0
var _active_locale: String = "en"

@onready var _camera_rig: TouchOrbitCamera = $TouchOrbitCamera
@onready var _hud: Control = $CanvasLayer/HudRoot
@onready var _badge_label: Label = $CanvasLayer/HudRoot/TopBar/BadgeLabel
@onready var _lang_button: Button = $CanvasLayer/HudRoot/TopBar/LangButton
@onready var _title_label: Label = $CanvasLayer/HudRoot/HeaderBox/TitleLabel
@onready var _subtitle_label: Label = $CanvasLayer/HudRoot/HeaderBox/SubtitleLabel
@onready var _hint_label: Label = $CanvasLayer/HudRoot/BottomCard/VBox/HintLabel
@onready var _status_label: Label = $CanvasLayer/HudRoot/BottomCard/VBox/StatusLabel
@onready var _pulse_button: Button = $CanvasLayer/HudRoot/BottomCard/VBox/Actions/PulseButton
@onready var _reset_button: Button = $CanvasLayer/HudRoot/BottomCard/VBox/Actions/ResetButton


func _ready() -> void:
	var table := MobileLocale.load_table()
	MobileLocale.register_translations(table)
	_build_procedural_stage()
	_pulse_button.pressed.connect(_on_pulse_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_lang_button.pressed.connect(_on_lang_pressed)
	_apply_locale("en")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_reset_pressed()


func _process(delta: float) -> void:
	var base_speed := 0.75 + _spin_boost
	_spin_boost = maxf(0.0, _spin_boost - delta * 2.4)
	if _crystal != null:
		_crystal.rotate_y(delta * base_speed)
		_crystal.position.y = 0.78 + sin(Time.get_ticks_msec() * 0.0025) * 0.08
	if _orbit_ring != null:
		_orbit_ring.rotate_y(-delta * (base_speed * 0.65))
		for sat in _satellites:
			sat.rotate_x(delta * 1.3)


func _on_pulse_pressed() -> void:
	_pulse_count += 1
	_spin_boost = 4.2
	_refresh_texts()


func _on_reset_pressed() -> void:
	if _camera_rig != null:
		_camera_rig.reset_view(false)


func _on_lang_pressed() -> void:
	_apply_locale("ar" if _active_locale == "en" else "en")


func _apply_locale(locale: String) -> void:
	_active_locale = locale
	MobileLocale.set_locale_and_direction(locale, _hud)
	_refresh_texts()


func _refresh_texts() -> void:
	_badge_label.text = tr("badge_mit")
	_lang_button.text = tr("btn_lang")
	_title_label.text = tr("title")
	_subtitle_label.text = tr("subtitle")
	_hint_label.text = tr("hint_gesture")
	_pulse_button.text = tr("btn_pulse")
	_reset_button.text = tr("btn_reset")
	_status_label.text = tr("status_pulses") % _pulse_count


func _build_procedural_stage() -> void:
	var stage := Node3D.new()
	stage.name = "ProceduralStage"
	add_child(stage)

	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.11, 0.15, 0.22)
	base_mat.metallic = 0.65
	base_mat.roughness = 0.35

	var brass_mat := StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.95, 0.74, 0.38)
	brass_mat.metallic = 0.88
	brass_mat.roughness = 0.24

	var crystal_mat := StandardMaterial3D.new()
	crystal_mat.albedo_color = Color(0.62, 0.94, 0.81)
	crystal_mat.metallic = 0.15
	crystal_mat.roughness = 0.12
	crystal_mat.emission_enabled = true
	crystal_mat.emission = Color(0.24, 0.72, 0.56)
	crystal_mat.emission_energy_multiplier = 0.75

	var pedestal := MeshInstance3D.new()
	var ped_mesh := CylinderMesh.new()
	ped_mesh.top_radius = 1.45
	ped_mesh.bottom_radius = 1.7
	ped_mesh.height = 0.32
	ped_mesh.radial_segments = 32
	pedestal.mesh = ped_mesh
	pedestal.material_override = base_mat
	pedestal.position = Vector3(0.0, -0.16, 0.0)
	stage.add_child(pedestal)

	var rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 1.28
	rim_mesh.outer_radius = 1.48
	rim_mesh.rings = 32
	rim_mesh.ring_segments = 16
	rim.mesh = rim_mesh
	rim.material_override = brass_mat
	rim.position = Vector3(0.0, 0.02, 0.0)
	stage.add_child(rim)

	_crystal = MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.86, 1.28, 0.86)
	_crystal.mesh = prism
	_crystal.material_override = crystal_mat
	_crystal.position = Vector3(0.0, 0.78, 0.0)
	stage.add_child(_crystal)

	_orbit_ring = Node3D.new()
	_orbit_ring.position = Vector3(0.0, 0.78, 0.0)
	stage.add_child(_orbit_ring)

	for i in range(4):
		var angle := (TAU / 4.0) * i
		var sat := MeshInstance3D.new()
		var sat_mesh := SphereMesh.new()
		sat_mesh.radius = 0.16
		sat_mesh.height = 0.32
		sat.mesh = sat_mesh
		sat.material_override = brass_mat
		sat.position = Vector3(cos(angle) * 1.45, 0.0, sin(angle) * 1.45)
		_orbit_ring.add_child(sat)
		_satellites.append(sat)
