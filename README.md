# REGBOT Balance Assignment

Team repository for MATLAB code, Simulink models, mission scripts, and notes for the 34722 Linear Control Design 1 final assignment.

**Status: complete.** The report and code were submitted on Learn for Group 47 (May 2026). This repository is final; no further work is planned.

## Team (Group 47)

- Andreas Skånning (s241123)
- Jonas Beck Jensen (s240324)
- Mads Rudolph (s246132)
- Sigurd Hestbech Christiansen (s245534)

## Structure

| Folder / file | Contents |
|---|---|
| `simulink/` | Simulink starter model + `regbot_mg.m` parameter script + `design_task{1,2,3,4}.m` controller-design scripts (all plots saved into `docs/images/`) |
| `data/` | Day 5 identification `.mat` files (shared so teammates can skip Day 5) |
| `docs/` | Notes, progress log, test plan, handoff + per-task design write-ups. Open as an Obsidian vault for the best reading experience. |
| `docs/images/` | Generated plots (Bode, Nyquist, pole-zero, step, hardware test PNGs). Single source of truth. |
| `config/` | Firmware ini file (`regbot_group47.ini`) — the values flashed onto the robot |
| `logs/` | Raw log files recorded from REGBOT during each hardware test |
| `Report/` | Symlink to the Overleaf/LaTeX report repo (separate git repo) |
| `Group_47.pdf` | Final submitted report/note (the exact PDF handed in on Learn) |
| `Group_47_code.zip` | Final submitted archive — the report PDF, `simulink/` code, the Task 1 `data/` file, and all robot `logs/` |

## Tasks

- [x] **Task 1** — Wheel speed PI controller (Day 5 v2 on-floor plant)
- [x] **Task 2** — Balance controller with post-integrator (Lecture 10, Method 2)
- [x] **Task 3a** — Zero-velocity balance (drift within 0.5 m)
- [x] **Task 3b** — Square run at 0.8 m/s
- [x] **Task 4** — Position controller (2 m move, peak v > 0.7 m/s)

## Prerequisites

- MATLAB with **Simscape Multibody** and **Simulink Control Design** packages
- REGBOT with calibrated gyro and tilt-offset
- Starter files from Learn → Resources/REGBOT balance resources

## Running the design scripts

Open MATLAB in `simulink/` and run the design scripts in order. Each one:

1. `regbot_mg` — loads all REGBOT parameters, the Day 5 plant, and the committed gain block into the base workspace.
2. `design_task1_wheel` — designs the wheel-speed PI against $G_{vel} = 2.198/(s+5.985)$, prints gains, saves Bode and closed-loop step PNGs.
3. `design_task2_balance` — linearises the Simulink model with the wheel-speed loop closed, runs Lecture 10 Method 2 (sign check → post-integrator → PI-Lead), saves pole-zero, Nyquist, Bode, IC-response PNGs.
4. `design_task3_velocity` — linearises with the balance loop closed, designs the velocity PI, saves plant-pz / open-loop Bode / step PNGs.
5. `design_task4_position` — linearises with balance + velocity closed, designs the position P (+ tiny Lead), saves plant-pz / open-loop Bode / step PNGs.

All plots are written into `docs/images/` — that's the single source of truth for figures in both the Obsidian notes and the LaTeX report. Each script ends with a copy-paste gains block; paste those back into `regbot_mg.m` to commit the design.

## Reading the notes

`docs/` is the canonical place for all project notes and is intended to be opened as an Obsidian vault ("Open folder as vault"). Wikilinks and image embeds resolve automatically.

- [`docs/REGBOT Balance Assignment.md`](docs/REGBOT%20Balance%20Assignment.md) — progress log + per-task design write-ups
- [`docs/Test Plan.md`](docs/Test%20Plan.md) — hardware test plan with recorded results
- [`docs/HANDOFF.md`](docs/HANDOFF.md) — end-of-session handoff for continuation
- [`docs/REDESIGN_ROADMAP.md`](docs/REDESIGN_ROADMAP.md) — phase tracker for the Day 5 on-floor redesign
- [`docs/PLAN.md`](docs/PLAN.md) — early phase/role plan
- [`docs/Lesson 10 - Unstable Systems and REGBOT Balance.md`](docs/Lesson%2010%20-%20Unstable%20Systems%20and%20REGBOT%20Balance.md) — lecture theory snapshot

## Report

The LaTeX report lives in a separate git repo (`git@github.com:MadsRudolph/REGBOT-Balance-assignment.git`) and is accessible here through the `Report/` symlink.

## Submission

The final assignment was handed in on Learn (course 34722 → Assignments → REGBOT balance), one submission for Group 47:

- `Group_47.pdf` — the report/note (within the 5-page limit).
- `Group_47_code.zip` — a single archive bundling the report PDF (`Group_47.pdf`), the MATLAB/Simulink code (`simulink/`), the Task 1 data (`data/Day5_results_v2.mat`), and all robot logs (`logs/`).

The project is finished.
