---
course: "34722"
course-name: "Linear Control Design 1"
type: handoff
tags: [LCD, regbot, handoff, matlab-cleanup]
date: 2026-05-13
---
# REGBOT Balance Assignment — MATLAB Cleanup Handoff

> [!abstract] Goal
> Make `simulink/` ready for submission. The current design scripts are
> heavily commented (they were written pedagogically and a separate
> walkthrough doc in `docs/MATLAB Walkthrough.md` captures all the
> pedagogy). For grading, the user wants the code **leaner**:
> simplified comments, only enough to explain what's going on, and any
> unused code removed. Numerical content (gains, design parameters) is
> off-limits — those are validated on hardware.

> [!warning] Hard rules carried over from `docs/HANDOFF.md`
> 1. **No AI / Claude attribution in commits** — global rule, project-wide.
> 2. **Do not alter the canonical numerical content** of the four loops.
>    The committed v3 gains in `simulink/regbot_mg.m` and
>    `config/regbot_group47.ini` are hardware-validated. Don't "improve"
>    them.
> 3. **Don't regenerate plots in `docs/images/`** unless the user
>    explicitly asks. Future-you re-running the design scripts will
>    overwrite them.
> 4. **Don't add `=====` decorative banners** back to the design scripts.
>    The user explicitly stripped them previously and the existing
>    section-header comments use `%% ====== STEP N — TITLE =====` only.
>    Don't escalate.
> 5. **Stage selectively at commit time.** `git add -A` is forbidden
>    (CRLF churn + stray scratch files).
> 6. **The `Report/` submodule has a symlink quirk** — do not touch.
> 7. **The MATLAB Walkthrough doc (`docs/MATLAB Walkthrough.md`) is the
>    home for the pedagogy.** Scripts can be lean *because* the
>    walkthrough exists. Cite it briefly in the script headers ("see
>    `docs/MATLAB Walkthrough.md §X` for the math") rather than repeating
>    derivations inline.

---

## Scope

Files in scope:

```
simulink/
├── regbot_mg.m                     -- workspace loader (114 lines)
├── design_task1_wheel.m            -- Task 1 PI design   (180 lines)
├── design_task2_balance.m          -- Task 2 Method 2    (321 lines)
├── design_task3_velocity.m         -- Task 3 PI design   (202 lines)
├── design_task4_position.m         -- Task 4 P design    (226 lines)
└── lib/
    ├── pick_image_dir.m            -- helper             ( 18 lines)
    ├── poly_to_str.m               -- helper             ( 34 lines)
    ├── print_tf.m                  -- helper             ( 14 lines)
    └── save_plot.m                 -- helper             (  6 lines)
```

Out of scope:
- `simulink/regbot_1mg.slx` — binary Simulink model. Don't open in this
  session. The user updates it manually.
- `data/Day5_results_v2.mat` — plant-ID artefact. Don't touch.
- `config/regbot_group47.ini` — firmware gains. Don't touch.
- Anything outside `simulink/`.

---

## What "ready for submission" means

The graders will read the four `design_task*.m` scripts and
`regbot_mg.m`. They need to:

1. Run end-to-end without errors on a fresh MATLAB session.
2. Produce the gain values committed in `regbot_mg.m`.
3. Produce the figures embedded in the report.
4. Be **readable**, not bloated — enough comments to follow the
   recipe, no long pedagogical paragraphs.

The MATLAB Walkthrough (`docs/MATLAB Walkthrough.md`) is where the
detailed reasoning lives. The scripts should defer to it.

---

## Inventory: which figures are actually used

Run this audit once at the start so you know what's a deliverable vs.
diagnostic-only.

**Used in the report** (`Report/sections/*.tex`, also visible in `Report/main.pdf`):

| Image | Source script | Figure handle |
|---|---|---|
| `regbot_task1_bode.png` | `design_task1_wheel.m` | fig 200 |
| `regbot_task1_step.png` | `design_task1_wheel.m` | fig 201 |
| `regbot_task2_bode_post.png` | `design_task2_balance.m` | fig 300 |
| `regbot_task2_nyquist_post.png` | `design_task2_balance.m` | fig 301 |
| `regbot_task2_loop_bode.png` | `design_task2_balance.m` | fig 302 |
| `regbot_task2_step.png` | `design_task2_balance.m` | fig 303 |
| `regbot_task3_loop_bode.png` | `design_task3_velocity.m` | fig 400 |
| `regbot_task3_step.png` | `design_task3_velocity.m` | fig 401 |
| `regbot_task4_loop_bode.png` | `design_task4_position.m` | fig 500 |
| `regbot_task4_sim_step_v3.png` | **NOT a design script** — produced manually from the full Simulink simulation. Don't try to generate from a script. | — |

**Generated but NOT used in the report** (diagnostic / pedagogical plots):

| Image | Source script | Action |
|---|---|---|
| `regbot_task1_step1_plant_bode.png` | task1 fig 190 | Remove |
| `regbot_task1_step3_pi_overlay.png` | task1 fig 191 | Remove |
| `regbot_task1_step4_phase_balance.png` | task1 fig 192 | Remove |
| `regbot_Gwv_bode.png` | task2 fig 100 | Remove |
| `regbot_Gtilt_bode.png` | task2 fig 101 | Remove |
| `regbot_Gwv_pzmap.png`, `_pzmap_zoom.png` | task2 figs 102, 104 | Remove |
| `regbot_Gtilt_pzmap.png`, `_pzmap_zoom.png` | task2 figs 103, 105 | Remove |
| `regbot_Gtilt_nyquist.png` | task2 fig 106 | Remove |
| `regbot_task2_phase_balance.png` | task2 fig 305 | Remove |
| `regbot_task2_ic_response.png` | task2 fig 304 | Remove |
| `regbot_task3_plant_pz.png` | task3 fig 402 | Remove |
| `regbot_task3_phase_balance.png` | task3 fig 403 | Remove |
| `regbot_task4_plant_pz.png` | task4 fig 502 | Remove |
| `regbot_task4_phase_balance.png` | task4 fig 503 | Remove |
| `regbot_task4_step.png` | task4 fig 501 | Remove (report uses `_sim_step_v3` instead) |

"Remove" means delete the figure-generation block from the design
script. **Do NOT delete the existing PNG files in `docs/images/`** —
that violates hard rule #3. Future re-runs of the cleaned scripts
just won't regenerate those PNGs.

---

## Per-file plan

### `lib/` helpers — likely no changes

These are already lean and used by the design scripts:

- `pick_image_dir.m` — 18 lines, fine. Maybe trim the "historically also
  mirrored into Obsidian" paragraph in the docstring to one line.
- `poly_to_str.m` — pure function, already terse. Skip.
- `print_tf.m` — 14 lines. Skip.
- `save_plot.m` — 6 lines. Skip.

Pass on `lib/`: maybe 5-10 lines total.

### `regbot_mg.m` (114 → target ~70 lines)

**Keep:**
- Physical parameters block — these are the assignment-given values
- The four committed-gain blocks (Kpwv/tiwv/Kffwv, Kptilt/titilt/tdtilt/tipost, Kpvel/tivel, Kppos/tdpos) — numerical content is canonical

**Trim:**
- The 14-line header banner → 3-line header
- The "WHERE EACH GAIN COMES FROM" explanatory paragraph (lines 16-28) → drop entirely; each gain block already names its source script
- The Day-5-redesign history paragraphs above each gain block (e.g. lines 78-83 for Task 2, lines 96-112 for Task 4 with its DUPLICATE Lead-drop paragraph) → one-line "from design_task2_balance.m: wc=15, gamma_M=60, Ni=3 → Kp=1.20, ..."
- Task 4 has two paragraphs about dropping the Lead — keep one

Target header for each gain block:

```matlab
% --- Task 1: Wheel-speed PI (design_task1_wheel.m) -----------------
% wc = 30 rad/s, gamma_M = 82.85 deg, GM = inf dB.
Kpwv   = 13.2037;
tiwv   = 0.1000;
Kffwv  = 0;
```

### `design_task1_wheel.m` (180 → target ~110 lines)

This is the template. Get this one right; the other three follow the
same pattern.

**Keep:**
- All numerical/algorithmic content (PI zero placement, phase-balance read, Kp solve, margin verify)
- The 6-step section structure (`%% STEP N — TITLE`)
- Final-plot generation: fig 200 (margin Bode → `regbot_task1_bode.png`) and fig 201 (closed-loop step → `regbot_task1_step.png`)
- The base-workspace write at the end (`Kpwv = Kp_wv;` etc.) — Simulink reads these
- Output `fprintf` calls — the user reads them to copy-paste into `regbot_mg.m`

**Trim:**
- Header (lines 1-23) → 5-6 lines: file purpose, plant, specs, pointer to walkthrough §2
- Per-step prose comments → 1-2 lines each
- Step 1: keep plant-summary numbers but drop the multi-line "Three numbers..." comment
- Step 2: drop the wc/gamma_M/Ni rationale paragraphs (they're in the walkthrough). Keep the assignments.
- Step 3: drop the "Below the zero the PI behaves like..." paragraph; keep the corrected `arctan(Ni) - 90` comment.
- Step 4: keep the algorithm, drop the "findall returns axes most-recent-first" plumbing commentary
- Step 5: drop "Kp is a flat (frequency-independent) gain..." prose; one-line "Solve from |L(jwc)| = 1"
- Step 6: keep margin() output

**Remove (figure-generation blocks no longer needed):**
- Lines 55-58 (fig 190, plant Bode diagnostic)
- Lines 91-100 (fig 191, PI overlay diagnostic)
- Lines 122-136 (fig 192, phase-balance check diagnostic)

After removing the three diagnostic figure blocks, the script drops to
maybe 110 lines and produces only the two figures the report uses.

### `design_task2_balance.m` (321 → target ~180 lines)

The longest. Follow the same template as Task 1, plus careful handling
of Method 2 specifics.

**Keep:**
- Step 0 plant-ID logic: linearise `vel_ref → tilt` with Task 1 closed.
- Step 1 sign-of-K_PS logic (`sign_K = -1` for DC>0, P=1 plants).
- Step 2 post-integrator placement at the magnitude peak (`tau_ip = 1/w_peak`).
- Step 3 outer PI-Lead recipe.
- Step 4 verification.
- Final plots: fig 300 (`regbot_task2_bode_post.png`), fig 301 (`regbot_task2_nyquist_post.png`), fig 302 (`regbot_task2_loop_bode.png`), fig 303 (`regbot_task2_step.png`)
- The custom Nyquist hand-drawing for fig 301 — yes, keep, even though it's long. The default `nyquistplot` autoscales and hides the (−1, 0) point.
- Base-workspace write at end (`Kptilt`, `titilt`, `tdtilt`, `tipost`)
- The explicit firmware sign-flip warning `fprintf('(firmware [cbal] kp must be entered as -%.4f)\n', Kptilt);`

**Trim:**
- Header (lines 1-24) → 5-6 lines
- Multi-line pedagogical comments → 1-2 lines each
- The "linio + setlinio + linearize" plumbing commentary is fine — keep brief
- Step 1: drop the multi-line "Nyquist criterion: Z = N + P. For Gtilt we have P = 1, want Z = 0..." explanation. One line: "% P = 1 plant: need sign(K_PS) = -1 (Lec 10 Method 2)."
- Step 2: drop the prose about "magnitude reshape" — one line: "% Place PI zero at |Gtilt| peak; combined plant has monotonically decreasing magnitude."

**Remove (figure blocks not used in report):**
- Fig 100 (Gwv bode), fig 101 (Gtilt bode) — plant-ID Bode plots
- Figs 102-105 (pole-zero maps, both zoomed and not) — diagnostics
- Fig 106 (basic plant Nyquist) — diagnostic
- Fig 305 (phase-balance check, lines 256-267 area) — diagnostic
- Fig 304 (IC response simulation, lines 290-308 area) — useful for understanding but not in report. **Note: removing this also removes the linear-IC settling-time print (`settle_t`) and peak-undershoot print (`peak_us`)** — those values appear in the report as `1.34 s` settling and `~6.6° undershoot`. The values are committed in `regbot_mg.m`'s comment and the report. **Decision:** remove the IC simulation block but **keep the numbers as comments** in the verify-step output so the report's claim stays traceable.

The pre-figure-101 chunk that linearises `Gwv` (lines 50-59) is
**unused for the final design** — `Gwv` is only used to plot
fig 100. Once you remove fig 100, the `Gwv` linearisation is dead code.
Remove the `io_wv` / `Gwv` block entirely.

### `design_task3_velocity.m` (202 → target ~120 lines)

Same template as Task 1.

**Keep:**
- Plant linearisation (`io(1) = linio([model VEL_CTRL_OUT_BLOCK]...)`)
- Specs, PI zero placement, phase-balance read, Kp solve, verify
- The phase-wrap fix at line 132 (`phi_L_phys = mod(phi_G_unwrapped + 180, 360) - 180`) — **keep with a one-line comment** explaining why (high-order plant; MATLAB unwrap can add +360)
- Final plots: fig 400 (`regbot_task3_loop_bode.png`), fig 401 (`regbot_task3_step.png`)
- Base-workspace write (`Kpvel`, `tivel`)

**Trim:**
- Header
- Per-step pedagogical prose

**Remove:**
- Fig 402 (plant pz map) — diagnostic
- Fig 403 (phase-balance check) — diagnostic

### `design_task4_position.m` (226 → target ~130 lines)

Same template as Task 1, plus the Lead-drop decision tree.

**Keep:**
- Plant linearisation
- Specs (`wc_pos = 0.6` — note this is iterated against mission, not derived)
- Phase-balance computation
- The Lead-decision logic (lines 151-178 area): if `phi_Lead <= LEAD_DROP_THRESHOLD_DEG`, drop; else proper Lead with `ALPHA = 0.1`
- Verify with both design and firmware controllers
- Mission-spec checks (peak v, settling)
- Final plots: fig 500 (`regbot_task4_loop_bode.png`)
- Base-workspace write (`Kppos`, `tdpos`)

**Decision on `regbot_task4_step.png` (fig 501):** the report uses
`regbot_task4_sim_step_v3.png` from the full Simulink simulation, NOT
the design-script step. So `task4_step.png` is unused in the report.
Either remove fig 501 or keep — it's a quick `step(T_pos_firmware,
20)` plot that doesn't cost much. **Recommend: remove.** Keep only
fig 500.

**Remove:**
- Fig 502 (plant pz map) — diagnostic
- Fig 503 (phase-balance check) — diagnostic
- Fig 501 (closed-loop step from design script) — superseded by Simulink full-cascade step

**Note on the design vs firmware controller distinction:** the script
computes both `L_pos_design` (with ideal Lead) and `L_pos_firmware`
(with the Step-4-selected Lead, dropped if small). This is good
engineering and worth keeping — it documents the PM tradeoff.

---

## Workflow

1. **Read this handoff in full** before touching code.
2. **Read `docs/MATLAB Walkthrough.md`** §1–§5 to understand what the
   scripts do at a high level. The walkthrough is the home for
   pedagogy; the scripts can be lean *because* it exists.
3. **Run all four design scripts on the current code first** (in MATLAB)
   to confirm baseline: they should print the v3 gains and save plots
   to `docs/images/`. If MATLAB is unavailable in your session, ask
   the user to do this verification step manually before you start.
4. **Clean `lib/` first** (low risk). Skip if all four are already clean.
5. **Clean `regbot_mg.m`** (numerical content unchanged, comments trimmed).
6. **Clean `design_task1_wheel.m`** (the template — get it right).
7. **Clean `design_task2_balance.m`** (the longest, with Method 2 specifics).
8. **Clean `design_task3_velocity.m`** and **`design_task4_position.m`**.
9. **Have the user re-run each cleaned script** in MATLAB to verify:
   - No errors.
   - Final printed gains match the committed values in `regbot_mg.m`.
   - The expected report-deliverable PNGs are still generated (don't
     verify by image-diff — just confirm they exist with sensible mtimes).
10. **Commit selectively** — files you actually changed only. No
    `git add -A`.

---

## Verification checklist

After cleanup, each design script should:

- [ ] Run end-to-end on a clean MATLAB session.
- [ ] Print final gains matching `regbot_mg.m`'s committed values.
- [ ] Produce the report-deliverable PNGs (table above).
- [ ] Be readable in under 30 seconds of skim (target ~130-180 lines
      per design script, ~70 for `regbot_mg.m`).

If a script breaks during cleanup: the most likely cause is variable
removal — e.g. removing the `Gwv` linearisation block in task 2 but
forgetting that some later print/plot still references `Gwv`.
`grep "Gwv"` in the file after each edit.

---

## Commit guidance

Stage selectively, by filename. No `git add -A`. Suggested commit
breakdown:

1. `lib/` trims (single commit if any changes)
2. `regbot_mg.m` trim
3. `design_task1_wheel.m` clean
4. `design_task2_balance.m` clean
5. `design_task3_velocity.m` + `design_task4_position.m` clean
6. Final verification commit if anything else needs tweaking

Commit messages: terse, focused on the *what* (e.g. "Trim Task 1 design
script for submission: remove diagnostic figures and pedagogical prose").
**No "Co-Authored-By" lines. No "Generated with Claude" lines.**

When done, push:
```
cd C:\Users\Mads2\DTU\4. Semester\Linear Control Design\REGBOT-Balance-Assignment
git push origin main
```

Don't bump the DTU parent submodule pointer unless the user asks.

---

## Open questions for the user (optional)

If unclear after reading, ask the user before guessing:

- Should the diagnostic plots (plant Bode, pz-maps, phase-balance
  visualizations) be **deleted from `docs/images/`** as well, or only
  removed from the scripts? The handoff says scripts only — confirm if
  unsure.
- Should `regbot_task4_step.png` be regenerated (and kept) for
  internal completeness, even though the report uses
  `regbot_task4_sim_step_v3.png`?
- Are there any *additional* scripts (e.g. `tes.m` from past sessions)
  hidden in `simulink/` that should be removed? Run `ls simulink/` to
  catch strays.

---

## Pointers to read

- `docs/HANDOFF.md` — the master handoff with project state and rules.
- `docs/MATLAB Walkthrough.md` — pedagogy lives here; reference it
  from cleaned scripts.
- `Report/main.tex` (and `Report/sections/*.tex`) — see which figures
  the report actually depends on.
- `simulink/regbot_mg.m` — the gold-standard for what numerical values
  must be preserved.

---

*Written 2026-05-13 after the report rewrite + appendix push. The
scripts grew comments organically across multiple design phases; the
walkthrough doc absorbed the pedagogy and the scripts can now be lean.
The graders read this code — make it tell the design story cleanly,
not with the full reasoning chain.*
