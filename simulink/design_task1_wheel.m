%% =======================================================================
%  Task 1 — Wheel-speed PI controller design  (step-by-step / pedagogical)
%  =======================================================================
%
%  Walks through the design DECISION BY DECISION, with a Bode plot at
%  every intermediate stage. Run the whole script and read top-to-bottom:
%  each section prints why we do what we do and saves a figure that shows
%  the state of the design at that point.
%
%  Plant:   Gvel(s) = 2.198/(s+5.985)
%           (Day 5 v2 on-floor 1-pole tfest fit; loaded from
%            data/Day5_results_v2.mat as G_1p_avg)
%
%  Specs:   wc = 30 rad/s,  gamma_M >= 60 deg,  Ni = 3
%
%  Sections:
%    Step 1  Inspect the plant            -> figure 190
%    Step 2  Pick specs                   -> console only
%    Step 3  Place the PI zero            -> figure 191
%    Step 4  Phase balance (Lead?)        -> figure 192
%    Step 5  Solve Kp                     -> console only
%    Step 6  Verify                       -> figures 200, 201
%  =======================================================================

close all; clear;

% --- Load workspace ------------------------------------------------------
% regbot_mg populates physical params + committed gains and addpaths lib/
% so the helpers (print_tf, save_plot, pick_image_dir) resolve.
addpath(fileparts(mfilename('fullpath')));
regbot_mg;

s       = tf('s');
IMG_DIR = pick_image_dir();


%% ====================== STEP 1 — INSPECT THE PLANT ======================
% Load the averaged 1-pole training-wheels on-floor fit.
mat_path = fullfile(fileparts(mfilename('fullpath')), '..', 'data', ...
    'Day5_results_v2.mat');
S         = load(mat_path, 'G_1p_avg');
Gvel_day5 = S.G_1p_avg;     % 2.198 / (s + 5.985)

% Three numbers that summarise the plant.
p_plant = pole(Gvel_day5);
K_DC    = dcgain(Gvel_day5);
omega_b = -p_plant(1);          % break frequency = -pole (rad/s)
tau_p   = 1/omega_b;            % time constant   = 1/break

print_tf('Gvel_day5', Gvel_day5);
fprintf('DC gain = %.4f (m/s)/V\n', K_DC);
fprintf('break   = %.3f rad/s\n', omega_b);
fprintf('tau     = %.3f s\n\n', tau_p);

% Plot 1: bare plant.
save_plot(figure(190), @() bode(Gvel_day5, {0.1, 1000}), ...
    'Step 1: bare plant  G_{vel}(s) = 2.198/(s+5.985)', ...
    IMG_DIR, 'regbot_task1_step1_plant_bode.png');


%% ====================== STEP 2 — PICK SPECS =============================
% wc       — bandwidth knob. Lower bound: cascade rule (>= 2x Task 2's 15
%            rad/s). Upper bound: noise/saturation (every dB above the
%            plant break costs Kp). 30 rad/s satisfies both.
% gamma_M  — stability cushion. 60 deg is the course default — gives
%            ~10% step overshoot, robust to plant uncertainty.
% Ni       — PI zero placement. Higher = phase-cheap but weak integral
%            action. Lower = strong integral but eats phase margin.
%            3 is the course default sweet spot.
wc_wv        = 30;       % target crossover [rad/s]
gamma_M_spec = 60;       % phase margin spec [deg]
Ni_wv        = 3;        % PI zero at wc/Ni

fprintf('wc      = %d rad/s\n', wc_wv);
fprintf('gamma_M = %d deg\n',   gamma_M_spec);
fprintf('Ni      = %d\n\n',     Ni_wv);


%% ====================== STEP 3 — PLACE THE PI ZERO ======================
% Place the PI zero at wc/Ni. Below the zero the PI behaves like a pure
% integrator (slope -20 dB/dec, phase -90). Above the zero, the zero
% cancels the integrator's slope (slope 0 dB/dec, phase climbing back to 0).
% At wc, the zero has done most of its phase recovery, so the PI's
% phase contribution is only arctan(Ni) - 90 = -18.4 deg for Ni=3
% (equivalently: -arctan(1/Ni) = -arctan(1/3) = -18.4 deg).
tau_i_wv   = Ni_wv / wc_wv;
C_PI_shape = (tau_i_wv*s + 1) / (tau_i_wv*s);   % PI with Kp = 1

fprintf('tau_i = Ni/wc = %.4f s   (PI zero at %.2f rad/s)\n\n', tau_i_wv, 1/tau_i_wv);

% Plot 2: plant alone, PI alone, and the combined (still no Kp).
figure(191); clf
bode(Gvel_day5, C_PI_shape, C_PI_shape*Gvel_day5, {0.1, 1000});
grid on;
legend('G_{vel}  (plant only)', ...
       'C_{PI,shape}  (PI, K_p=1)', ...
       'C_{PI,shape} \cdot G_{vel}  (combined, no K_p)', ...
       'Location','best');
title('Step 3: plant alone vs PI alone vs combined');
saveas(gcf, fullfile(IMG_DIR, 'regbot_task1_step3_pi_overlay.png'));


%% ====================== STEP 4 — PHASE BALANCE ==========================
% Read the phase of the combined PI*G at wc and compute the natural
% phase margin. If natural PM >= spec, no Lead. Otherwise Lead must
% close the gap.
%
% bode() at a single frequency returns scalar mag and phase.
[magL_unscaled, phi_L_wc] = bode(C_PI_shape*Gvel_day5, wc_wv);
magL_unscaled   = squeeze(magL_unscaled);
phi_L_wc        = squeeze(phi_L_wc);
gamma_M_natural = 180 + phi_L_wc;

fprintf('phase at wc = %+.2f deg\n', phi_L_wc);
fprintf('natural PM  = %+.2f deg  (spec %d)\n', gamma_M_natural, gamma_M_spec);
if gamma_M_natural >= gamma_M_spec
    fprintf('-> no Lead needed\n\n');
else
    fprintf('-> Lead required\n\n');
end

% Plot 3: combined Bode with wc marker and the "PM line" (-180+gamma_M).
% If the phase curve is ABOVE the green dashed line at wc, we have margin.
figure(192); clf
bode(C_PI_shape*Gvel_day5, {0.1, 1000});
grid on;
ax_all = findall(gcf, 'type', 'axes');
% findall returns axes most-recent-first; for bode that is [phase, mag].
phase_ax = ax_all(1);
mag_ax   = ax_all(2);
xline(mag_ax,   wc_wv, 'r--', sprintf('\\omega_c = %g', wc_wv));
xline(phase_ax, wc_wv, 'r--', sprintf('\\omega_c = %g', wc_wv));
yline(phase_ax, -180 + gamma_M_spec, 'g--', ...
      sprintf('-180+%d°  (= %d° PM line)', gamma_M_spec, gamma_M_spec));
title(mag_ax, 'Step 4: phase at \omega_c vs PM line tells us if Lead is needed');
saveas(gcf, fullfile(IMG_DIR, 'regbot_task1_step4_phase_balance.png'));


%% ====================== STEP 5 — SOLVE Kp ===============================
% Kp is a flat (frequency-independent) gain — it lifts the entire
% magnitude curve uniformly without touching phase. Pick Kp so the
% magnitude crosses 1 (= 0 dB) at exactly wc.
Kp_wv = 1 / magL_unscaled;

fprintf('|L|_unscaled = %.4f at wc\n', magL_unscaled);
fprintf('Kp = 1/|L|   = %.4f\n\n',     Kp_wv);

C_wv = Kp_wv * C_PI_shape;
L_wv = C_wv * Gvel_day5;
print_tf('C_wv', C_wv);


%% ====================== STEP 6 — VERIFY =================================
% margin() recomputes wc, GM, PM from the open-loop L. If everything
% above is consistent, the printed wc matches the spec and PM matches
% the Step 4 prediction.
[GM, PM, ~, wc_ach] = margin(L_wv);

fprintf('wc = %.2f rad/s\n', wc_ach);
fprintf('PM = %.2f deg\n',   PM);
fprintf('GM = %.2f dB\n\n',  20*log10(GM));

save_plot(figure(200), @() margin(L_wv), ...
    'Step 6: Open-loop Bode  L = C_{wv} G_{vel}', ...
    IMG_DIR, 'regbot_task1_bode.png');

save_plot(figure(201), @() step(feedback(L_wv, 1), 0.5), ...
    'Step 6: Closed-loop step response  (T = L/(1+L))', ...
    IMG_DIR, 'regbot_task1_step.png');


%% ------------------- Write to workspace + gains block ------------------
% Push to base workspace so Simulink reads them immediately.
Kpwv  = Kp_wv;
tiwv  = tau_i_wv;
Kffwv = 0;

fprintf('Kpwv  = %.4f;\n',  Kpwv);
fprintf('tiwv  = %.4f;\n',  tiwv);
fprintf('Kffwv = %d;\n\n',  Kffwv);
