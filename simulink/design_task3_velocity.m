%% =======================================================================
%  Task 3 — Velocity outer loop (PI)
%  =======================================================================
%
%  Plant:    G_vel,outer(s) = theta_ref -> wheel_vel_filter
%            Identified from regbot_1mg.slx via linearize() with the
%            balance loop CLOSED (Task 2 gains active) and the velocity
%            loop OPEN at theta_ref (linio 'openinput' breaks feedback).
%
%  Specs:    wc_vel = 1 rad/s    (well below the RHP zero at +8.5 rad/s;
%                                 the rule wc_vel <= z/5 keeps |L|
%                                 monotonically decreasing past crossover)
%            gamma_M >= 60 deg,  Ni = 3
%
%  Method:   Standard PI design on a stable plant — no post-integrator
%            trick needed here because the closed balance loop has
%            stabilised the RHP pole of G_tilt.
%              1. tau_i = Ni/wc
%              2. Phase balance — check if a Lead is needed
%              3. Kp from |L(j wc)| = 1
%              4. Verify poles, margins, step response
%
%  Run this script on its own once the Simulink model has:
%    - A velocity-controller chain  v_ref -> Sum(+-) -> Gvel_PI -> Kpvel_gain
%      whose output feeds into the balance controller's first Sum
%      (replacing the Constant = 0 that used to sit there).
%    - The Kpvel_gain block NAMED 'Kpvel_gain' (so linearize can find it).
%    - A signal tap from wheel_vel_filter output into Sum(-).
%
%  See: Simulink wiring checklist in the REGBOT Balance Assignment note.
%  =======================================================================

close all; clear;

% --- Load workspace ------------------------------------------------------
% regbot_mg populates physical params + committed gains (Task 1 and
% Task 2 active, Task 3 placeholders). It also addpaths lib/.
addpath(fileparts(mfilename('fullpath')));
regbot_mg;

s       = tf('s');
model   = 'regbot_1mg';
IMG_DIR = pick_image_dir();

% The block you labelled 'Kpvel_gain' in Simulink — change here if you
% used a different name.
VEL_CTRL_OUT_BLOCK = '/Kpvel_gain';


%% ------------------ Preamble: plant identification ---------------------
% Ensure placeholders are sane (regbot_mg already sets these, but we set
% them again defensively in case someone edited regbot_mg).
Kpvel = 0;     %#ok<NASGU>
tivel = 1;     %#ok<NASGU>

load_system(model);
open_system(model);

% Linearise theta_ref -> wheel_vel_filter with velocity loop broken.
% 'openinput' on the Kpvel_gain output port severs the velocity feedback
% at that point, treating theta_ref as an exogenous input.
Gvel_outer = identify_tf(model, VEL_CTRL_OUT_BLOCK, '/wheel_vel_filter');

fprintf('==============================================================\n');
fprintf('  Task 3 plant: G_{vel,outer}(s) = theta_ref -> wheel_vel_filter\n');
fprintf('  (balance loop CLOSED with Task 2 gains; velocity loop OPEN)\n');
fprintf('==============================================================\n');
print_tf('Gvel_outer', Gvel_outer);
describe_plant(Gvel_outer);


%% ----------------------------- Design ----------------------------------
% Specs
% ω_c is set by the RHP zero in Gvel,outer at +8.5 rad/s (physics: to
% tilt forward the robot must first roll backward). Rule of thumb:
%   ω_c <= z/5   keeps |L| monotonic past crossover -> stable design.
% Picking wc_vel = 1 rad/s puts us safely below the gain-bump region
% caused by the complex pole pair near -2.63 and the RHP zero.
wc_vel       = 1;        % target crossover [rad/s]
gamma_M_spec = 60;       % phase margin spec [deg]
Ni_vel       = 3;        % PI zero at wc/Ni

fprintf('---- Design (specs: wc = %.1f rad/s, gamma_M >= %.0f deg, Ni = %d) ----\n', ...
        wc_vel, gamma_M_spec, Ni_vel);

% Step 1: I-part
tau_i_vel = Ni_vel / wc_vel;
C_PI_vel  = (tau_i_vel*s + 1) / (tau_i_vel*s);

fprintf('  Step 1 — I-part:\n');
fprintf('      tau_i = Ni/wc        = %.4f s\n', tau_i_vel);
fprintf('      C_PI(s)              = (%.4f s + 1) / (%.4f s)\n\n', tau_i_vel, tau_i_vel);

% Step 2: Phase balance
[~, phi_G]  = bode(Gvel_outer, wc_vel);
phi_PI      = -atand(1/Ni_vel);
phi_Lead    = -180 + gamma_M_spec - phi_G - phi_PI;

fprintf('  Step 2 — Phase balance at wc = %.1f rad/s:\n', wc_vel);
fprintf('      phi_Gvel,outer(j wc) = %+7.2f deg\n', phi_G);
fprintf('      phi_PI(j wc)         = %+7.2f deg    (= -atan(1/Ni))\n', phi_PI);
fprintf('      phi_Lead required    = %+7.2f deg    (= -180 + gamma_M - phi_G - phi_PI)\n', phi_Lead);

if phi_Lead <= 0
    tau_d_vel = 0;  C_Lead_vel = tf(1);
    fprintf('      Lead NOT needed — phase margin already met by PI alone.\n\n');
else
    tau_d_vel  = tand(phi_Lead) / wc_vel;
    C_Lead_vel = tau_d_vel*s + 1;
    fprintf('      Lead required — tau_d = %.4f s  (but Task 3 usually sticks with pure PI)\n', tau_d_vel);
    fprintf('      If the resulting PM is acceptable without Lead, leave tau_d = 0 in Simulink.\n\n');
end

% Step 3: Loop gain — choose Kp so |L(j wc)| = 1 using the PI-only design
% (we stay with a pure PI for Task 3; if PM is too low we revisit).
magL     = squeeze(bode(C_PI_vel * Gvel_outer, wc_vel));
Kp_vel   = 1 / magL;

fprintf('  Step 3 — Loop gain:\n');
fprintf('      |C_PI * Gvel,outer|_{wc} = %.4f\n', magL);
fprintf('      Kp = 1 / |.|            = %.4f\n\n', Kp_vel);

% Full controller + loop
C_vel = Kp_vel * C_PI_vel;
L_vel = C_vel * Gvel_outer;
T_vel = feedback(L_vel, 1);
[GM, PM, ~, wc_ach] = margin(L_vel);

fprintf('---- Verification ---------------------------------------------\n');
fprintf('  Achieved wc             = %.2f rad/s   (target %.1f)\n', wc_ach, wc_vel);
fprintf('  Phase margin            = %.2f deg     (target >= %.0f)\n', PM, gamma_M_spec);
fprintf('  Gain margin             = %.2f dB\n',   20*log10(GM));
fprintf('  Closed-loop RHP poles   = %d\n\n',      sum(real(pole(T_vel)) > 0));


%% ----------------------------- Plots -----------------------------------
save_plot(figure(400), @() margin(L_vel), ...
    'Task 3: Open-loop Bode  L = C_{vel} G_{vel,outer}', ...
    IMG_DIR, 'regbot_task3_loop_bode.png');

save_plot(figure(401), @() step(T_vel, 5), ...
    'Task 3: Closed-loop step response (v_{ref} = 1 m/s)', ...
    IMG_DIR, 'regbot_task3_step.png');

figure(402); plot_pz_stability(Gvel_outer, 'G_{vel,outer}');
xlim([-50 10]); ylim([-50 50]);
saveas(gcf, fullfile(IMG_DIR, 'regbot_task3_plant_pz.png'));


%% ------------------- Write to workspace + gains block ------------------
Kpvel = Kp_vel;
tivel = tau_i_vel;

fprintf('==============================================================\n');
fprintf('  Copy-paste this block into regbot_mg.m (Task 3 gains)\n');
fprintf('==============================================================\n');
fprintf('    Kpvel  = %.4f;\n', Kpvel);
fprintf('    tivel  = %.4f;\n\n', tivel);
