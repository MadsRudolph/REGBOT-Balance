---
course: "34722"
course-name: "Linear Control Design 1"
type: handoff
tags: [LCD, regbot, handoff, learning]
date: 2026-04-29
---
# REGBOT Balance Assignment — Handoff

> [!abstract] Where the user is
> The cascade is fully designed, simulated, and validated on the physical robot (v3 Day 5 on-floor gains, all four hardware tests passed 2026-04-22). What the user is doing **now** is going through the MATLAB design scripts and the Simulink model **to actually understand what's happening**, not to redesign anything. They didn't author the original scripts and have been iterating on style + pedagogy as they read through. The next session continues that walkthrough.

> [!warning] Hard rules carried over
> 1. **No AI / Claude attribution in commits** — global rule, project-wide.
> 2. **Do not alter the canonical numerical content** of the four loops — the v3 gains in `simulink/regbot_mg.m` and `config/regbot_group47.ini` are correct and validated on hardware. Don't "improve" them.
> 3. **Do not regenerate plots in `docs/images/`** unless the user explicitly asks. The PNGs were regenerated this session to match the new script style, and committed. Future-you re-running scripts will overwrite them — that's fine if the user asked, surprising otherwise.
> 4. **Hardware test results in `docs/Test Plan.md` are experimental facts.** Don't touch.
> 5. **The Report submodule (`Report/`) is a real git submodule** at the latest v3 commit (`799e873`). It's also a *symlink* into `Obsidian/Courses/.../regbot/Report` — that's a known quirk, don't try to absorb it. (The previous session's HANDOFF described this in detail; the symlink layout is intentional for now.)
> 6. **Don't add `=====` decorative banners back to the design scripts.** The user explicitly stripped them this session.

---

## What this session did

Three rounds of iteration on the four `simulink/design_task*.m` scripts:

### Round 1 — Inline math helpers, replace plot helpers with built-ins

Removed five helpers from `simulink/lib/` (no longer used anywhere):
- `identify_tf.m` — wrapped `linio` + `linearize` + `ss2tf`. Now inlined at every call site so the linearization step is visible.
- `describe_plant.m` — printed poles/zeros/DC gain/RHP-pole count. Now inlined.
- `plot_pz_stability.m` — custom shaded LHP/RHP pole-zero map. Replaced with `zplane(zero(G), pole(G))` from the Signal Processing Toolbox (user's choice over `pzmap`).
- `plot_nyquist_critical.m` — custom Nyquist with (-1, 0) marker. Replaced with manual data extraction from `nyquist()` + a `plot(-1,0,'r+')` overlay. **See Round 3 below for the final shape — the simple `nyquist(G)` call wasn't enough.**
- `ternary.m` — one-liner conditional. Inlined as `if/else`.

**Helpers kept** (these are *plumbing*, not math, per the user's distinction): `pick_image_dir.m`, `save_plot.m`, `print_tf.m`, `poly_to_str.m`. They live in `simulink/lib/` and are added to the path by `simulink/regbot_mg.m`.

> [!important] User's mental model for "math vs plumbing"
> The user wants to **see the control-design math top-to-bottom** in each script (linearization, phase-balance, magnitude condition, post-integrator placement, etc.). They're fine with helpers for boilerplate (file paths, figure saving, transfer-function display formatting). Don't reintroduce helpers that hide a control-theory step.

### Round 2 — Trim verbose fprintf to minimal

The user pointed at a typical Step-N block (`fprintf('====...\n'); fprintf('  STEP 4 — VERIFY\n'); ...`) and called out everything that "makes it pretty in the terminal" as overkill. Stripped from all four scripts:

- `=====` decoration lines
- `STEP N — TITLE` banners (the `%%` MATLAB cell headers in the editor still mark sections — those stay)
- Inline pedagogical parentheticals like `(course default)`, `(target X)`, `(negative is OK on P=1 plants...)`
- Alignment padding (multi-space columns)
- "Copy-paste this block into regbot_mg.m" headers — the bare gain assignments are still printed, just without the wrapper

Result: each script now prints just the **values with minimal labels**, plus `print_tf` output where relevant. About 50 % shorter terminal output.

### Round 3 — Fix T2 Nyquist plots

The user noticed both Nyquist plots in T2 looked wrong:
- **`Gtilt`** Nyquist: the default `nyquist(G)` overlays an M-circle / dB-grid that clutters the plot.
- **`Gtilt_post`** Nyquist: badly broken because `Gtilt_post` has a free integrator (from `C_PI_post`'s `1/s`). The curve heads to ±∞ at low ω, and MATLAB's auto-axis blew up to ±40 imaginary, collapsing the entire curve into a horizontal smear with no visible (-1, 0) neighbourhood.

Fix: extract `[re, im] = nyquist(G)` and plot manually. Specifically:
- Solid blue line for the ω > 0 branch, dashed blue for the mirror (ω < 0)
- Red `+` marker at `(-1, 0)`
- **Three direction arrows** at 20 / 50 / 80 % along the ω > 0 branch (`quiver` with `MaxHeadSize=5`) so encirclement direction is unambiguous
- `axis equal; grid on`
- For `Gtilt_post`: sample only `logspace(-1, 4, 2000)` (skip ω < 0.1 rad/s), then explicitly `xlim([-3 1]); ylim([-3 3])` to focus on the critical-point neighbourhood

This shape lives in two places in `simulink/design_task2_balance.m` (figures 106 and 301). It's the right pattern if a similar Nyquist plot ever needs to appear in T3/T4 (currently they don't).

### Things the user understood this session, conversationally

These came up while reading the code together — keeping a record so the next session doesn't re-explain unless asked:

- **The two PI blocks in `Tilt_Controller`** are both `(τs+1)/(τs)` — the left one is the post-integrator (`tipost = 0.1245`, zero at the magnitude peak ω_peak = 8.03 rad/s, reshapes Gtilt for stabilizability), the right one is the standard outer PI (`titilt = 0.2`, zero at ω_c/N_i = 5 rad/s, drives e_ss to 0). Method 2's two-stage strategy: stabilize first, then standard design.
- **The gyro-shortcut Lead** (`tdtilt · gyro + θ` summed before the comparator) is mathematically `(τs+1)·θ`, i.e. the *ideal* Lead with no α-pole. The α-pole exists in the proper Lead `(τs+1)/(ατs+1)` to filter numerical-differentiation noise. Since the gyro is a *physical* derivative sensor, that filter is unnecessary — slide showed the algebraic derivation (`1/(ατs+1) · (τ·sθ + θ) → τ·gyro + θ`).
- **Why Method 2 needs the sign flip + post-integrator before the standard PI**: with `P = 1` RHP poles, Nyquist needs `N = -1` (one CCW encirclement of (-1, 0)). Positive Kp can't deliver that when DC gain > 0; flipping sign + reshaping the magnitude peak does.

---

## Repo state right now

| Repo | Branch | Tip | Origin |
|---|---|---|---|
| `REGBOT-Balance-Assignment` | `main` | `bf9408c` Trim fprintf, fix T2 Nyquist | up to date |
| `Report` (submodule) | `main` | `799e873` Trim report to 5 pages | up to date (parent records this SHA) |
| `DTU` parent (regbot is itself a submodule of DTU) | `main` | not bumped this session | parent's submodule pointer for regbot is *behind* by `bf9408c` and `032ac38` — not relevant unless the user wants to bump |

> [!info] DTU submodule pointer
> The user hasn't asked to bump the DTU `4. Semester/Linear Control Design/REGBOT-Balance-Assignment` submodule pointer. Don't do it unless they ask. This session pushed two new commits to `Skab101/REGBOT-Balance` `main`; if the user wants the DTU vault to point at the new tip, that's a separate `git add` + commit + push from the DTU root.

### Uncommitted state on disk

- `docs/REGBOT Balance Assignment.md` — pure CRLF line-ending churn from Windows tooling. **No semantic change.** Skipped from this session's commit by design. If git keeps showing it as modified, that's a `core.autocrlf` configuration thing, not real work.

That's the only thing not committed.

---

## What the next session probably looks like

The user explicitly said: *"i want to keep on going through the matlab scripts and simulink model in order to understand what exactly is going on"*.

So this is **a learning walkthrough, not an implementation task**. The next instance should:

### 1. Pick up wherever the user left off

Likely candidates the user might want to dig into next:
- The **Simulink model** (`simulink/regbot_1mg.slx`) — they've seen the `Tilt_Controller` subsystem in detail today. Other subsystems they might want to walk: the wheel-velocity controller (with its parallel-form PI), the Velocity PI, the position P loop, the `robot with balance` Simscape Multibody plant, the disturbance injection block.
- The **design scripts** — T1 and T4 still haven't been walked through line-by-line in conversation as much as T2. T3 has been touched but lightly.
- The **firmware ini** (`config/regbot_group47.ini`) — useful when discussing how a controller block in MATLAB maps to the firmware-side dialog parameters.
- The **plant-identification** step itself — Day 5 black-box fitting, what `tfest` does, why a 1-pole fit was chosen, etc. (This data lives in `data/Day5_results_v2.mat`.)

### 2. Match the established style

When asked to edit code, the conventions established this session are:
- Math is inlined (no helpers hiding control-theory steps)
- Plumbing helpers are fine (`save_plot`, `print_tf`, `pick_image_dir`, `poly_to_str`)
- Terminal output is minimal — no decorative headers, no pedagogical parentheticals, no alignment padding
- For Nyquist plots: extract data manually, axis equal, focus axis on (-1, 0), draw direction arrows
- For pole-zero maps: `zplane(zero(G), pole(G))`
- For Bode plots: `bode(G, {0.1, 1000})` is fine
- The user's working language is English (commit messages, docs, comments)

### 3. Match the explanation style they like

Looking at how this session's conversation went, the user responds well to:
- **Concrete + grounded**: explain what a block *is* algebraically, what it *does* dynamically, *why* it's there (in terms of Method 2 / phase balance / Nyquist / cascade rules)
- **Tables and short bulleted lists** over prose paragraphs
- **Cross-references to the design scripts** by file path + line number when applicable
- Brief mathematical derivations inline in `$$...$$` when they clarify
- Avoid rebuilding the entire course from scratch in every answer — assume they remember what we covered earlier in the day (or reference the lecture notes)

### 4. Useful context the user has at hand

- Lecture notes in their DTU vault (Obsidian) at `C:\Users\Mads2\DTU\Obsidian\Courses\34722 Linear Control Design 1\Lecture Notes\` — they have lesson notes for Lessons 1-12, plus Fundamentals + Diagnostic Guide + Worked Example for the position controller.
- The slides PDFs live at `Slides/Lecture_*.pdf` in the same Obsidian folder. The user often shares screenshots from these — they're reading the slide deck alongside the code.
- The user is `Mads Rudolph (s246132)`, one of four group members.
- Today's date when this handoff was written: 2026-04-29.

---

## Quick orientation map

```
REGBOT-Balance-Assignment/
├── README.md                  -- run order, prerequisites, structure overview
├── config/regbot_group47.ini  -- v3 firmware gains (load via REGBOT GUI)
├── data/Day5_results_v2.mat   -- on-floor plant identification (G_1p_avg)
├── docs/
│   ├── REGBOT Balance Assignment.md  -- main pedagogical writeup of all 4 tasks
│   ├── Test Plan.md                  -- hardware test results (do not modify)
│   ├── PLAN.md                       -- early phase plan
│   ├── REDESIGN_ROADMAP.md           -- Day 5 redesign phase tracker (all done except merge)
│   ├── HANDOFF.md                    -- this file
│   └── images/                       -- 47 PNGs, single source for Obsidian + LaTeX
├── logs/test*_v3_onfloor_*.txt       -- raw REGBOT logs, 2026-04-22 hardware run
├── simulink/
│   ├── regbot_1mg.slx                -- the Simulink model (cascade + Simscape plant)
│   ├── regbot_mg.m                   -- workspace loader (params + committed gains)
│   ├── design_task1_wheel.m          -- Day 5 plant from MAT, PI design
│   ├── design_task2_balance.m        -- linearise vel_ref→tilt, Method 2
│   ├── design_task3_velocity.m       -- linearise theta_ref→v, PI
│   ├── design_task4_position.m       -- linearise pos_ref→x, P
│   └── lib/                          -- plumbing helpers only:
│       ├── pick_image_dir.m          -- always returns docs/images/
│       ├── save_plot.m               -- figure(N); plot; title; saveas
│       ├── print_tf.m                -- pretty-print a TF (no built-in display)
│       └── poly_to_str.m             -- helper for print_tf
└── Report/                           -- LaTeX submodule (real git submodule + symlink quirk)
```

### Canonical gains (do not change)

| Task | Loop | Type | ω_c | γ_M | Parameters |
|---|---|---|---|---|---|
| 1 | Wheel speed | PI | 30 rad/s | 82.85° | `Kpwv = 13.2037`, `tiwv = 0.1` |
| 2 | Balance | PILead + post-PI | 15 rad/s | 60° | `Kptilt = 1.1999` (firmware: **−1.1999**), `titilt = 0.2`, `tdtilt = 0.0442`, `tipost = 0.1245` |
| 3 | Velocity | PI | 1 rad/s | 68.98° | `Kpvel = 0.1581`, `tivel = 3.0` |
| 4 | Position | P (Lead dropped) | 0.6 rad/s | ~57° | `Kppos = 0.5411`, `tdpos = 0` |

### Two facts that bite if forgotten

1. **Firmware sign flip on `[cbal] kp`** — the firmware Balance block does not absorb Method 2's `−1`. The ini must enter `kp = -1.1999` (negative). Positive runs the wheels into a positive-feedback runaway.
2. **Day 5 redesign is canonical** — the original design used the Day 4 wheels-up plant `13.34/(s+35.71)`. That plant was 6× faster than the on-floor reality, so Test 0 measured a 4× slower effective inner loop. Re-fit on-floor `2.198/(s+5.985)`, all four loops retuned, hardware re-validated. **All numbers in the repo are v3.** Don't be confused by the v1-day4-wheels-up backup branch on origin.

---

## Commit workflow when work needs committing

Standard:
1. `git status --ignore-submodules=all --short` to see what changed
2. Stage selectively — *do not* `git add -A` because the user often has CRLF-churn `.md` files or stray `.slx` save artefacts they don't want bundled in
3. Commit with a clear title + body. **No `Co-Authored-By` lines, no "Generated with Claude" lines, no AI attribution.** Just write it as if the developer wrote it.
4. Push to `origin/main`
5. Don't bump the DTU parent submodule pointer unless asked

For the Report submodule: it lives at `Report/` as both a git submodule *and* a symlink into the Obsidian vault. Don't try `git submodule absorbgitdirs` — the symlink confuses git's relative-path resolution and the previous session got into a mess unwinding a half-completed absorb. The submodule wiring is functional; leave it.

---

*Written 2026-04-29. The next session picks up from "the user wants to walk through the MATLAB and Simulink to understand the cascade in detail" — be a patient guide, match the established style, and ask before making changes that affect the canonical numerical content.*
