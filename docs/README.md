# Team docs — REGBOT notes

`docs/` is the **single source of truth** for notes and figures on this
project. Open the folder as an Obsidian vault for the best reading
experience — wikilinks and image embeds resolve automatically.

## Contents

| File / folder | What it is |
|---|---|
| `REGBOT Balance Assignment.md` | Progress log for the assignment — Tasks 1–4 design write-ups, plots, commentary |
| `Test Plan.md` | Hardware test plan with recorded results |
| `HANDOFF.md` | End-of-session handoff for picking up the work later |
| `REDESIGN_ROADMAP.md` | Phase tracker for the Day 5 on-floor redesign |
| `PLAN.md` | Early-stage team plan (phases, role division) |
| `Lesson 10 - Unstable Systems and REGBOT Balance.md` | Lecture note covering unstable systems, Nyquist, post-integrator, gyro Lead |
| `images/` | All design-time plots (Bode, Nyquist, pole-zero, step, IC response) and hardware test PNGs. The MATLAB design scripts write into this folder directly — run one of them and your Obsidian notes pick up the new plot. |

## Regenerating the plots

From MATLAB in `simulink/`, run any of `design_task1_wheel`,
`design_task2_balance`, `design_task3_velocity`, `design_task4_position`.
Each script saves its Bode / Nyquist / pole-zero / step PNGs into
`docs/images/` and prints the design summary (gains, margins) to the
console. Commit the updated PNGs alongside your notes changes.
