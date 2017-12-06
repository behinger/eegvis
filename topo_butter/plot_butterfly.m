function hA = plot_butterfly(inp_data,inp_times,varargin)

g = finputcheck(varargin,...
    {'n_topos','integer',[],15; % we need this information to see how much to drop on the left / right side
    'highlighted_channel','integer',[1:size(inp_data,1)],[]; % highlight a single channel
    'time','real',[],[]; % what time range to plot
    'pvalues','real',[],[]; % if you want to highlight clusters/electrodes that are significant. Can be 0/1 binairy or p-values, in that case 'topoalpha'(default 0.05) is used as a cutoff
    'topoalpha','real',[],0.05; % change the statistical alpha-value indicating significant electrodes
    'minorXTicks','boolean',[],1;...
    'parentAxes','',[],gca; % plot it in the current axis, or a different one
    },[],'ignore');
if isstr(g)
    error(g)
end
hA = struct; %output axes
hA.parent = g.parentAxes;

%% Define Plotting time and get an idea of what plot_topo is doing
if isempty(g.time)
    plt.time = inp_times;
    plt.data = inp_data(:,:,1);
else
    assert(length(g.time)>1,'error, please provide either no time or two timepoints')
    plt.timeidx = inp_times>g.time(1) & inp_times<g.time(2);
    plt.time = inp_times(plt.timeidx);
    plt.data = inp_data(:,plt.timeidx,1); % in this function we cut the data here
end
plt.topotimes = linspace(min(plt.time),max(plt.time),g.n_topos+1);


%% Define new axes
% We want a bit of space to the topoplots
parentPos = get(g.parentAxes,'Position');
axis(g.parentAxes,'off');

pos_width = parentPos(3)/(g.n_topos+1);
shrinkY = 0.2*(parentPos(4));

plot_pos = [parentPos(1)+ pos_width,...
    parentPos(2)+shrinkY, ...
    parentPos(3) - pos_width*2,...line
    parentPos(4)-shrinkY];



plotAxes = axes('Position',plot_pos);
hA.plot = plotAxes;

%% Plot the data + 0-lines
hold all
plot(plt.time,plt.data,'Color',[0.3 0.3 0.5 0.4])
xlim([min(plt.time),max(plt.time)]);
vline(0,'k')
hline(0,'k')



set(plotAxes,'Box','off','YAxisLocation','right') % y axis to the right

%% Plot minorXTicks at locations of topoplot
if g.minorXTicks
    set(gca,'XMinorTick','on')

if verLessThan('matlab','8.5') %2014b or earlier
    % no easy way to make MinorTicksValues
     set(gca,'XMinorTick','off')
     minorTickAxes = axes('Position',plot_pos);
     set(minorTickAxes,'XLim',get(plotAxes,'XLim'),'XTick',plt.topotimes,'XTickLabel',[],'YTick',[],'Color','none','ticklength',[0.005 0])
     axes(plotAxes);%go back to normal plot axes
elseif verLessThan('matlab','9.0')
        plotAxes.XRuler.MinorTicks = plt.topotimes;
else 
        plotAxes.XAxis.MinorTickValues = plt.topotimes;


end
end
%% Mark the significant portions
if ~isempty(g.pvalues)
    % Calculate thresholded values
    if length(unique(g.pvalues)) == 2 % already thresholded
        sigTime = g.pvalues(:,:);
    else
        sigTime = g.pvalues(:,:) < g.topoalpha    ;
    end
    
    % Mark Single Channels
    for ch = 1:size(plt.data,1)
        sigConnected = bwlabel(sigTime(ch,plt.timeidx));
        for sigC = 1:max(sigConnected)
            sigTimeIdx = find(sigConnected == sigC);
            plot(plt.time(sigTimeIdx),plt.data(ch,sigTimeIdx),'k','LineWidth',1.5)
            hold all
        end
        
    end


    % Mark rectangular things in the background
    sigAny = any(sigTime,1);
    sigConnected = bwlabel(sigAny(plt.timeidx));
    
    % We need to do this to get anything in the background in matlab
    pvalAreaAxes = axes('Position',plot_pos,'XLim',get(plotAxes,'XLim'),'YLim',get(plotAxes,'YLim'));
    
    uistack(pvalAreaAxes,'bottom')
    axis off
    p = [];
    for sigC = 1:max(sigConnected)
        sigBegin= find(sigConnected == sigC,1,'first');
        sigEnd= find(sigConnected == sigC,1,'last');

        p(sigC) = patch(plt.time([sigBegin  sigEnd sigEnd sigBegin]),sort([ylim ylim]),repmat([0.2],1,4)); % last entry is irrelevant, because facecolor is changed later anyway.
    end
    set(p,'EdgeColor','none')
    set(p,'FaceColor',[0.8 0.8 0.8])

   hA.pvalArea = pvalAreaAxes; 
   hA.pvalAreaPatch = p;
end
set(plotAxes,'Color','none') %this allows us to see the background with the significant-areas patches

% Highlight an single channel
if ~isempty(g.highlighted_channel)
    plot(plotAxes,plt.time,plt.data(g.highlighted_channel,:),'r','LineWidth',1.5)
end