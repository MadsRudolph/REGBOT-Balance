%% Task 4 — Position outermost loop (P, Lead dropped for firmware)
%  Plant:  Gpos,outer(s) = pos_ref -> x_position (Tasks 1+2+3 closed).
%          Type-1 (free integrator v -> x), so pure P gives e_ss = 0.
%  Specs:  wc = 0.6 rad/s (iterated against mission), gamma_M >= 60 deg.
%  Prereq: Tasks 1-3 gains committed in regbot_mg.m.

close all; clear;

addpath(fileparts(mfilename('fullpath')));
regbot_mg;

s     = tf('s');
model = 'regbot_1mg';

POS_CTRL_OUT_BLOCK = '/Kppos_gain';
X_POS_BLOCK        = '/robot with balance';
X_POS_PORT         = 3;       % port 3 = x_position


%% ====== STEP 0 — IDENTIFY THE PLANT =====
% Break the position loop at Kppos_gain; Tasks 1-3 stay closed.
Kppos = 0;     %#ok<NASGU> breaks the position loop for linearisation

load_system(model);
open_system(model);

io(1) = linio([model POS_CTRL_OUT_BLOCK], 1,          'openinput');
io(2) = linio([model X_POS_BLOCK],        X_POS_PORT, 'openoutput');
setlinio(model, io);
sys        = linearize(model, io, 0);
[num, den] = ss2tf(sys.A, sys.B, sys.C, sys.D);
Gpos_outer = minreal(tf(num, den));

P_count = sum(real(pole(Gpos_outer)) > 0);
n_int   = sum(abs(pole(Gpos_outer)) < 1e-6);   % poles ~ 0

print_tf('Gpos_outer', Gpos_outer);
fprintf('Poles:  '); fprintf('%7.2f  ', sort(real(pole(Gpos_outer)))); fprintf('\n');
fprintf('Zeros:  '); fprintf('%7.2f  ', sort(real(zero(Gpos_outer)))); fprintf('\n');
fprintf('DC gain     = %.4e\n', dcgain(Gpos_outer));
fprintf('RHP poles   = %d\n', P_count);
fprintf('integrators = %d\n', n_int);
% One pole at the origin (the v -> x integrator) makes the open loop
% Type-1, so a pure P controller already gives zero steady-state error
% to a step reference.
fprintf('-> Type-%d (pure P gives e_ss = 0 on step)\n\n', n_int);


%% ====== STEP 1 — PICK wc =====
% wc iterated against the 2 m mission spec (peak v >= 0.7 m/s, reach 2 m
% within 10 s; the 2% settle envelope is pessimistic):
%   wc = 0.2 -> peak v 0.33, settle 20 s     FAIL
%   wc = 0.5 -> peak v 0.68, settle 12 s     close
%   wc = 0.6 -> peak v 0.77, settle ~11 s    CHOSEN (firmware, Lead dropped)
wc_pos       = 0.6;       % chosen against mission specs
gamma_M_spec = 60;        % course default

fprintf('wc = %.2f rad/s, gamma_M = %d deg\n\n', wc_pos, gamma_M_spec);


%% ====== STEP 2 — PHASE BALANCE =====
% No PI (plant already Type-1): phi_Lead = -180 + gamma_M - phi_G.
% High-order plant; unwrap can add +360 at wc -- wrap to [-180,180].
% phi_Lead comes out only ~ +2.85 deg (a small Lead) for this plant.
[~, phi_G_unwrapped] = bode(Gpos_outer, wc_pos);
phi_G_unwrapped = squeeze(phi_G_unwrapped);
phi_G      = mod(phi_G_unwrapped + 180, 360) - 180;
phi_Lead   = mod(-180 + gamma_M_spec - phi_G + 180, 360) - 180;
tau_d_pos  = tand(phi_Lead) / wc_pos;   % ideal Lead time constant
C_Lead_pos = tau_d_pos*s + 1;           % ideal Lead (tau_d s + 1)

fprintf('phase wrapped = %+.2f deg\n', phi_G);
fprintf('phi_Lead      = %+.2f deg  (small)\n', phi_Lead);
fprintf('tau_d (ideal) = %.4f s\n\n', tau_d_pos);


%% ====== STEP 3 — SOLVE Kp =====
% Magnitude condition: Kp = 1/|L| at wc. The Lead is ~unity-gain here,
% so dropping it (Step 4) barely moves Kp.
magL   = squeeze(bode(C_Lead_pos * Gpos_outer, wc_pos));
Kp_pos = 1 / magL;

fprintf('|L|        = %.4f at wc\n', magL);
fprintf('Kp = 1/|L| = %.4f\n\n',     Kp_pos);


%% ====== STEP 4 — LEAD DECISION =====
% The ideal Lead (tau_d s + 1) is improper -- Simulink's Transfer Fcn
% block rejects it. A proper Lead (tau_d s + 1)/(alpha tau_d s + 1) would
% add a fast filter pole whose lag costs back ~3 deg -- about the same as
% the ~3 deg the Lead was buying. So we drop the Lead and run pure P,
% accepting gamma_M ~ 57 deg instead of 60 deg.
tdpos_firmware  = 0;
C_Lead_firmware = tf(1);

fprintf('Lead dropped -> pure P (tdpos = 0); trades ~%.1f deg of PM\n\n', ...
    phi_Lead);


%% ====== STEP 5 — VERIFY =====
% Design controller (ideal Lead) vs firmware controller (Step-4 choice).
% Mission-spec checks use the firmware controller.
L_pos_design = Kp_pos * C_Lead_pos * Gpos_outer;
[GM_d, PM_d, ~, wc_d] = margin(L_pos_design);

L_pos_firmware = Kp_pos * C_Lead_firmware * Gpos_outer;
T_pos_firmware = feedback(L_pos_firmware, 1);
[GM_f, PM_f, ~, wc_f] = margin(L_pos_firmware);

fprintf('design:   wc = %.3f rad/s, PM = %.2f deg, GM = %.2f dB\n', ...
    wc_d, PM_d, 20*log10(GM_d));
fprintf('firmware: wc = %.3f rad/s, PM = %.2f deg, GM = %.2f dB\n', ...
    wc_f, PM_f, 20*log10(GM_f));
fprintf('RHP CL poles = %d\n\n', sum(real(pole(T_pos_firmware)) > 0));

% 2 m mission step (firmware controller)
[y_step, t_step] = step(2 * T_pos_firmware, 20);
peak_v   = max(gradient(y_step, t_step));
settle_i = find(abs(y_step - 2) > 0.02*2, 1, 'last');
settle_t = t_step(settle_i);

fprintf('peak v       = %.3f m/s\n', peak_v);
fprintf('settle (2%%)  = %.2f s\n\n', settle_t);


%% ------------------- Write to workspace + gains block ------------------
Kppos = Kp_pos;
tdpos = tdpos_firmware;       % Step-4 selection

fprintf('Kppos  = %.4f;\n',   Kppos);
fprintf('tdpos  = %.4f;\n\n', tdpos);
