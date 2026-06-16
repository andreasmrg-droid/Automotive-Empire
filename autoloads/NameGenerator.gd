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
	nationality = resolve_nationality(nationality)
	var nat_data = NameData.data[nationality]
	var seed_key = "male_seeds" if sex == "Male" else "female_seeds"
	if seed_key in nat_data and not nat_data[seed_key].is_empty():
		return nat_data[seed_key][randi() % nat_data[seed_key].size()]
	return _generate_first_name(nat_data, sex)

func get_surname(nationality: String) -> String:
	nationality = resolve_nationality(nationality)
	var nat_data = NameData.data[nationality]
	if "surname_seeds" in nat_data and not nat_data["surname_seeds"].is_empty():
		return nat_data["surname_seeds"][randi() % nat_data["surname_seeds"].size()]
	return _generate_surname(nat_data)

func get_full_name(nationality: String, sex: String) -> Dictionary:
	nationality = resolve_nationality(nationality)
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
	# Fallback: use middle initial to create unique name
	var nat_data = NameData.data[nationality]
	var initials = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for initial in initials:
		result_first = get_first_name(nationality, sex)
		result_last  = get_surname(nationality)
		result_full  = result_first + " " + initial + " " + result_last
		if not result_full in _used_names:
			_used_names[result_full] = true
			return {"first": result_first, "last": initial + " " + result_last, "full": result_full}
	# Last resort: procedural generation with middle initial
	result_first = _generate_first_name(nat_data, sex)
	result_last  = _generate_surname(nat_data)
	for initial in initials:
		result_full = result_first + " " + initial + " " + result_last
		if not result_full in _used_names:
			_used_names[result_full] = true
			return {"first": result_first, "last": initial + " " + result_last, "full": result_full}
	# Absolute last resort
	_used_names[result_first + " " + result_last] = true
	return {"first": result_first, "last": result_last, "full": result_first + " " + result_last}

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

## Maps ISO 3-letter country codes to NameData nationality keys.
## Used when team data provides a country code (e.g. "GBR") instead of
## a full nationality string (e.g. "British").
const CODE_TO_NATIONALITY: Dictionary = {
	# Europe
	"GBR": "British",     "ITA": "Italian",     "GER": "German",
	"FRA": "French",      "ESP": "Spanish",     "NLD": "Dutch",
	"BEL": "Belgian",     "PRT": "Portuguese",  "GRC": "Greek",
	"SWE": "Swedish",     "DNK": "Danish",      "FIN": "Finnish",
	"NOR": "Norwegian",   "CHE": "Swiss",       "AUT": "Austrian",
	"POL": "Polish",      "CZE": "Czech",       "HUN": "Hungarian",
	"ROU": "Romanian",    "HRV": "Croatian",    "SRB": "Serbian",
	"TUR": "Turkish",     "UKR": "Ukrainian",   "IRL": "Irish",
	"SCO": "Scottish",    "WAL": "Welsh",       "LUX": "Luxembourgish",
	"CAT": "Catalan",     "BAS": "Basque",      "MCO": "Monegasque",
	"FLE": "Flemish",

	# Americas
	"USA": "American",    "CAN": "Canadian",    "MEX": "Mexican",
	"BRA": "Brazilian",   "ARG": "Argentinian", "COL": "Colombian",
	"CHL": "Chilean",     "VEN": "Venezuelan",  "URY": "Uruguayan",
	"PER": "Peruvian",

	# Asia & Middle East
	"JPN": "Japanese",    "KOR": "South Korean", "CHN": "Chinese",
	"IND": "Indian",      "THA": "Thai",         "MYS": "Malaysian",
	"IDN": "Indonesian",  "UAE": "Emirati",      "KSA": "Saudi",
	"QAT": "Qatari",      "KWT": "Kuwaiti",      "LBN": "Lebanese",
	"MAR": "Moroccan",    "EGY": "Egyptian",

	# Oceania & Africa
	"AUS": "Australian",  "NZL": "New Zealander","ZAF": "South African",
	"KEN": "Kenyan",

	# Russia & others
	"RUS": "Russian",
}

func resolve_nationality(nat: String) -> String:
	## Accepts both full names ("British") and country codes ("GBR").
	## Falls back to "British" if not found.
	if has_nationality(nat):
		return nat
	var resolved = CODE_TO_NATIONALITY.get(nat, "")
	if resolved != "" and has_nationality(resolved):
		return resolved
	return "British"

func get_nationality_for_team(team_nationality: String) -> String:
	var resolved = resolve_nationality(team_nationality)
	if randf() < 0.7:
		return resolved
	return get_random_nationality()
