function Y_rgb = sd_slice_to_rgb(Y, layer)
% SD_SLICE_TO_RGB Converts 2D slice data to 3D RGB color coding
%  
% DESCRIPTION
% This function uses the pr_scaletocmap function, which is part of SPM's
% slover toolbox, to convert image data to RGB color using the color coding
% scheme specified in the layer's colormap.
%  
% SYNTAX 
% Y_rgb = SD_SLICE_TO_RGB(Y, layer, settings)
%
% Y             - NxM double, containing slice data
% layer         - layer struct of current layer
% settings      - settings struct
%
% Y_rgb         - NxMx3 double, containing RGB values
% 
% ......................................................................... 
% Bram Zandbelt (bramzandbelt@gmail.com), Radboud University

% Panel dimenstions
% pandims             = settings.slice.pandims;

% Use slover to scale slice to color map indices
Y_map_i             = pr_scaletocmap(Y, ...
                                     layer.color.range(1), ...
                                     layer.color.range(2), ...
                                     layer.color.map, ...
                                     [0 256 0]);

% Convert to RGB
Y_rgb                       = reshape(layer.color.map(Y_map_i(:),:),....
                                      [size(Y_map_i),3]);
Y_rgb(Y_rgb > 1)            = 1;   

% Subfunctions - copied from slover

function [img, badvals]=pr_scaletocmap(inpimg,mn,mx,cmap,lrn)
% scales image data to colormap, returning colormap indices
% FORMAT [img, badvals]=pr_scaletocmap(inpimg,mn,mx,cmap,lrn)
% 
% Inputs
% inpimg     - matrix containing image to scale
% mn         - image value that maps to first value of colormap
% mx         - image value that maps to last value of colormap
% cmap       - 3xN colormap
% lrn        - 1x3 vector, giving colormap indices that should fill:
%              - lrn(1) (L=Left) - values less than mn
%              - lrn(2) (R=Right) - values greater than mx
%              - lrn(3) (N=NaN) - NaN values
%             If lrn value is 0, then colormap values are set to 1, and
%             indices to these values are returned in badvals (below)
% 
% Output
% img        - inpimg scaled between 1 and (size(cmap, 1))
% badvals    - indices into inpimg containing values out of range, as
%              specified by lrn vector above
% 
% $Id: pr_scaletocmap.m,v 1.1 2005/04/20 15:05:00 matthewbrett Exp $

if nargin <  4
  error('Need inpimg, mn, mx, and cmap');
end

cml = size(cmap,1);

if nargin < 5
  lrn = [1 cml 0];
end

img = (inpimg-mn)/(mx-mn);  % img normalized to mn=0,mx=1
if cml==1 % values between 0 and 1 -> 1
  img(img>=0 & img<=1)=1;
else
  img = img*(cml-1)+1;
end
outvals = {img<1, img>cml, isnan(img)};
img= round(img);
badvals = zeros(size(img));
for i = 1:length(lrn)
  if lrn(i)
    img(outvals{i}) = lrn(i);
  else
    badvals = badvals | outvals{i};
    img(outvals{i}) = 1;
  end    
end
return