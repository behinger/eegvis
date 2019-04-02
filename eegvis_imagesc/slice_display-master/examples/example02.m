% Example 02 - dual-coded map (contrast estimates and t-statistics) overlaid on an anatomical image

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
layers                              = sd_config_layers('init',{'truecolor','dual','contour'});
settings                            = sd_config_settings('init');

% Step 2: Define layers
% ------------------------------------------------------------------------------

% Layer 1: Anatomical map
layers(1).color.file                = fullfile(spm('Dir'),'canonical','single_subj_T1.nii');
layers(1).color.map                 = gray(256);

% Layer 2: Dual-coded layer (contrast estimates color-coded; t-statistics
% opacity-coded)
layers(2).color.file                = fullfile(data_dir,'con_0002.nii');
layers(2).color.map                 = CyBuGyRdYl;
layers(2).color.label               = '\beta_{faces} - \beta_{baseline} (a.u.)';
layers(2).opacity.file              = fullfile(data_dir,'spmT_0002.nii');
layers(2).opacity.label             = '| t |';
layers(2).opacity.range             = [0 5.77];

% Layer 3: Contour of significantly activated voxels
layers(3).color.file                = fullfile(data_dir,'F_vs_B_significant_voxels_FWE_voxel_level.nii');

% Specify settings
settings.slice.orientation          = 'axial';
settings.slice.disp_slices          = -30:10:60;
settings.fig_specs.n.slice_column   = 5;
settings.fig_specs.title            = 'faces - baseline';

% Display the layers
[settings,p] = sd_display(layers,settings);