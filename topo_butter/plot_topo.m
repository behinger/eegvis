function hA = plot_topo(inp_data,inp_times,chanlocs,varargin)
g = finputcheck(varargin,...
    {'n_topos','integer',[],15; % How many topos to divide the time in
    'caxis','integer',[],[]; % custom color-scale
    'highlighted_channel','integer',[1 1:size(inp_data,1)],[]; % highlight a single channel in the first topoplot
    'pvalues','real',[],[]; % if you want to highlight clusters/electrodes that are significant. Can be 0/1 binairy or p-values, in that case 'topoalpha'(default 0.05) is used as a cutoff
    'time','real',[min(inp_times), max(inp_times)],[]; % specify the time to plot the topoplots in
    'topoalpha','real',[],0.05; % change the statistical alpha-value indicating significant electrodes
    'contour','string',{'yes','no'},'yes'; % activate/deactive contour
    'individualcontour','string',{'yes','no'},'no'; % do not put the contour lines on the same value
    'individualcolormap','string',{'yes','no'},'no'; % do not put the same caxis limit for all colormaps
    'colormap','cell',{},{'div'}; % customized colorbars are possible: {{'div','RdYlBu'},{'div','BrBG'},'seq'}. The whole set of colorbrewer is available
    'n_rows','integer',[1 1:size(inp_data,3)],size(inp_data,3); % number of rows to be used, by default plots one row per third-dimension entry of EEG.data. But it is possible to skip some*
    'numcontour','integer',[],6; % How many contour lines
    'parentAxes','',[],gca;
    },[],'ignore');

%* the [1 1:size] is necessary as the finputchecker needs two values. Thus
% if there is only a single third dimension, only a single value would be
% inputted and and error results.

background_color = get(gcf,'Color'); %eeglab has the tendency to make this aweful blue background. At the end we restore the original backgroundcolor
if isstr(g)
    error(g)
end
hA = struct; %struct for handles
hA.parent = g.parentAxes;

%% Figure out the timing limits and calculate where to put the topoplots
if isempty(g.time)
    plt.time = inp_times;
else
    assert(length(g.time)>1,'error, please provide either no time or two timepoints')
    plt.timeidx = inp_times>g.time(1) & inp_times<g.time(2);
    plt.time = inp_times(plt.timeidx);
end


plt.topotimes = linspace(min(plt.time),max(plt.time),g.n_topos+1);

%% Define Colorbars
cMap = [];

% We can have divergent or sequential colormaps, each row has one colormap.
for row = 1:g.n_rows
    if length(g.colormap) < row
        cm = g.colormap{end};
    else
        cm = g.colormap{row};
    end
    if iscell(cm)
        ctype  = cm{1};
        cname = cm{2};
    else
        ctype = cm;
        if strcmp(cm,'div')
            cname = 'RdYlBu';
            
        elseif strcmp(cm,'seq')
            cname = 'RdPu';
        else
            error('unknown colorbar definition')
        end
        
        
    end
    cMap.topo(row,:,:) = cbrewer(ctype,cname,  100,[]);
    cMap.topo(row,:,:) = cMap.topo(row,end:-1:1,:); % I don't like the way cbrewer sorts the color, we reverse all colormaps
    cMap.ctype{row} = ctype;
    
end
cMap.lines = cbrewer('qual','Set1',8);%
%% Define topo positions
parentPos = get(g.parentAxes,'Position');
axis off

pos_width = parentPos(3)/(g.n_topos+2);
pos_height = parentPos(4)/g.n_rows;

x_pos = parentPos(1) + (0:pos_width:(parentPos(3)-pos_width));
y_pos = parentPos(2) + (parentPos(4)-pos_height:-pos_height:0);
topo_pos = [];
for row = 1:g.n_rows
    for n = 1:length(x_pos)
        topo_pos(row,n,:) = [x_pos(n) y_pos(row) pos_width,pos_height];
    end
end

%% Plot the Indicator Topoplot
hA.indicator = axes('position',topo_pos(1,1,:));

topoplot([zeros(1,length(chanlocs))],chanlocs,'style','map','colormap',[1 1 1],...
    'electrodes','on', 'emarker2',{g.highlighted_channel,'o','r',5,1});
set(findobj(hA.indicator,'Type','patch'),'FaceColor',background_color) % there is a patch object which hides the pixelated border of the topo-map. Hide it!

colormap(hA.indicator,[1 1 1])

%% Plot the other topoplots
for row = 1:g.n_rows
    tic
    fprintf('Plotting Topoplots ... ')
    % Calculate the data for each topoplot
    data = [];
    sigElecs = {};
    for k = 1:length(plt.topotimes)-1
        toT = find(inp_times<plt.topotimes(k+1),1,'last');
        fromT = find(inp_times>=plt.topotimes(k),1,'first');
        if (fromT-toT) <=1
            % we only have one element
            data(k,:) = inp_data(:,fromT,row); 
        elseif any(isnan(inp_data(:)))
            data(k,:) = nanmedian(inp_data(:,fromT:toT,row),2);
            warning('nans detected, cannot use winsorized Mean. Falling back to nanmedian')
        else
            data(k,:) = winMean(inp_data(:,fromT:toT,row),2);
        end
        
        if ~isempty(g.pvalues)
            if length(unique(g.pvalues)) == 2 % already thresholded
                sigElecs{k} = any(g.pvalues(:,fromT:toT)'<g.topoalpha);
            else
                sigElecs{k} = any(g.pvalues(:,fromT:toT)'<g.topoalpha);
            end
        end
    end
    
    if ~isempty(g.caxis)
        scale = g.caxis;
    else
    scale = prctile(data(:),[1 99]);
    end
    
    % make scale symmetric for divergent colormaps
    if strcmp(cMap.ctype{row},'div')
        scale = max(abs(scale));
        scale = [-scale scale];
    end
    
    % Calculate the contourvals, we want to have the same contours for each
    % row
    contourvals = linspace(scale(1),scale(2),g.numcontour+2);
    contourvals = contourvals(2:end-1);
    
    for k = 1:length(plt.topotimes)-1
        
        topo_image = axes('position',topo_pos(row,k+1,:));% The axes for the data
        topo_init = axes('position',topo_pos(row,k+1,:));% The axes for the contour + head
        
        % Make the initial topoplot
        topoargin = {'maplimits',scale,...
            'electrodes','off','gridscale',120};
        
        switch g.individualcontour
            case 'yes'
                 topoargin = [topoargin 'numcontour',g.numcontour];
            case'no'
                topoargin = [topoargin 'numcontour',[contourvals]];
        end
        if ~isempty(g.pvalues) % we want to mark significant electrodes
            emarker2 = {[find(sigElecs{k})] '.','k',10,1};
            topoargin = [topoargin 'emarker2',{emarker2}];
        end
        
        [~,cdata] = topoplot(data(k,:),chanlocs,topoargin{:});
        
        
        % We delete the surface and replace it with a imagesc plot. This
        % allows for better exporting.
        delete(findobj(topo_init,'Type','surface'))
        if strcmp(g.contour,'no')
            delete(findobj(topo_init,'Type','contour'))
        end
        set(findobj(topo_init,'Type','patch'),'FaceColor',background_color) % there is a patch object which hides the pixelated border of the topo-map. Hide it!
        
        % Generate a new axis to plot the imagesc plot
        axes(topo_image); % in newer matlabversions this can be moved into imagesc, but for backwards compatibility we keep it like this
        uistack(topo_image,'bottom'); %due to the above fix, we have to reorder. axes(topo_image) puts the topo_image axes into the front (which we dont want)
        h = imagesc(cdata);
        
        set(topo_image,'YDir','normal');
        axis(topo_image,'square','off')
        set(h,'alphadata',~isnan(cdata))
        switch g.individualcolormap
            case 'no'
                caxis(topo_image,scale)
        end
        % Change the respective colormap
        colormap(topo_image,squeeze(cMap.topo(row,:,:)))
        
        hA.topo{row}.image{k} = topo_image;
        hA.topo{row}.lines{k} = topo_init;
    end
    
    %% Do the  Colorbars
   if scale(1) == scale(2)
        warning('min and max of data is the same, not printing colorbar. Is there any data in the topoplot at all?')
        continue
    end
    ax_colorbar = axes('position',topo_pos(row,end,:));
    
    colormap(ax_colorbar,squeeze(cMap.topo(row,:,:)))
    caxis(ax_colorbar,scale)

    
    set(ax_colorbar, 'CLim', [scale]);% not sure if really necessary.
    
    
    % We want only 2 (3) Ticklabels  one at the top, one at the bottom (one at 0 if divergent colormap). But all Tickmarks of the contourlines.
    % http://stackoverflow.com/questions/26917900/rounding-to-n-significant-digits
    % The top/bottom tick needs to be rounded to significant digits but the
    % top one needs to be floored, the bottom one ceiled. Else it can
    % happen that one of them is outside the range of the colormap and then
    % not displayed in the colorbar.
    d = 2; %// number of digits

    D = 10.^(d-ceil(log10(abs(scale))));
    sRound(1) =ceil( scale(1)*D(2))/D(2);
    sRound(2) =  floor(scale(2)*D(2))/D(2);
    
    colorbarTicks = [sRound round(contourvals,2,'significant')] ;
    
    if strcmp(cMap.ctype{row},'div') % add the 0 if there is divergend colormaps
        colorbarTicks(end+1) = 0;
    end
    colorbarTicks = sort(colorbarTicks); % the 0 and scale wasn't added in the middle
    
    
    c= colorbar('location','west');
    
    set(c , 'XTick', colorbarTicks)
    XTickLabel = get(c ,'XTickLabel');
    XTickLabel(2:end-1) = {''}; % remove all ticklabels except the top/bottom
    
    if strcmp(cMap.ctype{row},'div')
        XTickLabel(colorbarTicks == 0) = {'0'}; % add the 0 if necessary
    end
    set(c ,'XTickLabel',XTickLabel)
    axis(ax_colorbar,'off','image') % remove the background white ugly thing. Also set the ratio to "image". I noticed way better rescaling-properties (except very small topoplots)
    fprintf('%.2fs for row %i/%i\n',toc,row,g.n_rows)
    
    hA.colorbar{row} = c;
    hA.ax_colorbar{row} = ax_colorbar;
    drawnow
end

set(gcf,'Color',background_color); % see above, eeglab changes the background color and we have to reset it

end

function [x, std] = winMean(x,dim,percent)
%% [winsorizedMean winsorizedSTD]function winMean(x,dim,percent)
%
% http://benediktehinger.de/blog/science/matlab-winsorized-mean-over-all-dimension/
% Taken and adapted strongly from LIMO toolbox (2014)
% Copyright LIMO Team 2010
% Original code provided by Prof. Patrick J. Bennett, McMaster University
% made 3D: GAR - University of Glasgow - 7 Dec 2009

if nargin<3;percent=20;end
if length(x) ==1
    return
end
if isempty(x)
    error('Vector should not be empty or length = 1');
end

if (percent >= 100) || (percent < 0)
    error('PERCENT must be between 0 and 100, is: %.2f',percent);
end
if nargin == 1
    dim = find(size(x)~=1,1,'first');
    if isempty(dim), dim = 1; end
end

%check for nans
if any(isnan(x(:))) && sum(size(x)~=1)==1
    x(isnan(x)) = [];
elseif any(isnan(x(:)))
    error('nans found but not one dimensional matrix, currently not implemented. One would have to do each row separately, but this might be inefficient')
end
% number of trials
n=size(x,dim);

% number of items to winsorize and trim
g=floor((percent/100)*n);

% permuteOrder = [dim notDim];
% orgSize = size(x);
% xsort = permute(x,permuteOrder); % make the first dimension the one to do the thing over

% winsorise x
x=sort(x,dim); % now sort over  dimension
% wx=xsort;
% Prepare Structs
Srep.type = '()';
S.type = '()';

% replace the left hand side
nDim = length(size(x));

beforeColons = num2cell(repmat(':',dim-1,1));

afterColons  = num2cell(repmat(':',nDim-dim,1));
Srep.subs = {beforeColons{:} [g+1]    afterColons{:}};
S.subs    = {beforeColons{:} [1:g+1]  afterColons{:}};
x = subsasgn(x,S,repmat(subsref(x,Srep),[ones(1,dim-1) g+1 ones(1,nDim-dim)])); % general case

% replace the right hand side
Srep.subs = {beforeColons{:} [n-g]            afterColons{:}};
S.subs    = {beforeColons{:} [n-g:size(x,dim)]  afterColons{:}};

x= subsasgn(x,S,repmat(subsref(x,Srep),[ones(1,dim-1) g+1 ones(1,nDim-dim)])); % general case
% wx(:,1:g+1)=repmat(xsort(:,g+1),[1 g+1]); %dim = 2 case
% wx(:,n-g:end)=repmat(xsort(:,n-g),[1 g+1]); % dim =2 case

% wvarx=squeeze(std(x,0,dim));
std = squeeze(nanstd(x,[],dim));
x = squeeze(nanmean(x,dim));




end