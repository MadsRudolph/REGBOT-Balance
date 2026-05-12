---
course: "34722"
course-name: "Linear Control Design 1"
type: walkthrough
tags: [LCD, regbot, walkthrough, learning]
date: 2026-05-12
---

# REGBOT MATLAB & Simulink Walkthrough

> [!abstract] Purpose
> A companion document built up as we read through the MATLAB design scripts
> and the Simulink model. Not a redesign — the v3 numerical content in the
> repo is the validated truth (hardware-tested 2026-04-22). This document
> explains **what the code does and why**, with slide references and
> NotebookLM-verified citations attached to every concrete claim.
> Verification is automated: Claude consults the `lcd1` NotebookLM notebook
> (loaded with all 12 lecture slides + MATLAB exercises, 40 sources) via the
> `nlm.bat` CLI when filling in this document, and embeds the cited finding
> inline. You read the verified statement; the verification step itself
> happens during the walkthrough conversation.

---

## How to use this document

### Reading flow

Sections are filled in **as we walk through each script in conversation**. An
empty section header just means we haven't gotten there yet.

Within a script section, each step contains:

1. **Code block** — the actual MATLAB excerpt for that step, with the line
   range in the heading so you can jump straight into the script.
2. **Prose explanation** — what the code does, what the math says, why this
   step exists at this point in the recipe.
3. **Claim → cited verification pairs** — every concrete assertion about
   control theory is followed by a `> [!cite]` callout containing the
   NotebookLM-grounded quote + slide/page reference.
4. **Slide refs** — links to the specific slide pages backing the step.

### How verification works

Claims in this document are grounded in the user's actual course material,
not Claude's general training data. The mechanism:

- The `lcd1` NotebookLM notebook is pre-loaded with the 12 lecture PDFs and
  the MATLAB exercise material (40 sources total). It lives at notebook ID
  `dcddcf87-0a72-40eb-afae-7dab260350e8` (alias `lcd1`).
- While filling in this document, Claude runs:
  ```
  C:\Users\Mads2\.claude\skills\notebooklm\scripts\nlm.bat ask "<question>" --notebook-id lcd1
  ```
  for each concrete claim. The returned answer is grounded in the slides
  and exercises, with NotebookLM's own citations to source documents.
- Claude copies the cited finding into a `> [!cite]` callout next to the
  claim, including the slide/page reference NotebookLM gave back.

Three possible outcomes per claim, marked accordingly in the callout:

- ✅ **Confirmed** — sources back the claim. Quote + slide ref shown.
- ✏️ **Corrected** — sources contradict the claim. The corrected version is
  what appears in this document; the original wrong version is noted in
  the callout so the reasoning is traceable.
- ❔ **Not in sources** — claim is general control-theory knowledge not
  specifically covered in `lcd1`. Marked as such; user should treat it as
  Claude's reasoning, not as sourced fact.

If you want to re-verify a claim yourself, copy the claim text and run
the same `nlm.bat ask` command — the question that produced the citation
is reconstructable from the claim, so the doc doesn't preserve the prompt
separately.

### Slide link format

Links use Obsidian's URI scheme (`obsidian://open?vault=Obsidian&file=...`)
so they resolve from anywhere on disk — this document doesn't have to live
inside the vault. Clicking launches Obsidian and opens the target file.
Path components are URL-encoded (`/` → `%2F`, space → `%20`, `&` → `%26`).
Example:

```markdown
[Lec 8 · slide 12 — PI zero placement](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2FLecture_08_PI_LEAD_design.pdf)
```

The `obsidian://` URI doesn't carry a page anchor, so the slide number lives
in the link text — Obsidian opens the PDF, you scroll to the cited slide.

### Template for a step (copy this when filling in)

````markdown
### X.Y Step N — Title   *(lines aa–bb)*

```matlab
% code excerpt
```

Prose explanation of what this step does and why.

**Claim:** A concrete statement about the math/control theory.

> [!cite] ✅ Verified — Lecture N · slide M
> > Direct quote from the slide/exercise as returned by NotebookLM.
>
> *Source: `lcd1` notebook, `<filename>.pdf` slide M (cited by NotebookLM).*

**Slide refs**
- [Lec N · slide M — topic](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2F<filename>.pdf)
````

Variants of the `[!cite]` callout for the other two outcomes:

````markdown
> [!cite] ✏️ Corrected — Lecture N · slide M
> **Original wrong claim:** "<the claim before NotebookLM corrected it>"
> **What the sources actually say:**
> > Direct quote.
>
> *Source: `lcd1` notebook, `<filename>.pdf` slide M.*

> [!cite] ❔ Not in `lcd1` sources
> Claim could not be located in the loaded slides or exercises. Treat as
> Claude's general control-theory reasoning, not as sourced fact.
````

---

## Source map

### MATLAB scripts (in this repo)

| Script | Role |
|---|---|
| `simulink/regbot_mg.m` | Workspace loader — physical params, committed gains, addpath |
| `simulink/design_task1_wheel.m` | Wheel-speed PI design |
| `simulink/design_task2_balance.m` | Method 2 PILead + post-PI (the tilt controller) |
| `simulink/design_task3_velocity.m` | Velocity PI design |
| `simulink/design_task4_position.m` | Position P design |
| `simulink/regbot_1mg.slx` | Simulink model (cascade + Simscape plant) |
| `simulink/lib/pick_image_dir.m` | Helper — returns `docs/images/` |
| `simulink/lib/save_plot.m` | Helper — figure → title → saveas |
| `simulink/lib/print_tf.m` | Helper — pretty-print a transfer function |
| `simulink/lib/poly_to_str.m` | Helper — used by `print_tf` |

### Lecture slides (in Obsidian vault)

| # | Title |
|---|---|
| 1 | [Welcome](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2F1_Welcome_Lecture.pdf) |
| 2 | [Block diagrams & control concepts](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2F2_block_control_concept.pdf) |
| 3 | [Laplace & transfer functions](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2F3_Laplace_TF.pdf) |
| 4 | [Frequency & time analysis](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2F4_Frequency_and_Time_Analysis_NoSol.pdf) |
| 5 | [Modelling](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2F5_Modelling.pdf) |
| 6 | [Bode plot & stability](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2F6_Bode_plot%26Stability.pdf) |
| 7 | [Nyquist plot & stability](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2FLecture_07_Nyquist%20plot%20and%20stability.pdf) |
| 8 | [PI-Lead design](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2FLecture_08_PI_LEAD_design.pdf) |
| 9 | [PI-Lead design with specifications](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2FLecture_09_PI_LEAD_design_specifications.pdf) |
| 10 | [Unstable systems](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2FLecture_10_Unstable_systems.pdf) |
| 11 | [Limited systems](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2FLecture_11_Limited_systems.pdf) |
| 12 | [Disturbances, sensitivity, prefilters](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2FLecture_12_Disturbances_sensitivity_prefilters.pdf) |

### Lesson notes (in Obsidian vault)

Located at `Obsidian/Courses/34722 Linear Control Design 1/Lecture Notes/`. Markdown
notes are linked without the `.md` extension (Obsidian convention).

- [Fundamentals – Intuitive Control Theory](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FLecture%20Notes%2FFundamentals%20-%20Intuitive%20Control%20Theory)
- [Diagnostic Guide – What Went Wrong](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FLecture%20Notes%2FDiagnostic%20Guide%20-%20What%20Went%20Wrong)
- [Lesson 2 – Block Diagrams and Control Concepts](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FLecture%20Notes%2FLesson%202%20-%20Block%20Diagrams%20and%20Control%20Concepts)
- [Lesson 3 – Laplace Transform and Transfer Functions](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FLecture%20Notes%2FLesson%203%20-%20Laplace%20Transform%20and%20Transfer%20Functions)
- [Lesson 4 – Frequency Domain and Time Analysis](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FLecture%20Notes%2FLesson%204%20-%20Frequency%20Domain%20and%20Time%20Analysis)
- [Lesson 8 – Position Controller Design](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FLecture%20Notes%2FLesson%208%20-%20Position%20Controller%20Design)
- [Lesson 9 – PI-Lead Design with Specifications](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FLecture%20Notes%2FLesson%209%20-%20PI-Lead%20Design%20with%20Specifications)
- [Lesson 10 – Unstable Systems and REGBOT Balance](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FLecture%20Notes%2FLesson%2010%20-%20Unstable%20Systems%20and%20REGBOT%20Balance)
- [Worked Example – REGBOT Position Controller](obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FLecture%20Notes%2FWorked%20Example%20-%20REGBOT%20Position%20Controller)

---

## 1. `regbot_mg.m` — workspace loader  *(skim)*

> [!success] Status: walked 2026-05-12 — kept brief on purpose

**File:** `simulink/regbot_mg.m`

Plumbing, not design. The script loads the assignment-given physical
parameters (motor specs, geometry, masses) and the committed v3 gains
into the MATLAB base workspace, and adds `simulink/` + `simulink/lib/`
to the path. Nothing in here is something we *design* — the parameters
are given, and the gains are produced by the four `design_task*.m`
scripts that print copy-pasteable blocks back into this file.

Workflow:

1. Open MATLAB, run `regbot_mg` (or let Simulink's PreLoadFcn do it).
2. Run a design script. It uses the workspace, computes new gains,
   prints them.
3. Paste the new block into the "Committed controller gains" section of
   `regbot_mg.m` and re-run it before designing the next outer loop.

The only two values worth noting before moving on (because they recur in
later sections):

- `Kemf = Km = 0.0105`  — DC motor convention (back-EMF constant equals
  torque constant in SI units; standard result from Lec 2).
- `twvlp = 0.005 s` — first-order low-pass on the wheel-velocity
  feedback. Break frequency 200 rad/s, far above any loop crossover, so
  it adds negligible phase at the bandwidths we care about while
  attenuating encoder quantization noise.

All the gain blocks at lines 66–114 are the meaningful output of
§2–§5 — we unpack each one there.

### Committed controller gains  *(lines 66–114)*

The canonical source of truth for the v3 gains. Reference table for the
whole document — every gain mentioned in later sections traces back to
one of these rows.

| Task | Variable | Value | Loop | Source script |
|---|---|---|---|---|
| 1 | `Kpwv` | 13.2037 | Wheel-speed PI — proportional | `design_task1_wheel.m` |
| 1 | `tiwv` | 0.1000 s | Wheel-speed PI — integral time | `design_task1_wheel.m` |
| 1 | `Kffwv` | 0 | Wheel-speed feed-forward | `design_task1_wheel.m` |
| 2 | `Kptilt` | 1.1999 *(firmware: **−1.1999**)* | Balance — proportional | `design_task2_balance.m` |
| 2 | `titilt` | 0.2000 s | Balance — integral time | `design_task2_balance.m` |
| 2 | `tdtilt` | 0.0442 s | Balance — Lead time constant | `design_task2_balance.m` |
| 2 | `tipost` | 0.1245 s | Balance — post-integrator zero | `design_task2_balance.m` |
| 3 | `Kpvel` | 0.1581 | Velocity PI — proportional | `design_task3_velocity.m` |
| 3 | `tivel` | 3.0000 s | Velocity PI — integral time | `design_task3_velocity.m` |
| 4 | `Kppos` | 0.5411 | Position — proportional | `design_task4_position.m` |
| 4 | `tdpos` | 0 *(Lead dropped)* | Position — Lead time constant | `design_task4_position.m` |

Two things to flag now, expanded later:

- **Task 2 sign flip.** `Kptilt = 1.1999` in MATLAB, but the firmware
  `[cbal] kp` entry in `config/regbot_group47.ini` is `−1.1999`. The
  firmware Balance block does not absorb Method 2's `−1`. Positive `kp`
  on the robot runs the wheels into a positive-feedback runaway. We
  cover the Method 2 sign-flip in §3.
- **Task 4 killed Lead.** `tdpos = 0` because a pure Lead `(τs + 1)` is
  improper and Simulink rejects it; adding `1/(ατs + 1)` would make it
  proper at the cost of a noisy fast pole, not worth ~3° of PM at
  ω_c = 0.6 rad/s. Covered in §5.

---

## 2. `design_task1_wheel.m` — wheel-speed PI

> [!note] Status: not yet walked

**File:** `simulink/design_task1_wheel.m`
**Plant:** `Gvel(s) = 2.198 / (s + 5.985)`  *(Day 5 v2 on-floor 1-pole fit, loaded from `data/Day5_results_v2.mat` as `G_1p_avg`)*
**Specs:** ω_c = 30 rad/s, γ_M ≥ 60°, Ni = 3
**Result:** `Kpwv = 13.2037`, `tiwv = 0.1`

*(Walkthrough goes here.)*

---

## 3. `design_task2_balance.m` — Method 2 PILead + post-PI

> [!note] Status: not yet walked

**File:** `simulink/design_task2_balance.m`
**Plant:** Linearised vel_ref → tilt (one RHP pole, P = 1)
**Specs:** ω_c = 15 rad/s, γ_M ≥ 60°
**Result:** `Kptilt = 1.1999` *(firmware sign-flipped: −1.1999)*, `titilt = 0.2`, `tdtilt = 0.0442`, `tipost = 0.1245`

*(Walkthrough goes here. Topics expected: linearisation of the inverted
pendulum, why Method 2 is needed for P = 1, post-integrator placement at
the magnitude peak, the sign flip, the gyro-shortcut Lead, the two Nyquist
plots.)*

---

## 4. `design_task3_velocity.m` — velocity PI

> [!note] Status: not yet walked

**File:** `simulink/design_task3_velocity.m`
**Plant:** Linearised θ_ref → v
**Specs:** ω_c = 1 rad/s
**Result:** `Kpvel = 0.1581`, `tivel = 3.0`, ω_c achieved = 1 rad/s, γ_M = 68.98°

*(Walkthrough goes here.)*

---

## 5. `design_task4_position.m` — position P

> [!note] Status: not yet walked

**File:** `simulink/design_task4_position.m`
**Plant:** Linearised pos_ref → x
**Specs:** ω_c = 0.6 rad/s
**Result:** `Kppos = 0.5411`, `tdpos = 0` *(Lead dropped after natural-PM check)*

*(Walkthrough goes here. Topics expected: cascade rule of 5–10×, why P is
enough on a pre-stabilised cascade, the "natural PM" check that dropped
the Lead.)*

---

## 6. `simulink/regbot_1mg.slx` — the cascade in Simulink

> [!note] Status: not yet walked

**File:** `simulink/regbot_1mg.slx`

Subsystems to walk:

- **Wheel velocity controller** — parallel-form PI implementing `Kpwv (1 + 1/(tiwv·s))`
- **Tilt controller** — post-PI → sign-flip → outer PI → gyro-shortcut Lead → summed before comparator
- **Velocity PI** — standard PI on the linearised θ → v plant
- **Position P** — P-only on pos_ref → x
- **`robot with balance`** — Simscape Multibody plant (the physics)
- **Disturbance injection** — where we add load disturbance to test sensitivity

*(Walkthrough goes here.)*

---

## 7. Helpers in `simulink/lib/`

> [!note] Status: not yet walked

Plumbing — kept because they save boilerplate, not because they hide math.

- `pick_image_dir.m` — always returns `docs/images/`
- `save_plot.m` — `figure(N) → bode/plot → title → saveas`
- `print_tf.m` — pretty-print a transfer function in factored form
- `poly_to_str.m` — helper used by `print_tf`

*(Walkthrough goes here. Probably one short section since these are pure
plumbing.)*

---

## Appendix A — Concept ↔ slide ↔ script cross-reference

Grows as we walk through. Empty for now.

| Concept | Slides / Notes | Script(s) | Status |
|---|---|---|---|
| *(filled as we walk §2–§5)* | | | |

---

## Appendix B — Open questions log

Things that came up during the walkthrough that need follow-up. Empty for now.

| Date | Question | Status |
|---|---|---|
| *(filled as we go)* | | |
