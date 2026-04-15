function img_dir = pick_image_dir()
%PICK_IMAGE_DIR  Return the folder where design plots should be saved.
%
% Uses the Obsidian vault if available (Mads' setup); otherwise falls
% back to <repo>/docs/images (created if missing). Set FORCE_LOCAL = true
% inside this function to force the local docs/images path.
FORCE_LOCAL = false;

here = fileparts(fileparts(mfilename('fullpath')));   % simulink/
obs  = fullfile(here, '..', '..', '..', '..', 'Obsidian', 'Courses', ...
    '34722 Linear Control Design 1', 'Exercises', 'Work', 'regbot', 'Images');
docs = fullfile(here, '..', 'docs', 'images');

if ~FORCE_LOCAL && exist(obs, 'dir')
    img_dir = obs;
else
    img_dir = docs;
    if ~exist(img_dir, 'dir'), mkdir(img_dir); end
end
end
