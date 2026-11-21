class_name MobileLocale
extends RefCounted
## Lightweight runtime EN/AR localization loader with RTL direction support.

const STRINGS_PATH := "res://localization/strings.json"
const SUPPORTED_LOCALES := ["en", "ar"]


static func load_table(path: String = STRINGS_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var raw := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		return parsed
	return {}


static func register_translations(table: Dictionary) -> int:
	var count := 0
	for locale in SUPPORTED_LOCALES:
		if not table.has(locale) or not (table[locale] is Dictionary):
			continue
		var tr_obj := Translation.new()
		tr_obj.locale = locale
		var entries: Dictionary = table[locale]
		for key in entries.keys():
			tr_obj.add_message(str(key), str(entries[key]))
		TranslationServer.add_translation(tr_obj)
		count += 1
	return count


static func set_locale_and_direction(locale: String, root_control: Control) -> void:
	var normalized := locale if locale in SUPPORTED_LOCALES else "en"
	TranslationServer.set_locale(normalized)
	if root_control != null:
		root_control.layout_direction = (
			Control.LAYOUT_DIRECTION_RTL if normalized == "ar" else Control.LAYOUT_DIRECTION_LTR
		)
