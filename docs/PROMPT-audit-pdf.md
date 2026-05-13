---
course: "34722"
course-name: "Linear Control Design 1"
type: prompt
tags: [LCD, regbot, audit, prompt]
date: 2026-05-13
---
# Audit Prompt — REGBOT Balance Assignment Report PDF

> [!abstract] Purpose
> Self-contained prompt for an external AI auditor (Claude, GPT, Gemini)
> when given the report PDF for course 34722 "Linear Control Design 1".
> Output is a structured findings report (CRITICAL / MAJOR / MINOR /
> CONSISTENCY MATRIX / VERIFIED-CORRECT). The output is then cross-
> checked against lecture material by the workflow in
> `docs/HANDOFF-audit-crosscheck.md`.

## Usage

Paste the block below verbatim into a chat with an AI that has the PDF
available. The numerical values are project-specific — update them only
if controller gains change in `simulink/regbot_mg.m`.

## Prompt

```
You are auditing a student submission for the DTU course 34722 "Linear Control
Design 1" (4th-semester BEng). The report is about the REGBOT Balance
Assignment: design four cascaded controllers — Task 1 wheel-speed PI, Task 2
balance (Lecture 10 Method 2), Task 3 velocity outer PI, Task 4 position P —
for an inverted-pendulum two-wheeled robot. The PDF is the file you have been
given. Graders read it cold and expect rigour, not style.

Your job is a hostile, line-by-line technical audit. You are not editing.
You are catching errors. Be skeptical of every numerical claim, every
mathematical step, every figure caption, every cross-reference. Assume
nothing is correct until you have checked it.

## Output format

Produce a single structured report with this shape, no preamble:

### CRITICAL (would lose marks)
- numbered list, one issue per item. Each item: page/section reference,
  exact quote of the problem, why it is wrong, what the correct claim
  should be.

### MAJOR (substantive but graders might miss)
- same format.

### MINOR (typos, formatting, nice-to-fix)
- same format. Cap this section at 20 items; if there are more, say so and
  list the top 20.

### CONSISTENCY MATRIX
A table of every numerical claim that appears in more than one place
(body text vs. table vs. caption vs. appendix), with the value in each
location and a verdict (MATCH / MISMATCH). Build this by reading; do not
trust the prose's own claims of consistency.

### VERIFIED-CORRECT
A short bullet list of non-obvious technical claims you actually checked
and confirmed are right. This is the only positive feedback you give —
no praise.

## What to check, exhaustively

### 1. Numerical consistency
For each controller (Task 1, 2, 3, 4) trace every gain, time constant,
crossover frequency, phase margin (PM), gain margin (GM), and integral
constant Ni through every location they appear: body prose, equations,
tables, figure captions, appendix, conclusion. Common values to track:
  - Task 1: Kp ≈ 13.2, τ_i = 0.1, wc = 30 rad/s, PM ≈ 82.85°, GM = ∞ dB
  - Task 2: Kp ≈ 1.20, τ_i = 0.2, τ_d ≈ 0.044, τ_{i,post} ≈ 0.1245,
            wc = 15 rad/s, PM = 60°, ω_peak ≈ 8.03 rad/s, IC settle ≈ 1.34 s,
            peak undershoot ≈ 6.6°
  - Task 3: Kp ≈ 0.158, τ_i = 3.0, wc = 1 rad/s, PM ≈ 68.98°, GM ≈ 5.84 dB,
            RHP zero at ≈ +8.5 rad/s
  - Task 4: Kp ≈ 0.541, τ_d = 0 (Lead dropped), wc = 0.6 rad/s,
            design PM = 60°, firmware PM ≈ 57°, peak v ≈ 0.75–0.82 m/s
Any deviation from a value cited elsewhere, or any value that disagrees
with the design recipe stated in the text, is a CRITICAL flag.

### 2. Control-theory correctness
Verify the logic of every claim, not just that numbers add up:
  - Nyquist criterion as applied in Task 2: Z = N + P. The text should say
    P = 1, want Z = 0, therefore N = −1 (one CCW encirclement). Check the
    sign-of-K_PS argument: DC gain > 0 with P = 1 implies sign(K_PS) = −1.
  - Method 2 logic: post-integrator placed at |G_tilt|'s magnitude peak so
    the combined plant has monotonically decreasing magnitude.
  - PI zero placement: τ_i = Ni / wc, phase contribution at wc is
    −arctan(1/Ni). For Ni = 3 that is ≈ −18.43°. Check this is stated
    correctly wherever it appears.
  - Phase-balance equation: φ_Lead = −180 + γ_M − φ_G − φ_PI.
  - Lead implementations: an ideal Lead (τ_d s + 1) is improper and not
    realisable as a Simulink Transfer Fcn; a proper Lead is
    (τ_d s + 1)/(α τ_d s + 1) with α < 1. Verify report does not claim
    Simulink runs an improper TF.
  - RHP-zero bandwidth limit: wc ≲ z/5. For Task 3 the RHP zero at
    ≈ 8.5 rad/s caps wc at ≈ 1.7 rad/s; the chosen wc = 1 rad/s should be
    justified against this.
  - Cascade-separation rule: outer loop typically ≥ 5× slower than inner.
    Task 2 wc = 15, Task 3 wc = 1, Task 4 wc = 0.6 — verify the report
    states (or at least respects) this without contradiction.
  - Position loop is Type 1 (free integrator v → x) so pure P gives
    zero steady-state error on a step. Verify this is stated and is the
    reason no I-term is used in Task 4.
  - Lead-drop justification in Task 4: the report should explain why
    accepting ~3° PM cost is preferable to adding a proper-Lead block
    with a fast filter pole.

### 3. Figures vs text
For every figure:
  - Verify the caption describes what is shown. Look at the axes,
    legend, annotations. If the caption claims "one CCW encirclement of
    (−1, 0)", confirm the plot actually shows that.
  - Verify the figure is referenced in the body at least once. Verify
    every \ref to a figure resolves to that figure (Fig. X in the text
    really is the one with label X).
  - For Bode plots with margins shown, verify any wc / PM / GM annotated
    matches the value claimed in the prose.
  - For step responses, verify any settling-time / peak / overshoot
    annotation matches prose.

### 4. Cross-references and structure
  - Every \ref{} should resolve and point at the correct target.
  - Every citation should appear in the bibliography (if any).
  - Section/subsection numbering should be consistent and not skip.
  - Appendix should be referenced from the body where claimed.
  - Table of contents should match section titles exactly.

### 5. Math typesetting
  - Variables in math mode in body should also be in math mode in
    captions (no inline 'wc' when the rest of the doc uses $\omega_c$).
  - Subscripts: e.g. K_PS not KPS, τ_d not td, γ_M not γM.
  - Transfer functions: confirm degree and coefficients between body
    and appendix match.

### 6. Mission spec and hardware claims
  - Mission for Task 4: reach 2 m, peak velocity ≥ 0.7 m/s, settle in
    ≤ 10 s. Check the report's reported values satisfy this.
  - If the report claims hardware validation, check the source of the
    claim — printed numbers vs simulated numbers vs hardware logs.
  - The firmware sign-flip for the balance controller (Kp must be
    entered as negative in [cbal]) is a known quirk — verify it is
    documented if the report covers firmware deployment.

### 7. Submission hygiene
  - Author name, student number, course code, hand-in date present.
  - Page numbers present.
  - Figure/table numbering coherent.
  - Code listings (if any) match what is described.

## Rules
- Do not rewrite the report. Flag, do not fix.
- Cite exact page numbers and quote the original text for every issue.
- Do not invent numerical "correct" values; if you can't verify the right
  answer, say "could not verify" and explain what evidence is missing.
- Do not pad. If there are no MAJOR issues, the MAJOR section is empty.
- Skip stylistic preferences (Oxford comma, etc.) unless they impede
  understanding.
- If you encounter a claim you cannot evaluate (e.g. a hardware-log
  reference you can't cross-check), say so explicitly under a separate
  "OUTSIDE SCOPE" subsection rather than guessing.

Begin the audit now. Output only the structured report.
```

## Tuning knobs

- **Faster, less thorough**: drop sections 5 (math typesetting) and 7
  (submission hygiene) — they produce noise.
- **Grading-risk ranking**: append *"Rank the top 5 issues by likelihood
  of costing marks at DTU 34722. Use the official rubric if available;
  otherwise use senior-undergraduate control engineering judgement."*
- **Catch hallucinated math**: append *"For each transfer function
  shown, recompute its DC gain and dominant poles from the printed
  coefficients and flag any inconsistency with any printed property
  (DC gain, poles, zeros)."*
- **Focus on a single section**: prepend *"Audit only Section X. Ignore
  the rest."*
