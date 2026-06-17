class_name FinancialEngine
## Version: S27.0 — Extracted from GameState.gd (P57 Phase 2)
##   Owns all weekly financial processing: expenses, campus income, loans, CEO salary,
##   supply contracts, company valuation.
##   Called by GameState.advance_week() via process_weekly().
extends RefCounted

## Reference to the main GameState node — all data lives there.
var gs  # GameState reference (untyped to avoid circular dependency)


func _init(game_state) -> void:
	gs = game_state


# ═══════════════════════════════════════════════════════════════════════════
# WEEKLY PROCESSING — called from advance_week()
# ═══════════════════════════════════════════════════════════════════════════

## Master weekly financial tick — call this once from advance_week().
func process_weekly() -> void:
	apply_campus_income()
	apply_weekly_expenses()
	process_supply_contracts_weekly()
	process_loans_weekly()
	update_ceo_salary()


# ═══════════════════════════════════════════════════════════════════════════
# WEEKLY EXPENSES
# ═══════════════════════════════════════════════════════════════════════════

func apply_weekly_expenses() -> void:
	var player_expenses = 0.0

	# Driver salaries — use per-driver negotiated salary, fall back to championship rate
	for driver_id in gs.player_team.drivers:
		var driver = gs.all_drivers.get(driver_id)
		if driver == null: continue
		var sal = driver.weekly_salary if driver.weekly_salary > 0 \
				else get_championship_driver_salary()
		player_expenses += sal

	# Staff salaries — sum all hired staff
	for staff_id in gs.all_staff:
		var staff = gs.all_staff[staff_id]
		if staff.contract_team == gs.player_team.id:
			player_expenses += staff.weekly_salary

	gs.player_team.balance -= player_expenses
	## P&L summary logged in advance_week() after all income/expense functions run

	# Bankruptcy — escalating warnings, screen after 8 consecutive weeks negative
	if gs.player_team.balance < 0:
		gs.weeks_in_negative += 1
		if gs.weeks_in_negative >= 6:
			gs.add_notification("Critical",
				"🚨 CRITICAL: %d weeks insolvent (CR %s). Team collapse imminent!" % [
					gs.weeks_in_negative, gs._fmt_int(int(gs.player_team.balance))])
		elif gs.weeks_in_negative >= 3:
			gs.add_notification("Critical",
				"🚨 BANKRUPTCY RISK: %d weeks negative (CR %s). Sell assets or find sponsors now." % [
					gs.weeks_in_negative, gs._fmt_int(int(gs.player_team.balance))])
		else:
			gs.add_notification("High",
				"⚠ Balance negative (CR %s). Address this urgently." % gs._fmt_int(int(gs.player_team.balance)))
		if gs.weeks_in_negative >= 8 and not gs.bankruptcy_screen_shown:
			gs.bankruptcy_screen_shown = true
			gs.emit_signal("bankruptcy_triggered")
	else:
		gs.weeks_in_negative = 0
		gs.bankruptcy_screen_shown = false
		if player_expenses > 0 and gs.player_team.balance < player_expenses * 4:
			gs.add_notification("High",
				"⚠ Low funds: CR %s covers ~%d weeks. Consider selling assets or finding sponsors." % [
					gs._fmt_int(int(gs.player_team.balance)),
					int(gs.player_team.balance / player_expenses)])

	# AI teams — simple salary model (unchanged)
	for team in gs.all_teams:
		if team.is_player_team:
			continue
		var driver_count = team.drivers.size()
		var ai_expenses = (team.weekly_driver_salary * driver_count) + team.weekly_mechanic_salary
		team.balance -= ai_expenses


func get_championship_driver_salary() -> float:
	if gs.active_championship == null:
		return 50.0
	match gs.active_championship.id:
		"C-001": return 20.0
		"C-021": return 420.0
		"C-024": return 2850.0
	return 50.0


# ═══════════════════════════════════════════════════════════════════════════
# CAMPUS INCOME & MAINTENANCE
# ═══════════════════════════════════════════════════════════════════════════

func apply_campus_income() -> void:
	var total_income = 0
	var total_maintenance = 0
	for building_id in gs.campus_buildings:
		var building = gs.campus_buildings[building_id]
		# Income and maintenance continue during upgrades (level >= 1).
		if building["built"] and building["level"] >= 1:
			total_income      += gs.get_building_income(building)
			total_maintenance += gs.get_building_maintenance(building)
	if total_income > 0:
		gs.player_team.balance += total_income
	gs.player_team.balance -= total_maintenance
	## Suppressed from log — shown as part of weekly P&L summary instead


# ═══════════════════════════════════════════════════════════════════════════
# CEO SALARY
# ═══════════════════════════════════════════════════════════════════════════

func update_ceo_salary() -> void:
	var weekly_profit = gs.player_team.balance - gs._prev_week_balance
	if weekly_profit > 0:
		gs.ceo_accumulated_salary += weekly_profit * 0.01  ## GDD: 1% of weekly net profit
	gs._prev_week_balance = gs.player_team.balance


# ═══════════════════════════════════════════════════════════════════════════
# SUPPLY CONTRACTS
# ═══════════════════════════════════════════════════════════════════════════

func process_supply_contracts_weekly() -> void:
	for sc in gs.active_supply_contracts:
		if not sc.active: continue
		var weekly_parts = max(1, int(sc.parts_per_season / 52.0))
		var inv_key = "%s_%s" % [sc.championship_id, sc.part_code]
		if inv_key in gs.cnc_parts_inventory and \
		   gs.cnc_parts_inventory[inv_key].quantity >= weekly_parts:
			gs.cnc_parts_inventory[inv_key].quantity -= weekly_parts
			if gs.cnc_parts_inventory[inv_key].quantity <= 0:
				gs.cnc_parts_inventory.erase(inv_key)
			gs.player_team.balance += weekly_parts * sc.cr_per_part
			sc.parts_delivered += weekly_parts


func process_supply_contracts_season_end() -> void:
	var to_remove: Array = []
	for sc in gs.active_supply_contracts:
		if not sc.active: continue
		if sc.parts_delivered < sc.parts_per_season:
			var shortfall = sc.parts_per_season - sc.parts_delivered
			var penalty = shortfall * sc.penalty_per_dns
			gs.player_team.balance -= penalty
			gs.add_notification("High",
				"Supply penalty: CR %s. Short %d parts to %s." % [
					gs._fmt_int(penalty), shortfall, sc.ai_team_name])
		sc.parts_delivered = 0
		sc.seasons_remaining -= 1
		if sc.seasons_remaining <= 0:
			sc.active = false
			gs.supply_contract_history.append(sc)
			to_remove.append(sc)
	for sc in to_remove:
		gs.active_supply_contracts.erase(sc)


# ═══════════════════════════════════════════════════════════════════════════
# LOAN SYSTEM (P44)
# ═══════════════════════════════════════════════════════════════════════════

func get_loan_tier() -> int:
	var hq_level = gs.campus_buildings.get("Headquarters", {}).get("level", 1)
	if hq_level >= 12: return 5
	if hq_level >= 9:  return 4
	if hq_level >= 6:  return 3
	if hq_level >= 3:  return 2
	return 1


## Returns the maximum loan amount available for a given tier.
## Based on company value × tier percentage. CFO negotiation adds up to +10%.
func get_max_loan_amount(tier: int = -1) -> float:
	if tier < 0: tier = get_loan_tier()
	const TIER_PCT = {1: 0.20, 2: 0.35, 3: 0.50, 4: 0.65, 5: 0.80}
	var base_pct = TIER_PCT.get(tier, 0.20)
	var company_val = calculate_company_value()
	var max_amount = company_val * base_pct
	## CFO negotiation bonus — up to +10% of cap at skill 100
	var cfo = gs.get_cfo()
	if cfo:
		var cfo_bonus = (cfo.sponsor_negotiation / 100.0) * 0.10
		max_amount *= (1.0 + cfo_bonus)
	## Without CFO: cap at Tier 1 regardless of HQ (applied in take_loan, not here)
	return max(0.0, max_amount)


## Returns the annual interest rate for a new loan.
func get_loan_rate() -> float:
	var base = gs.current_loan_rate
	## Risk premium: low rep teams pay more
	var risk_premium = max(0.0, (50.0 - gs.player_team.reputation) * 0.05)
	var cfo = gs.get_cfo()
	var cfo_discount = 0.0
	if cfo:
		cfo_discount = (cfo.budget_planning / 100.0) * 2.0   ## up to -2%
	else:
		base += 1.5  ## no-CFO penalty
	return clamp(base + risk_premium - cfo_discount, 0.5, 25.0)


## Returns the max number of simultaneous loans.
## Default: 2. CFO unlocks 3rd slot.
func get_max_loan_slots() -> int:
	return 3 if gs.get_cfo() != null else 2


## Calculates weekly mortgage payment for a loan.
func _calc_weekly_payment(principal: float, annual_rate: float, n_weeks: int) -> float:
	if n_weeks <= 0: return principal
	var weekly_r = (annual_rate / 100.0) / 52.0
	if weekly_r < 0.00001:
		return principal / float(n_weeks)
	var factor = weekly_r * pow(1.0 + weekly_r, float(n_weeks))
	var denom   = pow(1.0 + weekly_r, float(n_weeks)) - 1.0
	return principal * (factor / denom)


## Take a loan. Returns error string or "".
func take_loan(amount: float, seasons: int) -> String:
	var cfo = gs.get_cfo()
	var max_tier = get_loan_tier()
	if cfo == null: max_tier = 1   ## no-CFO cap

	if gs.active_loans.size() >= get_max_loan_slots():
		return "Maximum active loans reached (%d). Repay one first." % get_max_loan_slots()

	var max_amount = get_max_loan_amount(max_tier)
	if amount > max_amount:
		return "Amount exceeds maximum for current tier (CR %s)." % gs._fmt_int(int(max_amount))

	const MIN_SEASONS = {1:4, 2:4, 3:4, 4:4, 5:4}
	const MAX_SEASONS = {1:8, 2:12, 3:16, 4:20, 5:25}
	var tier = get_loan_tier() if cfo else 1
	var min_s = MIN_SEASONS.get(tier, 4)
	var max_s = MAX_SEASONS.get(tier, 8)
	if seasons < min_s or seasons > max_s:
		return "Duration must be %d–%d seasons for Tier %d." % [min_s, max_s, tier]

	var annual_rate = get_loan_rate()
	var n_weeks = seasons * 52
	var weekly_pay = _calc_weekly_payment(amount, annual_rate, n_weeks)

	var loan = {
		"id":               gs._loan_next_id,
		"amount_original":  amount,
		"balance_remaining": amount,
		"weekly_payment":   weekly_pay,
		"annual_rate":      annual_rate,
		"seasons_duration": seasons,
		"weeks_remaining":  n_weeks,
		"taken_season":     gs.current_season,
		"taken_week":       gs.current_week,
		"cfo_name":         cfo.full_name() if cfo else "No CFO",
	}
	gs._loan_next_id += 1
	gs.active_loans.append(loan)
	gs.player_team.balance += amount

	gs.add_log("🏦 Loan taken: CR %s over %d seasons @ %.1f%% p.a. (CR %s/wk)." % [
		gs._fmt_int(int(amount)), seasons, annual_rate, gs._fmt_int(int(weekly_pay))])
	gs.add_notification("High",
		"Loan of CR %s approved. Weekly repayment: CR %s." % [
			gs._fmt_int(int(amount)), gs._fmt_int(int(weekly_pay))], "hq")
	return ""


## Repay a loan fully. Penalty = 1 season of interest on remaining balance.
func repay_loan_early(loan_id: int) -> String:
	for i in range(gs.active_loans.size()):
		var loan = gs.active_loans[i]
		if loan["id"] != loan_id: continue
		var remaining = loan["balance_remaining"]
		var penalty   = remaining * (loan["annual_rate"] / 100.0)  ## ~1 year interest
		var total_due = remaining + penalty
		if gs.player_team.balance < total_due:
			return "Insufficient balance. Need CR %s (balance + penalty)." % gs._fmt_int(int(total_due))
		gs.player_team.balance -= total_due
		gs.active_loans.remove_at(i)
		gs.add_log("🏦 Loan #%d repaid early. Penalty: CR %s." % [loan_id, gs._fmt_int(int(penalty))])
		gs.add_notification("Normal", "Loan fully repaid. Penalty: CR %s." % gs._fmt_int(int(penalty)), "hq")
		return ""
	return "Loan not found."


## Called every advance_week() — deducts weekly payments from active loans.
func process_loans_weekly() -> void:
	var finished: Array = []
	for loan in gs.active_loans:
		if loan["weeks_remaining"] <= 0:
			finished.append(loan)
			continue
		var pay = min(loan["weekly_payment"], loan["balance_remaining"])
		gs.player_team.balance -= pay
		loan["balance_remaining"] = max(0.0, loan["balance_remaining"] - pay)
		loan["weeks_remaining"] -= 1
		if loan["weeks_remaining"] <= 0 or loan["balance_remaining"] < 1.0:
			finished.append(loan)
	for loan in finished:
		gs.active_loans.erase(loan)
		gs.add_log("🏦 Loan #%d fully repaid." % loan["id"])
		gs.add_notification("Normal", "Loan fully repaid! Financial obligations cleared.", "hq")


# ═══════════════════════════════════════════════════════════════════════════
# COMPANY VALUATION & FINANCIAL HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func calculate_company_value() -> float:
	var value = gs.player_team.balance
	for bname in gs.campus_buildings:
		var b = gs.campus_buildings[bname]
		if b.get("level", 0) > 0:
			value += b.get("build_cost", 0) * b.get("level", 1)
	for car in gs.player_team_cars:
		var car_value = gs.get_provider_car_cost(car.championship_id) * 0.6 \
			if car.championship_id != "" else 10000
		value += car_value
	return value


## Shared weekly expense total (staff + drivers + building maintenance)
func get_weekly_expenses() -> float:
	var total = 0.0
	for s_id in gs.all_staff:
		var s = gs.all_staff[s_id]
		if s.contract_team == gs.player_team.id:
			total += s.weekly_salary
	## Use per-driver negotiated salary; fall back to championship rate
	for driver_id in gs.player_team.drivers:
		var driver = gs.all_drivers.get(driver_id)
		if driver == null: continue
		total += driver.weekly_salary if driver.weekly_salary > 0 \
				else get_championship_driver_salary()
	for bname in gs.campus_buildings:
		var b = gs.campus_buildings[bname]
		if b.get("level", 0) > 0:
			total += b.get("weekly_maintenance", 0)
	return total


## Runway in weeks at current expense rate
func get_runway_weeks() -> int:
	var bal = gs.player_team.balance
	if bal <= 0: return 0
	var weekly = get_weekly_expenses()
	if weekly <= 0: return 999
	return int(bal / weekly)
