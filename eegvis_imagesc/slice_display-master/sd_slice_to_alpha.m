function Y_alpha = sd_slice_to_alpha(Y, layer)
% SD_SLICE_TO_ALPHA Converts 2D slice data to 2D opacity coding
%  
% DESCRIPTION
% Converts 2D slice data to 2D opacity coding, based on value range
% specified in layer struct.
%
% SYNTAX 
% Y_alpha = SD_SLICE_TO_ALPHA(Y, layer)
%
% Y             - NxM double, containing slice data
% layer         - layer struct of current layer
%
% Y_alpha       - NxM double, containing opacity data
% 
% ......................................................................... 
% Bram Zandbelt (bramzandbelt@gmail.com), Radboud University

Y_alpha                                     = abs(Y);
Y_alpha(Y_alpha  > layer.opacity.range(2))  = layer.opacity.range(2);
Y_alpha(Y_alpha  < layer.opacity.range(1))  = 0;
Y_alpha                                     = Y_alpha / layer.opacity.range(2);