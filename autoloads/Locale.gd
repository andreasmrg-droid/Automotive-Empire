extends Node
## Version: S29.0 — Added not-interested popup keys (ap_ni_popup_*).
## --- S23.0 — TP proposals popup keys added.
## Usage: Locale.t("key")  →  returns translated string for current language.
## Adding a language: add a new dict entry in STRINGS below and a matching entry in LANGUAGES.
## Dynamic strings with substitutions: Locale.tf("key", [arg1, arg2])
##   Each language handles its own word order via positional placeholders {0} {1} etc.
## Rule: every hardcoded UI label must use Locale.t(). Proper nouns (driver names,
##   track names, championship names) are never translated.

## Active language code. Change via set_language().
var language: String = "en"

## Registered languages: code → display name
const LANGUAGES: Dictionary = {
	"en": "English",
}

## ── String tables ─────────────────────────────────────────────────────────────
## Keys are snake_case. Values are the display string for that language.
## Sections mirror the game's scenes for easy navigation.
const STRINGS: Dictionary = {

	# ── COMMON ────────────────────────────────────────────────────────────────
	"btn_back":           { "en": "← Back",        },
	"btn_close":          { "en": "Close",           },
	"btn_confirm":        { "en": "Confirm",       },
	"btn_cancel":         { "en": "Cancel",          },
	"btn_dismiss":        { "en": "✕ Dismiss",       },
	"btn_negotiate":      { "en": "📋 Negotiate",    },
	"btn_hire":           { "en": "✅ Hire",         },
	"btn_release":        { "en": "Release",         },
	"btn_assign":         { "en": "Assign →",     },
	"btn_unassign":       { "en": "✕ Unassign",      },
	"btn_fix":            { "en": "Fix →",         },
	"btn_go":             { "en": "Go →",            },
	"btn_manufacture":    { "en": "Manufacture →",   },
	"btn_submit":         { "en": "Submit",         },
	"btn_install":        { "en": "Install →",       },
	"btn_remove":         { "en": "Remove",          },	"btn_stop":           { "en": "⏹ Stop",         },
	"btn_start":          { "en": "▶ Start",        },
	"btn_walk_away":      { "en": "✕ Walk Away",     },
	"btn_accept_terms":   { "en": "Accept Their Terms",  },
	"lbl_season":         { "en": "Season",         },
	"lbl_week":           { "en": "Week",           },
	"lbl_round":          { "en": "Round",          },
	"lbl_of":             { "en": "of",             },
	"lbl_balance":        { "en": "Balance",       },
	"lbl_reputation":     { "en": "Reputation",    },
	"lbl_marketability":  { "en": "Marketability",   },
	"lbl_runway":         { "en": "Runway",         },
	"lbl_stable":         { "en": "Stable",         },
	"lbl_seasons":        { "en": "seasons",         },
	"lbl_season_s":       { "en": "season",          },
	"lbl_weeks":          { "en": "weeks",         },
	"lbl_week_s":         { "en": "week",            },
	"lbl_wk":             { "en": "wk",             },
	"lbl_none":           { "en": "None",           },
	"lbl_you":            { "en": "← YOU",          },
	"lbl_assigned":       { "en": "Assigned",        },
	"lbl_not_assigned":   { "en": "⚠ Not assigned",  },
	"lbl_empty_slot":     { "en": "Empty",           },
	"lbl_empty_part":     { "en": "⚠ EMPTY SLOT",    },
	"lbl_provider":       { "en": "Provider",         },
	"lbl_cnc":            { "en": "CNC",              },
	"lbl_condition":      { "en": "Condition",        },
	"lbl_terminal":       { "en": "⚠ TERMINAL DAMAGE",},
	"lbl_no_parts":       { "en": "No parts available.", },
	"lbl_bp_owned":       { "en": "✅ owned",          },
	"lbl_bp_active":      { "en": "🔬 active",         },
	"lbl_bp_wra":         { "en": "⏳ WRA pending",    },
	"lbl_bp_approved":    { "en": "🟢 WRA approved",   },
	"lbl_bp_none":        { "en": "⬜ none",           },
	"lbl_bp_mfg_ready":   { "en": "✅ ready to mfg",  },
	"lbl_bp_warehouse":   { "en": "📦 in warehouse",   },
	"lbl_bp_installed":   { "en": "🔩 installed",      },
	"btn_change_part":    { "en": "Change",            },
	"lbl_level":          { "en": "Level",           },
	"lbl_type":           { "en": "Type",           },
	"lbl_pts":            { "en": "pts",             },
	"lbl_per_week":       { "en": "per week",       },
	"lbl_total":          { "en": "TOTAL (est.)",    },
	"lbl_no_data":        { "en": "No data.",        },

	# ── MAIN HUB ──────────────────────────────────────────────────────────────
	"mainhub_advance":      { "en": "Advance Week ▶",    },
	"mainhub_next_race":    { "en": "⏭ Next Race",       },
	"mainhub_start_season": { "en": "Start Season %d ▶", },
	"mainhub_tab_campus":   { "en": "🏗 Campus",         },
	"mainhub_tab_hq":       { "en": "🏛 HQ",            },
	"mainhub_tab_logistics":{ "en": "📦 Logistics",     },
	"mainhub_tab_garage":   { "en": "🔧 Garage",        },
	"mainhub_tab_racing":   { "en": "🏁 Racing",        },
	"mainhub_tab_menu":     { "en": "☰ Menu",           },
	"menu_new_game":        { "en": "🏁  New Game",      },
	"menu_save":            { "en": "💾  Save Game",      },
	"menu_load":            { "en": "📂  Load Game" },
	"menu_load_title":      { "en": "📂  LOAD GAME" },
	"menu_load_empty":      { "en": "— empty —" },
	"menu_load_no_saves":   { "en": "No save files found." },
	"menu_load_manual":     { "en": "Manual Save" },
	"menu_load_auto":       { "en": "Autosave %d" },
	"menu_settings":        { "en": "⚙   Settings",      },
	"menu_quit":            { "en": "❌  Quit",           },
	"menu_saved":           { "en": "Game saved successfully!",  },
	"menu_load_confirm":    { "en": "Load saved game?\nAll unsaved progress will be lost.",
							   },
	"menu_quit_confirm":    { "en": "Quit to desktop?\nAll unsaved progress will be lost.",
							   },
	"menu_new_game_confirm":{ "en": "Start a new game?\nAll unsaved progress will be lost.",
							   },

	# ── HQ ────────────────────────────────────────────────────────────────────
	"hq_title":             { "en": "🏛  HEADQUARTERS",       },
	"hq_tab_overview":      { "en": "📊  Overview",           },
	"hq_tab_financial":     { "en": "💰  Financial Department", },
	"hq_tab_wra":           { "en": "📋  World Racing Association", },
	"hq_sec_ceo":           { "en": "CEO",                     },
	"hq_sec_finances":      { "en": "FINANCES",                },
	"hq_sec_effects":       { "en": "HQ EFFECTS",              },
	"hq_sec_championships": { "en": "ACTIVE CHAMPIONSHIPS",    },
	"hq_sec_drivers":       { "en": "DRIVERS",                 },
	"hq_sec_staff":         { "en": "STAFF",                  },
	"hq_sec_sponsors":      { "en": "SPONSORS",               },
	"hq_sec_tp_slots":      { "en": "TEAM PRINCIPAL SLOTS",    },
	"hq_sec_cfo":           { "en": "CFO",                     },
	"hq_sec_navigate":      { "en": "NAVIGATE",                },
	"hq_ceo_you":           { "en": "CEO  (You)",              },
	"hq_ceo_salary_desc":   { "en": "1% of weekly net profit", },
	"hq_hire_tp":           { "en": "Hire TP →",               },
	"hq_hire_cfo":          { "en": "Hire CFO →",              },
	"hq_no_cfo":            { "en": "— No CFO hired —",        },
	"hq_tp_slot_empty":     { "en": "TP Slot %d — Empty",      },
	"hq_no_championships":  { "en": "No active championships. Register via World Racing Association tab.",
							   },
	"hq_no_drivers":        { "en": "No drivers signed.",      },
	"hq_no_staff":          { "en": "No staff hired.",         },
	"hq_btn_hall_of_fame":  { "en": "🏆 Hall of Fame",         },
	"hq_btn_drivers":       { "en": "🏎 Drivers",             },
	"hq_btn_staff":         { "en": "👤 Staff Hub",            },

	# ── FINANCIAL DEPARTMENT ──────────────────────────────────────────────────
	"fin_title":            { "en": "💰  FINANCIAL DEPARTMENT", },
	"fin_tab_finances":     { "en": "📊  Finances",            },
	"fin_tab_sponsors":     { "en": "🤝  Sponsors",           },
	"fin_tab_proposals":    { "en": "💼  CFO Proposals",      },
	"fin_income":           { "en": "WEEKLY INCOME",          },
	"fin_expenses":         { "en": "WEEKLY EXPENSES",         },
	"fin_indicators":       { "en": "KEY INDICATORS",          },
	"fin_race_prizes":      { "en": "Race Prizes (est.)",      },
	"fin_sponsors_type1":   { "en": "Sponsors (Type 1)",      },
	"fin_parts_sales":      { "en": "Parts Sales",             },
	"fin_building_income":  { "en": "Building Income",        },
	"fin_driver_salaries":  { "en": "Driver Salaries",        },
	"fin_staff_salaries":   { "en": "Staff Salaries",          },
	"fin_maintenance":      { "en": "Maintenance",            },
	"fin_rnd_projects":     { "en": "R&D Projects",           },
	"fin_fuel_est":         { "en": "Fuel (est.)",             },
	"fin_loan_interest":    { "en": "Loan Interest",           },
	"fin_company_value":    { "en": "Company Value",           },
	"fin_max_loan":         { "en": "Max Loan",                },
	"fin_ceo_wealth":       { "en": "CEO Wealth",             },
	"fin_economy":          { "en": "Economy",                 },
	"fin_fuel_price":       { "en": "Fuel Price",            },
	"fin_wkly_cost":        { "en": "Wkly Cost",               },
	"fin_economy_boom":     { "en": "Boom",                   },
	"fin_economy_normal":   { "en": "Normal",                  },
	"fin_economy_recession":{ "en": "Recession",               },

	# ── SPONSORS ──────────────────────────────────────────────────────────────
	"sp_slots":             { "en": "Sponsor Slots:",          },
	"sp_active":            { "en": "ACTIVE SPONSORS",         },
	"sp_offers":            { "en": "PENDING OFFERS",         },
	"sp_cfo_search":        { "en": "CFO SPONSOR SEARCH",      },
	"sp_no_active":         { "en": "No active sponsors.",     },
	"sp_type1_detail":      { "en": "+CR %s/wk",              },
	"sp_type2_detail":      { "en": "Win: CR %s",             },
	"sp_type3_detail":      { "en": "Commitment deal",        },
	"sp_seasons_left":      { "en": "%d season%s left",       },
	"sp_no_offers":         { "en": "No offers pending.",      },
	"sp_expires_season":    { "en": "⚠ Expires this season",   },
	"sp_searching":         { "en": "🔍 CFO searching...",    },
	"sp_start_search":      { "en": "🔍 Start Sponsor Search", },
	"sp_stop_search":       { "en": "⏹ Stop Search",           },
	"sp_no_cfo_search":     { "en": "No CFO hired. Hire a CFO in HQ to unlock sponsor search.",
							   },
	"sp_cfo_proposals":     { "en": "CFO PROPOSALS",          },
	"sp_no_cfo_proposals":  { "en": "No CFO hired — hire one to receive financial proposals.",
							   },
	"sp_all_healthy":       { "en": "✅ All financial indicators healthy this week.",
							   },

	# ── WRA ───────────────────────────────────────────────────────────────────
	"wra_title":            { "en": "WRA & REGISTRATION",      },
	"wra_cycles":           { "en": "REGULATION CYCLE STATUS", },
	"wra_ready_submit":     { "en": "BLUEPRINTS READY TO SUBMIT",},
	"wra_pending":          { "en": "PENDING APPROVAL",        },
	"wra_approved":         { "en": "APPROVED — READY TO MANUFACTURE", },
	"wra_supply":           { "en": "SUPPLY CONTRACTS",        },
	"wra_registration":     { "en": "CHAMPIONSHIP REGISTRATION", },
	"wra_no_submit":        { "en": "No blueprints awaiting submission.",
							   },
	"wra_no_pending":       { "en": "No pending submissions.", },
	"wra_no_approved":      { "en": "No approved blueprints yet.", },
	"wra_no_supply":        { "en": "No active supply contracts.", },
	"wra_reg_btn":          { "en": "🏁  Championship Registration →", },
	"wra_resets_next":      { "en": "⚠ Resets NEXT SEASON",   },
	"wra_resets_in_2":      { "en": "⚠ Resets in 2 seasons", },
	"wra_resets_in_n":      { "en": "Resets in %d seasons",   },

	# ── NEW GAME ──────────────────────────────────────────────────────────────
	"ng_new_game":          { "en": "🏁  NEW GAME",            },
	"ng_continue":          { "en": "▶  CONTINUE",            },
	"ng_quit":              { "en": "Quit to Desktop",        },
	"ng_ceo_title":         { "en": "👤  CEO CREATION",       },
	"ng_team_title":        { "en": "🏎  TEAM CREATION",      },
	"ng_champ_title":       { "en": "🏆  CHOOSE YOUR ENTRY POINT", },
	"ng_difficulty_title":  { "en": "⚙  DIFFICULTY",         },
	"ng_summary_title":     { "en": "🏁  READY TO RACE",      },
	"ng_start_empire":      { "en": "🏁  START YOUR EMPIRE",   },
	"ng_ceo_name":          { "en": "Your Name",              },
	"ng_ceo_sex":           { "en": "Sex",                    },
	"ng_ceo_male":          { "en": "Male",                    },
	"ng_ceo_female":        { "en": "Female",                 },
	"ng_ceo_age":           { "en": "Starting Age (%d)",       },
	"ng_ceo_nationality":   { "en": "Nationality",             },
	"ng_team_name":         { "en": "Team Name",              },
	"ng_primary_color":     { "en": "Primary Color",          },
	"ng_secondary_color":   { "en": "Secondary Color",         },
	"ng_badge_preview":     { "en": "BADGE PREVIEW",          },

	# ── BEGIN / END OF SEASON ─────────────────────────────────────────────────
	"bos_title":            { "en": "🏁  SEASON %d BEGINS", },
	"bos_subtitle":         { "en": "Week 1 of 52  ·  Build your legacy.",
							   },
	"bos_championships":    { "en": "🏆  CHAMPIONSHIPS THIS SEASON",},
	"bos_tdl":              { "en": "📋  SEASON TO-DO",       },
	"bos_start_btn":        { "en": "▶  START SEASON %d",    },
	"bos_no_champs":        { "en": "No championships active. Register first.",
							   },
	"eos_title":            { "en": "🏁  SEASON %d COMPLETE",  },
	"eos_standings":        { "en": "🏆  CHAMPIONSHIP STANDINGS", },
	"eos_our_driver":       { "en": "← Our Driver",             },
	"eos_us":               { "en": "← Us",                     },
	"eos_drivers_hdr":      { "en": "DRIVERS",                   },
	"eos_teams_hdr":        { "en": "TEAMS",                    },
	"eos_weekly_profit":    { "en": "Weekly Profit",             },
	"eos_people":           { "en": "📈  DRIVER & STAFF PROGRESS", },
	"eos_rnd":              { "en": "🔬  R&D PIPELINE",        },
	"eos_finances":         { "en": "💰  FINANCIAL STATUS",    },
	"eos_continue_btn":     { "en": "▶  Continue to Season %d", },
	"eos_no_champs":        { "en": "No championships ran this season.",
							  },

	# ── CONTRACT NEGOTIATION ──────────────────────────────────────────────────
	"cn_title":             { "en": "📋  CONTRACT NEGOTIATION", },
	"cn_round":             { "en": "Round %d of %d",          },
	"cn_cfo_edge":          { "en": "💼 CFO +%.0f%% edge",    },
	"cn_term":              { "en": "TERM",                    },
	"cn_their_ask":         { "en": "THEIR ASK",               },
	"cn_your_offer":        { "en": "YOUR OFFER",             },
	"cn_deal":              { "en": "✅ Deal Agreed!",         },
	"cn_no_deal":           { "en": "❌ No Deal",              },
	"cn_walked_away":       { "en": "Negotiation ended. You walked away.",
							   },
	"cn_field_salary":      { "en": "Weekly Salary (CR)",      },
	"cn_field_win_bonus":   { "en": "Win Bonus (CR)",         },
	"cn_field_podium":      { "en": "Podium Bonus (CR)",      },
	"cn_field_champ_bonus": { "en": "Championship Bonus (CR)", },
	"cn_field_perf_bonus":  { "en": "Performance Bonus (CR)",  },
	"cn_field_release":     { "en": "Release Clause (CR)",     },
	"cn_field_duration":    { "en": "Duration (seasons)",     },
	"cn_field_weekly_pay":  { "en": "Weekly Payment (CR)",    },
	"cn_field_season_bonus":{ "en": "Season Bonus (CR)",       },
	"cn_field_commitment":  { "en": "Commitment Total (CR)",   },
	"cn_field_seasons":     { "en": "Seasons",                 },
	"cn_submit_offer":      { "en": "Submit Offer →",          },

	# ── DRIVERS ───────────────────────────────────────────────────────────────
	"drv_my_drivers":       { "en": "🏎 My Drivers (%d)",     },
	"drv_available":        { "en": "🌍 Available (%d)",     },
	"drv_negotiate":        { "en": "📋 Negotiate Contract",   },
	"drv_renegotiate":      { "en": "📋 Renegotiate",         },
	"drv_release":          { "en": "👋 Release",             },
	"drv_no_slot":          { "en": "⚠ No Slot",              },

	# ── STAFF ─────────────────────────────────────────────────────────────────
	"staff_my_staff":       { "en": "👥 My Staff (%d)",      },
	"staff_available":      { "en": "🌍 Available Staff (%d)", },
	"staff_assign_to":      { "en": "Assign to championship:", },
	"staff_no_eligible":    { "en": "No eligible championships.", },

	# ── APPROACH / BOND / NEGOTIATION ────────────────────────────────────────
	"ap_approach":          { "en": "📤 Approach",             },
	"ap_awaiting_reply":    { "en": "⏳ Awaiting Reply",        },
	"ap_bond_counter":      { "en": "💰 Bond Counter — Decide", },
	"ap_negotiating":       { "en": "📋 Negotiating Round %d",  },
	"ap_pre_signed":        { "en": "✅ Pre-signed (Next Season)", },
	"ap_no_tp":             { "en": "⚠ No Team Principal",      },
	"ap_no_slot":           { "en": "⚠ No Slot",               },
	"ap_sign_next_season":  { "en": "📋 Sign for Next Season",  },
	"ap_not_interested":    { "en": "🚫 Not interested",        },
	"ap_ni_popup_title":    { "en": "🚫 Not Interested",        },
	"ap_ni_popup_body":     { "en": "%s is not interested in joining your team at this time.", },
	"ap_ni_popup_hint":     { "en": "Improving your team's reputation and assigning a strong Team Principal makes targets more receptive.", },
	"ap_timing_immediate":  { "en": "🚀 Immediate Transfer",    },
	"ap_timing_next_season":{ "en": "📅 Next Season",           },
	"ap_bond_estimate":     { "en": "Bond estimate: CR %s – %s", },
	"ap_bond_no_cfo":       { "en": "⚠ No CFO — estimate ±30%%", },
	"ap_lock":              { "en": "🔓",                       },
	"ap_locked":            { "en": "🔒",                       },
	"ap_agreed":            { "en": "✅",                       },
	"ap_pending_activity":  { "en": "PENDING ACTIVITY",         },
	"ap_bond_incoming":     { "en": "📥 %s wants %s · CR %s",  },
	"ap_pre_signed_hq":     { "en": "✅ Pre-signed: %s · joins Season %d", },
	"ap_approach_sent":     { "en": "📤 Bond approach → %s (%s) · reply next week", },
	"ap_negotiating_hq":    { "en": "📋 Negotiating: %s · Round %d/%d · %d locked", },
	"graph_balance":        { "en": "💰 Balance",       },
	"graph_fuel":           { "en": "⛽ Fuel Price",    },
	"graph_economy":        { "en": "🌍 Economy",       },
	"graph_fans":           { "en": "👥 Active Fans",   },
	"graph_merch":          { "en": "🛍 Merchandise",   },
	"graph_reputation":     { "en": "⭐ Reputation",    },
	"graph_no_data":        { "en": "No data yet — advance weeks to populate.", },

	"hq_marketability":     { "en": "Marketability",   },
	"hq_active_fans":       { "en": "Active Fans",     },
	"hq_mktg_bonus":        { "en": "+%d%% Mktg Bonus", },
	"driver_reputation":    { "en": "⭐ Reputation",   },

	"fan_drivers_champ":    { "en": "🏆 %s wins Drivers Championship! Team +%.0f reputation.", },
	"fan_teams_champ":      { "en": "🏆 Constructors Championship won! Team +%.0f reputation.", },
	"fan_legacy_bonus":     { "en": "⭐ %s's legacy sustains team marketability for %d seasons.", },
	"fan_active_fans":      { "en": "Active Fans",    },
	"fan_marketability":    { "en": "Marketability",  },
	"fan_global_fans":      { "en": "Global Fans",    },

	"notif_critical":       { "en": "Critical",              },
	"notif_high":           { "en": "High",                 },
	"notif_normal":         { "en": "Normal",                },
	"notif_all_clear":      { "en": "✅ All clear",           },

	# ── RACING WORLD ──────────────────────────────────────────────────────────
	"rw_title":             { "en": "🌍  RACING WORLD",                      },
	"rw_btn":               { "en": "🌍 Racing World →",                     },
	"rw_btn_short":         { "en": "🌍 Racing World",                       },
	"rw_no_championships":  { "en": "No active championships.\nRegister via HQ → World Racing Association.", },
	"rw_no_active":         { "en": "No active championships in this discipline.", },
	"rw_not_in_standings":  { "en": "Not yet in standings.",                 },
	"rw_round_progress":    { "en": "Round %d / %d",                         },
	"rw_next_race":         { "en": "Next: %s  (Week %d)",                   },
	"rw_your_position":     { "en": "P%d of %d  ·  %s  ·  %d pts",          },
	"rw_team_position":     { "en": "Team P%d of %d  ·  %d pts",             },
	"rw_gk_no_data":        { "en": "GK group data not yet generated.\nAdvance to next season.", },
	"rw_gk_not_registered": { "en": "Not registered in any GK tier.\nRegister via HQ → WRA.", },
	"rw_gk_group_hdr":      { "en": "Group %d%s",                            },
	"rw_gk_group_n":        { "en": "Group %d",                              },
	"rw_gk_other_groups":   { "en": "OTHER GROUPS",                          },

	# ── TP PROPOSALS POPUP ────────────────────────────────────────────────────
	"tp_popup_title":       { "en": "🏁  TP ASSIGNMENT PROPOSALS",            },
	"tp_popup_accept_all":  { "en": "✅ Accept All",                           },
	"tp_popup_skip_all":    { "en": "Skip for Now",                            },
	"tp_popup_open_btn":    { "en": "📋 Review Proposals →",                   },
	"tp_popup_empty":       { "en": "✅ No assignments needed — all cars covered.", },

	# ── TP PROPOSALS (Racing Department) ──────────────────────────────────────
	"rw_tp_proposals":      { "en": "TP ASSIGNMENT PROPOSALS",               },
	"rw_no_proposals":      { "en": "✅ No pending TP suggestions.",          },
	"rw_accept":            { "en": "✅ Accept",                              },

	# ── READINESS ─────────────────────────────────────────────────────────────
	"ready_no_car":         { "en": "No car — buy at Logistics", },
	"ready_no_driver":      { "en": "No driver assigned",     },
	"ready_no_mechanic":    { "en": "No mechanic assigned",   },
	"ready_no_pit_crew":    { "en": "No pit crew — DNS risk", },
	"ready_blueprint_req":  { "en": "REQUIRED (Formula)",     },
	"ready_blueprint_ok":   { "en": "ready ✓",              },

}

# ── Public API ────────────────────────────────────────────────────────────────

## Returns the translated string for key in the current language.
## Falls back to English if the key or language is missing.
func t(key: String) -> String:
	if key not in STRINGS:
		push_warning("[Locale] Missing key: '%s'" % key)
		return key
	var table = STRINGS[key]
	if language in table: return table[language]
	if "en" in table:     return table["en"]
	push_warning("[Locale] No translation for key '%s' in language '%s'" % [key, language])
	return key

## Returns translated string with positional substitutions.
## Uses {0}, {1}... placeholders OR GDScript % formatting if no braces found.
## Example: Locale.tf("cn_round", [1, 5])  →  "Round 1 of 5"
func tf(key: String, args: Array) -> String:
	var s = t(key)
	## If the string uses {0} {1} placeholders, replace them
	if "{0}" in s:
		for i in range(args.size()):
			s = s.replace("{%d}" % i, str(args[i]))
		return s
	## Otherwise use GDScript % formatting (positional)
	if args.is_empty(): return s
	return s % args

## Change the active language.
func set_language(lang_code: String) -> void:
	if lang_code in LANGUAGES:
		language = lang_code
		emit_signal("language_changed")
	else:
		push_warning("[Locale] Unknown language code: '%s'" % lang_code)

## Returns the display name of the current language.
func current_language_name() -> String:
	return LANGUAGES.get(language, language)

signal language_changed
