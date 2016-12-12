function [varargout] = plot_main(inp_data,inp_times,chanlocs,varargin)
% Subfunction:
% plot_topo
% plot_butterfly
assert(isnumeric(inp_data));assert(isnumeric(inp_times));assert(isstruct(chanlocs))
g = finputcheck(varargin,...
    {'topoplot','string',{'yes','no'},'yes';
    'butterfly','string',{'yes','no'},'yes';
    'constrainAspectRatio','string',{'yes','no'},'no'; % I don't recommend it yet, its not working as smoothly as I want it
    },[],'ignore');

% do the figure
plt = [];hA = [];
plt.f = figure;
set(plt.f,'Color','w');

plt.time = inp_times;
plt.data = inp_data;

% Prepare the axes of topoplot vs butterfly as needed
if strcmp(g.topoplot,'yes')
    if strcmp(g.butterfly,'yes')
        topoSize = size(plt.data,3)/(size(plt.data,3) + 2);
    else
        topoSize = 1;
    end
    
else
    topoSize = 0;
end



%change the  figure aspect ratio
if strcmp(g.constrainAspectRatio,'yes')
    set(plt.f,'ResizeFcn',{@doResizeFcn,topoSize})
end


if strcmp(g.topoplot,'yes')
    ax.topo = axes('Position',[0.05, 0.05,0.95,topoSize-0.05]);axis off;
    hA.topo = plot_topo(plt.data,plt.time,chanlocs,'parentAxes',ax.topo,varargin{:});
    
end
if strcmp(g.butterfly,'yes')
    ax.butter = axes('Position',[0.05 topoSize,0.95,1-topoSize-0.05]);axis off;
    hA.butterfly = plot_butterfly(plt.data(:,:,1),plt.time,'parentAxes',ax.butter,varargin{:});
end

plt.f.Position(3) = plt.f.Position(3)*2; % make the initial size bigger
doResizeFcn([],[],topoSize)
if nargout == 1
   varargout{1} = hA; 
end
end

function doResizeFcn(varargin)
topoSize = varargin{3};
% p = get(plt.f,'outerposition');
p = get(gcf,'outerposition');

% XXX No Resize if only topoplots are plotted. Then toposize is 1 and does
% not contain any information on how many rows there are.
if topoSize ~= 1
p(4) = round(p(3)/6* 1/(1-topoSize));
set(gcf,'outerposition',p)

end

end