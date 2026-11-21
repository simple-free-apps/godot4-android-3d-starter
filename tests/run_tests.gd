extends SceneTree
## Headless verification test suite for Godot 4 Android 3D Starter.

func _initialize() -> void:
	var failures := 0

	# 1. Verify localization table parity (EN == AR keys).
	var table := MobileLocale.load_table()
	if not table.has("en") or not table.has("ar"):
		push_error("Localization table missing en or ar sections.")
		failures += 1
	else:
		var en_keys: Array = table["en"].keys()
		var ar_keys: Array = table["ar"].keys()
		en_keys.sort()
		ar_keys.sort()
		if en_keys != ar_keys:
			push_error("Localization key mismatch between EN and AR.")
			failures += 1
		var reg_count := MobileLocale.register_translations(table)
		if reg_count != 2:
			push_error("Expected 2 registered locales, got %d" % reg_count)
			failures += 1

	# 2. Verify TouchOrbitCamera pitch and zoom bounds.
	var rig := TouchOrbitCamera.new()
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	rig.add_child(cam)
	rig.reset_view(true)
	rig.apply_orbit_delta(Vector2(100.0, 5000.0))
	rig.apply_zoom_delta(-999.0)
	var state_min := rig.get_state()
	if state_min["pitch"] > rig.max_pitch_deg or state_min["pitch"] < rig.min_pitch_deg:
		push_error("Pitch out of clamped range: %s" % str(state_min["pitch"]))
		failures += 1
	if not is_equal_approx(state_min["distance"], rig.min_distance):
		push_error("Zoom min clamp failed: %s" % str(state_min["distance"]))
		failures += 1
	rig.apply_zoom_delta(999.0)
	var state_max := rig.get_state()
	if not is_equal_approx(state_max["distance"], rig.max_distance):
		push_error("Zoom max clamp failed: %s" % str(state_max["distance"]))
		failures += 1
	rig.free()

	# 3. Verify Main scene instantiation and procedural stage generation.
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		push_error("Failed to load res://scenes/main.tscn")
		failures += 1
	else:
		var instance := packed.instantiate()
		root.add_child(instance)
		await process_frame
		var stage := instance.get_node_or_null("ProceduralStage")
		if stage == null or stage.get_child_count() < 4:
			push_error("ProceduralStage did not generate expected 3D meshes.")
			failures += 1
		instance.queue_free()

	if failures > 0:
		printerr("TESTS FAILED: %d failure(s)." % failures)
		quit(1)
	else:
		print("ALL TESTS PASSED (3/3 suites).")
		quit(0)
