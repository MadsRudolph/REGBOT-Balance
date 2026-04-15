function out = ternary(cond, a, b)
%TERNARY  Minimal inline if/else helper: ternary(c, a, b) == (c ? a : b).
if cond, out = a; else, out = b; end
end
