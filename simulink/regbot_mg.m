%% regbot_mg.m — workspace loader for the REGBOT Balance Assignment.
%  Populates physical params and the committed controller gains so
%  regbot_1mg.slx can compile and simulate. Each gain block names the
%  design script that produced it. See docs/MATLAB Walkthrough.md.

this_dir = fileparts(mfilename('fullpath'));
addpath(this_dir);
addpath(fullfile(this_dir, 'lib'));


%% ----------------------------- Physical parameters --------------------
% Motor — electrical (two motors in parallel)
RA   = 3.3/2;            % armature resistance          [ohm]
LA   = 6.6e-3/2;         % armature inductance          [H]
Kemf = 0.0105;           % EMF / torque constant        [V s/rad]
Km   = Kemf;             % torque constant              [N m/A]

% Motor — mechanical (two motors)
JA   = 1.3e-6 * 2;       % rotor inertia                [kg m^2]
BA   = 3e-6   * 2;       % rotor friction               [N m s/rad]
NG   = 9.69;             % gear ratio

% Vehicle
WR   = 0.03;             % wheel radius                 [m]
Bw   = 0.155;            % distance between wheels      [m]

% Masses and geometry
mmotor    = 0.193;                        % motor + gear                     [kg]
mframe    = 0.32;                         % frame + base PCB                 [kg]
mtopextra = 0.97 - mframe - mmotor;       % top mass (battery + charger)     [kg]
mpdist    = 0.10;                         % distance to lid                  [m]
pushDist  = 0.10;                         % disturbance application (Z)      [m]

% Simulation settings
startAngle = 10;         % initial tilt at t = 0        [deg]
twvlp      = 0.005;      % wheel-velocity filter tau    [s]


%% ----------------------------- Committed controller gains -------------

% --- Task 1: Wheel-speed PI (design_task1_wheel.m) ---------------------
% wc = 30 rad/s, PM = 82.85 deg, GM = Inf dB. Plant Gvel = 2.198/(s+5.985).
Kpwv   = 13.2037;
tiwv   = 0.1000;
Kffwv  = 0;

% --- Task 2: Balance PI-Lead + post-integrator (design_task2_balance.m) -
% wc = 15 rad/s, PM = 60 deg, Ni = 3. Linear-model IC settling 1.34 s.
Kptilt = 1.1999;
titilt = 0.2000;
tdtilt = 0.0442;
tipost = 0.1245;

% --- Task 3: Velocity outer PI (design_task3_velocity.m) ---------------
% wc = 1 rad/s (RHP-zero z/5 rule), PM = 68.98 deg, GM = 5.84 dB.
Kpvel  = 0.1581;
tivel  = 3.0000;

% --- Task 4: Position P (design_task4_position.m) ----------------------
% Pure P on Gpos,outer (Type-1 plant). wc = 0.6 rad/s, PM = 57 deg.
% Lead dropped: ideal (tau_d s + 1) is improper (Simulink rejects), and a
% proper-Lead block isn't worth the ~3 deg PM cost. Linear 2 m step:
% peak v = 0.753 m/s (spec >= 0.7 m/s).
Kppos  = 0.5411;
tdpos  = 0;
