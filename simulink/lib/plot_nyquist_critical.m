function plot_nyquist_critical(G, ttl)
%PLOT_NYQUIST_CRITICAL  Nyquist plot with (-1,0) highlighted and the
%open-loop RHP-pole count P displayed in the title.
clf
P = sum(real(pole(G))>0);
[re, im, w] = nyquist(G);
re = squeeze(re); im = squeeze(im);

hold on; grid on
plot(re,  im, 'b-', 'LineWidth',1.5);
plot(re, -im, 'b--','LineWidth',1.0);

th = linspace(0, 2*pi, 200);
plot(-1 + 0.05*cos(th), 0.05*sin(th), 'r-', 'LineWidth',1);
plot(-1, 0, 'r+', 'MarkerSize',14,'LineWidth',2);

xl = xlim; yl = ylim;
plot(xl, [0 0], 'k', 'LineWidth',0.5);
plot([0 0], yl, 'k', 'LineWidth',0.5);

k = max(2, round(length(w)/3));
quiver(re(k), im(k), re(k+1)-re(k), im(k+1)-im(k), 0, ...
       'Color','b','MaxHeadSize',2,'LineWidth',1.2,'AutoScale','off');

axis equal
xlabel('Re\{G(j\omega)\}'); ylabel('Im\{G(j\omega)\}');
title(sprintf('Nyquist: %s  (RHP poles P = %d)', ttl, P));
legend({'\omega > 0','\omega < 0','critical (-1,0)'}, 'Location','best');
hold off
end
