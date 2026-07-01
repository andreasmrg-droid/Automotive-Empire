class_name FinancialEngine
## Version: S40.14 — CORPORATE TAX system: 24% base (OECD 2025 avg) on season profit, reduced by CFO
##   budget_planning (→15% floor at skill 100) + P4 tax_reduction, never below the 15% real-world
##   minimum. Losses untaxed. get_season_profit/get_effective_tax_rate/get_projected_season_tax +
##   apply_season_end_tax (deducts at season end with a notification) + snapshot_season_start_balance.
## Version: S40.13 — P4 ECONOMY cluster wired into apply_campus_income: maintenance_reduction lowers
##   total campus upkeep; passive-income effects lift campus income.
## Version: S39.5 — apply_commercial_income uses GameState.commercial_line_economics per line (income == UI preview)
## Version: S38.3 — Factory 2× cap now anchored to TOTAL racing income (sponsors+prizes+EOS) via
##   gs.get_avg_weekly_racing_income() (rolling window), replacing the sponsor-only anchor.
## Version: S38.2 — Phase 3 Factory income. apply_commercial_income() (called in process_weekly after
##   campus income) realizes per-line road-car sales: units=min(demand,capacity), credits=units×margin
##   ×CREDIT_SCALE×sales_factor, minus per-model marketing (player ratio × 18%-of-gross recommended).
##   CFO MANDATORY (no CFO → zero output; upkeep still charged via campus maintenance). Pillar-4
##   "weekly_commercial_output" boosts capacity. calculate_company_value() now folds in commercial
##   line asset value (~10× weekly gross per line). Reads gs._commercial_market + gs.commercial_lines.
## Version: S37.49 — Notification & News Roadmap, Phase 3 (events→notify_event). All 8 FinancialEngine
##   notifications migrated: the 4 recurring financial-distress warnings (insolvent / bankruptcy-risk /
##   negative-balance / low-funds) → "standing" so each week's state supersedes the last instead of
##   stacking a fresh Critical every week; supply penalty + the 3 loan-lifecycle events (approved /
##   repaid-with-penalty / cleared) → "event", HQ-routed.
## Version: S35.7 — PERF: get_weekly_expenses() (called on every HQ open) and the weekly salary
##   deduction now read the cached player-staff list instead of scanning all 5000+ staff.
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
	apply_commercial_income()   ## S38.2 — Phase 3 Factory road-car income
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

	# Staff salaries — sum all hired staff (S35.7: cached player-staff list)
	for staff in gs.get_all_player_staff():
		player_expenses += staff.weekly_salary

	gs.player_team.balance -= player_expenses
	## P&L summary logged in advance_week() after all income/expense functions run

	# Bankruptcy — escalating warnings, screen after 8 consecutive weeks negative
	if gs.player_team.balance < 0:
		gs.weeks_in_negative += 1
		if gs.weeks_in_negative >= 6:
			gs.notify_event("fin_insolvent", "Critical",
				"🚨 CRITICAL: %d weeks insolvent (CR %s). Team collapse imminent!" % [
					gs.weeks_in_negative, gs._fmt_int(int(gs.player_team.balance))], "", "standing")
		elif gs.weeks_in_negative >= 3:
			gs.notify_event("fin_bankruptcy_risk", "Critical",
				"🚨 BANKRUPTCY RISK: %d weeks negative (CR %s). Sell assets or find sponsors now." % [
					gs.weeks_in_negative, gs._fmt_int(int(gs.player_team.balance))], "", "standing")
		else:
			gs.notify_event("fin_negative", "High",
				"⚠ Balance negative (CR %s). Address this urgently." % gs._fmt_int(int(gs.player_team.balance)), "", "standing")
		if gs.weeks_in_negative >= 8 and not gs.bankruptcy_screen_shown:
			gs.bankruptcy_screen_shown = true
			gs.emit_signal("bankruptcy_triggered")
	else:
		gs.weeks_in_negative = 0
		gs.bankruptcy_screen_shown = false
		if player_expenses > 0 and gs.player_team.balance < player_expenses * 4:
			gs.notify_event("fin_low_funds", "High",
				"⚠ Low funds: CR %s covers ~%d weeks. Consider selling assets or finding sponsors." % [
					gs._fmt_int(int(gs.player_team.balance)),
					int(gs.player_team.balance / player_expenses)], "", "standing")

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
	## S40.13 — P4 ECONOMY cluster. maintenance_reduction lowers total campus upkeep; the passive-
	## income effects lift campus income (Museum/Theme Park/Club/Merchandise perks). Applied as
	## whole-cycle multipliers on the aggregate so any qualifying project contributes.
	var maint_cut: float = gs.rnd_maintenance_reduction()
	if maint_cut > 0.0:
		total_maintenance = int(round(float(total_maintenance) * max(0.2, 1.0 - maint_cut)))
	var passive_gain: float = gs.rnd_passive_income_bonus()
	if passive_gain > 0.0 and total_income > 0:
		total_income = int(round(float(total_income) * (1.0 + passive_gain)))
	if total_income > 0:
		gs.player_team.balance += total_income
	gs.player_team.balance -= total_maintenance
	## Suppressed from log — shown as part of weekly P&L summary instead


# ═══════════════════════════════════════════════════════════════════════════
# COMMERCIAL CAR FACTORY INCOME  (Phase 3 — GDD §4.4 / §1 Commercial_Car_Sales_Income)
# ═══════════════════════════════════════════════════════════════════════════
## Weekly road-car business income. Each active production line realizes
## sales = min(demand, capacity); credits = units × margin × CREDIT_SCALE × sales_factor.
## Marketing (≈18% of gross at recommended) is netted out per line. CFO is MANDATORY: with no CFO
## the Factory produces nothing but still burns building upkeep (campus maintenance already charges
## that), so this simply earns zero. Pillar-4 "weekly_commercial_output" boosts capacity.
func apply_commercial_income() -> void:
	var market = gs._commercial_market
	if market == null:
		return
	# CFO gate — no CFO → zero output (GDD §4.0). Upkeep is charged via apply_campus_income().
	if gs.get_cfo() == null:
		return
	if gs.commercial_lines.is_empty():
		return
	var factory = gs.campus_buildings.get("Vehicle Assembly Factory", {})
	if not factory.get("built", false) or factory.get("level", 0) < 1:
		return

	var net_total: float = 0.0
	for line in gs.commercial_lines:
		var seg: String = line.get("segment", "")
		if seg == "":
			continue
		## S39.5 — single source of truth so applied income matches the UI preview exactly (same floor
		## + 2× cap, applied per line inside commercial_line_economics).
		net_total += float(gs.commercial_line_economics(seg).get("net", 0.0))

	var net: float = net_total
	gs.player_team.balance += net
	## Logged as part of the weekly P&L summary; the Commercial Department screen shows the per-line
	## breakdown (demand / capacity / sales / gross / marketing / net).


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
			gs.notify_event("supply_penalty_%s" % sc.ai_team_name, "High",
				"Supply penalty: CR %s. Short %d parts to %s." % [
					gs._fmt_int(penalty), shortfall, sc.ai_team_name], "", "event")
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
	gs.notify_event("loan_approved", "High",
		"Loan of CR %s approved. Weekly repayment: CR %s." % [
			gs._fmt_int(int(amount)), gs._fmt_int(int(weekly_pay))], "hq", "event")
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
		gs.notify_event("loan_repaid", "Normal", "Loan fully repaid. Penalty: CR %s." % gs._fmt_int(int(penalty)), "hq", "event")
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
		gs.notify_event("loan_cleared", "Normal", "Loan fully repaid! Financial obligations cleared.", "hq", "event")


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
	## S38.2 — Commercial line asset value (GDD §1 Value_of_Commercial_Inventory): each active
	## production line is a going concern worth ~10 weeks of its current gross output.
	var market = gs._commercial_market
	if market != null and not gs.commercial_lines.is_empty() and gs.get_cfo() != null:
		var factory = gs.campus_buildings.get("Vehicle Assembly Factory", {})
		if factory.get("built", false) and factory.get("level", 0) >= 1:
			var flevel: int = int(factory.get("level", 1))
			var sfactor: float = gs.get_commercial_sales_factor()
			var obonus: float = gs._rnd_engine.get_rnd_bonus("weekly_commercial_output")
			for line in gs.commercial_lines:
				var seg: String = line.get("segment", "")
				if seg == "":
					continue
				value += market.line_weekly_credits(seg, gs.economy_index, flevel, sfactor, obonus) * 10.0
	return value


## Shared weekly expense total (staff + drivers + building maintenance)
func get_weekly_expenses() -> float:
	var total = 0.0
	## S35.7 — cached player-staff list instead of scanning all 5000+ staff (called on HQ open).
	for s in gs.get_all_player_staff():
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


# ═══════════════════════════════════════════════════════════════════════════
# CORPORATE TAXATION  (S40.14 — GDD: seasonal tax on profit)
# ═══════════════════════════════════════════════════════════════════════════
## Grounded in real-world 2025 figures (OECD): ~24% average statutory rate, a 15% global-minimum
## floor, ~36% top. Model: 24% base on the season's net profit, reduced by the CFO's budget_planning
## (skill 100 → -9pp, reaching the 15% real floor) and by any P4 tax_reduction research. Never below
## 15%. Losses are NOT taxed. Deducted once at season end with a notification.

const TAX_BASE_RATE := 0.24        ## OECD 2025 average statutory corporate rate
const TAX_FLOOR_RATE := 0.15       ## OECD global-minimum-tax floor — effective rate never goes below
const TAX_CFO_MAX_CUT := 0.09      ## a maxed CFO (budget_planning 100) cuts the rate by 9pp → 15%

## The season's profit basis: how much the balance grew since season start (losses → 0, untaxed).
func get_season_profit() -> float:
	return max(0.0, gs.player_team.balance - gs.season_start_balance)

## Effective corporate tax rate for the player this season, after CFO skill + P4 research, floored.
func get_effective_tax_rate() -> float:
	var rate := TAX_BASE_RATE
	var cfo = gs.get_cfo()
	if cfo != null:
		rate -= (cfo.budget_planning / 100.0) * TAX_CFO_MAX_CUT
	rate -= gs.rnd_tax_reduction()          ## P4 tax_reduction effect (accessor from S40.13)
	return max(TAX_FLOOR_RATE, rate)

## Projected tax on current season profit — for the HQ Financial Department display (live preview).
func get_projected_season_tax() -> int:
	return int(round(get_season_profit() * get_effective_tax_rate()))

## Deducts the season's corporate tax at season end and notifies the player. Called from
## SeasonManager.end_season(). No profit → no tax (and no notification clutter).
func apply_season_end_tax() -> void:
	var profit := get_season_profit()
	if profit <= 0.0:
		gs.notify_event("season_tax_%d" % gs.current_season, "Normal",
			"🧾 Season %d closed with no taxable profit — no corporate tax due." % gs.current_season,
			"hq", "event")
		return
	var rate := get_effective_tax_rate()
	var tax := int(round(profit * rate))
	gs.player_team.balance -= float(tax)
	gs.log_news("🧾 Corporate tax: -%s CR (%.0f%% on %s profit)" % [
		_fmt_cr(tax), rate * 100.0, _fmt_cr(int(profit))])
	gs.notify_event("season_tax_%d" % gs.current_season, "High",
		"🧾 Season %d corporate tax: -%s CR (%.0f%% of %s profit) has been deducted." % [
		gs.current_season, _fmt_cr(tax), rate * 100.0, _fmt_cr(int(profit))],
		"hq", "event")

## Snapshot the balance at the start of a season (called from SeasonManager.start_new_season and at
## game start) so next season's profit is measured from here.
func snapshot_season_start_balance() -> void:
	gs.season_start_balance = gs.player_team.balance

func _fmt_cr(n: int) -> String:
	## Compact CR formatting (e.g. 1.2M, 340K) for tax messages.
	var a: int = abs(n)
	if a >= 1_000_000: return "%.1fM" % (n / 1_000_000.0)
	if a >= 1_000:     return "%.0fK" % (n / 1_000.0)
	return str(n)
