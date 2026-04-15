function print_tf(name, G)
%PRINT_TF  Display a transfer function in polynomial form with a fixed
%layout, independent of MATLAB's `tf` display settings.
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
