# Step 3 — ContractEngine event ledger (for sign-off before coding)

33 remaining `add_notification` calls. Each → a `notify_event` mode (`event` / `news` / `once` /
`standing`) + destination, OR flagged as a **leftover blocking error** (→ `show_popup`, Phase 1
straggler), OR **leave** (already correct). Modes recap: `event`=one-shot notice; `news`=notice +
feed; `standing`=supersede by subject (collapses weekly re-fires); `once`=fires once per save.

## A. Leftover BLOCKING ERRORS (missed in Phase 1) → show_popup

| Line | Message | Proposed |
|---|---|---|
| 371 | "Deal fell through — no driver slots…immediate. Sign next season." | show_popup "No Slot" |
| 384 | "Deal fell through — TP slots full. Sign for next season." | show_popup "No Slot" |
| 1557 | "Racing Dept full — can't sign %s immediately…" | show_popup "Slots Full" |
| 1614 | "TP slots full. Upgrade HQ." | show_popup "Slots Full" |
| 1617 | "You already have a CFO." | show_popup "Already Have a CFO" |

*These are "you can't complete this action" results at sign time — popups, per Phase 1 rule.*

## B. NEGOTIATION-GATE INFO (runs on open; information, not a chore) → event

| Line | Message | Proposed |
|---|---|---|
| 816 | "%s's team recently refused… try again in N weeks." | event (no dest) |
| 834 | "%s is not interested at this time." | event (no dest) — *note: also shown as popup by caller; see Q4* |
| 850 | "%s is not willing to release their %s. Try again…" | event (no dest) — *also popup'd by caller; Q4* |

## C. APPROACH / BOND LIFECYCLE (discrete events, mostly HQ-routed) → event

| Line | Message | Dest |
|---|---|---|
| 891 | "Approach sent for %s. Their team will name a buyout next week." | drivers/staff_hub |
| 920 | "Bond agreed for %s (CR). Contract negotiation begins." | hq |
| 933 | "Bond negotiation with %s's team failed." | hq |
| 959 | "%s (AI team) wants to approach %s. Proposed bond CR — respond in HQ." | hq |
| 976 | "Bond accepted: CR received for %s." | hq |
| 983 | "Counter-bond sent for %s. Awaiting reply." | (none) |
| 986 | "Approach for %s rejected." | (none) |
| 1339 | "%s's team wants CR to let them go. Decide from %s." | hq |
| 1359 | "%s's team accepted the bond (CR). Contract negotiation begins." | hq |
| 1369 | "%s's team countered: CR for the bond. Accept/counter/reject…" | drivers/staff_hub |
| 1376 | "%s's team rejected the bond offer." | (none) |

## D. CONTRACT-ROUND LIFECYCLE → event (HQ); reminders → standing

| Line | Message | Proposed |
|---|---|---|
| 1059 | "Contract negotiations with %s have broken down." | event |
| 1234 | "Incoming approach for %s auto-rejected (no response)." | event |
| 1245 | "Negotiations with %s expired — no response." | event |
| 1254 | "Reminder: Contract Round N/M with %s — respond from HQ." | **standing** subj `nego_<id>` → hq |
| 1266 | "Contract negotiations with %s concluded without a deal." | event |
| 1269 | "Contract Round N/M with %s — respond from HQ." | **standing** subj `nego_<id>` → hq |

*1254 & 1269 are the recurring weekly "respond now" nudges — `standing` collapses them so they don't
stack week over week. They pair with the existing negotiation TDL. Q3: confirm standing here.*

## E. SIGNINGS & DEPARTURES → NEWS (your rule: marquee signings + every departure = news)

| Line | Message | Proposed |
|---|---|---|
| 414 | "%s is no longer interested for 2 seasons." (walk-away result) | **news** |
| 1114 | "You walked away from negotiations with %s." | **news** |
| 1180 | "%s pre-signed, joins start of Season N." | **news** + dest hq |
| 1569 | "%s pre-signed, joins start of Season N." (driver) | **news** + dest hq |
| 1604 | "%s pre-signed, joins start of Season N." (staff) | **news** + dest hq |
| 1590 | "%s signed. Assign them to a car in the Garage." | **news** + dest garage + pairs with assign-TDL |
| 1628 | "%s (%s) joined your team." | **news** |

*Q1: are ALL signings news, or only "marquee" (some rep threshold)? Your earlier "yes" implies all.
Q2: 1590 signed→"assign in Garage" — keep the assign reminder as a TDL (already covered) + a news
entry for the signing itself?*

## F. SPONSOR / MISC → event

| Line | Message | Dest |
|---|---|---|
| 1193 | "Sponsor deal with %s updated." | hq |

## Open questions (need your calls)
- **Q1.** All signings → news, or only above a reputation/notability threshold?
- **Q2.** A signing that needs assignment (1590): news for the signing + the existing assign-TDL — correct?
- **Q3.** Recurring "respond to Round N" nudges (1254/1269) → `standing` (collapse weekly), or plain `event` each week?
- **Q4.** "Not interested"/"team refused" (816/834/850) already pop a modal in the caller scene. Keep the notification too (a record in the panel), or drop it (popup is enough)?
- **Q5.** Walk-away (414/1114) → news: both the player's own walk-away AND the resulting "no longer interested"? Or is walk-away too minor for the feed?
