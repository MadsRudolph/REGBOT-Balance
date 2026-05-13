%% Task 3 — Velocity outer loop (PI)
%  Plant:  Gvel,outer(s) = theta_ref -> wheel_vel_filter (with Tasks 1+2
%          closed). Stable; RHP zero at +8.5 rad/s sets a bandwidth ceiling.
%  Specs:  wc_vel = 1 rad/s (< z/5), gamma_M >= 60 deg, Ni = 3.
%  Prereq: Tasks 1+2 gains pasted into regbot_mg.m; model has 'Kpvel_gain'.
%  See docs/MATLAB Walkthrough.md §4 for the derivation.

close all; clear;

addpath(fileparts(mfilename('fullpath')));
regbot_mg;

s       = tf('s');
model   = 'regbot_1mg';
IMG_DIR = pick_image_dir();

VEL_CTRL_OUT_BLOCK = '/Kpvel_gain';   % linearisation break point


%% ====== STEP 0 — IDENTIFY THE PLANT =====
% Linearise theta_ref -> wheel_vel_filter with the velocity loop broken at
% Kpvel_gain. Tasks 1+2 stay closed (non-zero gains in the workspace).
% Defensive zeroing in case someone edited regbot_mg:
Kpvel = 0;
tivel = 1;

load_system(model);
open_system(model);

io(1) = linio([model VEL_CTRL_OUT_BLOCK], 1, 'openinput');
io(2) = linio([model '/wheel_vel_filter'], 1, 'openoutput');
setlinio(model, io);
sys        = linearize(model, io, 0);
[num, den] = ss2tf(sys.A, sys.B, sys.C, sys.D);
Gvel_outer = minreal(tf(num, den));

P_count = sum(real(pole(Gvel_outer)) > 0);
z_all   = zero(Gvel_outer);
rhp_z   = z_all(real(z_all) > 0);

print_tf('Gvel_outer', Gvel_outer);

fprintf('Poles:  '); fprintf('%7.2f  ', sort(real(pole(Gvel_outer)))); fprintf('\n');
fprintf('Zeros:  '); fprintf('%7.2f  ', sort(real(zero(Gvel_outer)))); fprintf('\n');
fprintf('DC gain   = %.4e\n', dcgain(Gvel_outer));
fprintf('RHP poles = %d\n', P_count);
if ~isempty(rhp_z)
    fprintf('RHP zeros at: '); fprintf('%+7.3f  ', real(rhp_z)); fprintf('rad/s\n\n');
else
    fprintf('RHP zeros = 0\n\n');
end

%% ====== STEP 1 — PICK SPECS =====
% wc bounded by: (a) cascade rule wc <= 15/5 = 3 rad/s,
% (b) RHP-zero wc <= z/5 ~= 1.7 rad/s. (b) is tighter; pick wc = 1.
wc_vel       = 1;        % target crossover [rad/s]
gamma_M_spec = 60;       % phase margin spec [deg]
Ni_vel       = 3;        % PI zero at wc/Ni

if ~isempty(rhp_z)
    z_min = min(real(rhp_z));
    wc_max = z_min / 5;
else
    z_min = NaN;
    wc_max = Inf;
end

fprintf('wc      = %.2f rad/s  (z/5 = %.2f)\n', wc_vel, wc_max);
fprintf('gamma_M = %.0f deg\n', gamma_M_spec);
fprintf('Ni      = %d\n\n',     Ni_vel);


%% ====== STEP 2 — PLACE PI ZERO =====
tau_i_vel = Ni_vel / wc_vel;
C_PI_vel  = (tau_i_vel*s + 1) / (tau_i_vel*s);

fprintf('tau_i = Ni/wc = %.4f s   (PI zero at %.4f rad/s)\n\n', tau_i_vel, 1/tau_i_vel);


%% ====== STEP 3 — PHASE BALANCE =====
[magL_unscaled, phi_G_unwrapped] = bode(C_PI_vel * Gvel_outer, wc_vel);
magL_unscaled    = squeeze(magL_unscaled);
phi_G_unwrapped  = squeeze(phi_G_unwrapped);

% High-order plant: MATLAB's unwrap can add +360 deg before wc; wrap to
% [-180, 180] for the physical phase.
phi_L_phys = mod(phi_G_unwrapped + 180, 360) - 180;
gamma_M_natural = 180 + phi_L_phys;

phi_PI = -atand(1/Ni_vel);
% Plant-only phase = combined - PI contribution
phi_G_only = phi_L_phys - phi_PI;

phi_Lead = -180 + gamma_M_spec - phi_G_only - phi_PI;

fprintf('phase (raw)    = %+.2f deg\n', phi_G_unwrapped);
fprintf('phase wrapped  = %+.2f deg\n', phi_L_phys);
fprintf('plant-only     = %+.2f deg\n', phi_G_only);
fprintf('phi_PI         = %+.2f deg\n', phi_PI);
fprintf('natural PM     = %+.2f deg  (spec %d)\n', gamma_M_natural, gamma_M_spec);
if gamma_M_natural >= gamma_M_spec
    fprintf('-> no Lead needed\n\n');
else
    fprintf('-> Lead required\n\n');
end

%% ====== STEP 4 — SOLVE Kp =====
% Kp < 1: Gvel,outer is LOUD at wc (free integrator from Task 2's
% post-integrator), so the magnitude condition divides down.
Kp_vel = 1 / magL_unscaled;

fprintf('|L|_unscaled = %.4f at wc  (%+.2f dB)\n', magL_unscaled, 20*log10(magL_unscaled));
fprintf('Kp = 1/|L|   = %.4f\n\n',   Kp_vel);

C_vel = Kp_vel * C_PI_vel;
L_vel = C_vel * Gvel_outer;
T_vel = feedback(L_vel, 1);
print_tf('C_vel', C_vel);


%% ====== STEP 5 — VERIFY =====
[GM, PM, ~, wc_ach] = margin(L_vel);

fprintf('wc = %.2f rad/s\n', wc_ach);
fprintf('PM = %.2f deg\n',   PM);
fprintf('GM = %.2f dB\n',    20*log10(GM));
fprintf('RHP CL poles = %d\n\n', sum(real(pole(T_vel)) > 0));

save_plot(figure(400), @() margin(L_vel), ...
    'Open-loop  L = C_{vel} G_{vel,outer}', ...
    IMG_DIR, 'regbot_task3_loop_bode.png');

save_plot(figure(401), @() step(T_vel, 5), ...
    'Closed-loop step (v_{ref} = 1 m/s)', ...
    IMG_DIR, 'regbot_task3_step.png');


%% ------------------- Write to workspace + gains block ------------------
Kpvel = Kp_vel;
tivel = tau_i_vel;

fprintf('Kpvel  = %.4f;\n',   Kpvel);
fprintf('tivel  = %.4f;\n\n', tivel);
