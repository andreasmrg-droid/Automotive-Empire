class_name Team
extends Resource

# Identity
@export var id: String = ""
@export var team_name: String = ""
@export var nationality: String = ""
@export var is_player_team: bool = false

# Academy
@export var has_academy: bool = false
@export var academy_slots: int = 0
@export var academy_drivers: Array[String] = []  # driver IDs

# Championships
@export var active_championships: Array[String] = []

# Finance
@export var balance: float = 50000.0
@export var company_value: float = 50000.0
@export var reputation: float = 15.0
@export var marketability: float = 10.0

# Drivers and Staff
@export var drivers: Array[String] = []  # driver IDs
@export var loan_balance: float = 0.0

# Weekly costs specific to GK Regional
@export var weekly_entry_fee: float = 0.0
@export var weekly_driver_salary: float = 50.0
@export var weekly_mechanic_salary: float = 250.0

func get_weekly_expenses() -> float:
	return weekly_driver_salary + weekly_mechanic_salary

func can_afford(amount: float) -> bool:
	return balance >= amount

func apply_weekly_expenses() -> void:
	balance -= get_weekly_expenses()
