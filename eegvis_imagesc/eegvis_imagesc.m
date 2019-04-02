function imagesc_display(m,t,varargin)
cfg = finputcheck(varargin,...
    {'colorbar','boolean',[],1; % plot colorbar
    'figure','boolean',[],1;  % generate new figure
    'chanlocs','struct',[],struct(); % add labels
    'times','real',[],[]; % times
    'mask','real',[],[]; %additionally mask the input
    'xlabel','boolean',[],0;...
    'ylabel','boolean',[],0;...
    'clustermask','real',[],[]; % a clustermask
    'contour','boolean',[],0; % plot contour of all non-zero clustermask entries?
    },[],'ignore');

if ischar(cfg)
    error(cfg)
end
assert(~(cfg.contour & isempty(cfg.clustermask)),'please specify the clustermask to get contours, could also be abs(t)>2.3 or the likes')
assert(all(size(t) == size(m)));
if isempty(cfg.times)
    warning('no "times" specified, using 1:n')
    cfg.times = 1:size(m,2);
end
layer_types = {'dual','contour'}; % can have multiple layers
layers = sd_config_layers('init',layer_types);


layers(1).color.map = cbrewer('div','RdBu',  100,[]);
layers(1).color.map = layers(1).color.map(end:-1:1,:);

% layers(1).opacity.range             = [-5.77 5.77];
layers(1).color.data   = m;
layers(1).opacity.data = abs(t);
if ~isempty(cfg.clustermask)
    layers(2).color.data = cfg.clustermask;
else
    layers(2) = [];
end
layers      = sd_config_layers('fill-defaults',layers);

Y_m = cfg.mask; % don't specify for now
%%
if cfg.figure
    figure
end
for i_layer = 1:numel(layers)
    % all layers have color
    Y_c = layers(i_layer).color.data;
    
    % not all alyers have opacity
    try
        Y_o = layers(i_layer).opacity.data;
    catch
        Y_o = [];
    end
    
    
    % find color range
    if isempty(layers(i_layer).color.range)
        [color_max, color_min] = deal(max(Y_c(:)),min(Y_c(:)));
        
        % Make map symmetrical
        if color_min < 0
            abs_color_max = max(abs([color_max, color_min]));
            layers(i_layer).color.range = [-abs_color_max, abs_color_max];
        else
            layers(i_layer).color.range = [color_min, color_max];
        end
        
    end
    
    %find opacity range
    % Range
    % -----------------------------------------------------
    % Assume opacity-coding uses absolute numbers and map
    % ranges from 0 to absolute max.
    switch layers(i_layer).type
        case 'dual'
            if isempty(layers(i_layer).opacity.range)
                [opacity_max, opacity_min] = deal(max(Y_o(:)),min(Y_o(:)));
                
                abs_opacity_max = max(abs([opacity_max, opacity_min]));
                layers(i_layer).opacity.range = [0, abs_opacity_max];
            end
    end
    
    
    Y_rgb = sd_slice_to_rgb(Y_c,layers(i_layer));
    
    
    
    switch layers(i_layer).type
        case {'truecolor','blob','cluster'}
            Y_alpha = ones(size(Y_o)) .* layers(i_layer).color.opacity;
        case 'contour'
            
        case 'dual'
            % Convert to alpha map
            Y_alpha = sd_slice_to_alpha(Y_o,layers(i_layer)); % requires layers(i_layer).opacity.range(1:2)
            
    end
    
    % Masking
    % =================================================================
    
    if ~isempty(Y_m)
        % do nothing if prespecified
    else
        switch layers(i_layer).type
            case 'cluster'
                Y_m = ones(size(Y_c));
                Y_m(Y_c == 0) = 0;
            otherwise
                Y_m = ones(size(Y_c));
        end
    end
    
    % Display layer
    % =================================================================
    
    switch layers(i_layer).type
        case {'truecolor', 'blob', 'dual','cluster'}
            h_image = image(cfg.times,1:length(cfg.chanlocs),Y_rgb);
            set(h_image,'alphaData',Y_alpha .* Y_m);
            
            ix = round(linspace(1,length(cfg.chanlocs),15));
            labels = {cfg.chanlocs.labels};
            set(gca,'YTickLabels',labels(ix),'YTick',ix)
        case 'contour'
            contour_color = layers(i_layer).color.map;
            
            hold on
            [~, h_contour] = contour(cfg.times,1:length(cfg.chanlocs),Y_c,1);
            
            
            set(h_contour,'LineColor',contour_color)
            set(h_contour,'LineStyle',layers(i_layer).color.line_style);
            set(h_contour,'LineWidth',layers(i_layer).color.line_width);
    end
    
    
end
if cfg.xlabel
xlabel('Time [ms]')
end
if cfg.ylabel
ylabel('Channel')
end
box off
%%

i_layer = 1;
imagepos = get(gca,'Position');
cbarpos = imagepos;

imagepos(2) = imagepos(2)+imagepos(4)*.2;

cbarpos(4) = imagepos(4)*.1;
imagepos(4) = imagepos(4)*.8;

set(gca,'Position',imagepos)

if cfg.colorbar
    axes('Position',cbarpos)
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
                'YDir','normal',...
                'XLim',layers(i_layer).color.range, ...
                'YLim',layers(i_layer).opacity.range, ...
                'YTick',layers(i_layer).opacity.range, ...
                'YTickLabel',{layers(i_layer).opacity.range(1),sprintf('>%.1f',layers(i_layer).opacity.range(2))});
            
    end
end