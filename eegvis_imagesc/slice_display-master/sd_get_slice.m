function slice = sd_get_slice(V, xyzmm, transform, vdims, hold)
% SD_GET_SLICE Obtains information from images
%  
% DESCRIPTION
% This function obtains information from images, including header
% specifics, transformation matrix, and slice dimensions and positions.
%  
% SYNTAX 
% [h_figure, p, settings] = SD_GET_SLICE(layers, settings);
%
% V             - 1x1 struct, containing image volume information (see spm_vol)
% xyzmm         - 4xN double of voxel coordinates in world space
% transform     - 4x4 double, specifying affine transformation matrix
% vdims         - 1x3 double, specifying voxel dimensions
% hold          - scalar or 1x2 double, specifying interpolation method for
%                 the for the resampling (see spm_sample_vol)
%
% slice         - NxM slice data
%
% ......................................................................... 
% Bram Zandbelt (bramzandbelt@gmail.com), Radboud University


% SLICE TO PANEL Selects slice data
% 
% hold - see spm_sample_vol
%
% This function largely identical to the sf_slice2panel subfunction in the
% panel function of the slover package that comes with SPM.
%

% to voxel space of image
vixyz = (transform*V.mat) \ xyzmm;

% return voxel values from image volume
if isempty(hold)
    hold = 1;
end


slice = spm_sample_vol(V,vixyz(1,:),vixyz(2,:),vixyz(3,:), hold);

% transpose to reverse X and Y for figure
slice = reshape(slice, vdims(1:2))';

end

