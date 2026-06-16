extends Node

var _used_names: Dictionary = {}
var nationalities: Array = []

func _ready() -> void:
	nationalities = NameData.data.keys()
	print("[NameGenerator] Ready with %d nationalities" % nationalities.size())

func has_nationality(nationality: String) -> bool:
	return nationality in NameData.data

func get_random_nationality() -> String:
	if nationalities.is_empty():
		return "British"
	return nationalities[randi() % nationalities.size()]

func get_first_name(nationality: String, sex: String) -> String:
	if not has_nationality(nationality):
		nationality = "British"
	var nat_data = NameData.data[nationality]
	var seed_key = "male_seeds" if sex == "Male" else "female_seeds"
	if seed_key in nat_data and not nat_data[seed_key].is_empty():
		return nat_data[seed_key][randi() % nat_data[seed_key].size()]
	return _generate_first_name(nat_data, sex)

func get_surname(nationality: String) -> String:
	if not has_nationality(nationality):
		nationality = "British"
	var nat_data = NameData.data[nationality]
	if "surname_seeds" in nat_data and not nat_data["surname_seeds"].is_empty():
		return nat_data["surname_seeds"][randi() % nat_data["surname_seeds"].size()]
	return _generate_surname(nat_data)

func get_full_name(nationality: String, sex: String) -> Dictionary:
	if not has_nationality(nationality):
		nationality = "British"
	var result_first = ""
	var result_last = ""
	var result_full = ""
	for _attempt in range(10):
		result_first = get_first_name(nationality, sex)
		result_last = get_surname(nationality)
		result_full = result_first + " " + result_last
		if not result_full in _used_names:
			_used_names[result_full] = true
			return {"first": result_first, "last": result_last, "full": result_full}
	# Procedural fallback
	var nat_data = NameData.data[nationality]
	result_first = _generate_first_name(nat_data, sex)
	result_last = _generate_surname(nat_data)
	result_full = result_first + " " + result_last
	var suffix = 2
	var final_name = result_full
	while final_name in _used_names:
		final_name = result_full + " " + str(suffix)
		suffix += 1
	_used_names[final_name] = true
	var name_parts = final_name.split(" ")
	return {
		"first": name_parts[0],
		"last": final_name.substr(name_parts[0].length() + 1),
		"full": final_name
	}

func _generate_first_name(nat_data: Dictionary, sex: String) -> String:
	var syl_key = "male_syl" if sex == "Male" else "female_syl"
	if not syl_key in nat_data or nat_data[syl_key].is_empty():
		return "Alex"
	var syllables = nat_data[syl_key]
	var base = syllables[randi() % syllables.size()]
	var endings = ["o", "a", "i", "e", "u", "an", "en", "on", "in", "ar", "el", "al"]
	return base + endings[randi() % endings.size()]

func _generate_surname(nat_data: Dictionary) -> String:
	if not "sur_roots" in nat_data or nat_data["sur_roots"].is_empty():
		return "Smith"
	if not "sur_end" in nat_data or nat_data["sur_end"].is_empty():
		return "Smith"
	return nat_data["sur_roots"][randi() % nat_data["sur_roots"].size()] + nat_data["sur_end"][randi() % nat_data["sur_end"].size()]

func release_name(full_name: String) -> void:
	_used_names.erase(full_name)

func get_nationality_for_team(team_nationality: String) -> String:
	if randf() < 0.7:
		return team_nationality
	return get_random_nationality()
