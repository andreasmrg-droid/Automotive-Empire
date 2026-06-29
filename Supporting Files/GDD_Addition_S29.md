# GDD Addition — Session S29 (design/vision)

**Append to the manual-additions section of the GDD. Bump GDD to the next version
(handoff was at v4.4 → v4.5).**
Date: 2026-06-21 · Session: design/vision brainstorm (no code changed)
Companion design notes live in `Breanstrming_Threads.md` (project directory).

---

## §24. WIN-CONTINGENT SPONSORS

A class of sponsor that only engages teams with recent on-track success. Rides on
systems already specced — §13 Contract Negotiation (CFO-handled) and the news/reach
tier-scaling — rather than introducing a new subsystem.

### Lifecycle
1. **Initial offer.** A win-sponsor will approach/offer a team only if the team has
   **≥1 win in the relevant season** (see "relevant season" below). Sponsor tier is
   scaled by the news reach math — a GK win attracts GK-tier sponsors, not GP1 money.
2. **Contract runs** for its term.
3. **Extension at contract end.** The sponsor offers an extension only if the team has
   **≥1 win in the relevant season**; otherwise the sponsor walks (no extension offer).

The test is identical at both points: *did the team win in the relevant season?*

### "Relevant season" (resolves the season-boundary edge case)
- Contract ends **at season rollover** → evaluate against **the season that just finished**
  (the one actually raced), NOT the freshly-zeroed new season.
- Contract ends **mid-season** → evaluate against **the current running season**, counting
  wins so far.
- In all cases: evaluate against whichever season is the live competitive context at the
  moment of expiry. No sponsor is ever judged against an empty zeroed counter due to calendar
  timing.

### Scope & consequences
- **Applies to AI teams and the player alike. GK included.**
- Doubles as the AI ladder's automatic income mechanic (no scripting required):
  - A **fallen giant** (dropped to Survive) that goes winless through a contract term loses
    its win-sponsors at renewal → automatic income contraction.
  - A **climbing AI team** that starts winning gains win-sponsors at the next contract cycle
    → automatic income expansion through Settle→Develop.
- "What counts as a win" = a race win (engine already raises RACE WIN / WIN events, §12).
  Sponsor tiering may distinguish race win vs championship win via the existing event types
  if desired (open polish, not required for v1).

### Implementation note (for the coding chat, not decided here)
- Needs only a per-team season win counter the engine already has reason to track, plus a
  check hooked onto the existing contract-expiry event. No new heartbeat.

---

## §25. DEMO STRUCTURE

- **Playable demo = one full season in GK.** GK is the bottom of the pyramid, self-contained,
  and reachable before the full economy and the race module are complete (fits economy-first/
  race-last). One season is a naturally bounded arc with a clear ending.
- **Vision video plays at season end.** On completing the GK season, a trailer-style video
  presents the full game above the GK foothill — higher tiers, the other disciplines
  (Rally/Touring/Open-Wheel/Stock Car/Endurance/GP), the commercial car business, and the
  race module. Conversion design: the player has just invested a season and felt the loop, then
  is shown the mountain above the hill they climbed.
- **The demo teaches the win-sponsor loop in miniature** (§24): within that single GK season the
  player must win to attract a sponsor → income → reinvest. The slice expresses the core economic
  pressure of the full game.
- Strategy/marketing decision (see `Breanstrming_Threads.md` strategy section): a vision/trailer
  video can go up early with the Steam page + wishlist campaign; the playable GK-season demo lands
  later (≈ Phase 3, "playable without the race"). Any pre-final footage in the video is framed
  honestly (pre-alpha / target footage) — consistent with the project's over-transparency stance.

---

## §26. UI VISUAL DIRECTION (new — first visual-design section in the GDD)

### 26.1 Button motif
A telemetry/blueprint button used as the consistent UI button language:
- **Background:** dark — black or deep semi-transparent black/grey. The body recedes.
- **Tire (left):** a blueprint-style wheel — **concentric** outer tire wall + inner rim
  (same shared center), drawn as technical line-work, not a rendered rubber tire. Spokes from
  the shared center, hub dot on center. The outer tire wall has an **opening on the right**;
  the inner rim is a **full closed circle**.
- **Lines:** four telemetry-style lines — two top, two bottom, each pair one longer + one
  shorter (unequal). The **two outer (longer) lines connect to the outer tire wall's opening**;
  the inner/shorter lines sit free as data ticks. No vertical lines — the lines frame the text
  box (top edge + bottom edge), open at the sides.
- **Label:** left-aligned (starts on the left of the text band), sitting in the clear band
  between the top and bottom line pairs.

### 26.2 Color language
- **Color encodes button FUNCTION / SECTION, applied identically in every scene** (a UI
  consistency principle, not a data-encoding axis). Examples (palette TBD): back button
  consistent everywhere; important/destructive = red; buildings = blue; finance = green.
- The colored elements are the tire line-work and the telemetry lines (bright strokes on the
  dark background); background stays constant.
- **Defined centrally, referenced everywhere** — a single color-role source of truth the whole
  UI reads from. Never hand-set per scene (prevents drift across localized scenes).
- **Open:** section-color vs action-color precedence when a red/important action sits inside a
  themed scene — recommended rule: **action-type wins** (a destructive button is red even in a
  green finance screen; safety beats theme). To confirm in a balance/UI pass.

### 26.3 Typography
- **UI font = Inter (SIL OFL — safe to ship).** Chosen for screen legibility in dense tables/
  standings/finance panels, neutral and localization-friendly.
- **Defined centrally in the theme and referenced everywhere** — same principle as the color map.
- **Open (optional):** a technical display font (Rajdhani or Saira, both OFL) for data/headers
  (lap times, money, standings) to add dashboard character; and/or a monospaced font
  (JetBrains Mono, OFL) for numeric column alignment. Not required — Inter-only is a valid,
  lower-maintenance decision; motif personality can come from the graphics alone.
- **Rejected:** Apple SD Gothic Neo — proprietary macOS system font (Sandoll Communications),
  not licensed for redistribution in shipped software. If the humanist-Apple look is wanted,
  the free OFL stand-in is Pretendard.

### 26.4 Production note (for the coding chat)
- The actual button scene, theme resource, color-role map, font resource, and all UI strings
  (`Locale.t(...)`) are built at the keyboard, not in brainstorm. Wire color + font centrally
  BEFORE building many scenes to avoid a painful retrofit.
