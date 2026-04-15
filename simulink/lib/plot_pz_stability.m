function plot_pz_stability(G, ttl)
%PLOT_PZ_STABILITY  Pole-zero map with shaded LHP (green) / RHP (red).
clf
p = pole(G); z = zero(G);
all_pts = [p; z];
if isempty(all_pts), lim = 10;
else, lim = max(max(abs(real(all_pts))), max(abs(imag(all_pts))))*1.2+1;
end

hold on
patch([0 -lim -lim 0], [-lim -lim lim lim], [0.85 1 0.85], ...
      'EdgeColor','none','FaceAlpha',0.5);
patch([0  lim  lim 0], [-lim -lim lim lim], [1 0.85 0.85], ...
      'EdgeColor','none','FaceAlpha',0.5);
plot([-lim lim],[0 0],'k','LineWidth',0.5);
plot([0 0],[-lim lim],'k','LineWidth',1.5);
plot(real(p), imag(p), 'rx', 'MarkerSize',14,'LineWidth',2.5);
plot(real(z), imag(z), 'bo', 'MarkerSize',12,'LineWidth',2);
rhp = p(real(p)>0);
if ~isempty(rhp)
    plot(real(rhp), imag(rhp), 'o', 'MarkerSize',20, ...
         'MarkerEdgeColor',[1 0.6 0], 'LineWidth',2.5);
end
xlim([-lim lim]); ylim([-lim lim]); axis equal; grid on
xlabel('Real axis'); ylabel('Imaginary axis');
title(sprintf('Pole-zero map: %s', ttl));
text(-lim*0.6, lim*0.85,'LHP (stable)','Color',[0 0.5 0],'FontWeight','bold');
text( lim*0.15, lim*0.85,'RHP (unstable)','Color',[0.7 0 0],'FontWeight','bold');
legend_items = {'Poles','Zeros'};
if ~isempty(rhp), legend_items{end+1} = 'RHP poles (unstable)'; end
legend(legend_items, 'Location','best');
hold off
end
