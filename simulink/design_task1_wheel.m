%% =======================================================================
%  Task 1 — Wheel-speed PI controller design
%  =======================================================================
%
%  Plant:    G_vel(s) = 13.34 / (s + 35.71)          (Day 5 black-box ID)
%  Specs:    wc = 30 rad/s,  gamma_M >= 60 deg,  Ni = 3
%  Method:   Place PI zero at wc/Ni; pick Kp so |L(j wc)| = 1.
%
%  Run this script on its own. It loads the workspace via regbot_mg,
%  designs the controller, prints every intermediate value, generates
%  the Bode + closed-loop-step plots, and finishes with a copy-pasteable
%  "Task 1 gains" block you paste back into regbot_mg.m.
%  =======================================================================

close all; clear;

% --- Load workspace ------------------------------------------------------
% regbot_mg populates physical params + committed gains. It also addpaths
% its own folder, so every helper (print_tf, pick_image_dir, ...) resolves.
addpath(fileparts(mfilename('fullpath')));
regbot_mg;

s       = tf('s');
IMG_DIR = pick_image_dir();


%% ----------------------------- Plant -----------------------------------
Gvel_day5 = 13.34 / (s + 35.71);

fprintf('==============================================================\n');
fprintf('  Task 1 plant: Gvel_day5(s) = voltage -> wheel velocity\n');
fprintf('==============================================================\n');
print_tf('Gvel_day5', Gvel_day5);
fprintf('  DC gain = %.3f (m/s)/V   pole = %.2f rad/s   tau = %.3f s\n\n', ...
        dcgain(Gvel_day5), pole(Gvel_day5), 1/35.71);


%% ----------------------------- Design ----------------------------------
% Specs
wc_wv        = 30;       % target crossover [rad/s]
gamma_M_spec = 60;       % phase margin spec [deg]
Ni_wv        = 3;        % PI zero at wc/Ni

% PI zero placement (shape without gain)
tau_i_wv     = Ni_wv / wc_wv;
C_wv_shape   = (tau_i_wv*s + 1) / (tau_i_wv*s);

% Kp so |L(j wc)| = 1
magL_wc      = squeeze(bode(C_wv_shape * Gvel_day5, wc_wv));
Kp_wv        = 1 / magL_wc;

% Full controller + loop
C_wv         = Kp_wv * C_wv_shape;
L_wv         = C_wv * Gvel_day5;

[GM, PM, ~, wc_ach] = margin(L_wv);

fprintf('---- Design (specs: wc = %.1f rad/s, gamma_M >= %.0f deg, Ni = %d) ----\n', ...
        wc_wv, gamma_M_spec, Ni_wv);
fprintf('  tau_i = Ni/wc          = %.4f s\n', tau_i_wv);
fprintf('  |C_shape * G|_{wc}     = %.4f\n',   magL_wc);
fprintf('  Kp = 1/|.|             = %.4f\n\n', Kp_wv);
print_tf('C_wv = Kp * (tau_i s + 1)/(tau_i s)', C_wv);

fprintf('---- Verification ---------------------------------------------\n');
fprintf('  Achieved wc            = %.2f rad/s   (target %.1f)\n', wc_ach, wc_wv);
fprintf('  Phase margin           = %.2f deg     (target >= %.0f)\n', PM, gamma_M_spec);
fprintf('  Gain margin            = %.2f dB\n\n', 20*log10(GM));


%% ----------------------------- Plots -----------------------------------
save_plot(figure(200), @() margin(L_wv), ...
    'Task 1: Open-loop Bode  L = C_{wv} G_{vel,day5}', ...
    IMG_DIR, 'regbot_task1_bode.png');

save_plot(figure(201), @() step(feedback(L_wv, 1), 0.5), ...
    'Task 1: Closed-loop step response (wheel speed)', ...
    IMG_DIR, 'regbot_task1_step.png');


%% ------------------- Write to workspace + gains block ------------------
% Push to base workspace so Simulink can read them immediately (this lets
% you try the new design in Simulink before committing it to regbot_mg.m).
Kpwv  = Kp_wv;
tiwv  = tau_i_wv;
Kffwv = 0;

fprintf('==============================================================\n');
fprintf('  Copy-paste this block into regbot_mg.m (Task 1 gains)\n');
fprintf('==============================================================\n');
fprintf('    Kpwv  = %.4f;\n',  Kpwv);
fprintf('    tiwv  = %.4f;\n',  tiwv);
fprintf('    Kffwv = %d;\n\n',  Kffwv);
