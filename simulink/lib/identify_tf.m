function G = identify_tf(model, in_block, out_block)
%IDENTIFY_TF  Linearise a Simulink model between two named signals.
%
%   G = identify_tf(model, in_block, out_block)
%
% Inserts an openinput point at model/in_block (port 1) and an openoutput
% point at model/out_block (port 1), runs linearize at t = 0, and returns
% the resulting transfer function in minimum realisation.
io(1) = linio(strcat(model, in_block),  1, 'openinput');
io(2) = linio(strcat(model, out_block), 1, 'openoutput');
setlinio(model, io);
sys = linearize(model, io, 0);
[num, den] = ss2tf(sys.A, sys.B, sys.C, sys.D);
G = minreal(tf(num, den));
end
