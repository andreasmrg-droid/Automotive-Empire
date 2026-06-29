# Phase 3 — Commercial Car Industry: Design Validation & Rationale

**Companion to GDD v7.2 §4 (Commercial Car Industry).** This document is the *reasoning and proof* behind
the locked Phase-3 design — the "why we chose this and how we know it works." The GDD holds the canonical
*decisions and numbers*; this holds the *derivation*. Read this when balancing, re-tuning, or questioning a
constant. Produced from a full design + headless-simulation pass (all simulations are pure Python, mirroring
the GDD rule that economic logic lives in Python-testable form before GDScript).

**Status:** design + calibration COMPLETE and validated over 100 seasons. Not yet coded.

---

## 1. The core design (what was locked, in brief)

The Factory is a late-game, climb-gated road-car business — a second income stream that pairs with racing.

- **Segments:** 12 vehicle segments from the Excel "Commercial Cars Industry" tab (Economy Hatchbacks →
  Limited Run Megacars), each with volume, margin, complexity, market-type (Mass/Premium/Hyper), difficulty.
- **Unlock:** racing a championship with a `Factory_Unlock` (Excel Championships col BF) unlocks that
  segment's car. The mapping IS the discipline→segment matrix (e.g. RALLY4→Economy Hatch, GP1→Megacars).
  Racing the championship → notification → research the **Pillar-5** blueprint → build it on a Factory line.
- **Factory = production lines:** level = number of lines (1 per level); level 12 = 12 lines = all segments
  concurrently. Each line runs ONE model.
- **CnC stays separate** — CnC is racing parts only; the Factory is commercial cars only. No shared code.
- **Pillar 4** = Factory-boosting special projects (the 4 authored: robotic assembly, conveyor, monocoque,
  smart-factory). **Pillar 5** = per-segment car models + improvement ladder (Facelift / Next-Gen).
- **CFO mandatory:** no CFO → Factory burns full upkeep, zero output. CFO `sales_skill` amplifies sales,
  share growth, and marketing effectiveness via `sales_factor = 0.75 + sales_skill/200` (0.75…1.25).
- **Marketing PER MODEL:** CFO recommends a budget, player sets it; paid from revenue (~18% of gross at
  recommended); under-spend loses share; diminishing returns above recommended.
- **Specialist:** spreading across many segments is punished — committing lines to a few high-value segments
  beats dabbling (emerges naturally from per-model attractiveness).
- **Lifecycle:** real ~15–26 season (=15–26 in-game-season) model life; ramp → long plateau → death by ~25;
  decline driven by competitiveness drift (rivals refresh, you don't), not a hard age cap; Facelift (cheap,
  restores competitiveness) and Next-Gen (expensive, launches successor, resets clock) keep a line alive.
- **Living market:** player + AI shares drift on attractiveness; "Others %" is a resisting residual bloc;
  every segment sums to 100%.

---

## 2. Real-world research (the income-mix anchor)

FY2024 road-car vs racing revenue for the brands the designer named:

- **Ferrari:** road cars **86%**, racing (F1+WEC+brand) **~10%** — even the most racing-defined brand.
- **Porsche:** motorsport **<1%**. **Toyota/Hyundai/Škoda:** racing **<1%**. **Aston/Merc/BMW:** low single digits.
- **McLaren:** racing is a **legally separate company** (£530M) from the road-car business.

**Key finding:** everywhere, racing is a *marketing expense that sells road cars* (validates the
Racing_Buzz→share design). But in reality the road business *dwarfs* racing (10×+). Since this is a
**racing-team management sim**, mirroring that would make racing pointless. **Decision: invert reality for
playability — cap the mature Factory at ~1× racing income (max 2×), McLaren-style** (the two comparable).

---

## 3. Racing income model (the cap's anchor) — derived from game data

Racing income = sponsors + prize money + EOS, computed from the Excel Championships sheet + teams.json
sponsor counts (scale with reputation: rep 36→~4 sponsors, rep 100→~12) × Sponsors-sheet payments.

| Stage | Racing income/week |
|---|---:|
| Early rally (RALLY4) | ~CR 46K |
| Established mid-tier | ~CR 140–190K |
| Top non-GP1 (SC Cup, TC Elite) | ~CR 225–500K |
| GP1 champion | ~CR 2.79M (prize-driven outlier) |

**Sponsors are the backbone** of racing income at every stage except the GP1 pinnacle, where the CR 140M EOS
prize dominates. The Factory cap is pegged to this curve, so it auto-scales across the career.

---

## 4. The market engine — why ATTRACTIVENESS/REDISTRIBUTION (the journey to v4)

Five iterations, each fixing the prior's flaw — this is why the final engine is shaped as it is:

- **v1 (single-player, multiplicative growth):** revenue ~1000× too high; runaway share; weak lifecycle.
- **all-AI test (designer's idea — run every real producer 100 seasons, no player):** exposed the core flaw —
  **rich-get-richer runaway** in thinly-contested segments (Thunderbolt → 80% of V8 Sedans). Crowded
  segments (6 producers) stayed stable. Lesson: few competitors → monopoly.
- **v2 (resisting "Others" bloc + player):** Others floor held, but (a) producer-vs-producer runaway
  persisted, and (b) **the cold-start player was frozen at 0.5% forever** — because multiplicative growth
  can't lift a tiny newcomer. This was the critical discovery: the player is *always* a new entrant.
- **v3 (ATTRACTIVENESS core + 3 named giants):** BREAKTHROUGH. Share won by competitiveness (reputation +
  model freshness + marketing + CFO), redistributed toward the more attractive each week with inertia
  (~5–8 season climb). Result: 1/12 runaways, player climbs 11–29% on merit, monopolies self-cap, market
  alive. All locked rules fall out naturally.
- **v4 (= v3 with 7 named giants) — LOCKED:** 0/12 runaways, volume leaders 12–17% (realistic
  fragmentation), faceless Others 2–7%, player 9–29%. Strictly better than 3 giants. **This is the engine.**

**Why it's right:** a strong newcomer pulls share *from* weak/stale incumbents (player climbs on merit); a
dominant producer faces the whole field's combined attractiveness + its own aging models (monopolies
self-cap); "Others" is a resisting participant; and reputation, marketing, the 25-season lifecycle, and the
specialist rule all matter automatically.

**Locked engine constants:** `INERTIA=0.045`, attractiveness = `1.0·(rep/100) + 0.8·freshness +
0.6·(marketing−1) + 0.15·giant_bonus`, `OTHERS_ATTR=0.35`. Lifecycle: ramp 2.5s, plateau to 16s, death 25s.

**The 7 giants (fictional volume incumbents):** Meridian Motors, Continental Auto, Pacifica Group, Aurora
Vehicles, Summit Automotive, Northwind Motors, Crestline Group — occupy the mass/volume segments (Economy,
Pickups, Pony, Hot Hatches, Entry Sports, EV, one into Rally Replica). They replace the faceless "Others" in
volume markets with real, beatable competitors.

---

## 5. Sponsor sensitivity (±30%) — confirms the cap auto-scales

Tested racing income at sponsors ×0.7, ×1.0, ×1.3:
- A ±30% sponsor change moves **early/mid game ~1:1** (sponsors are 97–99% of income there) but **barely
  moves the GP1 pinnacle (±2.7%)** (prize-dominated). So sponsors are the early/mid tuning dial; top-tier
  **prize/EOS payouts** are the pinnacle dial — two independent levers.
- **The Factory cap auto-scales** with whatever sponsor level is chosen (it's a multiple of racing income),
  so "max 2×" holds at every setting with zero rebalancing. The market engine is unaffected by sponsor
  changes (it governs share, not credits).

---

## 6. Economy cycles + a discovered issue in the existing build

The commercial demand cycle plugs into the game's EXISTING `economy_index`
(`GameState._update_economy_and_fuel`). Per-segment demand multiplier:
`demand_mult = 1 + ((economy_index−50)/50) × cyclicality`, cyclicality Mass 0.45 / Premium 0.25 / Hyper 0.08
(hyper is recession-resistant, matching the Ferrari data). Sponsor offers also soften in recessions
(±20%, plugged into `SponsorManager._generate_sponsor_offer`).

**Validated:** cycles do NOT destabilize the market — a boom/recession scales the whole segment's pie
equally, so shares still redistribute fairly; only credits-earned moves. v4 stays stable with cycles on.

**DISCOVERY (pre-existing, not caused by this feature):** the current economy formula (mean-reversion 0.008 +
drift ±0.5) keeps `economy_index` in a 35–67 band — it **never reaches Boom (>70) or Recession (<30)** in a
100-season career. The economy system is wired up but practically flat. **Recommended re-tune:** a slow
~4-season sine "regime" + light noise + rare shocks, which produces genuine but rare cycles (~3–4 booms and
~3–4 recessions per ~25-season career; mostly Normal). This is a small change to one existing function and
simultaneously revives the dormant fuel/loan/`speculation` systems. (Adopted — Option A.)

---

## 7. Income calibration (turning share into credits) + ROI

**The magnitude problem:** raw Excel margins (CR 8,500–3,150,000/unit) are real-world dollars, ~1000× the
game's credit scale; 8 mature lines would gross CR 110M/week (absurd). **Fix:** keep Excel MSRP/margins as
on-screen flavor; multiply actual commercial income by a **credit scale ≈0.0054** so a fully-built mature
Factory lands at ~1.2× racing income (anchored to ~CR 496K/wk "top stock" racing; deliberately NOT the GP1
champion outlier). Marketing costs 18% of gross.

**Validated weekly income (with realistic share climb):** the Factory ramps slowly — ~0.13× racing at S10,
~0.44× at S50, ~0.85× at S75, **~1.18× at S100 (mature)** — on target, under the 2× cap, reached gradually.

**Per-line ROI (measured inside the sim with the share climb, NOT a static snapshot):** payback ranges
**~0.5–5 seasons** — healthy, never instant, never dead money. (An earlier static-snapshot calculation
wrongly showed ~8-week paybacks by assuming mature share on day one; corrected here.)

**Upgrade-cost staircase (replaces the broken flat 250K):** descending, ~3-season payback per line —
12.08M, 9.89M, 7.94M, 6.95M, 6.79M, 6.62M, 4.84M, 4.47M, 2.81M, 1.6M, 1.2M (L1→L2 … L11→L12). **Build cost
kept at 1.2M** (accessible entry; the slow share-climb prevents instant riches; the real weight is in the
upgrades). Total Factory capex ~CR 66.4M.

---

## 8. Representation (for ALL players, even without a Factory)

- **New "Commercial Department" in HQ** — read-only market view (12 segments, producers = giants + racing
  brands, live shares, "Others", the economy's current commercial effect). Visible to everyone from the
  start (aspirational + scouting); becomes interactive (set marketing, manage models) once a Factory is
  owned. The **economy graph stays in Financial dept** (it's a financial indicator); its commercial
  *consequences* show in the Commercial Department.
- **News + notifications** carry events: economy shifts (already exists, CFO-gated), market-share milestones,
  and the "you can research this segment's blueprint" unlock breadcrumbs from racing the linked championship.
- **Staggered model seeding:** new-game setup seeds AI models at deliberate, varied mid-life ages (persisted
  in save) so the industry looks mature on day one and avoids synchronized 25-season death waves.

---

## 9. Calibrated constants (the authoritative table — also in GDD §4)

| Constant | Value | Note |
|---|---|---|
| Commercial credit scale | ≈0.0054 | lands mature Factory at ~1.18× racing; recompute if racing income re-tuned (self-corrects) |
| Factory mature income | ~1.18× racing, cap 2× | reached gradually over the career |
| `sales_factor` (CFO) | 0.75 + sales_skill/200 | 0.75 (no CFO band) … 1.25; no CFO = Factory off entirely |
| Marketing cost | 18% of gross @ recommended | paid from revenue; under-spend loses share; diminishing returns above |
| Per-line capacity | 500 u/wk L1, +250/level | Excel; income is capacity-bound then scaled |
| Build cost (L1) | 1,200,000 | code value; accessible entry |
| Upgrade staircase | 12.08M…1.2M (see §7) | descending; ~3-season payback per line; total capex ~66.4M |
| Lifecycle | ramp 2.5s / plateau→16s / death 25s | hard ~25-season model life |
| Attractiveness inertia | 0.045 | ~5–8 season climb for a newcomer |
| Per-segment cyclicality | Mass 0.45 / Premium 0.25 / Hyper 0.08 | recession resistance scales with prestige |
| Sponsor economy multiplier | 1 + (idx−50)/50 × 0.20 | recessions → leaner offers (in `_generate_sponsor_offer`) |
| Economy re-tune | ~4-season sine regime + noise + rare shocks | makes the existing flat economy genuinely cycle |

---

## 10. Integration points (where each piece touches the code)

1. New commercial market engine → a pure RefCounted `CommercialMarketSim` (Python-portable, per GDD rule).
2. Economy re-tune → `GameState._update_economy_and_fuel` (the ~810–826 block).
3. Sponsor economy multiplier → `SponsorManager._generate_sponsor_offer`.
4. Factory income → `FinancialEngine` (new `Commercial_Car_Sales_Income` term in §3; inventory value in
   `calculate_company_value`).
5. CFO `sales_factor` → applied to Factory commercial income + market-share growth ONLY (not other
   commercial buildings — those stay marketability/fan income).
6. Pillar-5 catalog → 12 model blueprints + improvement ladder (Facelift/Next-Gen) — data to author.
7. Commercial Department screen → new HQ building/scene; read-only until Factory owned.
8. Save/load → per-segment player shares, model ages/lifecycle, marketing budgets, factory level/lines;
   AI staggered seeding persisted.
9. News/notification classification → market milestones + unlock breadcrumbs (news); routine shifts (ops).

---

## 11. Simulation artifacts (the runnable proof)

All pure-Python, re-runnable: `market_v4_LOCKED.py` (the engine), `ai_market.py` (all-AI stability test),
`market_v2.py` / `market_v3.py` (the journey), `sponsor_test.py` (±30% sensitivity),
`market_v5_cycles.py` (economy cycles), `roi_fix.py` (corrected per-line ROI), `income_calibration.py`
(credit scale + staircase). Findings reports accompany each. These constitute the headless validation the
GDD requires before shipping economic logic.

---

**Bottom line:** every Phase-3 design decision is backed by a 100-season simulation. The market is stable,
realistic, living, and winnable; the Factory is capped to racing; the economy cycles meaningfully; ROI is
satisfying. Ready to port to GDScript from the GDD §4 spec + this rationale.
