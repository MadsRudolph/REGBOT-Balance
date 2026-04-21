%% =======================================================================
%  Task 4 — Position outermost loop (P / P-Lead)
%  =======================================================================
%
%  Plant:    G_pos,outer(s) = pos_ref-like input -> x_position
%            Identified from regbot_1mg.slx via linearize() with the
%            balance loop CLOSED (Task 2 gains active), the velocity
%            loop CLOSED (Task 3 gains active), and the position loop
%            OPEN at the Kppos_gain output.
%
%  The plant already contains a free integrator (1/s from wheel
%  velocity -> wheel position), so a pure P controller is enough to
%  drive the steady-state error to a step reference to zero.
%  A Lead is added only if the phase margin falls below the spec.
%
%  Specs:    wc_pos = 0.2 rad/s    (well below wc_vel = 1 rad/s; the
%                                   cascaded design rule keeps the
%                                   outer loop ~5x slower than the
%                                   inner velocity loop)
%            gamma_M >= 60 deg
%
%  Method:   1. Phase at wc  ->  decide if a Lead is needed
%            2. Kp from |L(j wc)| = 1  (with Lead if required)
%            3. Verify margins, closed-loop poles, 2 m step response
%
%  Run this script on its own once the Simulink model has:
%    - A position-controller chain  pos_ref -> Sum(+-) -> Kppos_gain
%      feeding into the spot where v_ref used to come from (replacing
%      the Step / In1 used for Task 3 validation).
%    - The gain block NAMED 'Kppos_gain' (so linearize can find it).
%    - A signal tap from x_position (System output) into Sum(-).
%
%  See: Simulink wiring checklist in the REGBOT Balance Assignment note.
%  =======================================================================

close all; clear;

% --- Load workspace ------------------------------------------------------
% regbot_mg populates physical params + committed gains (Task 1, Task 2
% and Task 3 active, Task 4 placeholders).
addpath(fileparts(mfilename('fullpath')));
regbot_mg;

s       = tf('s');
model   = 'regbot_1mg';
IMG_DIR = pick_image_dir();

% Block names — change here if you used different labels in Simulink.
% NOTE: on 'robot with balance', port 1 = pitch, port 2 = gyro,
% port 3 = x_position, port 4 = wheel_vel. We linearise to port 3.
POS_CTRL_OUT_BLOCK = '/Kppos_gain';
X_POS_BLOCK        = '/robot with balance';
X_POS_PORT         = 3;                         % x_position output port


%% ------------------ Preamble: plant identification ---------------------
% Break the position loop at the Kppos_gain output so pos_ref becomes an
% exogenous input while the balance and velocity loops stay closed.
Kppos = 0;     %#ok<NASGU>

load_system(model);
open_system(model);

Gpos_outer = identify_tf(model, POS_CTRL_OUT_BLOCK, X_POS_BLOCK, X_POS_PORT);

fprintf('==============================================================\n');
fprintf('  Task 4 plant: G_{pos,outer}(s) = pos_ref -> x_position\n');
fprintf('  (balance + velocity loops CLOSED; position loop OPEN)\n');
fprintf('==============================================================\n');
print_tf('Gpos_outer', Gpos_outer);
describe_plant(Gpos_outer);

fprintf('  RHP poles of Gpos_outer  : %d\n',  sum(real(pole(Gpos_outer)) > 0));
fprintf('  Integrators (poles ~ 0)  : %d   (expected >= 1, from v -> x)\n\n', ...
        sum(abs(pole(Gpos_outer)) < 1e-6));


%% ----------------------------- Design ----------------------------------
% Specs
% The cascade rule wants wc_pos well below wc_vel = 1 rad/s. We iterated:
%   wc = 0.2  -> PM 87 deg, but peak v 0.33 m/s (fails 0.7 spec)
%                and settling 20 s (fails 10 s window)
%   wc = 0.5  -> PM 66 deg, peak v 0.68 m/s (just short), settling 12 s
%   wc = 0.6  -> PM ~60 deg, peak v ~0.82 m/s, settling ~10 s  <-- chosen
% 0.6 rad/s is still 1.67x below wc_vel = 1 rad/s. Tight but acceptable;
% the closed-loop velocity plant has PM 64 deg so it doesn't add much
% phase lag at 0.6 rad/s.
wc_pos       = 0.6;      % target crossover [rad/s]
gamma_M_spec = 60;       % phase margin spec [deg]

fprintf('---- Design (specs: wc = %.2f rad/s, gamma_M >= %.0f deg) ----\n', ...
        wc_pos, gamma_M_spec);

% Step 1: Phase balance — no PI, since plant is already Type-1.
% bode() returns an unwrapped phase; for a plant with a free integrator
% it often comes back as +266 deg instead of -94 deg. Wrap to (-360, 0]
% so the Lead formula sees the physically meaningful value.
[~, phi_G] = bode(Gpos_outer, wc_pos);
phi_G      = mod(phi_G + 180, 360) - 180;    % wrap to [-180, 180]
phi_Lead   = mod(-180 + gamma_M_spec - phi_G + 180, 360) - 180;   % wrap Lead to [-180, 180]

fprintf('  Step 1 — Phase balance at wc = %.2f rad/s:\n', wc_pos);
fprintf('      phi_Gpos,outer(j wc)    = %+7.2f deg\n', phi_G);
fprintf('      phi_Lead required       = %+7.2f deg    (= -180 + gamma_M - phi_G)\n', phi_Lead);

if phi_Lead <= 0
    tau_d_pos   = 0;  C_Lead_pos = tf(1);
    lead_note   = 'no Lead needed — phase margin already met by P alone.';
elseif phi_Lead >= 89
    tau_d_pos   = NaN; C_Lead_pos = tf(1);
    lead_note   = sprintf('WARN: phi_Lead = %.1f deg too high — lower wc or cascade Leads', phi_Lead);
else
    tau_d_pos   = tand(phi_Lead) / wc_pos;
    C_Lead_pos  = tau_d_pos*s + 1;
    lead_note   = 'standard ideal Lead (tau_d*s + 1)';
end

fprintf('      tau_d = tan(phi_Lead)/wc = %.4f s\n', tau_d_pos);
fprintf('      C_Lead(s)               = %.4f s + 1       (%s)\n\n', tau_d_pos, lead_note);

% Step 2: Loop gain — choose Kp so |L(j wc)| = 1
magL    = squeeze(bode(C_Lead_pos * Gpos_outer, wc_pos));
Kp_pos  = 1 / magL;

fprintf('  Step 2 — Loop gain:\n');
fprintf('      |C_Lead * Gpos,outer|_{wc} = %.4f\n', magL);
fprintf('      Kp = 1 / |.|               = %.4f\n\n', Kp_pos);

% Full controller + loop
C_pos = Kp_pos * C_Lead_pos;
L_pos = C_pos * Gpos_outer;
T_pos = feedback(L_pos, 1);
[GM, PM, ~, wc_ach] = margin(L_pos);

fprintf('---- Verification ---------------------------------------------\n');
fprintf('  Achieved wc             = %.3f rad/s   (target %.2f)\n', wc_ach, wc_pos);
fprintf('  Phase margin            = %.2f deg     (target >= %.0f)\n', PM, gamma_M_spec);
fprintf('  Gain margin             = %.2f dB\n',   20*log10(GM));
fprintf('  Closed-loop RHP poles   = %d\n\n',      sum(real(pole(T_pos)) > 0));

% Step response to 2 m reference (matches the Task 4 physical test)
[y_step, t_step] = step(2 * T_pos, 20);
peak_v   = max(gradient(y_step, t_step));
settle_i = find(abs(y_step - 2) > 0.02*2, 1, 'last');
settle_t = t_step(settle_i);

fprintf('  2 m step response:\n');
fprintf('    Peak velocity (d/dt)  = %.3f m/s    (spec: must exceed 0.7 m/s)\n', peak_v);
fprintf('    Settling time (2%%)    = %.2f s     (mission window: 10 s)\n\n', settle_t);


%% ----------------------------- Plots -----------------------------------
save_plot(figure(500), @() margin(L_pos), ...
    'Task 4: Open-loop Bode  L = C_{pos} G_{pos,outer}', ...
    IMG_DIR, 'regbot_task4_loop_bode.png');

save_plot(figure(501), @() step(2 * T_pos, 20), ...
    'Task 4: Closed-loop step response (pos_{ref} = 2 m)', ...
    IMG_DIR, 'regbot_task4_step.png');

figure(502); plot_pz_stability(Gpos_outer, 'G_{pos,outer}');
xlim([-10 2]); ylim([-10 10]);
saveas(gcf, fullfile(IMG_DIR, 'regbot_task4_plant_pz.png'));


%% ------------------- Write to workspace + gains block ------------------
Kppos = Kp_pos;
tdpos = tau_d_pos;

fprintf('==============================================================\n');
fprintf('  Copy-paste this block into regbot_mg.m (Task 4 gains)\n');
fprintf('==============================================================\n');
fprintf('    Kppos  = %.4f;\n', Kppos);
fprintf('    tdpos  = %.4f;\n\n', tdpos);
