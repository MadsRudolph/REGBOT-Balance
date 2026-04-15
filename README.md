# REGBOT Balance Assignment

Team repository for MATLAB code, Simulink models, and mission scripts for the 34722 Linear Control Design 1 final assignment.

## Team (Group 47)

- Andreas Skånning (s241123)
- Jonas Beck Jensen (s240324)
- Mads Rudolph (s246132)
- Sigurd Hestbech Christiansen (s245534)

## Structure

| Folder | Contents |
|--------|----------|
| `src/` | MATLAB scripts for controller design (Tasks 1-4) |
| `simulink/` | Simulink models (`regbot_1mg`, balance loop, etc.) |
| `figures/` | Generated plots (Bode, step responses, XY-plane) |
| `missions/` | REGBOT mission scripts (`.txt` files) |
| `logs/` | Log files recorded from REGBOT during experiments |
| `Report/` | Symlink to the Overleaf report repo (not tracked) |

## Tasks

- [ ] **Task 1** — Wheel speed PI controller (from Day 5 voltage-to-velocity TF)
- [ ] **Task 2** — Balance controller with post-integrator (stabilises RHP pole)
- [ ] **Task 3a** — Zero-velocity balance (drift within 0.5 m)
- [ ] **Task 3b** — Square run at 0.8 m/s (side 1 m, turning radius 0.2 m)
- [ ] **Task 4** — Position controller (2 m move, max speed > 0.7 m/s)

## Prerequisites

- MATLAB with **Simscape Multibody** and **Simulink Control Design** packages
- REGBOT with calibrated gyro and tilt-offset
- Starter files from Learn → Resources/REGBOT balance resources

## Running the script

Open MATLAB in `simulink/` and run `regbot_mg`. The script automatically:
- Loads all REGBOT parameters
- Defines the Day 5 plant
- Designs the Task 1 wheel-speed PI controller
- Linearizes the Simulink model to get $G_{wv}$ and $G_{tilt}$
- Prints poles, zeros, and RHP pole counts
- Generates Bode plots, pole-zero maps, and step responses

### Plot output location

The script **auto-detects** where to save plots:

- **If you have Mads's Obsidian vault** at `DTU/Obsidian/Courses/34722 Linear Control Design 1/...`, plots go there (so they embed directly in his notes).
- **Otherwise**, plots are saved locally in `simulink/images/` (gitignored, so they stay on your machine).

To force local output even with Obsidian present, set `FORCE_LOCAL = true` at the top of the script.

## Report

The LaTeX report lives in a separate repo:
`git@github.com:MadsRudolph/REGBOT-Balance-assignment.git`

Accessible here via the `Report/` symlink.
