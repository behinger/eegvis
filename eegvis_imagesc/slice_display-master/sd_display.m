function [settings, p] = sd_display(layers, settings)
% SD_DISPLAY Displays one or more layers of a series of NIfTI image slices
% 
% DESCRIPTION
% Displays layered brain maps
%  
% SYNTAX 
% [settings, p] = SD_DISPLAY(layers, settings);
%
% layers        - Nx1 struct, specifying the N layers to be displayed (for
%                 details, type 'help sd_config_layers')
% settings      - 1x1 struct, specifying the figure and display settings
%                 (for details, type 'help sd_config_settings')
%
% p             - panel object (for details, type 'help panel')
%
% EXAMPLES
% Display the single subject T1-weighted scan in SPM's canonical directory
% layers                = sd_config_layers('init',{'truecolor'});
% settings              = sd_config_settings('init');
% layers(1).color.file  = fullfile(spm('Dir'),'canonical','single_subj_T1.nii');
% layers(1).color.map   = gray(256);
% sd_display(layers,settings);
%
% ......................................................................... 
% Bram Zandbelt (bramzandbelt@gmail.com), Radboud University

% Make sure required toolboxes are on path
assert(~isempty(spm('Dir')),'<a href="http://www.fil.ion.ucl.ac.uk/spm/">SPM</a> cannot be found; make sure it is on MATLAB''s search path.')
assert(exist('panel.m','file') > 0,'<a href="https://www.mathworks.com/matlabcentral/fileexchange/20003-panel">Panel</a> cannot be found; make sure it is on MATLAB''s search path')

% Fill in defaults for empty fields in settings and layers
% -------------------------------------------------------------------------
layers      = sd_config_layers('fill-defaults',layers);
settings    = sd_config_settings('fill-defaults',settings);

% Gather information from image(s)
% -------------------------------------------------------------------------
settings    = sd_get_image_specs(layers, settings);

transform   = settings.slice.transform;
x           = settings.slice.x;
y           = settings.slice.y;
zmm         = settings.slice.zmm;
vdims       = settings.slice.vdims;
nvox        = prod(vdims(1:2));

% Set up figure
% -------------------------------------------------------------------------
[h_figure, ...
 p, ...
 settings]  = sd_config_figure(layers, settings);


% Display slices
% -------------------------------------------------------------------------

figure(h_figure);

if ~isempty(settings.fig_specs.title)
    title(settings.fig_specs.title);
    axis off
end

for i_slice = 1:settings.fig_specs.n.slice
    
    xyzmm = [x(:)';y(:)';ones(1,nvox)*zmm(i_slice);ones(1,nvox)];
    
    % Select axis/panel
    p(1, i_slice).select();
    
    axis image; axis off;
    p(1, i_slice).hold('on')
    
    
    
    for i_layer = 1:numel(layers)
        
        % Color-coding
        % =================================================================
        
        % Get slice data
        Y_c = sd_get_slice(layers(i_layer).color.header, ...
                           xyzmm, ...
                           transform, ...
                           vdims, ...
                           layers(i_layer).color.hold);
                       
        % Convert to RGB
        switch lower(layers(i_layer).type)
            case {'truecolor', 'blob', 'dual', 'cluster'}
                
                Y_rgb = sd_slice_to_rgb(Y_c,layers(i_layer),settings);
                
        end
        
        % Opacity settings
        switch lower(layers(i_layer).type)
            case {'truecolor','blob','cluster'}
                Y_alpha = ones(size(Y_c)) .* layers(i_layer).color.opacity;
            case 'contour'
        end
        
        % Opacity-coding
        % =================================================================
        
        switch lower(layers(i_layer).type)
            case 'dual'
                
                % Get slice data
                Y_o = sd_get_slice(layers(i_layer).opacity.header, ...
                                   xyzmm, ...
                                   transform, ...
                                   vdims, ...
                                   layers(i_layer).opacity.hold);
                
                % Convert to alpha map
                Y_alpha = sd_slice_to_alpha(Y_o,layers(i_layer));
                
        end
        
        % Masking
        % =================================================================
        
        if ~isempty(layers(i_layer).mask.file)
            
            Y_m = sd_get_slice(layers(i_layer).mask.header, ...
                               xyzmm, ...
                               transform, ...
                               vdims, ...
                               layers(i_layer).color.hold);
            
        else
            switch lower(layers(i_layer).type)
                case 'cluster'
                    Y_m = ones(size(Y_c));
                    Y_m(Y_c == 0) = 0;
                otherwise
                    Y_m = ones(size(Y_c));
            end
        end
        
        % Display layer
        % =================================================================
        
        switch lower(layers(i_layer).type)
            case {'truecolor', 'blob', 'dual','cluster'}
                h_image = image(Y_rgb);
                set(h_image,'alphaData',Y_alpha .* Y_m);
            case 'contour'
                contour_color = layers(i_layer).color.map;
                
                if strncmp(spm_type(layers(i_layer).color.header.dt),'int',3)
                    [~, h_contour] = contour(Y_c,1);
                else
                    % TODO: implement contour level(s) for float data
                    [~, h_contour] = contour(Y_c,1);
                end
                
                set(h_contour,'LineColor',contour_color)
                set(h_contour,'LineStyle',layers(i_layer).color.line_style);
                set(h_contour,'LineWidth',layers(i_layer).color.line_width);
        end
        
        % Display slice labels
        if settings.slice.show_labels
            
            text(.025,.025,sprintf('%d mm',settings.slice.zmm(i_slice)), ...
                             'Color','w', ...
                             'HorizontalAlignment','left', ...
                             'VerticalAlignment','bottom', ...
                             'Units','normalized', ...
                             'FontUnits','normalized', ...
                             'FontSize',0.075);
            
        end
        
        % Display orientation on last slice (L/R, 
        if i_slice == settings.fig_specs.n.slice
            if settings.slice.show_orientation
                switch lower(settings.slice.orientation)
                    case {'axial','coronal'}
                        text(.025,.975,'L', ...
                                 'Color','w', ...
                                 'HorizontalAlignment','left', ...
                                 'VerticalAlignment','top', ...
                                 'Units','normalized', ...
                                 'FontUnits','normalized', ...
                                 'FontSize',0.1);
                        text(.975,.975,'R', ...
                                 'Color','w', ...
                                 'HorizontalAlignment','right', ...
                                 'VerticalAlignment','top', ...
                                 'Units','normalized', ...
                                 'FontUnits','normalized', ...
                                 'FontSize',0.1);
                    case 'sagittal'
                        text(.025,.975,'P', ...
                                 'Color','w', ...
                                 'HorizontalAlignment','left', ...
                                 'VerticalAlignment','top', ...
                                 'Units','normalized', ...
                                 'FontUnits','normalized', ...
                                 'FontSize',0.1);
                        text(.975,.975,'A', ...
                                 'Color','w', ...
                                 'HorizontalAlignment','r', ...
                                 'VerticalAlignment','top', ...
                                 'Units','normalized', ...
                                 'FontUnits','normalized', ...
                                 'FontSize',0.1);
                end
            end
        end
    end
end

% Display color bars
% =========================================================================

for i_colorbar = 1:settings.fig_specs.n.colorbar
    
    i_layer = settings.fig_specs.i.colorbar(i_colorbar);
    
    [i_row,i_col] = ind2sub([settings.fig_specs.n.colorbar_row, ...
                             settings.fig_specs.n.colorbar_column], ...
                             i_colorbar);
    p(2,i_row,i_col).select();
    
    switch lower(layers(i_layer).type)
        case {'blob','cluster'}
            
            % Transform vectors coding for color and opacity into 2D matrix
            color_vector = linspace(layers(i_layer).color.range(1), ...
                                    layers(i_layer).color.range(2), ...
                                    size(layers(i_layer).color.map,1));
            alpha_vector = linspace(1,1, ...
                                    256);
            
            % Transform into a 2D matrix
            [color_mat,~] = meshgrid(color_vector,alpha_vector);
            
            % Plot the colorbar
            imagesc(color_vector,alpha_vector,color_mat);
            colormap(gca, layers(i_layer).color.map);
            axis tight
            
            h_xlabel = xlabel(layers(i_layer).color.label);
            set(h_xlabel,'interpreter','tex')
            
            if numel(unique(layers(i_layer).color.range)) == 1
                set(gca, 'Box', 'off', ...
                         'XTick',[], ...
                         'YTick',[]);
            else
                set(gca, 'Box', 'off', ...
                         'XLim',layers(i_layer).color.range, ...
                         'YTick',[]);
            end
            
        case 'dual'
            
            % Transform vectors coding for color and opacity into 2D matrix
            color_vector = linspace(layers(i_layer).color.range(1), ...
                                    layers(i_layer).color.range(2), ...
                                    size(layers(i_layer).color.map,1));
            alpha_vector = linspace(layers(i_layer).opacity.range(1), ...
                                    layers(i_layer).opacity.range(2), ...
                                    256);
                                
            % Transform into a 2D matrix
            [color_mat,alpha_mat] = meshgrid(color_vector,alpha_vector);
            
            % Plot the colorbar
            imagesc(color_vector,alpha_vector,color_mat);
            colormap(gca, layers(i_layer).color.map);
            alpha(alpha_mat);
            alpha('scaled');  
            axis tight
            
            h_xlabel = xlabel(layers(i_layer).color.label);
            h_ylabel = ylabel(layers(i_layer).opacity.label);
            set([h_xlabel, h_ylabel],'interpreter','tex')
            
            set(gca, 'Box', 'off', ...
                     'XLim',layers(i_layer).color.range, ...
                     'YLim',layers(i_layer).opacity.range, ...
                     'YTick',layers(i_layer).opacity.range, ...
                     'YTickLabel',{layers(i_layer).opacity.range(1),sprintf('>%.1f',layers(i_layer).opacity.range(2))});
                        
    end
end
