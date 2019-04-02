function [h_figure, p, settings] = sd_setup_figure(layers, settings)
% SD_SETUP_FIGURE Configures the figure window
%  
% DESCRIPTION
% This function computes the figure dimensions and the layout of the
% figure.
%  
% SYNTAX 
% [h_figure, p, settings] = SD_SETUP_FIGURE(layers, settings);
%
% layers        - Nx1 struct, specifying the N layers to be displayed (see)
% settings      - 1x1 struct, specifying the figure and display settings (see)
%
% h_figure      - figure handle
% p             - panel object (for details, type 'help panel')
% 
% ......................................................................... 
% Bram Zandbelt (bramzandbelt@gmail.com), Radboud University

% Check which layers need colorbar
has_colorbar            = zeros(1:numel(layers));
has_standard_colorbar   = zeros(1:numel(layers));
has_dual_colorbar       = zeros(1:numel(layers));

for i_layer = 1:numel(layers)
    if ~isempty(layers(i_layer).color.label())
        has_colorbar(i_layer) = 1;
        
        switch lower(layers(i_layer).type)
            case {'truecolor','blob'}
                has_standard_colorbar(i_layer) = 1;
            case 'dual'
                has_dual_colorbar(i_layer) = 1;
        end
    end
end
i_colorbar = find(has_colorbar);
settings.fig_specs.i.colorbar = i_colorbar;
settings.fig_specs.n.colorbar = numel(find(find(has_colorbar)));
settings.fig_specs.n.colorbar_standard = numel(find(find(has_standard_colorbar)));
settings.fig_specs.n.colorbar_dual = numel(find(find(has_dual_colorbar)));

% Get settings
m           = settings.fig_specs.margin;
w           = settings.fig_specs.width;
h           = settings.fig_specs.height;
wc          = settings.fig_specs.width_constraints;
hc          = settings.fig_specs.height_constraints;
hw_ratio    = settings.fig_specs.height_width_ratio;
n           = settings.fig_specs.n;

% Map panel
% =========================================================================
% Slice constraints are respected when number of slice rows and columns
% remain unspecified. If user has specified number of slices rows
% and/or columns, slice constraints are ignored.

if all([isempty(n.slice_row),isempty(n.slice_column)])

    % Estimate number of slice panel rows and columns
    n.slice_column    = ceil(sqrt(n.slice/(hw_ratio.slice)));

    % Slice panel width
    w.slice                 = w.map_panel / n.slice_column;

    % If not within constraints, set to min or max width
    if all(w.slice >= wc.slice(1) & ...
           w.slice <= wc.slice(2))
    elseif w.slice < wc.slice(1)
        w.slice         = wc.slice(1);
        n.slice_column  = floor(w.map_panel / w.slice);    
    elseif w.slice > wc.slice(2)
        w.slice         = wc.slice(2);
        if ceil(w.map_panel / w.slice) * w.slice <= w.map_panel
            n.slice_column  = ceil(w.map_panel / w.slice);
        else 
            n.slice_column  = floor(w.map_panel / w.slice);
        end
    end

    n.slice_row         = ceil(n.slice / n.slice_column);
    
elseif all([~isempty(n.slice_row),isempty(n.slice_column)])
    n.slice_column      = ceil(n.slice / n.slice_row);
    w.slice             = w.map_panel / n.slice_column;
elseif all([isempty(n.slice_row),~isempty(n.slice_column)])
    w.slice             = w.map_panel / n.slice_column;
    n.slice_row         = ceil(n.slice / n.slice_column);
elseif all([~isempty(n.slice_row),~isempty(n.slice_column)])
    w.slice             = w.map_panel / n.slice_column;
end

h.slice             = w.slice * hw_ratio.slice;
h.map_panel         = h.slice * n.slice_row;

% Legend panel
% =========================================================================

if n.colorbar >= 1
    n.colorbar_row      = 1;
    n.colorbar_column   = n.colorbar;
    if n.colorbar_dual >= 1
        h.legend_panel      = 10;
    else
        h.legend_panel      = 5;
    end
end

% Figure height
% =========================================================================

if n.colorbar >= 1
    prop_h_map      = h.map_panel / (h.map_panel + h.legend_panel);
    prop_h_colorbar = h.legend_panel / (h.map_panel + h.legend_panel);
    h.figure        = h.map_panel + h.legend_panel + ...
                      m.figure(2) + m.figure(4);
elseif n.colorbar == 0
    h.figure = h.map_panel + m.figure(2) + m.figure(4);
end

% Setup figure
% =========================================================================

% Make new figure
h_figure = figure;

% Get screen size
screen_size = get(0,'ScreenSize');

wf_pix = w.figure .* unitsratio('inches','mm') .* get(0,'ScreenPixelsPerInch');
hf_pix = h.figure .* unitsratio('inches','mm') .* get(0,'ScreenPixelsPerInch');

if wf_pix > screen_size(3) | hf_pix > screen_size(4)
   screen_wh_ratio = screen_size(3:4);
   pos = get(h_figure,'Position');
   pos(3:4) = min(screen_wh_ratio ./ [w.figure, h.figure]) .* [w.figure, h.figure];
   set(h_figure,'Position',[pos(3)/2,pos(4)/2,pos(3),pos(4)])
else
   left_pos = screen_size(3)/2 - wf_pix/2;
   bottom_pos = screen_size(4)/2 - hf_pix/2;
   set(h_figure,'Position',[left_pos,bottom_pos,wf_pix,hf_pix])
end

% Center figure on paper
set(h_figure, 'PaperType', settings.paper.type);
set(h_figure, 'PaperUnits', 'centimeters');

switch lower(settings.paper.orientation)
   case 'landscape'
      orient landscape
   case 'portrait'
      orient portrait
   otherwise
      orient portrait
end

% Paper settings
paper_dim = get(h_figure,'PaperSize');
paper_w = paper_dim(1);
paper_h = paper_dim(2);
x_left = (paper_w-w.figure/10)/2; 
y_top = (paper_h-h.figure/10)/2;
set(h_figure,'PaperPosition',[x_left, y_top, w.figure/10, h.figure/10]);

% Setup panels
% =========================================================================

figure(h_figure);
p = panel();

if n.colorbar >= 1
    p.pack('v',[prop_h_map, ...
                prop_h_colorbar]);

    norm_width  = 1/n.slice_column;
    norm_height = 1/n.slice_row;
    
    for i_row = 1:n.slice_row
        for i_col = 1:n.slice_column
            
            norm_left = i_col/n.slice_column - norm_width;
            norm_bottom = (n.slice_row - i_row)/n.slice_row;
            
            p(1).pack({[norm_left, norm_bottom, norm_width, norm_height]});
            
        end
    end

    p(2).pack(n.colorbar_row,n.colorbar_column)
    
    p.margin = m.figure;
    p.de.margin = m.panel;
    p(1).margin = m.slice;
    p(1).de.margin = m.slice;
    p(2).de.margin = m.colorbar;
    
elseif n.colorbar == 0
    p.pack('v',1)
    
    norm_width  = 1/n.slice_column;
    norm_height = 1/n.slice_row;
    
    for i_row = 1:n.slice_row
        for i_col = 1:n.slice_column
            
            norm_left = i_col/n.slice_column - norm_width;
            norm_bottom = (n.slice_row - i_row)/n.slice_row;
            
            p(1).pack({[norm_left, norm_bottom, norm_width, norm_height]});
            
        end
    end
    
    p.de.margin = m.figure;
    p(1).de.margin = m.slice;
end

% Update settings structure
settings.fig_specs.margin = m;
settings.fig_specs.width = w;
settings.fig_specs.height = h;
settings.fig_specs.width_constraints = wc;
settings.fig_specs.height_constraints = hc;
settings.fig_specs.width_height_ratio = hw_ratio;
settings.fig_specs.n = n;
settings.fig_specs.panel = p;