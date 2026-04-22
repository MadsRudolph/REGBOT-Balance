function img_dir = pick_image_dir()
%PICK_IMAGE_DIR  Return the folder where design plots should be saved.
%
% Always the submodule's docs/images/ folder. Historically this helper
% also mirrored into the DTU Obsidian vault, but docs/ is now the sole
% source of truth for both notes and figures -- keeping two copies in
% sync became a constant chore.
%
% The folder is created if missing so the first design-script run on a
% fresh clone does not fail.

here    = fileparts(fileparts(mfilename('fullpath')));   % simulink/
img_dir = fullfile(here, '..', 'docs', 'images');

if ~exist(img_dir, 'dir')
    mkdir(img_dir);
end
end
