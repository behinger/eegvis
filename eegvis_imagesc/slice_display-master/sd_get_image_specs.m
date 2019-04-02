function settings = sd_get_image_specs(layers, settings)
% SD_GET_IMAGE_SPECS Obtains information from images
%  
% DESCRIPTION
% This function obtains information from images, including header
% specifics, transformation matrix, and slice dimensions and positions.
%  
% SYNTAX 
% [settings, p] = SD_GET_IMAGE_SPECS(layers, settings);
%
% layers        - Nx1 struct, specifying the N layers to be displayed (see)
% settings      - 1x1 struct, specifying the figure and display settings (see)
%
% p             - panel object
%
% ......................................................................... 
% Bram Zandbelt (bramzandbelt@gmail.com), Radboud University

% Image orientation
orientation_ix  = strcmpi(settings.slice.orientation, ...
                               {'axial', 'coronal', 'sagittal'});

% Candidate transformations
ts              = [0 0 0 0 0 0 1 1 1;...
                   0 0 0 pi/2 0 0 1 -1 1;...
                   0 0 0 pi/2 0 -pi/2 -1 1 1];

% Relevant transformation
transform       = spm_matrix(ts(orientation_ix,:));

% Image header
V               = layers(1).color.header;

% Image dimensions
D               = V.dim(1:3);

% Image transformation matrix
T               = transform * V.mat;

% Image corners
voxel_corners   = [1 1 1; ...
                   D(1) 1 1; ...
                   1 D(2) 1; ... 
                   D(1:2) 1; ...
                   1 1 D(3); ...
                   D(1) 1 D(3); ...
                   1 D(2:3) ; ...
                   D(1:3)]';
corners         = T * [voxel_corners; ones(1,8)];
sorted_corners  = sort(corners, 2);

% Voxel size
voxel_size      = sqrt(sum(T(1:3,1:3).^2));

% Slice dimensions
% - rows: x and y of slice image; 
% - cols: negative maximum dimension, slice separation, positive maximum dimenions
slice_dims      = [sorted_corners(1,1) voxel_size(1) sorted_corners(1,8); ...
                   sorted_corners(2,1) voxel_size(2) sorted_corners(2,8)];

% Slices (in mm, world space):
slices          = sorted_corners(3,1):voxel_size(3):sorted_corners(3,8);

% Plane coordinates
X               = 1;
Y               = 2;
Z               = 3;
dims            = slice_dims;
xmm             = dims(X,1):dims(X,2):dims(X,3);
ymm             = dims(Y,1):dims(Y,2):dims(Y,3);
zmm             = slices(ismember(slices,settings.slice.disp_slices));
[y, x]          = meshgrid(ymm,xmm');

% Voxel and panel dimensions
vdims           = [length(xmm),length(ymm),length(zmm)];
pandims         = [vdims([2 1]) 3];

% Fill in settings
settings.slice.transform                    = transform;
settings.slice.xmm                          = xmm;
settings.slice.ymm                          = ymm;
settings.slice.zmm                          = zmm;
settings.slice.disp_slices                  = zmm;
settings.slice.x                            = x;
settings.slice.y                            = y;
settings.slice.vdims                        = vdims;
settings.slice.pandims                      = pandims; % NB XY transpose for display
settings.fig_specs.height_width_ratio.slice = pandims(1)/pandims(2);
settings.fig_specs.n.slice_panel            = vdims(Z);


