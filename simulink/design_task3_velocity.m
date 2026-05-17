%% Task 3 — Velocity outer loop (PI)
%  Plant:  Gvel,outer(s) = theta_ref -> wheel_vel_filter (Tasks 1+2 closed).
%          Stable; RHP zero at +8.5 rad/s sets a bandwidth ceiling.
%  Specs:  wc = 1 rad/s (< z/5), gamma_M >= 60 deg, Ni = 3.
%  Prereq: Tasks 1+2 gains committed in regbot_mg.m.

close all; clear;

addpath(fileparts(mfilename('fullpath')));
regbot_mg;

s     = tf('s');
model = 'regbot_1mg';

VEL_CTRL_OUT_BLOCK = '/Kpvel_gain';   % linearisation break point


%% ====== STEP 0 — IDENTIFY THE PLANT =====
% Break the velocity loop at Kpvel_gain; Tasks 1+2 stay closed.
Kpvel = 0;     %#ok<NASGU> breaks velocity loop for linearisation
tivel = 1;     %#ok<NASGU> benign placeholder

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

% Tasks 1+2 stabilised the falling mode, so Gvel,outer has 0 RHP poles,
% but a non-minimum-phase RHP zero (~ +8.5 rad/s) survives and caps the
% achievable bandwidth.
print_tf('Gvel_outer', Gvel_outer);
fprintf('Poles:  '); fprintf('%7.2f  ', sort(real(pole(Gvel_outer)))); fprintf('\n');
fprintf('Zeros:  '); fprintf('%7.2f  ', sort(real(zero(Gvel_outer)))); fprintf('\n');
fprintf('DC gain   = %.4e\n', dcgain(Gvel_outer));
fprintf('RHP poles = %d\n', P_count);
fprintf('RHP zero at: '); fprintf('%+.3f  ', real(rhp_z)); fprintf('rad/s\n\n');


%% ====== STEP 1 — PICK SPECS =====
% wc bounded by RHP-zero rule wc <= z/5 ~= 1.7 (tighter than the cascade
% rule 15/5 = 3); pick wc = 1.
wc_vel       = 1;        % target crossover [rad/s]
gamma_M_spec = 60;       % phase margin spec [deg]
Ni_vel       = 3;        % PI zero at wc/Ni

z_min  = min(real(rhp_z));   % RHP zero ~ +8.5 rad/s
wc_max = z_min / 5;          % bandwidth ceiling ~ 1.7 rad/s

fprintf('wc = %.2f rad/s (z/5 = %.2f), gamma_M = %.0f deg, Ni = %d\n\n', ...
    wc_vel, wc_max, gamma_M_spec, Ni_vel);


%% ====== STEP 2 — PLACE PI ZERO =====
tau_i_vel = Ni_vel / wc_vel;
C_PI_vel  = (tau_i_vel*s + 1) / (tau_i_vel*s);

fprintf('tau_i = Ni/wc = %.4f s   (PI zero at %.4f rad/s)\n\n', ...
    tau_i_vel, 1/tau_i_vel);


%% ====== STEP 3 — PHASE BALANCE =====
[magL_unscaled, phi_G_unwrapped] = bode(C_PI_vel * Gvel_outer, wc_vel);
magL_unscaled    = squeeze(magL_unscaled);
phi_G_unwrapped  = squeeze(phi_G_unwrapped);

% High-order plant: unwrap can add +360 before wc; wrap to [-180,180].
% Natural PM comes out +68.98 deg, above the 60 deg spec, so no Lead is
% needed -- the controller is a pure PI.
phi_L_phys      = mod(phi_G_unwrapped + 180, 360) - 180;
gamma_M_natural = 180 + phi_L_phys;
phi_PI          = -atand(1/Ni_vel);

fprintf('phase wrapped = %+.2f deg\n', phi_L_phys);
fprintf('phi_PI        = %+.2f deg\n', phi_PI);
fprintf('natural PM    = %+.2f deg  (spec %d) -> no Lead, pure PI\n\n', ...
    gamma_M_natural, gamma_M_spec);


%% ====== STEP 4 — SOLVE Kp =====
% Magnitude condition: Kp = 1/|L| at wc. Here |L| > 1 (loud plant from
% Task 2's free integrator), so Kp comes out < 1.
Kp_vel = 1 / magL_unscaled;

fprintf('|L|_unscaled = %.4f at wc  (%+.2f dB)\n', ...
    magL_unscaled, 20*log10(magL_unscaled));
fprintf('Kp = 1/|L|   = %.4f\n\n', Kp_vel);

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

figure; margin(L_vel);  grid on; title('Task 3: open-loop L_{vel} (margins)');
figure; step(T_vel, 5); grid on; title('Task 3: closed-loop step (v_{ref} = 1 m/s)');


%% ------------------- Write to workspace + gains block ------------------
Kpvel = Kp_vel;
tivel = tau_i_vel;

fprintf('Kpvel  = %.4f;\n',   Kpvel);
fprintf('tivel  = %.4f;\n\n', tivel);
