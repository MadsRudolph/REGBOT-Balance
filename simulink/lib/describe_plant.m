function describe_plant(G)
%DESCRIBE_PLANT  Compact summary (poles, zeros, DC gain, RHP-pole count).
fprintf('  Poles:  '); fprintf('%7.2f  ', sort(real(pole(G)))); fprintf('\n');
fprintf('  Zeros:  '); fprintf('%7.2f  ', sort(real(zero(G)))); fprintf('\n');
fprintf('  DC gain   = %.4e\n', dcgain(G));
fprintf('  RHP poles = %d  (anything > 0 means the plant is unstable)\n\n', ...
        sum(real(pole(G))>0));
end
