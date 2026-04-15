%% =======================================================================
%  Task 2 — Balance controller (Lecture 10, Method 2)
%  =======================================================================
%
%  Plant:    G_tilt(s) = vel_ref -> tilt angle
%            Identified from regbot_1mg.slx via linearize().
%            7th order, 1 RHP pole at +8.7 rad/s (inverted pendulum).
%
%  Method 2 (Lecture 10 slide 13) steps:
%     Step 1 : Nyquist sign-check on G_tilt  ->  sign(K_PS)
%     Step 2 : Post-integrator  tau_i,post = 1/w_peak of |G_tilt|
%              Stabilised plant   G_tilt,post = sign(K_PS)*C_PI,post*G_tilt
%     Step 3 : Outer PI-Lead on G_tilt,post
%                3a. tau_i = N_i/wc
%                3b. phi_Lead from phase balance
%                3c. tau_d  = tan(phi_Lead)/wc           (gyro shortcut)
%                3d. Kp     from |L(j wc)| = 1
%     Step 4 : Verify — closed-loop poles, margins, regulation response
%
%  Run this script on its own. It loads the workspace via regbot_mg,
%  overrides Kptilt = 0 to break the balance loop during linearisation,
%  does the full design, and prints a copy-pasteable "Task 2 gains" block.
%  =======================================================================

close all; clear;

% --- Load workspace ------------------------------------------------------
% regbot_mg populates physical params + committed gains. It also addpaths
% its own folder, so every helper (print_tf, identify_tf, ...) resolves.
addpath(fileparts(mfilename('fullpath')));
regbot_mg;

s       = tf('s');
model   = 'regbot_1mg';
IMG_DIR = pick_image_dir();


%% ------------------ Preamble: plant identification ---------------------
% Open the balance loop before linearising so G_tilt is the true plant
% from vel_ref to tilt angle (not a partially closed loop).
Kptilt = 0;     %#ok<NASGU>  % breaks the balance loop at the Kptilt gain
tdtilt = 0;     %#ok<NASGU>  % silences the gyro Lead path
titilt = 1;     %#ok<NASGU>  % benign TF placeholder
tipost = 1;     %#ok<NASGU>  % benign TF placeholder

load_system(model);
open_system(model);

Gwv   = identify_tf(model, '/Limit9v', '/wheel_vel_filter');
Gtilt = identify_tf(model, '/vel_ref', '/robot with balance');

fprintf('==============================================================\n');
fprintf('  Plant identification (linearize with balance loop open)\n');
fprintf('==============================================================\n');
fprintf('  Gwv(s)   = voltage -> wheel velocity\n');
print_tf('Gwv', Gwv);
describe_plant(Gwv);

fprintf('  Gtilt(s) = vel_ref -> tilt angle\n');
print_tf('Gtilt', Gtilt);
describe_plant(Gtilt);

% Plant-ID plots (used in the report + Obsidian doc)
save_plot(figure(100), @() bode(Gwv), ...
    'G_{wv}: voltage -> wheel velocity', ...
    IMG_DIR, 'regbot_Gwv_bode.png');

save_plot(figure(101), @() bode(Gtilt), ...
    'G_{tilt}: vel_{ref} -> tilt angle', ...
    IMG_DIR, 'regbot_Gtilt_bode.png');

figure(102); plot_pz_stability(Gwv,   'Gwv');
saveas(gcf, fullfile(IMG_DIR, 'regbot_Gwv_pzmap.png'));
figure(103); plot_pz_stability(Gtilt, 'Gtilt');
saveas(gcf, fullfile(IMG_DIR, 'regbot_Gtilt_pzmap.png'));
figure(104); plot_pz_stability(Gwv,   'Gwv (zoomed)');
xlim([-50 50]); ylim([-50 50]);
saveas(gcf, fullfile(IMG_DIR, 'regbot_Gwv_pzmap_zoom.png'));
figure(105); plot_pz_stability(Gtilt, 'Gtilt (zoomed)');
xlim([-50 50]); ylim([-50 50]);
saveas(gcf, fullfile(IMG_DIR, 'regbot_Gtilt_pzmap_zoom.png'));
figure(106); plot_nyquist_critical(Gtilt, 'Gtilt');
saveas(gcf, fullfile(IMG_DIR, 'regbot_Gtilt_nyquist.png'));


%% =========================================================================
%  Lecture 10, Method 2
%  =========================================================================
fprintf('\n==============================================================\n');
fprintf('  Task 2 — Lecture 10 Method 2 design\n');
fprintf('==============================================================\n');
fprintf('  Plant:        Gtilt(s) = vel_ref -> tilt angle\n');
fprintf('  RHP poles:    P = %d  (inverted-pendulum falling mode)\n', ...
        sum(real(pole(Gtilt))>0));
fprintf('  Nyquist req.: Z = N + P = 0  =>  need N = -%d  (CCW around -1)\n\n', ...
        sum(real(pole(Gtilt))>0));


%% ---- Step 1: Nyquist sign-check ---------------------------------------
% The DC-gain sign + RHP-pole count fix the sign of K_PS. A positive DC
% gain combined with P = 1 means no positive K_PS can produce a CCW
% encirclement -> absorb a minus sign into the post-integrator.
w_grid = logspace(-2, 4, 4000);
[mag_g, phi_g] = bode(Gtilt, w_grid);
mag_g = squeeze(mag_g); phi_g = squeeze(phi_g);
dc    = dcgain(Gtilt);

fprintf('---- Step 1: Sign check ---------------------------------------\n');
fprintf('  DC gain of Gtilt         = %+.3e\n', dc);
if dc > 0
    sign_K = -1;
    fprintf('  DC gain > 0 AND P = 1    =>  need sign(K_PS) = -1\n');
    fprintf('  (positive K_PS alone cannot produce the required CCW encirclement)\n\n');
else
    sign_K = +1;
    fprintf('  DC gain < 0              =>  sign(K_PS) = +1 may suffice\n\n');
end


%% ---- Step 2: Post-integrator design -----------------------------------
% Place the PI zero at the magnitude peak of |Gtilt| so that the combined
% |G_tilt,post| is monotonically decreasing beyond the peak.
[mag_peak, k_peak] = max(mag_g);
w_ip       = w_grid(k_peak);
tau_ip     = 1 / w_ip;

C_PI_post  = (tau_ip*s + 1) / (tau_ip*s);
Gtilt_post = sign_K * C_PI_post * Gtilt;

fprintf('---- Step 2: Post-integrator ----------------------------------\n');
fprintf('  |Gtilt|_max              = %.4f  at  w_peak = %.3f rad/s\n', mag_peak, w_ip);
fprintf('  tau_i,post = 1/w_peak    = %.4f s\n', tau_ip);
fprintf('  C_PI,post(s)             = (%.4f s + 1) / (%.4f s)\n', tau_ip, tau_ip);
print_tf('C_PI_post', C_PI_post);
fprintf('  Stabilised plant         : Gtilt,post = (%+d)*C_PI,post*Gtilt\n', sign_K);
print_tf('Gtilt_post', minreal(Gtilt_post));
fprintf('  RHP poles of Gtilt,post  : %d  (outer loop will close this)\n\n', ...
        sum(real(pole(minreal(Gtilt_post)))>0));

save_plot(figure(300), @() bode(Gtilt, Gtilt_post, w_grid), ...
    'Task 2 Step 2: G_{tilt} before (blue) vs. after (orange) post-integrator', ...
    IMG_DIR, 'regbot_task2_bode_post.png');
legend('G_{tilt}(s)', '-C_{PI,post}(s) G_{tilt}(s)', 'Location', 'best');
saveas(gcf, fullfile(IMG_DIR, 'regbot_task2_bode_post.png'));

figure(301); plot_nyquist_critical(Gtilt_post, 'G_{tilt,post}');
saveas(gcf, fullfile(IMG_DIR, 'regbot_task2_nyquist_post.png'));


%% ---- Step 3: Outer PI-Lead on Gtilt_post ------------------------------
% 3a. Specs
wc_tilt  = 15;           % target crossover [rad/s]
gamma_M  = 60;           % phase margin spec [deg]
Ni_tilt  = 3;            % PI zero at wc/Ni

fprintf('---- Step 3: Outer PI-Lead on G_{tilt,post} -------------------\n');
fprintf('  3a. Specs:           wc = %.1f rad/s   gamma_M = %.0f deg   Ni = %d\n\n', ...
        wc_tilt, gamma_M, Ni_tilt);

% 3b. I-part (outer PI)
tau_i_tilt = Ni_tilt / wc_tilt;
C_PI_tilt  = (tau_i_tilt*s + 1) / (tau_i_tilt*s);

fprintf('  3b. I-part (outer PI):\n');
fprintf('      tau_i = Ni/wc        = %.4f s\n', tau_i_tilt);
fprintf('      C_PI(s)              = (%.4f s + 1) / (%.4f s)\n\n', tau_i_tilt, tau_i_tilt);

% 3c. Phase balance at wc
[~, phi_G]  = bode(Gtilt_post, wc_tilt);
phi_PI      = -atand(1/Ni_tilt);
phi_Lead    = -180 + gamma_M - phi_G - phi_PI;

fprintf('  3c. Phase balance at wc = %.1f rad/s:\n', wc_tilt);
fprintf('      phi_Gtilt,post(j wc) = %+7.2f deg\n', phi_G);
fprintf('      phi_PI(j wc)         = %+7.2f deg    (= -atan(1/Ni))\n', phi_PI);
fprintf('      phi_Lead required    = %+7.2f deg    (= -180 + gamma_M - phi_G - phi_PI)\n\n', phi_Lead);

% 3d. Lead from gyro
if phi_Lead <= 0
    tau_d  = 0;  C_Lead = tf(1);
    lead_note = 'no Lead needed (phase margin already met)';
elseif phi_Lead >= 89
    tau_d  = NaN; C_Lead = tf(1);
    lead_note = sprintf('WARN: phi_Lead = %.1f deg too high — lower wc or cascade Leads', phi_Lead);
else
    tau_d  = tand(phi_Lead) / wc_tilt;
    C_Lead = tau_d*s + 1;
    lead_note = 'gyro-based ideal Lead (tau_d*gyro + theta)';
end

fprintf('  3d. Lead part (gyro shortcut):\n');
fprintf('      tau_d = tan(phi_Lead)/wc = %.4f s\n', tau_d);
fprintf('      C_Lead(s)            = %.4f s + 1       (%s)\n\n', tau_d, lead_note);

% 3e. Loop gain
magL    = squeeze(bode(C_PI_tilt * C_Lead * Gtilt_post, wc_tilt));
Kp_tilt = 1 / magL;

fprintf('  3e. Loop gain:\n');
fprintf('      |C_PI * C_Lead * Gtilt,post|_{wc} = %.4f\n', magL);
fprintf('      Kp = 1 / |.|         = %.4f\n\n', Kp_tilt);

% Full controller (for inspection / report)
C_outer_tilt = Kp_tilt * C_PI_tilt * C_Lead;
L_tilt       = C_outer_tilt * Gtilt_post;
C_total_tilt = Kp_tilt * sign_K * C_PI_post * C_PI_tilt * C_Lead;

fprintf('  Full tilt controller:\n');
fprintf('    C_total(s) = Kp * (%+d) * C_PI,post(s) * C_PI(s) * (tau_d s + 1)\n\n', sign_K);
print_tf('C_outer = Kp * C_PI * C_Lead', C_outer_tilt);
print_tf('C_total (full cascade, vel_ref command)', minreal(C_total_tilt));


%% ---- Step 4: Closed-loop verification ---------------------------------
T_tilt   = feedback(L_tilt, 1);
cl_poles = pole(minreal(T_tilt));
rhp_cl   = sum(real(cl_poles) > 0);
[GMt, PMt, ~, wct_ach] = margin(L_tilt);

fprintf('---- Step 4: Closed-loop verification -------------------------\n');
fprintf('  margin(L_tilt):\n');
fprintf('    Achieved wc           = %.2f rad/s   (target %.1f)\n', wct_ach, wc_tilt);
fprintf('    Phase margin          = %.2f deg     (target %.0f)\n', PMt, gamma_M);
fprintf('    Gain margin           = %.2f dB      (negative is OK when P=1:\n', 20*log10(GMt));
fprintf('                                          lower bound of stable K)\n');
fprintf('  Closed-loop poles (real parts, sorted):\n');
fprintf('    '); fprintf('%+7.2f  ', sort(real(cl_poles))); fprintf('\n');
fprintf('  RHP closed-loop poles   = %d   %s\n\n', rhp_cl, ...
        ternary(rhp_cl==0, '(stable ✓)', '(UNSTABLE — redesign)'));

save_plot(figure(302), @() margin(L_tilt), ...
    'Task 2 Step 4: Open-loop  L = K_P C_{PI} C_{Lead} G_{tilt,post}', ...
    IMG_DIR, 'regbot_task2_loop_bode.png');

save_plot(figure(303), @() step(T_tilt, 2), ...
    'Task 2 Step 4: Closed-loop step (reference tracking)', ...
    IMG_DIR, 'regbot_task2_step.png');

% Linear-model regulation response (proxy for IC release)
theta0 = deg2rad(10);
t_ic   = linspace(0, 2, 2001);
S_tilt = feedback(1, L_tilt);
[y_dist, t_out] = step(theta0 * S_tilt, t_ic);

figure(304); clf;
plot(t_out, rad2deg(y_dist), 'b', 'LineWidth',1.4); grid on
xlabel('Time [s]'); ylabel('Pitch [deg]');
title('Task 2 Step 4: Linear-model regulation from \theta_0 = 10° output disturbance');
yline(0,'k:');
saveas(gcf, fullfile(IMG_DIR, 'regbot_task2_ic_response.png'));

abs_env  = abs(y_dist);
settle_i = find(abs_env > 0.02*theta0, 1, 'last');
settle_t = t_out(settle_i);
peak_us  = max(-y_dist);
fprintf('  Linear-model regulation (theta_0 = 10 deg output disturbance):\n');
fprintf('    Settling time (2%% env.) = %.2f s\n', settle_t);
fprintf('    Peak undershoot         = %.2f deg\n', rad2deg(peak_us));
fprintf('    Authoritative IC test   : Simulink, startAngle = 10\n');
fprintf('                              (regbot_task2_sim_recovery_10deg.png)\n\n');


%% ------------------- Write to workspace + gains block ------------------
Kptilt = Kp_tilt;
titilt = tau_i_tilt;
tdtilt = tau_d;
tipost = tau_ip;

fprintf('==============================================================\n');
fprintf('  Copy-paste this block into regbot_mg.m (Task 2 gains)\n');
fprintf('==============================================================\n');
fprintf('    Kptilt = %.4f;\n', Kptilt);
fprintf('    titilt = %.4f;\n', titilt);
fprintf('    tdtilt = %.4f;\n', tdtilt);
fprintf('    tipost = %.4f;\n\n', tipost);
