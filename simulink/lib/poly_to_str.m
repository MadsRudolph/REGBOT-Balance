function s = poly_to_str(p)
%POLY_TO_STR  Turn a polynomial coefficient vector into a human-readable
%string in the Laplace variable s.
p = p(:)';
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
