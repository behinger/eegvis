% Example 01 - thresholded t-map overlaid on an anatomical image

% Define directories
example_dir = fileparts(mfilename('fullpath'));
data_dir    = fullfile(example_dir,'data');
sd_dir      = fileparts(example_dir);

% Make sure directory containing slice display functions is on path
addpath(sd_dir);

% Get custom colormaps
load(fullfile(sd_dir,'colormaps.mat'));

% Step 1: Initialize empty layers and settings variables
% ------------------------------------------------------------------------------
layers                              = sd_config_layers('init',{'truecolor','blob'});
settings                            = sd_config_settings('init');

% Step 2: Define layers
% ------------------------------------------------------------------------------
% Only the essential information is specified; other

% Layer 1: anatomical image
layers(1).color.file                = fullfile(spm('Dir'),'canonical','single_subj_T1.nii');
layers(1).color.map                 = gray(256);

% Layer 2: thresholded t-map
layers(2).color.file                = fullfile(data_dir,'spmT_0002.nii');
layers(2).color.map                 = CyBuBkRdYl;
layers(2).color.label               = 't-value';
layers(2).mask.file                 = fullfile(data_dir,'F_vs_B_significant_voxels_FWE_voxel_level.nii');

% Step 3: Specify other settings
% ------------------------------------------------------------------------------
settings.slice.orientation          = 'axial';
settings.slice.disp_slices          = -30:10:60;
settings.fig_specs.n.slice_column   = 5;
settings.fig_specs.title            = 'faces - baseline';

% Step 4: Display
% ------------------------------------------------------------------------------
sd_display(layers,settings);