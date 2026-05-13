%% Task 4 — Position outermost loop (P, Lead dropped for firmware)
%  Plant:  Gpos,outer(s) = pos_ref -> x_position (with Tasks 1+2+3 closed).
%          Type-1 (free integrator v -> x), so pure P gives e_ss = 0.
%  Specs:  wc_pos = 0.6 rad/s (iterated against mission, not derived),
%          gamma_M >= 60 deg.
%  Prereq: Tasks 1-3 gains pasted into regbot_mg.m; model has 'Kppos_gain'
%          and 'robot with balance' port 3 = x_position.
%  See docs/MATLAB Walkthrough.md §5 for the derivation.

close all; clear;

addpath(fileparts(mfilename('fullpath')));
regbot_mg;

s       = tf('s');
model   = 'regbot_1mg';
IMG_DIR = pick_image_dir();

POS_CTRL_OUT_BLOCK = '/Kppos_gain';
X_POS_BLOCK        = '/robot with balance';
X_POS_PORT         = 3;       % port 3 = x_position


%% ====== STEP 0 — IDENTIFY THE PLANT =====
% Linearise pos_ref -> x_position with the position loop broken at
% Kppos_gain. Tasks 1-3 stay closed.
Kppos = 0;     %#ok<NASGU>

load_system(model);
open_system(model);

io(1) = linio([model POS_CTRL_OUT_BLOCK], 1,          'openinput');
io(2) = linio([model X_POS_BLOCK],        X_POS_PORT, 'openoutput');
setlinio(model, io);
sys        = linearize(model, io, 0);
[num, den] = ss2tf(sys.A, sys.B, sys.C, sys.D);
Gpos_outer = minreal(tf(num, den));

P_count   = sum(real(pole(Gpos_outer)) > 0);
n_int     = sum(abs(pole(Gpos_outer)) < 1e-6);   % poles ~ 0

print_tf('Gpos_outer', Gpos_outer);

fprintf('Poles:  '); fprintf('%7.2f  ', sort(real(pole(Gpos_outer)))); fprintf('\n');
fprintf('Zeros:  '); fprintf('%7.2f  ', sort(real(zero(Gpos_outer)))); fprintf('\n');
fprintf('DC gain     = %.4e\n', dcgain(Gpos_outer));
fprintf('RHP poles   = %d\n', P_count);
fprintf('integrators = %d\n', n_int);
if n_int >= 1
    fprintf('-> Type-%d (pure P gives e_ss = 0 on step)\n\n', n_int);
end

%% ====== STEP 1 — PICK wc =====
% wc iterated against the 2 m mission spec (peak v >= 0.7 m/s, settle <= 10 s):
%   wc = 0.2 -> peak v 0.33, settle 20 s    FAIL
%   wc = 0.5 -> peak v 0.68, settle 12 s    close
%   wc = 0.6 -> peak v 0.82, settle ~10 s   CHOSEN
wc_pos       = 0.6;       % chosen against mission specs
gamma_M_spec = 60;        % course default

fprintf('wc      = %.2f rad/s\n', wc_pos);
fprintf('gamma_M = %d deg\n\n',    gamma_M_spec);


%% ====== STEP 2 — PHASE BALANCE =====
% No PI (plant is already Type-1): gamma_M - 180 = phi_G + phi_Lead.
% High-order plant; MATLAB unwrap can add +360 at wc -- wrap to [-180,180].
[~, phi_G_unwrapped] = bode(Gpos_outer, wc_pos);
phi_G_unwrapped = squeeze(phi_G_unwrapped);
phi_G    = mod(phi_G_unwrapped + 180, 360) - 180;
phi_Lead = mod(-180 + gamma_M_spec - phi_G + 180, 360) - 180;

if phi_Lead <= 0
    tau_d_pos   = 0;  C_Lead_pos = tf(1);
    lead_note   = 'no Lead needed -- phase margin already met';
elseif phi_Lead >= 89
    tau_d_pos   = NaN; C_Lead_pos = tf(1);
    lead_note   = sprintf('WARN: phi_Lead = %.1f deg too high', phi_Lead);
else
    tau_d_pos   = tand(phi_Lead) / wc_pos;
    C_Lead_pos  = tau_d_pos*s + 1;
    lead_note   = 'standard ideal Lead (tau_d s + 1)';
end

fprintf('phase (raw)   = %+.2f deg\n', phi_G_unwrapped);
fprintf('phase wrapped = %+.2f deg\n', phi_G);
fprintf('phi_Lead      = %+.2f deg\n', phi_Lead);
fprintf('tau_d         = %.4f s   (%s)\n\n', tau_d_pos, lead_note);

%% ====== STEP 3 — SOLVE Kp =====
magL    = squeeze(bode(C_Lead_pos * Gpos_outer, wc_pos));
Kp_pos  = 1 / magL;

fprintf('|L|        = %.4f at wc\n', magL);
fprintf('Kp = 1/|L| = %.4f\n\n',     Kp_pos);


%% ====== STEP 4 — LEAD DECISION =====
% Ideal Lead (tau_d s + 1) is improper -- Simulink Transfer Fcn rejects it.
% Options: (a) ideal -- rejected; (b) proper Lead with filter pole alpha<1;
% (c) drop the Lead, accept phi_Lead deg of PM cost.
% Drop if phi_Lead <= LEAD_DROP_THRESHOLD_DEG; otherwise proper Lead.
LEAD_DROP_THRESHOLD_DEG = 5;
ALPHA                   = 0.1;

if phi_Lead <= LEAD_DROP_THRESHOLD_DEG
    tdpos_firmware  = 0;
    C_Lead_firmware = tf(1);
    decision = sprintf(...
        'drop Lead (phi_Lead = %.2f deg <= threshold %.1f deg)', ...
        phi_Lead, LEAD_DROP_THRESHOLD_DEG);
else
    tdpos_firmware  = tau_d_pos;
    C_Lead_firmware = (tau_d_pos*s + 1) / (ALPHA*tau_d_pos*s + 1);
    decision = sprintf(...
        'proper Lead with alpha = %.2f (phi_Lead = %.2f deg > %.1f threshold)', ...
        ALPHA, phi_Lead, LEAD_DROP_THRESHOLD_DEG);
end

fprintf('phi_Lead       = %.2f deg\n', phi_Lead);
fprintf('drop threshold = %.1f deg\n', LEAD_DROP_THRESHOLD_DEG);
fprintf('decision       : %s\n\n',     decision);


%% ====== STEP 5 — VERIFY =====
% Margins for both the design controller (ideal Lead) and the firmware
% controller (Step-4-selected Lead). Mission-spec checks use the firmware
% controller; the design margins document the PM trade-off of dropping the
% Lead.
L_pos_design = Kp_pos * C_Lead_pos * Gpos_outer;
[GM_d, PM_d, ~, wc_d] = margin(L_pos_design);

L_pos_firmware = Kp_pos * C_Lead_firmware * Gpos_outer;
T_pos_firmware = feedback(L_pos_firmware, 1);
[GM_f, PM_f, ~, wc_f] = margin(L_pos_firmware);

fprintf('design:   wc = %.3f rad/s, PM = %.2f deg, GM = %.2f dB\n', wc_d, PM_d, 20*log10(GM_d));
fprintf('firmware: wc = %.3f rad/s, PM = %.2f deg, GM = %.2f dB\n', wc_f, PM_f, 20*log10(GM_f));
fprintf('RHP CL poles = %d\n\n', sum(real(pole(T_pos_firmware)) > 0));

% 2 m mission step (firmware controller)
[y_step, t_step] = step(2 * T_pos_firmware, 20);
peak_v   = max(gradient(y_step, t_step));
settle_i = find(abs(y_step - 2) > 0.02*2, 1, 'last');
settle_t = t_step(settle_i);

fprintf('peak v       = %.3f m/s\n', peak_v);
fprintf('settle (2%%)  = %.2f s\n\n', settle_t);

save_plot(figure(500), @() margin(L_pos_firmware), ...
    'Open-loop  L = C_{pos} G_{pos,outer}  (firmware)', ...
    IMG_DIR, 'regbot_task4_loop_bode.png');


%% ------------------- Write to workspace + gains block ------------------
Kppos = Kp_pos;
tdpos = tdpos_firmware;       % whatever Step 4 selected

fprintf('Kppos  = %.4f;\n',   Kppos);
fprintf('tdpos  = %.4f;\n\n', tdpos);
