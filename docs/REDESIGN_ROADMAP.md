# `day5-redesign` Roadmap

Cascade redesign against the Day 5 **on-floor v2** training-wheels plant `Gvel = 2.198/(s+5.985)` (DC 0.367, τ = 167 ms), replacing the Day 4 **wheels-up** approximation `Gvel = 13.34/(s+35.71)` that was used for the original design.

Branch is scoped to the two submodules (`REGBOT-Balance-Assignment` + `Report`). DTU main is not branched; submodule pointers bump only after merge.

Detailed plan: see Claude's plan file (local to the working machine).

---

## Phases

- [x] **Phase 0** — Branch `day5-redesign` on REGBOT-Balance and Report; this roadmap file in place.
- [x] **Phase 1** — Task 1 redesign
    - [x] 1.B  `design_task1_wheel.m` loads `G_1p_avg` from `data/Day5_results_v2.mat`
    - [x] 1.C  Ran script → **Kp = 13.2037**, τ_i = 0.1000, achieved wc = 30.00, PM = 82.85°, GM = Inf
    - [x] 1.D  Paste new gains into `regbot_mg.m`
    - [x] 1.E  Commit
- [x] **Phase 2** — Task 2 redesign
    - [x] Re-linearised Gtilt with the new inner loop in place
    - [x] **Kptilt = 1.1999, titilt = 0.2000, tdtilt = 0.0442, tipost = 0.1245** (achieved wc = 15.00, PM = 60.00°, GM = −5.58 dB, 0 RHP closed-loop poles)
    - [x] τ_d dropped 67% vs old design (0.1355 → 0.0442) — less Lead needed because the inner loop is properly fast now
- [ ] **Phase 3** — Task 3 redesign (re-linearise Gvel,outer)
- [ ] **Phase 4** — Task 4 redesign (re-linearise Gpos,outer)
- [ ] **Phase 5** — Push gains into `config/regbot_group47.ini`, verify in Simulink (startAngle=10, topos=2)
- [ ] **Phase 6** — Hardware validation (Tests 0, 3a, 3b, 4 with `v3_onfloor` suffix)
- [ ] **Phase 7** — Documentation sweep (`docs/*.md` + Report LaTeX)
- [ ] **Phase 8** — Merge `day5-redesign` → `main` on both submodules (`--no-ff`), then bump DTU main pointers

---

## Log entries (fill as phases complete)

| Date | Phase | Note |
|---|---|---|
| 2026-04-22 | 0 | Branch created on both submodules; roadmap in place. |
| 2026-04-22 | 1 | Task 1 PI redesigned against Gvel = 2.198/(s+5.985). New Kp = 13.2037, tau_i = 0.1000. Achieved wc = 30.00 rad/s, PM = 82.85°, GM = ∞. |
| 2026-04-22 | 2 | Task 2 re-linearised. Gtilt magnitude peak moved 5.95 → 8.03 rad/s. New tipost = 0.1245, titilt = 0.2000, tdtilt = 0.0442 (**−67%**), Kptilt = 1.1999. PM = 60.00°, settling 1.34 s vs 1.55 before. |
