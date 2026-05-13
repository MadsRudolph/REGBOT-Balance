---
course: "34722"
course-name: "Linear Control Design 1"
type: cookbook
tags: [LCD, regbot, cookbook, recipe, learning]
date: 2026-05-13
---

# REGBOT Balance — Cookbook

> [!abstract] What this is
> A short, recipe-style guide to **how we tackled this project**. It mirrors
> the LCD1 design recipe from lectures 8–10 and walks through how that
> recipe was applied to each of the four cascade loops.
>
> This is the *non-technical* counterpart to `docs/MATLAB Walkthrough.md`.
> Where the Walkthrough explains *why each line of MATLAB does what it
> does*, this Cookbook explains *what we did, in what order, and why*.
> No derivations, very little math — when a curious reader wants the
> equations, the pointers say "see §X of the Walkthrough".
>
> Audience: a future student or future-self opening the project cold.
> Knows roughly what a PI controller is and what a phase margin is.
> Wants the recipe, not the derivation.

---

## The cascade in one picture

Four nested loops, designed in this order:

```
                                                                ┌──────────┐
   x_ref ──► Position P ──► Velocity PI ──► Balance PILead ──► Wheel-speed PI ──► Robot
   (Task 4)    (Task 3)          (Task 2)         (Task 1)
                                                                              │
                                ◄────────── pitch / gyro / wheel-vel ◄────────┘
```

> [!important] Reading order matters
> Task 1 (innermost) is designed **first** and Task 4 (outermost) **last**.
> Each outer loop is built on top of an already-working inner loop —
> the next section explains why this isn't optional.

A nicer Mermaid version with feedback arrows lives in
[`docs/REGBOT Balance Assignment.md` → "Cascade architecture"][1].

[1]: REGBOT%20Balance%20Assignment.md

---

## The recipe

Every loop in this project follows the same six-step recipe — the LCD1
"Cookbook Recipe" from Lecture 8, in the spec-driven flavour from
Lecture 9 (where ω_c is *given*, not searched for). Each MATLAB design
script is structured as these six steps in order.

> [!cite] ✅ Verified — Lecture 8 + *Fundamentals - Intuitive Control Theory*
> > "The standard PI-Lead design procedure is formally presented as the
> > **Cookbook Recipe** in Lecture 8. […] When ω_c is **given** (or
> > derived from time-domain specs like rise time), the procedure flips:
> > you evaluate the system *at* that specific frequency."
>
> *Source: `lcd1` notebook — `Lecture_08_PI_LEAD_design.pdf`,
> `Lesson 8 - Position Controller Design.md`, and
> `Fundamentals - Intuitive Control Theory.md` (cited by NotebookLM).
> Lecture 9's worked examples confirm the spec-driven order is treated
> as a flavour of the same recipe.*

> [!summary]+ The 6 steps at a glance
> 1. **Identify the plant** — what is `G(s)`?
> 2. **Pick specs** — `ω_c`, `γ_M`, `N_i`.
> 3. **Place the PI zero** at `ω_c / N_i`, i.e. `τ_i = N_i / ω_c`.
> 4. **Phase balance** — does the natural PM hit spec, or do we need a Lead?
> 5. **Solve K_p** from the magnitude condition (open-loop = 1 at `ω_c`).
> 6. **Verify** with `margin()` and a closed-loop step.

### Step 1 — Identify the plant

What is `G(s)`? Either it's already given (Task 1, from a black-box fit)
or you build it by *linearising the Simulink model with the inner loops
already closed* (Tasks 2–4). The point of this step is to read off
poles, zeros, DC gain, RHP poles (any?), RHP zeros (any?). Those four
facts decide everything that follows.

### Step 2 — Pick the specs

Three knobs:

- **ω_c** — how fast the loop should respond. Bounded *above* by physical
  limits (motor saturation, RHP zeros, plant uncertainty) and *below* by
  the cascade rule (the next outer loop needs this one to be fast
  enough that it looks instantaneous).
- **γ_M** — how stable. The course default is 60°, which corresponds to
  ~10 % step overshoot. Higher = more damping but slower response.
- **N_i** — how aggressively the integrator acts. Default is 3, which
  places the PI's zero one decade-third below ω_c. Higher N_i is
  phase-cheap but weakens the integral region; lower N_i hits harder at
  DC but eats phase margin at ω_c.

### Step 3 — Place the PI zero

`τ_i = N_i / ω_c`. That's it. The PI zero now sits at `ω_c / N_i`, one
factor-of-N_i below the crossover. The PI's phase contribution at ω_c
is fixed by this placement — you can compute it from N_i alone, before
you've committed to any gain.

### Step 4 — Phase balance

The decision point. Add up the phase contributions at ω_c — plant phase
plus PI phase — and ask: is there enough margin left for the spec, or
do we need a Lead element to claw some back?

- If the natural margin already meets `γ_M` → no Lead, controller stays
  pure PI.
- If it falls short → add a Lead sized to make up the gap exactly. The
  Lead's `τ_d` falls out of a single `tan` of the deficit.

### Step 5 — Solve K_p

Phase is set. Now scale the gain so the loop crosses 0 dB at exactly
ω_c. K_p is just a flat multiplier on the magnitude — it slides the
whole curve up or down without touching the phase. So picking it is one
arithmetic step: K_p = 1 / (loop magnitude at ω_c, with K_p = 1).

(See §2.5 of `docs/MATLAB Walkthrough.md` for why this is called the
"magnitude condition" and where it comes from.)

### Step 6 — Verify

Build the open-loop `L = K_p · controller · G`, hand it to MATLAB's
`margin()`, read back ω_c / γ_M / GM, and plot a closed-loop step. If
the printed numbers match what Steps 2–5 set, the design is consistent
and the gains are ready to paste into `regbot_mg.m`.

---

## Why we design from the inside out

Cascades are designed *inner-first*: wheel-speed → balance → velocity →
position. Each outer loop is built on top of a working inner loop.

The reason is practical. When you sit down to design Task 3 (the
velocity loop), you need a plant that maps "tilt reference" to "actual
velocity". That plant only exists if Task 2 — the balance controller —
is already in place and stabilising the pendulum. With Task 2 closed,
the linearised plant is well-behaved and the standard PI recipe just
works. Without Task 2 closed, there's no such plant: the open-loop
inverted pendulum is unstable and falls over.

So the order isn't a stylistic choice. The outer-loop design *literally
requires* the inner loop's gains to be active in the workspace before
its own linearisation step runs. (See the script preambles for each
`design_task*.m` — they all start with `regbot_mg`, which loads the
already-committed gains for the inner loops.)

> [!cite] ✅ Verified — *Fundamentals - Intuitive Control Theory*
> > "Always Design Inner Loops First. […] The velocity controller needs
> > the tilt loop to already work, because it assumes 'I ask for tilt
> > θ_ref, I get tilt θ.' Likewise the position controller assumes the
> > velocity loop tracks v_ref. Tune inner → middle → outer."
>
> *Source: `lcd1` notebook — `Fundamentals - Intuitive Control Theory.md`
> (cited by NotebookLM). The lesson notes give the cascade rule
> qualitatively; no specific numerical separation factor (e.g. "≥ 5×")
> is fixed in the LCD1 material — that framing is general control-theory
> practice applied on top of the qualitative requirement.*

The other half of inner-first is the **bandwidth budget**. Each outer
loop has to be slower than the inner loop it sits on, by enough that the
inner loop's transient looks instantaneous from the outside. There's no
hard rule from LCD1, but in practice we used roughly:

| Loop | ω_c | Ratio to next loop in |
|---|---|---|
| Wheel speed (Task 1) | 30 rad/s | — innermost |
| Balance (Task 2) | 15 rad/s | 2× slower than Task 1 |
| Velocity (Task 3) | 1 rad/s | 15× slower than Task 2 |
| Position (Task 4) | 0.6 rad/s | ~1.7× slower than Task 3 |

The Task 2 → Task 3 jump is large because Task 3's bandwidth was
clamped by physics (an RHP zero — see below), not by the cascade rule.

---

## Per-loop variations

Same recipe, four different plants. Each section below is a one-page
"what was different about this loop". Math and derivations live in the
Walkthrough; the canonical gains live in the
[Committed controller gains][2] table at the top of the Walkthrough's §1.

[2]: MATLAB%20Walkthrough.md

### Task 1 — Wheel-speed PI · the clean run-through

> [!tldr]+ Task 1 in one block
> - **Script:** `simulink/design_task1_wheel.m`
> - **Plant:** `2.198 / (s + 5.985)` — first-order, stable, no RHP zeros.
> - **Specs:** ω_c = 30 rad/s, γ_M ≥ 60°, N_i = 3.
> - **Result:** K_p ≈ 13.20, τ_i = 0.1 s. **No Lead** — natural PM beats spec.
> - **What was different:** nothing. This is the textbook recipe.
> - **Walkthrough:** §2 of `docs/MATLAB Walkthrough.md` (full step-by-step).

The textbook example. A first-order plant from a `tfest` fit, no
RHP poles, no RHP zeros, no surprises. The recipe runs end-to-end
with no special cases:

1. Plant is `2.198/(s + 5.985)` — read DC gain, break, time constant.
2. Pick the specs above.
3. PI zero at 10 rad/s.
4. Combined phase at ω_c is ~−97°, giving a *natural* PM of ~83°.
   That's already comfortably above the 60° spec → **no Lead**.
5. K_p falls out as ≈ 13.20.
6. `margin()` confirms ω_c = 30, PM = 82.85°, GM = ∞.

> [!note] Over-margined on purpose
> 83° natural PM vs the 60° spec is a 23° cushion. That slack is
> intentional — the plant is identified from log data (fit uncertainty
> is real), and Task 1 is the foundation the whole cascade sits on, so
> being conservative here is cheap insurance and doesn't cost the outer
> loops anything.

### Task 2 — Balance PILead + post-PI · the hard one

> [!tldr]+ Task 2 in one block
> - **Script:** `simulink/design_task2_balance.m`
> - **Plant:** linearised `vel_ref → tilt`, **unstable** (RHP pole at ~+9.13 rad/s).
> - **Specs:** ω_c = 15 rad/s, γ_M ≥ 60°, N_i = 3.
> - **Result:** K_p = 1.1999 *(firmware: **−1.1999**)*, τ_i = 0.2 s, τ_d = 0.0442 s, τ_i,post = 0.1245 s.
> - **What was different:** the plant is unstable → standard PI-Lead can't stabilise it. We use **Lecture 10 Method 2**: sign-flip + post-integrator first, then a normal PI-Lead on top.
> - **Walkthrough:** §3 (when filled in). **Background:** `docs/REGBOT Balance Assignment.md` → "Task 2".

This loop is qualitatively different because the plant is **unstable**.
The linearised `vel_ref → tilt` transfer function has a pole in the
right half plane (~+9.13 rad/s — the "falling" mode of an inverted
pendulum). A normal PI-Lead can't stabilise it — the math (Nyquist
criterion) says we need a sign flip somewhere.

The recipe gets wrapped in a four-step preamble called **Method 2**
(Lecture 10):

1. **Sign-check.** Nyquist + the plant's positive DC gain force us to
   flip the gain sign. We hide the −1 inside the post-integrator block
   so the rest of the design stays positive-numbered.
2. **Post-integrator at the magnitude peak.** The plant has a resonance
   bump near 8 rad/s. We cancel the bump with a PI-shaped block whose
   zero sits exactly on the peak. Combined with the −1 sign flip, the
   reshaped plant `Gtilt,post = −C_PI,post · Gtilt` is now something a
   normal PI-Lead can stabilise.
3. **Standard PI-Lead on the reshaped plant** — Steps 2–6 of the recipe
   above, applied to `Gtilt,post`. The phase deficit at ω_c is large
   (~33° short of spec) so a **Lead is needed**. We get the Lead "for
   free" from the gyro: the gyro already measures `θ̇`, so adding
   `τ_d · gyro` to `θ` is an *ideal* Lead `(τ_d s + 1)` with no extra
   filter pole.
4. **Verify with `margin()` and the Nyquist plot**, *and* check that
   the closed-loop has zero RHP poles.

> [!note] Negative gain margin is **expected** for unstable plants
> `margin()` will print a *negative* GM (in dB) on the open-loop with
> Method 2 applied. That's correct — for a plant with RHP poles, GM
> measures how much you could *reduce* the gain before stability is
> lost. A positive GM here would actually be the warning sign. The
> sign-flipped post-integrator Nyquist plot should encircle (−1) **once
> counter-clockwise**.

> [!warning] The firmware sign on `[cbal] kp` is **negative**
> MATLAB stores `Kptilt = +1.1999`, but the firmware's Balance block
> does *not* absorb Method 2's −1 internally. The `[cbal] kp` entry in
> `config/regbot_group47.ini` must be entered as **−1.1999**. Positive
> runs the wheels into a positive-feedback runaway — this was a real
> bug in the first hardware campaign.

### Task 3 — Velocity PI · slow outer loop, RHP zero in the way

> [!tldr]+ Task 3 in one block
> - **Script:** `simulink/design_task3_velocity.m`
> - **Plant:** linearised `θ_ref → v` with Tasks 1 + 2 closed — stable, but with an **RHP zero at +8.51 rad/s** (the wheels-must-roll-backwards-first signature).
> - **Specs:** ω_c = 1 rad/s, γ_M ≥ 60°, N_i = 3.
> - **Result:** K_p ≈ 0.158, τ_i = 3 s. **No Lead** — natural PM beats spec.
> - **What was different:** bandwidth is **clamped by the RHP zero**, not by the cascade rule. K_p comes out small (`< 1`) — opposite of Task 1.
> - **Walkthrough:** §4 (when filled in). **Background:** `docs/REGBOT Balance Assignment.md` → "Task 3".

Once Task 2 stabilised the pendulum, the linearised `θ_ref → v` plant
is stable again — back to a normal PI design. The recipe runs without
Method 2 acrobatics:

1. Linearise with Tasks 1 + 2 closed → 9th-order plant. 0 RHP poles
   (good — Task 2 did its job). One RHP zero at +8.51 rad/s (physics:
   to roll forward, the wheels must roll backward briefly to put the
   centre of mass over the pivot — non-minimum-phase).
2. Pick specs. The RHP zero is the limiting constraint here:
   rule-of-thumb is ω_c ≤ z/5 ≈ 1.7 rad/s. We pick 1 rad/s for
   margin — also satisfies the cascade rule (15× slower than Task 2).
3. PI zero at 0.333 rad/s.
4. Combined phase at ω_c gives a natural PM of ~69°. Above spec → **no Lead**.
5. K_p falls out as ≈ 0.158. (Note `< 1` — opposite of Task 1: the
   plant is already loud at ω_c, so we *attenuate* instead of amplify.)
6. `margin()` confirms.

> [!tip] MATLAB phase-unwrap quirk
> MATLAB's Bode phase output is continuously unwrapped — for a 9th-order
> plant the phase at ω_c reads **+267°** instead of −93° (same angle,
> just unwrapped past −180°). The script wraps it back into [−180°, 180°]
> before computing the natural PM. If you read the phase off a Bode plot
> in MATLAB and it looks impossibly high, subtract 360°.

### Task 4 — Position P · Lead dropped after the natural-PM check

> [!tldr]+ Task 4 in one block
> - **Script:** `simulink/design_task4_position.m`
> - **Plant:** linearised `pos_ref → x` with Tasks 1 + 2 + 3 closed — Type-1 (free integrator), 0 RHP poles, RHP zero at +8.51 rad/s.
> - **Specs:** ω_c = 0.6 rad/s, γ_M ≥ 60°. *(No N_i — no PI.)*
> - **Result:** K_p ≈ 0.541, τ_d = 0 *(Lead dropped)*.
> - **What was different:** plant is already Type-1, so **no PI** needed. ω_c is **iterated against the mission spec**, not derived from cascade rules. Lead would only buy ~3° of PM and add a noisy filter pole — dropped.
> - **Walkthrough:** §5 (when filled in). **Background:** `docs/REGBOT Balance Assignment.md` → "Task 4".

The outermost loop. Two things make this design simpler than the
others:

1. The plant has a **free integrator** (position is the integral of
   velocity), so it's already Type-1. A pure P controller already gives
   zero steady-state error on a step — no I-term needed.
2. ω_c isn't picked from cascade rules. It's iterated against the
   **mission spec** (reach 2 m, peak v ≥ 0.7 m/s, in ≤ 10 s).
   Tried 0.2 (too slow) → 0.5 (almost) → 0.6 (just right).

Then the recipe proper:

1. Linearise with Tasks 1 + 2 + 3 closed → 11th-order plant. 0 RHP
   poles, the same RHP zero at +8.51 rad/s inherited from Task 3.
2. Pick specs (above).
3. *(no PI step — pure P)*
4. Phase balance at ω_c says we're 2.85° short of 60°. That's tiny —
   essentially noise.
5. Solve K_p ≈ 0.541.
6. **Decision: drop the Lead** *(see callout below)*. So `τ_d = 0` and
   the firmware controller is just `K_p`. Verified.

> [!note] Why we dropped the Lead
> A pure ideal Lead `(τ_d s + 1)` is improper and Simulink rejects it.
> The proper version `(τ_d s + 1)/(α τ_d s + 1)` adds a fast filter
> pole that would cost back some of the 2.85° anyway. Not worth the
> complexity for ~3° of PM when the gain margin is already 25 dB. In
> Task 2 the Lead was big (+33°) **and** the gyro made it free. Here
> it's small **and** would cost a filter pole — drop it.

---

## Hardware sanity checks

Every loop's behaviour is verified twice — once in MATLAB (Step 6 of the
recipe) and once on the physical robot. The hardware tests follow a
parallel four-mission script:

- **Test 0** — wheel-speed step (validates Task 1 in isolation, balance off).
- **Test 3a** — balance at rest for 10 seconds (validates Task 2 + Task 3 — does it stay up and not drift?).
- **Test 3b** — closed-loop square-path mission (validates the whole stack under load).
- **Test 4** — `topos` 2 m position step (validates Task 4 against the mission spec).

Every test has a written pass criterion (rise time, drift bound, peak
voltage, final position error) and a recorded pass/fail outcome. The
v3 (Day 5 redesign) gains in this repo all passed on 2026-04-22.

Full write-up — checklists, criteria, and recorded results — lives in
[`docs/Test Plan.md`][3].

[3]: Test%20Plan.md

> [!tip] Debugging order if something misbehaves on the robot
> 1. **Did the firmware actually load `config/regbot_group47.ini`?**
>    99 % of "the design is wrong" turns out to be "the gains weren't on
>    the robot."
> 2. **Is `[cbal] kp` signed correctly?** Method 2 needs **−1.1999**.
>    Positive runs into a positive-feedback runaway (see Task 2 callout).
> 3. **Battery charged + gyro calibrated?** Both checked off in the
>    Test Plan pre-flight section.
> 4. *Then* start questioning the design.

---

## Where to go next

> [!example]+ Pointers
> - **Want the math?** → `docs/MATLAB Walkthrough.md` — line-by-line
>   code with every claim cited against the LCD1 lectures.
> - **Want the polished writeup?** → `docs/REGBOT Balance Assignment.md` —
>   report-style version with all four tasks, plots, and validation
>   results in one place.
> - **Want the hardware test results?** → `docs/Test Plan.md`.
> - **Want to re-run the design?** → start MATLAB in `simulink/`, run
>   `regbot_mg`, then run the four `design_task*.m` scripts in order.
>   Each one prints a copy-pasteable gains block; paste it into
>   `regbot_mg.m` *before* running the next script.
