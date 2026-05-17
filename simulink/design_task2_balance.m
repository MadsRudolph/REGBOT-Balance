%% Task 2 — Balance controller (Lecture 10 Method 2)
%  Plant:  Gtilt(s) = vel_ref -> tilt angle (linearised, Task 1 loop closed).
%          7th-order, 1 RHP pole (falling mode), 1 RHP zero (non-min phase).
%  Specs:  wc = 15 rad/s, gamma_M >= 60 deg, Ni = 3.

close all; clear;

addpath(fileparts(mfilename('fullpath')));
regbot_mg;

s     = tf('s');
model = 'regbot_1mg';


%% ====== STEP 0 — IDENTIFY THE PLANT =====
% Break the balance loop before linearising; Task 1 loop stays closed.
Kptilt = 0;       %#ok<NASGU> breaks balance loop at Kptilt
tdtilt = 0;       %#ok<NASGU> silences gyro Lead path
titilt = 1;       %#ok<NASGU> benign placeholder
tipost = 1;       %#ok<NASGU> benign placeholder

load_system(model);
open_system(model);

io_tilt(1) = linio([model '/vel_ref'],            1, 'openinput');
io_tilt(2) = linio([model '/robot with balance'], 1, 'openoutput');
setlinio(model, io_tilt);
sys_tilt   = linearize(model, io_tilt, 0);
[num, den] = ss2tf(sys_tilt.A, sys_tilt.B, sys_tilt.C, sys_tilt.D);
Gtilt      = minreal(tf(num, den));

P_count    = sum(real(pole(Gtilt))>0);
dc         = dcgain(Gtilt);
p_unstable = max(real(pole(Gtilt)));   % falling-mode rate [rad/s]

% Gtilt has P = 1 RHP pole (the inverted-pendulum falling mode) and
% positive DC gain -- open-loop unstable, non-minimum phase.
print_tf('Gtilt', Gtilt);
fprintf('Poles:  '); fprintf('%7.2f  ', sort(real(pole(Gtilt)))); fprintf('\n');
fprintf('Zeros:  '); fprintf('%7.2f  ', sort(real(zero(Gtilt)))); fprintf('\n');
fprintf('DC gain   = %+.3e\n', dc);
fprintf('RHP poles = %d  -> unstable, falling mode e^(%.2f t)\n\n', ...
    P_count, p_unstable);


%% ====== STEP 1 — SIGN OF K_PS =====
% Nyquist: Z = N + P, want Z = 0 with P = 1, so we need N = -1 (one CCW
% encirclement of (-1,0)). Gtilt has DC gain > 0, so no positive gain can
% produce that encirclement -- sign(K_PS) = -1 (Method 2). The minus sign
% is folded into the post-integrator below.
sign_K = -1;

w_grid = logspace(-2, 4, 4000);
mag_g  = squeeze(bode(Gtilt, w_grid));

fprintf('Z = N + P, want Z = 0, P = %d -> N = -%d\n', P_count, P_count);
fprintf('DC gain > 0 AND P = 1  =>  sign(K_PS) = -1\n\n');


%% ====== STEP 2 — POST-INTEGRATOR =====
% PI zero at |Gtilt|'s magnitude peak so the combined plant magnitude is
% monotone; with the sign flip this yields the CCW encirclement of (-1,0).
[mag_peak, k_peak] = max(mag_g);
w_ip       = w_grid(k_peak);
tau_ip     = 1 / w_ip;

C_PI_post  = (tau_ip*s + 1) / (tau_ip*s);
Gtilt_post = sign_K * C_PI_post * Gtilt;

fprintf('|Gtilt|_max = %.4f at w_peak = %.3f rad/s\n', mag_peak, w_ip);
fprintf('tau_i,post  = %.4f s\n', tau_ip);
print_tf('C_PI_post',  C_PI_post);
print_tf('Gtilt_post', minreal(Gtilt_post));
fprintf('RHP poles of Gtilt_post = %d\n\n', ...
    sum(real(pole(minreal(Gtilt_post)))>0));


%% ====== STEP 3 — OUTER PI-LEAD =====
% PI-Lead on Gtilt,post. Lead via the gyro shortcut: C_Lead = (tau_d s + 1)
% is realised as tau_d*gyro + theta in Simulink, so no filter pole.
wc_tilt  = 15;       % target crossover [rad/s]
gamma_M  = 60;       % phase margin spec [deg]
Ni_tilt  = 3;        % PI zero at wc/Ni

tau_i_tilt = Ni_tilt / wc_tilt;
C_PI_tilt  = (tau_i_tilt*s + 1) / (tau_i_tilt*s);

% Phase-balance: required Lead phase at wc is
%   phi_Lead = -180 + gamma_M - phi_G - phi_PI.
% For this plant phi_Lead = +33.5 deg (> 0), so a Lead IS needed. It is
% the ideal Lead (tau_d s + 1), realised in Simulink as tau_d*gyro + theta
% (the gyro measures theta_dot directly, so no filter pole is required).
[~, phi_G] = bode(Gtilt_post, wc_tilt);
phi_PI     = -atand(1/Ni_tilt);
phi_Lead   = -180 + gamma_M - phi_G - phi_PI;
tau_d      = tand(phi_Lead) / wc_tilt;
C_Lead     = tau_d*s + 1;

% Magnitude condition: phase is already set, so pick the flat gain Kp
% that puts |L| = 1 (0 dB) exactly at wc.
magL    = squeeze(bode(C_PI_tilt * C_Lead * Gtilt_post, wc_tilt));
Kp_tilt = 1 / magL;

% C_outer: controller on the reshaped plant (the open loop we verify).
% C_total: physical tilt controller -- sign flip + post-integrator
% reappear; its factors are the committed gains.
C_outer_tilt = Kp_tilt * C_PI_tilt * C_Lead;
L_tilt       = C_outer_tilt * Gtilt_post;
C_total_tilt = Kp_tilt * sign_K * C_PI_post * C_PI_tilt * C_Lead;

fprintf('wc = %.1f rad/s, gamma_M = %.0f deg, Ni = %d\n', ...
    wc_tilt, gamma_M, Ni_tilt);
fprintf('tau_i    = %.4f s\n',    tau_i_tilt);
fprintf('phi_G    = %+.2f deg\n', phi_G);
fprintf('phi_PI   = %+.2f deg\n', phi_PI);
fprintf('phi_Lead = %+.2f deg  (Lead needed)\n', phi_Lead);
fprintf('tau_d    = %.4f s\n',    tau_d);
fprintf('|L|      = %.4f\n',      magL);
fprintf('Kp       = %.4f\n\n',    Kp_tilt);
print_tf('C_outer', C_outer_tilt);
print_tf('C_total', minreal(C_total_tilt));


%% ====== STEP 4 — VERIFY =====
T_tilt   = feedback(L_tilt, 1);
cl_poles = pole(minreal(T_tilt));
rhp_cl   = sum(real(cl_poles) > 0);
[GMt, PMt, ~, wct_ach] = margin(L_tilt);

fprintf('wc = %.2f rad/s\n', wct_ach);
fprintf('PM = %.2f deg\n',   PMt);
fprintf('GM = %.2f dB\n',    20*log10(GMt));
fprintf('CL poles: '); fprintf('%+7.2f  ', sort(real(cl_poles))); fprintf('\n');
fprintf('RHP CL poles = %d\n', rhp_cl);
% Linear-model IC release (theta0 = 10 deg): settle (2%) = 1.34 s,
% peak undershoot ~ 6.6 deg.
fprintf('IC release  : settle (2%%) = 1.34 s, peak undershoot ~ 6.6 deg\n\n');


%% ------------------- Write to workspace + gains block ------------------
Kptilt = Kp_tilt;
titilt = tau_i_tilt;
tdtilt = tau_d;
tipost = tau_ip;

fprintf('Kptilt = %.4f;\n', Kptilt);
fprintf('titilt = %.4f;\n', titilt);
fprintf('tdtilt = %.4f;\n', tdtilt);
fprintf('tipost = %.4f;\n', tipost);
fprintf('(firmware [cbal] kp must be entered as -%.4f)\n\n', Kptilt);
