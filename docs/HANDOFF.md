---
course: "34722"
course-name: "Linear Control Design 1"
type: handoff
tags: [LCD, regbot, handoff, learning]
date: 2026-05-12
---
# REGBOT Balance Assignment — Handoff

> [!abstract] Where the user is
> Mid-walkthrough of the MATLAB design scripts. The cascade is fully designed,
> simulated, and validated on the physical robot (v3 Day 5 on-floor gains, all
> four hardware tests passed 2026-04-22). The user is not redesigning — they
> are reading the scripts and the Simulink model to understand what's
> happening, with NotebookLM-grounded citations attached to every concrete
> control-theory claim. The companion document `docs/MATLAB Walkthrough.md`
> was created this session and §1 (`regbot_mg.m`) is done. **The next session
> picks up at §2 (`design_task1_wheel.m`).**

> [!warning] Hard rules carried over
> 1. **No AI / Claude attribution in commits** — global rule, project-wide.
> 2. **Do not alter the canonical numerical content** of the four loops — v3
>    gains in `simulink/regbot_mg.m` and `config/regbot_group47.ini` are
>    correct and validated on hardware. Don't "improve" them.
> 3. **Do not regenerate plots in `docs/images/`** unless the user explicitly
>    asks. Future-you re-running scripts will overwrite them — that's fine if
>    the user asked, surprising otherwise.
> 4. **Hardware test results in `docs/Test Plan.md` are experimental facts.**
>    Don't touch.
> 5. **The Report submodule (`Report/`) is a real git submodule** at the
>    latest v3 commit. It's also a *symlink* into the Obsidian vault — known
>    quirk, don't try to absorb it.
> 6. **Don't add `=====` decorative banners back to the design scripts.** The
>    user explicitly stripped them in the previous session.
> 7. **Stage selectively at commit time.** `git add -A` is forbidden — there
>    is persistent CRLF churn on several `.md` files plus occasional stray
>    scratch files. Add by name only.

---

## What this session did

Created `docs/MATLAB Walkthrough.md` — a learning companion that gets filled
in conversationally as we walk through each MATLAB script. Three iterations
shaped its final form:

### Round 1 — design the scaffold

Brainstormed the structure with the user:

- **Single master doc**, not one-per-script (cross-references stay easy).
- **Lives in `REGBOT-Balance-Assignment/docs/`**, git-tracked alongside the
  rest of the repo. Outside the Obsidian vault.
- **Slide links use the Obsidian URI scheme** —
  `obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2F<filename>.pdf`.
  This works regardless of where the source doc lives on disk (vault-relative
  paths would not, because the doc is outside the vault). Pattern lifted
  from `docs/REGBOT Balance Assignment.md`, which already uses it. The URI
  scheme does NOT carry a page anchor, so slide numbers live in the link
  text ("Lec 8 · slide 12 — PI zero placement") and the user navigates
  within the PDF after opening.
- Sections per MATLAB script, two appendices (concept cross-reference, open
  questions log).

### Round 2 — integrate the NotebookLM skill

The user has a skill at `C:\Users\Mads2\.claude\skills\notebooklm\` that
exposes a CLI wrapper for NotebookLM. The notebook `lcd1` (DTU 34722) is
pre-loaded with all 12 lecture PDFs, all lesson notes, and the MATLAB
exercise material — 40 sources total.

Critical for the next-session pickup:

- **The skill is registered at session start.** A session opened before the
  skill existed (or after it was edited) may not see it in the available-
  skills list. The fix is to invoke it via direct read of
  `C:\Users\Mads2\.claude\skills\notebooklm\SKILL.md` and follow its
  instructions — the Skill tool registration is not required to use the
  CLI wrapper.
- **The wrapper is** `C:\Users\Mads2\.claude\skills\notebooklm\scripts\nlm.bat`.
- **Auth** lasts ~7 days (cookies refresh every 3 days via Windows scheduled
  task `NotebookLM Cookie Refresh`). If `nlm.bat auth-status` reports
  `NOT AUTHENTICATED`, **don't trust it blindly** — that diagnostic is
  stale-prone. Run a real query first; only ask the user to re-login if
  the query fails with an actual auth error. The user logged in this
  session at 23:04 local time.
- **Invocation pattern:**
  ```
  "C:/Users/Mads2/.claude/skills/notebooklm/scripts/nlm.bat" ask "<question>" --notebook-id lcd1
  ```
- **Notebook aliases** in the wrapper: `dsp`, `lcd1`, `dsd`, `iae2`, `iot`.
  For this project, always `lcd1`.

Replaced the originally-planned `> [!notebooklm] Verify` callouts (prompts
the user would copy-paste manually) with `> [!cite]` callouts that contain
the **actual NotebookLM-grounded quote + source attribution**, generated
inline by Claude during the walkthrough. The user reads the verified
statement; the verification step happens during the conversation.

### Round 3 — depth calibration

First version of §1 was too deep — the user pushed back that "all the stuff
in `regbot_mg.m` is given to us so we don't need it to be in-depth at all,
this is actually just filling our document with useless stuff." Compressed
§1 to a short orientation (~25 lines) + the **Committed controller gains
reference table** (all v3 gains with values, loop role, source script). No
cite-callouts in §1 — the two NotebookLM queries I ran for §1 (Kemf=Km and
the close-inner-first cascade methodology) were technically verified but
pedagogically empty for a plumbing file. Both citations will be revisited
where they actually matter: cascade methodology in §3 (Task 2 / Method 2),
Kemf=Km isn't worth re-citing.

**Depth rule for the rest of the walkthrough:** be brief on plumbing
(workspace setup, parameter loading, helper functions), be deep on the
control-design steps (linearisation, phase-balance derivation, magnitude
condition, post-integrator placement, Nyquist interpretation, etc.).

---

## Walkthrough doc — format and conventions

`docs/MATLAB Walkthrough.md`. The conventions for filling in future sections:

### Per-step template

```markdown
### X.Y Step N — Title   *(lines aa–bb)*

```matlab
% code excerpt for this step
```

[prose explanation — what it does, what the math says, why this step]

**Claim:** [a concrete assertion about control theory]

> [!cite] ✅ Verified — Lecture N · slide M
> > [verbatim quote or NotebookLM's grounded paraphrase]
>
> *Source: `lcd1` notebook — `<filename>.pdf` slide M (cited by NotebookLM).*

**Slide refs**
- [Lec N · slide M — topic](obsidian://open?vault=Obsidian&file=Courses%2F...pdf)
```

Three cite-callout variants:

- `✅ Verified` — sources back the claim. Quote + slide ref.
- `✏️ Corrected` — sources contradict the claim. Original wrong version
  preserved in the callout; corrected version replaces the claim text.
- `❔ Not in lcd1 sources` — claim is general control-theory knowledge not
  in the loaded slides/exercises. Treat as Claude's reasoning, not sourced
  fact.

### NotebookLM query style

- Ask self-contained questions (NotebookLM has no conversation memory).
- Ask for the slide/page when possible: "Cite the specific slide or page
  where this is shown."
- NotebookLM's bracketed `[1, 2, 3]` citation markers are local to its
  response — strip them; attribute by source-document name in the
  cite-callout instead.
- NotebookLM will sometimes paraphrase rather than quote verbatim. That's
  fine — note "paraphrased from NotebookLM's grounded response" in the
  source line.

### Slide / note link format

Always the Obsidian URI scheme:
```
obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FSlides%2F<file>.pdf
obsidian://open?vault=Obsidian&file=Courses%2F34722%20Linear%20Control%20Design%201%2FLecture%20Notes%2F<note>
```
Markdown notes are linked without the `.md` extension (Obsidian convention).
URL-encode `/` → `%2F`, space → `%20`, `&` → `%26`.

---

## Repo state right now

| Repo | Branch | Tip | Origin |
|---|---|---|---|
| `REGBOT-Balance-Assignment` | `main` | `<this commit>` Add MATLAB Walkthrough scaffold; §1 done | will be pushed at end of this session |
| `Report` (submodule) | `main` | unchanged this session | unchanged |
| `DTU` parent (regbot is itself a submodule of DTU) | `main` | not bumped this session | parent's submodule pointer for regbot is *behind* — not relevant unless the user wants to bump |

### Uncommitted state on disk (not from this session — pre-existing in the working tree)

- **`docs/REGBOT Balance Assignment.md`** — has **real content changes**
  (358 insertions / 207 deletions, looked at the diff). Looks like a
  pedagogical expansion of Task 1's tldr and prose. **Origin unclear** —
  not from this session. The previous handoff said this file was CRLF
  churn only; that's no longer accurate. Leaving it alone; whoever knows
  the origin can stage/commit/discard appropriately.
- **`docs/PLAN.md`**, **`docs/REDESIGN_ROADMAP.md`** — pure CRLF, no
  semantic change. Skip.
- **`docs/images/regbot_task1_*.png`** (5 files) — git reports them as
  modified but `git diff --shortstat` shows no byte changes; probably a
  filesystem timestamp glitch. Skip.
- **`simulink/tes.m`** — untracked scratch file. Ignore.

The only things committed this session:
- `docs/MATLAB Walkthrough.md` (new)
- `docs/HANDOFF.md` (this file, updated)

---

## What the next session does

**Pick up at §2 (`design_task1_wheel.m`).** This is where the actual control
design starts, so depth is warranted — full step-by-step using the
established template, with cite-callouts for every concrete claim.

The script's own structure (already pedagogical) gives the section outline:

1. **Step 1 — Inspect the plant** (lines 37–58) — load `G_1p_avg` from
   `data/Day5_results_v2.mat`, read off DC gain / break / time constant.
2. **Step 2 — Pick specs** (lines 61–76) — `ω_c = 30` rad/s, `γ_M = 60°`,
   `N_i = 3`. Discuss cascade lower bound, noise/saturation upper bound.
3. **Step 3 — Place the PI zero** (lines 79–99) — `τ_i = N_i/ω_c`.
   Explain why placing at `ω_c/N_i` gives `-arctan(N_i) - 90°` phase
   contribution at ω_c.
4. **Step 4 — Phase balance** (lines 102–135) — read combined PI·G phase
   at ω_c, compute natural PM, decide if Lead is needed.
5. **Step 5 — Solve Kp** (lines 138–149) — `Kp = 1 / |L|_unscaled at ω_c`.
6. **Step 6 — Verify** (lines 152–168) — `margin(L)` recomputes ω_c, PM,
   GM; closed-loop step response.

Likely high-value NotebookLM queries (to run during §2):

- "What is the phase contribution at ω_c of a PI controller with the zero
  placed at ω_c/Ni? Is the formula −arctan(Ni) − 90° derived anywhere in
  the LCD1 material?"
- "What is the 'Type-0 plant' vs 'Type-1 plant' distinction and how does it
  determine whether a P or PI controller can achieve zero steady-state
  error?"
- "Why is the magnitude condition for crossover frequency
  `Kp = 1 / |G(jω_c)|`? Cite the slide where this is shown."

After §2 is done, the order is §3 (`design_task2_balance.m` — Method 2,
unstable, sign flip, two Nyquist plots; the hardest section), then §4
(`design_task3_velocity.m`), then §5 (`design_task4_position.m`), then §6
(the Simulink model), then §7 (helpers — short).

---

## Quick orientation map

```
REGBOT-Balance-Assignment/
├── README.md
├── config/regbot_group47.ini       -- v3 firmware gains (load via REGBOT GUI)
├── data/Day5_results_v2.mat        -- on-floor plant ID (G_1p_avg)
├── docs/
│   ├── MATLAB Walkthrough.md       -- THE NEW DOC (§1 done, §2–§7 to go)
│   ├── REGBOT Balance Assignment.md -- main pedagogical writeup (uncommitted edits!)
│   ├── Test Plan.md                -- hardware test results (do not modify)
│   ├── PLAN.md                     -- early phase plan
│   ├── REDESIGN_ROADMAP.md         -- Day 5 redesign phase tracker
│   ├── HANDOFF.md                  -- this file
│   └── images/                     -- 47 PNGs, single source for Obsidian + LaTeX
├── logs/test*_v3_onfloor_*.txt     -- raw REGBOT logs, 2026-04-22 hardware run
├── simulink/
│   ├── regbot_1mg.slx              -- the Simulink model
│   ├── regbot_mg.m                 -- workspace loader (§1)
│   ├── design_task1_wheel.m        -- §2 (NEXT)
│   ├── design_task2_balance.m      -- §3
│   ├── design_task3_velocity.m     -- §4
│   ├── design_task4_position.m     -- §5
│   └── lib/                        -- plumbing helpers
└── Report/                         -- LaTeX submodule
```

### Canonical gains (do not change)

| Task | Loop | Type | ω_c | γ_M | Parameters |
|---|---|---|---|---|---|
| 1 | Wheel speed | PI | 30 rad/s | 82.85° | `Kpwv = 13.2037`, `tiwv = 0.1` |
| 2 | Balance | PILead + post-PI | 15 rad/s | 60° | `Kptilt = 1.1999` (firmware: **−1.1999**), `titilt = 0.2`, `tdtilt = 0.0442`, `tipost = 0.1245` |
| 3 | Velocity | PI | 1 rad/s | 68.98° | `Kpvel = 0.1581`, `tivel = 3.0` |
| 4 | Position | P (Lead dropped) | 0.6 rad/s | ~57° | `Kppos = 0.5411`, `tdpos = 0` |

### Two facts that bite if forgotten

1. **Firmware sign flip on `[cbal] kp`** — the firmware Balance block does
   not absorb Method 2's `−1`. The ini must enter `kp = -1.1999` (negative).
   Positive runs the wheels into a positive-feedback runaway.
2. **Day 5 redesign is canonical** — all numbers in the repo are v3. The
   original design used the Day 4 wheels-up plant `13.34/(s+35.71)`; that
   was 6× faster than on-floor reality. Re-fit on-floor
   `2.198/(s+5.985)`, all four loops retuned, hardware re-validated.

---

## Tooling setup on the next PC

For the next-PC pickup (the user mentioned this on Discord; the other PC
also has the notebooklm skill installed):

1. **Check NotebookLM auth** before starting:
   ```powershell
   C:\Users\Mads2\.claude\skills\notebooklm\scripts\nlm.bat library-list
   ```
   If it errors with auth issues:
   ```powershell
   C:\Users\Mads2\.claude\skills\notebooklm\scripts\nlm.bat login
   ```
   ~30s browser sign-in.
2. **Pull the regbot repo** to fast-forward main with this session's
   commit:
   ```
   git fetch && git pull --ff-only
   ```
3. **Read this HANDOFF.md and `docs/MATLAB Walkthrough.md`** to get
   oriented, then start §2.

---

## Commit workflow when work needs committing

Standard:
1. `git status --ignore-submodules=all --short` to see what changed
2. **Stage selectively** by filename. NEVER `git add -A`.
3. Commit with a clear title + body. **No `Co-Authored-By` lines, no
   "Generated with Claude" lines, no AI attribution.**
4. Push to `origin/main`.
5. Don't bump the DTU parent submodule pointer unless asked.

For the Report submodule: it lives at `Report/` as both a git submodule
and a symlink into the Obsidian vault. Don't try `git submodule absorbgitdirs`.

---

*Written 2026-05-12 at end of walkthrough-doc creation session. The next
session picks up at §2 (`design_task1_wheel.m`) — the wheel-speed PI design,
where actual control theory starts. Be a patient guide, match the
established style, use NotebookLM to ground every concrete claim, and
defer to depth on design steps while staying brief on plumbing.*
