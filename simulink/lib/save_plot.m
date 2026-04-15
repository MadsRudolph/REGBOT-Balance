function save_plot(fig, plot_fn, ttl, img_dir, fname)
%SAVE_PLOT  Run a plotting closure into fig, title + grid it, and save.
figure(fig); plot_fn(); grid on;
title(ttl);
saveas(fig, fullfile(img_dir, fname));
end
