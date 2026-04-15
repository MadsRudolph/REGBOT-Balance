%% =======================================================================
%  REGBOT Balance Assignment — Main MATLAB Script
%  =======================================================================
%
%  PURPOSE
%  -------
%  Design all four controllers for the REGBOT balance assignment and print
%  every transfer function so the team can follow each step.
%
%   Task 1 (STEP 3): Wheel-speed PI   — inner loop
%   Task 2 (STEP 6+7): Balance        — stabilises the inverted pendulum
%   Task 3 (STEP 8): Velocity         — outer loop on the balanced system
%   Task 4 (STEP 9): Position         — outermost loop
%
%  HOW TO USE
%  ----------
%   - Run the script end-to-end (F5) or section-by-section (Ctrl+Enter).
%   - Every transfer function is disp()'ed as it is computed.
%   - Plots are written to the Obsidian vault (Mads) or docs/images (team).
%  =======================================================================

close all; clear;

%% ----------------------------- STEP 0 ----------------------------------
%  Setup: Laplace variable, model name, and where to save the plots.
%  ------------------------------------------------------------------------
s     = tf('s');
model = 'regbot_1mg';
IMG_DIR = pick_image_dir();
fprintf('Plots will be saved to:\n  %s\n\n', IMG_DIR);


%% ----------------------------- STEP 1 ----------------------------------
%  REGBOT physical parameters.
%  These values are REQUIRED by the Simulink model (it reads them from the
%  base workspace at load time). Don't touch unless you know why.
%  ------------------------------------------------------------------------

% --- Motor: electrical ---
RA   = 3.3/2;      % armature resistance [ohm]   (two motors in parallel)
LA   = 6.6e-3/2;   % armature inductance [H]
Kemf = 0.0105;     % EMF / torque constant [V s/rad]
Km   = Kemf;       % torque constant [N m/A]

% --- Motor: mechanical ---
JA = 1.3e-6*2;     % rotor inertia [kg m^2]   (two motors)
BA = 3e-6*2;       % rotor friction [N m s/rad]
NG = 9.69;         % gear ratio

% --- Vehicle ---
WR = 0.03;         % wheel radius [m]
Bw = 0.155;        % distance between wheels [m]

% --- Masses and geometry ---
mmotor    = 0.193;                       % motor + gear [kg]
mframe    = 0.32;                        % frame + base PCB [kg]
mtopextra = 0.97 - mframe - mmotor;      % top mass (battery + charger) [kg]
mpdist    = 0.10;                        % distance to lid [m]
pushDist  = 0.10;                        % disturbance position (Z) [m]

% --- Simulation settings ---
startAngle = 10;    % initial tilt [deg] at t = 0
twvlp      = 0.005; % wheel-velocity filter time constant [s]


%% ----------------------------- STEP 2 ----------------------------------
%  Day 5 plant — voltage -> wheel velocity.
%  We measured this on Day 5 with the robot flat on its side (no falling
%  dynamics), so it only captures motor and wheel behaviour.
%  It is the PLANT we will design the Task 1 PI controller against.
%  ------------------------------------------------------------------------

Gvel_day5 = 13.34 / (s + 35.71);

fprintf('==============================================================\n');
fprintf('  Day 5 plant  Gvel_day5(s) = voltage -> wheel velocity\n');
fprintf('==============================================================\n');
print_tf('Gvel_day5', Gvel_day5);
fprintf('  DC gain = %.3f (m/s)/V   pole = %.2f rad/s   tau = %.3f s\n\n', ...
    dcgain(Gvel_day5), pole(Gvel_day5), 1/35.71);


%% ----------------------------- STEP 3 ----------------------------------
%  TASK 1 — Wheel-speed PI controller design (uses Gvel_day5).
%
%  These parameters MUST be set BEFORE linearising the Simulink model
%  (Kpwv, tiwv, Kffwv are read by controller blocks inside regbot_1mg).
%
%  C_wv(s) = Kp * (tau_i*s + 1) / (tau_i*s)
%
%  Choices:   wc = 30 rad/s   gamma_M >= 60 deg   Ni = 3
%  Derived:   tau_i = Ni/wc = 0.10 s    Kp ≈ 3.31  (so |L(j wc)| = 1)
%  ------------------------------------------------------------------------

% Design parameters (used both here AND by the Simulink wheel-velocity block)
Kpwv  = 3.31;    % Kp
tiwv  = 0.10;    % tau_i [s]
Kffwv = 0;       % feed-forward gain (not used)

C_wv = Kpwv * (tiwv*s + 1) / (tiwv*s);

fprintf('==============================================================\n');
fprintf('  Task 1 controller  C_wv(s)\n');
fprintf('==============================================================\n');
print_tf('C_wv', C_wv);

% Verify against the Day 5 plant
L_wv = C_wv * Gvel_day5;
[GM, PM, ~, wc] = margin(L_wv);
fprintf('  Loop L_wv = C_wv * Gvel_day5\n');
fprintf('  Achieved:  wc = %.1f rad/s | PM = %.1f deg | GM = %.1f dB\n\n', ...
    wc, PM, 20*log10(GM));

% Plots
save_plot(figure(200), @() margin(L_wv), ...
    'Task 1: Open loop Bode  L = C_{wv} G_{vel,day5}', ...
    IMG_DIR, 'regbot_task1_bode.png');

save_plot(figure(201), @() step(feedback(L_wv, 1), 0.5), ...
    'Task 1: Closed-loop step response (wheel speed)', ...
    IMG_DIR, 'regbot_task1_step.png');


%% ----------------------------- STEP 4 ----------------------------------
%  Identify the two plants from the Simulink model (via linearize).
%  Requires Task 1 values (Kpwv, tiwv, Kffwv) to be defined.
%
%   Gwv   = voltage -> wheel velocity  (full plant, including tilt)
%   Gtilt = velocity reference -> tilt angle  (balance controller plant)
%
%  Gtilt is the one we use for Task 2.
%
%  NOTE: If the Simulink model contains balance-controller blocks (Task 2),
%  those blocks need their parameter variables to exist BEFORE linearize()
%  can compile the model. We set safe placeholder values here and then
%  overwrite them with the real designed values in STEP 7.
%  ------------------------------------------------------------------------

% --- Placeholder balance-controller parameters (overwritten in STEP 7) ---
% These are only here so the Simulink model compiles. Kptilt = 0 means the
% balance loop contributes nothing during linearisation, so Gtilt is still
% correctly the open-loop plant from vel_ref to pitch.
Kptilt = 0;    % outer loop gain      (final value set in STEP 7)
titilt = 1;    % outer PI tau_i [s]   (placeholder)
tdtilt = 0;    % Lead gain (gyro)     (placeholder)
tipost = 1;    % post-integrator tau  (placeholder)

load_system(model);
open_system(model);

Gwv   = identify_tf(model, '/Limit9v', '/wheel_vel_filter');
Gtilt = identify_tf(model, '/vel_ref', '/robot with balance');

fprintf('==============================================================\n');
fprintf('  Plant  Gwv(s) = voltage -> wheel velocity (from Simulink)\n');
fprintf('==============================================================\n');
print_tf('Gwv', Gwv);
describe_plant(Gwv);

fprintf('==============================================================\n');
fprintf('  Plant  Gtilt(s) = vel_ref -> tilt angle (from Simulink)\n');
fprintf('==============================================================\n');
print_tf('Gtilt', Gtilt);
describe_plant(Gtilt);


%% ----------------------------- STEP 5 ----------------------------------
%  Quick visual sanity-check plots for the identified plants.
%  ------------------------------------------------------------------------

save_plot(figure(100), @() bode(Gwv), ...
    'G_{wv}: voltage -> wheel velocity', ...
    IMG_DIR, 'regbot_Gwv_bode.png');

save_plot(figure(101), @() bode(Gtilt), ...
    'G_{tilt}: vel_{ref} -> tilt angle', ...
    IMG_DIR, 'regbot_Gtilt_bode.png');

figure(102); plot_pz_stability(Gwv, 'Gwv');
saveas(gcf, fullfile(IMG_DIR, 'regbot_Gwv_pzmap.png'));

figure(103); plot_pz_stability(Gtilt, 'Gtilt');
saveas(gcf, fullfile(IMG_DIR, 'regbot_Gtilt_pzmap.png'));

figure(104); plot_pz_stability(Gwv, 'Gwv (zoomed)');
xlim([-50 50]); ylim([-50 50]);
saveas(gcf, fullfile(IMG_DIR, 'regbot_Gwv_pzmap_zoom.png'));

figure(105); plot_pz_stability(Gtilt, 'Gtilt (zoomed)');
xlim([-50 50]); ylim([-50 50]);
saveas(gcf, fullfile(IMG_DIR, 'regbot_Gtilt_pzmap_zoom.png'));

figure(106); plot_nyquist_critical(Gtilt, 'Gtilt');
saveas(gcf, fullfile(IMG_DIR, 'regbot_Gtilt_nyquist.png'));


%% ----------------------------- STEP 6 ----------------------------------
%  TASK 2 — Balance controller (follows Lecture 10, Method 2).
%
%  Method 2 workflow for stabilising an open-loop unstable plant G(s):
%    Step 1 : Nyquist sign-check — decide whether sign(K_PS) = +1 or -1
%             (need P CCW encirclements of (-1,0), where P = #RHP poles).
%    Step 2 : Place a post-integrator so the stabilised plant
%             Gs(s) = sign(K_PS) * C_PI,post(s) * G(s) has a monotonically
%             decreasing |.| beyond its peak. Choose tau_i,post = 1/w_peak.
%    Step 3 : Design outer PI (+ Lead if needed) on Gs(s). Place PI zero at
%             wc/Ni; compute phi_Lead from phase balance; K_P from |L|=1.
%    Step 4 : Close the loop, verify poles, margins, and IC/step response.
%
%  We apply this to G(s) = Gtilt(s)  (vel_ref -> tilt angle).
%  ------------------------------------------------------------------------

fprintf('\n==============================================================\n');
fprintf('  Task 2 — Balance controller (Lecture 10 Method 2)\n');
fprintf('==============================================================\n');
fprintf('  Plant:        Gtilt(s) = vel_ref -> tilt angle\n');
fprintf('  RHP poles:    P = %d  (inverted-pendulum falling mode)\n', ...
        sum(real(pole(Gtilt))>0));
fprintf('  Nyquist req.: Z = N + P = 0  =>  need N = -%d  (CCW around -1)\n\n', ...
        sum(real(pole(Gtilt))>0));


% ---- Step 1: Nyquist sign-check ---------------------------------------
% Evaluate where Gtilt(jw) crosses the negative real axis at -180° phase.
% If the curve cannot be made to encircle (-1,0) CCW with any positive K_PS,
% we must absorb a minus sign (K_PS < 0). For the inverted pendulum this
% minus sign is the "-" that Lecture 10 folds into the post-integrator.
w_grid = logspace(-2, 4, 4000);
[mag_g, phi_g] = bode(Gtilt, w_grid);
mag_g = squeeze(mag_g); phi_g = squeeze(phi_g);
k_dc  = find(w_grid <= 1, 1, 'last');       % low-freq sample for DC sign
re_dc = dcgain(Gtilt);

fprintf('---- Step 1: Sign check ---------------------------------------\n');
fprintf('  DC gain of Gtilt          = %+.3e   (sign determines K_PS sign)\n', re_dc);
if re_dc > 0
    sign_K = -1;
    fprintf('  DC gain > 0 AND P = 1     =>  need sign(K_PS) = -1\n');
    fprintf('  (positive K_PS alone cannot produce the required CCW encirclement)\n\n');
else
    sign_K = +1;
    fprintf('  DC gain < 0               =>  sign(K_PS) = +1 may suffice\n\n');
end


% ---- Step 2: Post-integrator design -----------------------------------
% Find the peak of |Gtilt| on the Bode magnitude. Place the PI zero there:
%     tau_i,post = 1 / w_peak
[mag_peak, k_peak] = max(mag_g);
w_ip   = w_grid(k_peak);
tau_ip = 1 / w_ip;

C_PI_post  = (tau_ip*s + 1) / (tau_ip*s);
Gtilt_post = sign_K * C_PI_post * Gtilt;      % sign_K = -1 for REGBOT

fprintf('---- Step 2: Post-integrator ----------------------------------\n');
fprintf('  |Gtilt| magnitude peak    : max|G| = %.4f  at  w_peak = %.3f rad/s\n', ...
        mag_peak, w_ip);
fprintf('  tau_i,post = 1/w_peak     = %.4f s\n', tau_ip);
fprintf('  C_PI,post(s)              = (%.4f s + 1) / (%.4f s)\n', tau_ip, tau_ip);
print_tf('C_PI_post', C_PI_post);
fprintf('  Stabilised plant          : Gtilt,post(s) = (%+d) * C_PI,post(s) * Gtilt(s)\n', sign_K);
print_tf('Gtilt_post', minreal(Gtilt_post));
fprintf('  RHP poles of Gtilt,post   : %d  (outer loop will close this)\n\n', ...
        sum(real(pole(minreal(Gtilt_post)))>0));

% Plots for Step 2
save_plot(figure(300), @() bode(Gtilt, Gtilt_post, w_grid), ...
    'Task 2 Step 2: G_{tilt} before (blue) vs. after (orange) post-integrator', ...
    IMG_DIR, 'regbot_task2_bode_post.png');
legend('G_{tilt}(s)', '-C_{PI,post}(s) G_{tilt}(s)', 'Location', 'best');
saveas(gcf, fullfile(IMG_DIR, 'regbot_task2_bode_post.png'));

figure(301); plot_nyquist_critical(Gtilt_post, 'G_{tilt,post}');
saveas(gcf, fullfile(IMG_DIR, 'regbot_task2_nyquist_post.png'));


%% ----------------------------- STEP 7 ----------------------------------
%  Task 2, Step 3 — Outer PI-Lead on the stabilised plant Gtilt,post.
%
%  Phase balance at the crossover:
%     gamma_M - 180 = phi_Gtilt_post(wc) + phi_PI(wc) + phi_Lead(wc)
%
%  Gyro-based Lead: tau_d*s + 1 = tau_d*gyro + theta  (no filter pole).
%  ------------------------------------------------------------------------

% --- 3a. Design specifications -----------------------------------------
wc_tilt  = 15;    % target crossover [rad/s]
gamma_M  = 60;    % phase margin target [deg]
Ni_tilt  = 3;     % PI zero at wc/Ni

fprintf('---- Step 3: Outer PI-Lead on G_{tilt,post} -------------------\n');
fprintf('  3a. Specs:           wc = %.1f rad/s   gamma_M = %.0f deg   Ni = %d\n\n', ...
        wc_tilt, gamma_M, Ni_tilt);

% --- 3b. I-part (outer PI) ---------------------------------------------
tau_i_tilt = Ni_tilt / wc_tilt;
C_PI_tilt  = (tau_i_tilt*s + 1) / (tau_i_tilt*s);

fprintf('  3b. I-part (outer PI):\n');
fprintf('      tau_i = Ni/wc         = %.4f s\n', tau_i_tilt);
fprintf('      C_PI(s)               = (%.4f s + 1) / (%.4f s)\n\n', tau_i_tilt, tau_i_tilt);

% --- 3c. Phase balance --------------------------------------------------
[~, phi_G]  = bode(Gtilt_post, wc_tilt);
phi_PI      = -atand(1/Ni_tilt);                 % PI phase at wc
phi_Lead    = -180 + gamma_M - phi_G - phi_PI;   % required from phase balance

fprintf('  3c. Phase balance at wc = %.1f rad/s:\n', wc_tilt);
fprintf('      phi_Gtilt,post(j wc)  = %+7.2f deg\n', phi_G);
fprintf('      phi_PI(j wc)          = %+7.2f deg    (= -atan(1/Ni))\n', phi_PI);
fprintf('      phi_Lead required     = %+7.2f deg    (= -180 + gamma_M - phi_G - phi_PI)\n\n', phi_Lead);

% --- 3d. Lead from gyro -------------------------------------------------
if phi_Lead <= 0
    tau_d  = 0;           C_Lead = tf(1);
    lead_note = 'no Lead needed (phase margin already met)';
elseif phi_Lead >= 89
    tau_d  = NaN;         C_Lead = tf(1);
    lead_note = sprintf('WARN: phi_Lead = %.1f deg too high — lower wc or cascade Leads', phi_Lead);
else
    tau_d  = tand(phi_Lead) / wc_tilt;
    C_Lead = tau_d*s + 1;
    lead_note = 'gyro-based ideal Lead (tau_d*gyro + theta)';
end

fprintf('  3d. Lead part (gyro shortcut):\n');
fprintf('      tau_d = tan(phi_Lead)/wc = %.4f s\n', tau_d);
fprintf('      C_Lead(s)             = %.4f s + 1       (%s)\n\n', tau_d, lead_note);

% --- 3e. Loop gain (solve |L(j wc)| = 1) --------------------------------
magL     = squeeze(bode(C_PI_tilt * C_Lead * Gtilt_post, wc_tilt));
Kp_tilt  = 1 / magL;

fprintf('  3e. Loop gain:\n');
fprintf('      |C_PI * C_Lead * Gtilt,post|_{wc} = %.4f\n', magL);
fprintf('      Kp = 1 / |.|          = %.4f\n\n', Kp_tilt);

% --- Full controller ---------------------------------------------------
C_outer_tilt = Kp_tilt * C_PI_tilt * C_Lead;
L_tilt       = C_outer_tilt * Gtilt_post;
C_total_tilt = Kp_tilt * sign_K * C_PI_post * C_PI_tilt * C_Lead;

fprintf('  Full tilt controller:\n');
fprintf('    C_total(s) = Kp * (%+d) * C_PI,post(s) * C_PI(s) * (tau_d s + 1)\n\n', sign_K);
print_tf('C_outer = Kp * C_PI * C_Lead', C_outer_tilt);
print_tf('C_total (full cascade, vel_ref command)', minreal(C_total_tilt));


% ---- Step 4: Closed-loop verification ---------------------------------
T_tilt = feedback(L_tilt, 1);
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

% Plots for Step 4
save_plot(figure(302), @() margin(L_tilt), ...
    'Task 2 Step 4: Open-loop  L = K_P C_{PI} C_{Lead} G_{tilt,post}', ...
    IMG_DIR, 'regbot_task2_loop_bode.png');

save_plot(figure(303), @() step(T_tilt, 2), ...
    'Task 2 Step 4: Closed-loop step (reference tracking)', ...
    IMG_DIR, 'regbot_task2_step.png');

% Output-disturbance regulation (proxy for "released from tilt theta0").
% Physically: if an external torque instantly offsets pitch by theta0 and is
% then removed, the closed loop must drive pitch back to 0. The authoritative
% IC test is run in Simulink (startAngle = 10) — this plot just shows the
% linear-model recovery character: settling time, overshoot, undershoot.
theta0 = deg2rad(10);
t_ic   = linspace(0, 2, 2001);
S_tilt = feedback(1, L_tilt);                % sensitivity 1/(1+L)
[y_dist, t_out] = step(theta0 * S_tilt, t_ic);

figure(304); clf;
plot(t_out, rad2deg(y_dist), 'b', 'LineWidth',1.4); grid on
xlabel('Time [s]'); ylabel('Pitch [deg]');
title('Task 2 Step 4: Linear-model regulation from \theta_0 = 10° output disturbance');
yline(0,'k:');
saveas(gcf, fullfile(IMG_DIR, 'regbot_task2_ic_response.png'));

% Rough performance numbers from the regulation response
abs_env  = abs(y_dist);
settle_i = find(abs_env > 0.02*theta0, 1, 'last');  % 2% envelope
settle_t = t_out(settle_i);
peak_us  = max(-y_dist);                            % worst undershoot below 0
fprintf('  Linear-model regulation (theta_0 = 10 deg output disturbance):\n');
fprintf('    Settling time (2%% env.) = %.2f s\n', settle_t);
fprintf('    Peak undershoot         = %.2f deg\n', rad2deg(peak_us));
fprintf('    Authoritative IC test   : Simulink, startAngle = 10  (see regbot_task2_sim_recovery_10deg.png)\n\n');


% ---- Simulink handoff --------------------------------------------------
% Use these when wiring the balance controller into Simulink.
% The Lead is implemented as  tau_d * gyro + pitch  on the feedback path
% (BEFORE the error sum) — see Lecture 10 "gyro shortcut".
Kptilt = Kp_tilt;
titilt = tau_i_tilt;
tdtilt = tau_d;
tipost = tau_ip;

fprintf('---- Simulink handoff variables -------------------------------\n');
fprintf('  Kptilt = %.4f   (outer loop gain)\n',           Kptilt);
fprintf('  titilt = %.4f s (outer PI time constant)\n',    titilt);
fprintf('  tdtilt = %.4f s (gyro Lead gain)\n',            tdtilt);
fprintf('  tipost = %.4f s (post-integrator time const.)\n\n', tipost);


%% ----------------------------- STEP 8 ----------------------------------
%  TASK 3 — Velocity outer loop.
%
%  Do this AFTER the balance loop works in simulation. You then linearise
%  the model with the balance loop CLOSED:
%
%      Gvel_outer = identify_tf(model, '/theta_ref', '/wheel_vel_filter');
%
%  and design a PI on Gvel_outer with wc_vel ~ wc_tilt / 5.
%  ------------------------------------------------------------------------


%% ----------------------------- STEP 9 ----------------------------------
%  TASK 4 — Position outermost loop.
%
%  Same idea, but with the velocity loop CLOSED.
%
%      Gpos_outer = identify_tf(model, '/v_ref', '/x_position');
%
%  A P-controller is usually enough because there's already an integrator
%  in the loop (from the balance post-integrator).
%  ------------------------------------------------------------------------


fprintf('All design steps complete.\n');
fprintf('Simulink handoff variables are in the base workspace.\n');


%% =======================================================================
%  LOCAL HELPER FUNCTIONS
%  =======================================================================

function out = ternary(cond, a, b)
    % Minimal ternary helper so the main script reads cleanly.
    if cond, out = a; else, out = b; end
end

function img_dir = pick_image_dir()
    % Use the Obsidian vault if available, otherwise docs/images.
    here = fileparts(mfilename('fullpath'));
    obs  = fullfile(here,'..','..','..','..','Obsidian','Courses', ...
        '34722 Linear Control Design 1','Exercises','Work','regbot','Images');
    docs = fullfile(here, '..', 'docs', 'images');
    if exist(obs, 'dir')
        img_dir = obs;
    else
        img_dir = docs;
        if ~exist(img_dir, 'dir'), mkdir(img_dir); end
    end
end

function G = identify_tf(model, in_block, out_block)
    % Linearise the Simulink model between two signals and return a TF.
    io(1) = linio(strcat(model, in_block),  1, 'openinput');
    io(2) = linio(strcat(model, out_block), 1, 'openoutput');
    setlinio(model, io);
    sys = linearize(model, io, 0);
    [num, den] = ss2tf(sys.A, sys.B, sys.C, sys.D);
    G = minreal(tf(num, den));
end

function describe_plant(G)
    % Compact summary used after each plant's disp() call.
    fprintf('  Poles:  '); fprintf('%7.2f  ', sort(real(pole(G)))); fprintf('\n');
    fprintf('  Zeros:  '); fprintf('%7.2f  ', sort(real(zero(G)))); fprintf('\n');
    fprintf('  DC gain   = %.4e\n', dcgain(G));
    fprintf('  RHP poles = %d  (anything > 0 means the plant is unstable)\n\n', ...
            sum(real(pole(G))>0));
end

function print_tf(name, G)
    % Robustly print a transfer function in polynomial form, independent
    % of MATLAB display settings.
    [num, den] = tfdata(G, 'v');
    num_str = poly_to_str(num);
    den_str = poly_to_str(den);
    w = max(length(num_str), length(den_str));
    pad_n = repmat(' ', 1, floor((w - length(num_str))/2));
    pad_d = repmat(' ', 1, floor((w - length(den_str))/2));
    fprintf('  %s(s) =\n', name);
    fprintf('            %s%s\n', pad_n, num_str);
    fprintf('            %s\n',   repmat('-', 1, w));
    fprintf('            %s%s\n\n', pad_d, den_str);
end

function s = poly_to_str(p)
    % Turn a polynomial coefficient vector into a human-readable string in 's'.
    p = p(:)';
    % strip leading zeros
    nz = find(abs(p) > 1e-14, 1, 'first');
    if isempty(nz), s = '0'; return; end
    p = p(nz:end);
    n = length(p) - 1;
    parts = {};
    for k = 1:length(p)
        a = p(k); pwr = n - (k-1);
        if abs(a) < 1e-14, continue; end
        sign_str = '';
        if isempty(parts)
            if a < 0, sign_str = '-'; end
        else
            if a < 0, sign_str = ' - '; else, sign_str = ' + '; end
        end
        mag = abs(a);
        if pwr == 0
            term = sprintf('%s%.4g', sign_str, mag);
        elseif pwr == 1
            if mag == 1, term = sprintf('%ss',      sign_str);
            else,        term = sprintf('%s%.4g s', sign_str, mag);
            end
        else
            if mag == 1, term = sprintf('%ss^%d',      sign_str, pwr);
            else,        term = sprintf('%s%.4g s^%d', sign_str, mag, pwr);
            end
        end
        parts{end+1} = term; %#ok<AGROW>
    end
    s = strjoin(parts, '');
end

function save_plot(fig, plot_fn, ttl, img_dir, fname)
    % Run the user plot, set a title, grid, and save.
    figure(fig); plot_fn(); grid on;
    title(ttl);
    saveas(fig, fullfile(img_dir, fname));
end

function plot_pz_stability(G, ttl)
    % Pole-zero map with shaded LHP (green) and RHP (red) regions.
    clf
    p = pole(G); z = zero(G);
    all_pts = [p; z];
    if isempty(all_pts), lim = 10;
    else, lim = max(max(abs(real(all_pts))), max(abs(imag(all_pts))))*1.2+1;
    end

    hold on
    patch([0 -lim -lim 0], [-lim -lim lim lim], [0.85 1 0.85], ...
          'EdgeColor','none','FaceAlpha',0.5);
    patch([0  lim  lim 0], [-lim -lim lim lim], [1 0.85 0.85], ...
          'EdgeColor','none','FaceAlpha',0.5);
    plot([-lim lim],[0 0],'k','LineWidth',0.5);
    plot([0 0],[-lim lim],'k','LineWidth',1.5);
    plot(real(p), imag(p), 'rx', 'MarkerSize',14,'LineWidth',2.5);
    plot(real(z), imag(z), 'bo', 'MarkerSize',12,'LineWidth',2);
    rhp = p(real(p)>0);
    if ~isempty(rhp)
        plot(real(rhp), imag(rhp), 'o', 'MarkerSize',20, ...
             'MarkerEdgeColor',[1 0.6 0], 'LineWidth',2.5);
    end
    xlim([-lim lim]); ylim([-lim lim]); axis equal; grid on
    xlabel('Real axis'); ylabel('Imaginary axis');
    title(sprintf('Pole-zero map: %s', ttl));
    text(-lim*0.6, lim*0.85,'LHP (stable)','Color',[0 0.5 0],'FontWeight','bold');
    text( lim*0.15, lim*0.85,'RHP (unstable)','Color',[0.7 0 0],'FontWeight','bold');
    legend_items = {'Poles','Zeros'};
    if ~isempty(rhp), legend_items{end+1} = 'RHP poles (unstable)'; end
    legend(legend_items, 'Location','best');
    hold off
end

function plot_nyquist_critical(G, ttl)
    % Nyquist plot with (-1,0) highlighted and RHP-pole count in the title.
    clf
    P = sum(real(pole(G))>0);
    [re, im, w] = nyquist(G);
    re = squeeze(re); im = squeeze(im);

    hold on; grid on
    plot(re,  im, 'b-', 'LineWidth',1.5);
    plot(re, -im, 'b--','LineWidth',1.0);

    th = linspace(0, 2*pi, 200);
    plot(-1 + 0.05*cos(th), 0.05*sin(th), 'r-', 'LineWidth',1);
    plot(-1, 0, 'r+', 'MarkerSize',14,'LineWidth',2);

    xl = xlim; yl = ylim;
    plot(xl, [0 0], 'k', 'LineWidth',0.5);
    plot([0 0], yl, 'k', 'LineWidth',0.5);

    k = max(2, round(length(w)/3));
    quiver(re(k), im(k), re(k+1)-re(k), im(k+1)-im(k), 0, ...
           'Color','b','MaxHeadSize',2,'LineWidth',1.2,'AutoScale','off');

    axis equal
    xlabel('Re\{G(j\omega)\}'); ylabel('Im\{G(j\omega)\}');
    title(sprintf('Nyquist: %s  (RHP poles P = %d)', ttl, P));
    legend({'\omega > 0','\omega < 0','critical (-1,0)'}, 'Location','best');
    hold off
end
