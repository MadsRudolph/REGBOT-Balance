%% Task 1 — Wheel-speed PI controller design
%  Plant:  Gvel(s) = 2.198/(s+5.985)  (Day 5 on-floor 1-pole tfest fit)
%  Specs:  wc = 30 rad/s, gamma_M >= 60 deg, Ni = 3.

close all; clear;

addpath(fileparts(mfilename('fullpath')));
regbot_mg;

s = tf('s');


%% ====== STEP 1 — INSPECT THE PLANT =====
mat_path = fullfile(fileparts(mfilename('fullpath')), '..', 'data', ...
    'Day5_results_v2.mat');
S         = load(mat_path, 'G_1p_avg');
Gvel_day5 = S.G_1p_avg;

p_plant = pole(Gvel_day5);
K_DC    = dcgain(Gvel_day5);
omega_b = -p_plant(1);          % break frequency [rad/s]
tau_p   = 1/omega_b;            % time constant   [s]

print_tf('Gvel_day5', Gvel_day5);
fprintf('DC gain = %.4f (m/s)/V\n', K_DC);
fprintf('break   = %.3f rad/s\n', omega_b);
fprintf('tau     = %.3f s\n\n', tau_p);


%% ====== STEP 2 — PICK SPECS =====
wc_wv        = 30;       % target crossover [rad/s]
gamma_M_spec = 60;       % phase margin spec [deg]
Ni_wv        = 3;        % PI zero at wc/Ni

fprintf('wc = %d rad/s, gamma_M = %d deg, Ni = %d\n\n', ...
    wc_wv, gamma_M_spec, Ni_wv);


%% ====== STEP 3 — PLACE THE PI ZERO =====
% PI zero at wc/Ni. Phase at wc: arctan(Ni) - 90 = -18.4 deg (Ni = 3).
tau_i_wv   = Ni_wv / wc_wv;
C_PI_shape = (tau_i_wv*s + 1) / (tau_i_wv*s);   % PI with Kp = 1

fprintf('tau_i = Ni/wc = %.4f s   (PI zero at %.2f rad/s)\n\n', ...
    tau_i_wv, 1/tau_i_wv);


%% ====== STEP 4 — PHASE BALANCE =====
% If natural PM >= spec, no Lead is needed.
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


%% ====== STEP 5 — SOLVE Kp =====
% Kp from the magnitude condition |L(jwc)| = 1 (flat gain).
Kp_wv = 1 / magL_unscaled;

fprintf('|L|_unscaled = %.4f at wc\n', magL_unscaled);
fprintf('Kp = 1/|L|   = %.4f\n\n',     Kp_wv);

C_wv = Kp_wv * C_PI_shape;
L_wv = C_wv * Gvel_day5;
print_tf('C_wv', C_wv);


%% ====== STEP 6 — VERIFY =====
[GM, PM, ~, wc_ach] = margin(L_wv);

fprintf('wc = %.2f rad/s\n', wc_ach);
fprintf('PM = %.2f deg\n',   PM);
fprintf('GM = %.2f dB\n\n',  20*log10(GM));


%% ------------------- Write to workspace + gains block ------------------
Kpwv  = Kp_wv;
tiwv  = tau_i_wv;
Kffwv = 0;

fprintf('Kpwv  = %.4f;\n',  Kpwv);
fprintf('tiwv  = %.4f;\n',  tiwv);
fprintf('Kffwv = %d;\n\n',  Kffwv);
