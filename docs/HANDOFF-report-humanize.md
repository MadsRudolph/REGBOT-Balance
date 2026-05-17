---
course: "34722"
course-name: "Linear Control Design 1"
type: handoff
tags: [LCD, regbot, handoff, report, writing, humanize]
date: 2026-05-17
---
# REGBOT Balance Assignment — Report Humanization Handoff

> [!abstract] Goal
> The report is technically finished and numerically verified. The
> remaining job is **purely a writing pass**: make the prose read like a
> 4th-semester DTU BEng group (Andreas, Jonas, Mads, Sigurd) actually
> wrote it, not like an AI or a textbook. Nothing about the engineering,
> the numbers, the figures, or the structure-vs-rubric mapping changes.
> Voice only.

> [!warning] Hard rules
> 1. **Do not change a single number, gain, margin, frequency, time, or
>    equation.** Every value in the report is audit-cross-checked and
>    reconciled against the MATLAB design scripts (see
>    `HANDOFF-audit-crosscheck.md`). Touching numbers re-opens that whole
>    quality gate. If a number *reads* wrong, flag it — do not edit it.
> 2. **Do not change figure files, `\includegraphics` paths, `\label`/
>    `\ref` targets, or `\input` order.** Captions: wording may be
>    humanized, but the figure it describes and any value in it must stay
>    identical.
> 3. **Stay within the 5-page body limit.** The note (sections 1–7) is
>    capped at 5 pages by the hand-in spec; the appendix is extra and
>    uncapped. Humanizing tends to *add* words — every softened sentence
>    must be paid for by tightening another. Recompile and check the page
>    count before declaring done.
> 4. **Keep every rubric element per task** (see "Rubric" below). Voice
>    can change; the presence of TF / controller-and-why / parameters /
>    Bode / sim step / hardware step / comparison cannot.
> 5. **No AI attribution in commits.** No `Co-Authored-By`, no "Generated
>    with…". Commit messages read as the developer's own.
> 6. **`git add -A` is forbidden.** Stage Report files by explicit path.
> 7. **Do not touch `Report/.git`.** It was just repaired to an absolute
>    `gitdir:` path (see "Git workflow"). Leave it.

---

## Where things stand

- **Report submodule:** branch `main`, HEAD `5a23e8c`, clean, in sync
  with `origin/main` (`MadsRudolph/REGBOT-Balance-assignment.git`).
- **Super-repo** (`Skab101/REGBOT-Balance`): `main` @ `f238b9c`+, Report
  pointer bumped to `5a23e8c`; both pushed.
- **`main.pdf` is gitignored and stale.** It is a local build artifact,
  not version-controlled. It currently predates the YouTube-link edit
  (and possibly figure refreshes). The branch *source* is the source of
  truth. **Recompile (`latexmk -pdf main.tex` in `Report/`) before
  reviewing or submitting.**

### Already done — do NOT redo

- Audit cross-check against NotebookLM + report source (3 audits triaged;
  `HANDOFF-audit-crosscheck.md`).
- All Tier-1 mark-risk fixes shipped: figure refresh from design scripts,
  body↔MATLAB reconciliation (Task 4 GM 26.20 dB, peak v 0.772 m/s,
  PM 57.18°), Bode-post/Nyquist regenerated at correct aspect ratio,
  "three turns"→"four turns", ±9 V limiter consistency, rise-time
  0.012→0.087 s, τ_cl→t_r, "four laps"→"one square lap", Task 2 step
  figure swapped to the IC-recovery image, in-line XY figure dropped to
  the appendix, `\enlargethispage` removed.
- A YouTube link to the Test 3b square run was added in
  `velocity-controller.tex`.

### Optional polish still open (low priority; from the audit)

These were flagged but never actioned. They are minor; act only if it
also helps the prose read naturally:

- Body says `K_P = 13.20`, conclusion table `13.2037`
  (`wheel-speed-controller.tex`) — precision-display only.
- "same six-step **PI-Lead** procedure" but Task 4 is pure P
  (`control-architecture.tex`).
- φ_PI = 0 substitution not stated in Task 4 phase balance.
- Nyquist N sign convention not defined before first use.
- Type-1 vs the inherited post-integrator (two integrators) not
  reconciled in Task 4.

---

## What "humanize" actually means

The report is correct but reads **machine-polished**: relentless
em-dash fragments, a rigid `What's special / Plant / Recipe / Verify`
scaffold cloned onto every task, telegraphic note-style sentences
("This is the hard one."), and an over-confident, almost marketing
register. A grader can smell it.

Target voice: **four Danish engineering students explaining what they
did and why** — clear, direct, technically precise, but with the
connective tissue and slightly-less-than-perfect phrasing of real
human writing.

**Do**

- Use full sentences with connectors ("Because the plant has a RHP
  pole, …", "We then checked …", "This gave us …"). Let the prose
  breathe.
- Keep first-person plural — "we chose", "we found", "we expected" —
  it's a student report and it humanizes well.
- Vary sentence and paragraph rhythm. Not every idea needs its own
  punchy fragment.
- Keep it technically exact. Humanizing is a *register* change, not a
  precision change.
- Soften the templated section scaffold where it reads robotic. The
  rubric needs the *content* present, not literally the headers
  `What's special` / `Recipe (R2–R5)` on all four tasks. Reword headers
  to sound natural and varied; keep the information.
- Keep Danish-student-English: correct and clear, occasionally a touch
  less idiomatic than a native copywriter — that is the authentic voice,
  not something to "fix".

**Don't**

- Don't inflate. Humanizing ≠ padding. Wordier is not more human;
  *natural* is. Watch the page budget (Rule 3).
- Don't add hedging ("it could perhaps be argued that…"). Students
  state what they did.
- Don't introduce new claims, caveats, or numbers to sound thorough.
- Don't touch equations, `\ref`s, figure files, or values.
- Don't homogenize all four task sections into an identical template —
  some natural variation between tasks is *more* human.

**Texture cues that read "AI" in this report (hunt these)**

- Em-dash sentence-joining everywhere (`--` in the .tex). Replace many
  with full stops, commas, or "because/so/which".
- Sentence fragments used for punch ("No Lead needed.", "The hard
  one.").
- Triplet/parallel constructions ("fix the sign, fix the magnitude,
  run the recipe").
- Identical paragraph openers across tasks.
- Bold "key takeaway" phrasing and recipe-step abstraction (`R1`–`R6`)
  where a sentence would read more naturally.

Work **section by section**, smallest-risk first. Show the user a
before/after of one section and get a feel-check on the voice before
sweeping the rest.

---

## Source-of-truth files

Report body (the only files to edit for this pass):

- `Report/main.tex` — preamble, front page, `\input` order. Avoid
  editing except trivial prose on the title block if asked.
- `Report/sections/introduction.tex`
- `Report/sections/control-architecture.tex`
- `Report/sections/wheel-speed-controller.tex`
- `Report/sections/balance-controller.tex`
- `Report/sections/velocity-controller.tex`
- `Report/sections/position-controller.tex`
- `Report/sections/conclusion.tex`
- `Report/sections/appendix.tex` — captions/notes only; figures frozen.

Reference (read-only, to confirm a number before deciding it's *prose*
not *fact*):

- `simulink/regbot_mg.m` — committed gains.
- `simulink/design_task*.m` — printed margins/values.
- `docs/MATLAB Walkthrough.md` — long-form derivation, §1–§5.
- `docs/HANDOFF-audit-crosscheck.md` — what was verified and how.

## Rubric (every task section must still contain)

Per design step: which transfer function is controlled · which
controllers are in the open loop and why · the design/controller
parameters (Nᵢ, α, τ_d, τ_i, K_P, γ_M, ω_c…) and how they were found ·
a Bode plot of the open-loop TF with the phase margin · a closed-loop
step from Simulink · a step from the REGBOT (with the mission written
out) · comments comparing simulation vs. experiment. Plus: a few
general findings/method remarks, and the Task-4 XY plot (in the
appendix, referenced from the body).

---

## Git workflow (read carefully — non-standard)

`REGBOT-Balance-Assignment/Report` is a **Windows junction** to
`C:/Users/Mads2/DTU/Obsidian/Courses/34722 Linear Control Design 1/Exercises/Work/regbot/Report`.
`Report/.git` was repaired to an **absolute** `gitdir:` so git works
from any route. Do not "fix" it again.

**Report submodule git** — use explicit env vars (don't rely on `cd`
into the junction from the agent shell, the CWD resets):

```
RG="C:/Users/Mads2/DTU/.git/modules/Obsidian/Courses/34722 Linear Control Design 1/Exercises/Work/regbot/Report"
RW="C:/Users/Mads2/DTU/4. Semester/Linear Control Design/REGBOT-Balance-Assignment/Report"
GIT_DIR="$RG" GIT_WORK_TREE="$RW" git status --short
GIT_DIR="$RG" GIT_WORK_TREE="$RW" git add sections/<file>.tex
GIT_DIR="$RG" GIT_WORK_TREE="$RW" git commit -m "..."
GIT_DIR="$RG" GIT_WORK_TREE="$RW" git push origin main
```

**Bump the super-repo pointer** after a Report commit (super-repo's
own submodule path is also stale, so use `update-index`):

```
SG="C:/Users/Mads2/DTU/.git/modules/4. Semester/Linear Control Design/REGBOT-Balance-Assignment"
SW="C:/Users/Mads2/DTU/4. Semester/Linear Control Design/REGBOT-Balance-Assignment"
NEWSHA=$(GIT_DIR="$RG" git rev-parse HEAD)
cd "$SW" && GIT_DIR="$SG" git update-index --cacheinfo 160000,$NEWSHA,Report
GIT_DIR="$SG" git commit -m "Bump Report to <short> (<why>)"
GIT_DIR="$SG" git push origin main
```

The user works on `main` for the report (the `submission-code` branch is
the *code* hand-in, untouched by this pass). Don't push the DTU outer
repo — it treats the super-repo as a submodule boundary; nothing to do
there.

---

## Per-session workflow

1. Read this file and skim `HANDOFF-audit-crosscheck.md` (so you know
   which strings are facts, not prose).
2. Pick one section. Read its current `.tex`.
3. Humanize the prose only. Keep every number, `\ref`, equation, figure
   path, and rubric element intact.
4. Show the user the before/after for that section; get a voice
   feel-check before continuing to the rest.
5. Commit per section (or per logical batch) with a plain message,
   selective `git add`, no AI attribution.
6. After the prose pass: recompile `main.pdf`, confirm body ≤ 5 pages
   and figures still render, then bump the super-repo pointer and push.

> [!tip] First action for the next session
> Recompile the current PDF, then humanize **`introduction.tex`** and
> **`control-architecture.tex`** first (highest AI-smell, lowest
> numeric risk — almost no values there). Show the user that pair as
> the voice sample before touching the four task sections.

---

*Written 2026-05-17. Report is numerically final (`5a23e8c`); this pass
is voice/register only. The code hand-in lives on the `submission-code`
branch and is out of scope here.*
