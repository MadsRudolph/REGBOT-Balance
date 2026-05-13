function img_dir = pick_image_dir()
%PICK_IMAGE_DIR  Return docs/images/ in the repo, creating it if missing.

here    = fileparts(fileparts(mfilename('fullpath')));   % simulink/
img_dir = fullfile(here, '..', 'docs', 'images');

if ~exist(img_dir, 'dir')
    mkdir(img_dir);
end
end
