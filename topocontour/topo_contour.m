EEG = pop_loadset('../topo_butter/example.set');
addpath(genpath('../topo_butter'))
%% 
% The default way on how topoplots are plotted:

plot_main(EEG.data(:,:,[1]),EEG.times,EEG.chanlocs,'butterfly','no','individualcontour','yes','time',[-150 450]) 
set(gcf,'Position',[996,1270,1066, 68])
%% 
% I argue for another way to plot the same topoplots:

plot_main(EEG.data(:,:,[1]),EEG.times,EEG.chanlocs,'butterfly','no','individualcontour','no','time',[-150 450]) 
set(gcf,'Position',[996,1270,1066, 68])
%% 
% Here the contourlines are at the same value. This is in parallel to having 
% the same colorscale for each plot.
%% All possible comparisons

ax = plot_main(EEG.data(:,:,[1]),EEG.times,EEG.chanlocs,'butterfly','no','contour','no','individualcolormap','yes','time',[-150 450]);
cellfun(@(x)colormap(x,gray(128)),ax.topo.topo{1}.image)
set(gcf,'Position',[996,1270,1066, 68]);delete(ax.topo.ax_colorbar{1})
%% 
% Each topoplot has its individual color-limits. While the local (in a single 
% topoplot) extremata a clearly visible, no comparison between topoplots is possible


ax = plot_main(EEG.data(:,:,[1]),EEG.times,EEG.chanlocs,'butterfly','no','individualcolormap','yes','individualcontour','yes','time',[-150 450]);
cellfun(@(x)colormap(x,gray(128)),ax.topo.topo{1}.image)
set(gcf,'Position',[996,1270,1066, 68]);delete(ax.topo.ax_colorbar{1})
%% 
% Individual contours improve the readability of each map, but they do not 
% add anything for the comparison.

ax = plot_main(EEG.data(:,:,[1]),EEG.times,EEG.chanlocs,'butterfly','no','contour','no','time',[-150 450]);
cellfun(@(x)colormap(x,gray(128)),ax.topo.topo{1}.image)
set(gcf,'Position',[996,1270,1066, 68]);delete(ax.topo.ax_colorbar{1})
%% 
% Forcing the same color-limits allows for direct comparison between topoplots. 
% But whether the white of the 9's or the 12's topoplot is bigger is hard to tell.

ax = plot_main(EEG.data(:,:,[1]),EEG.times,EEG.chanlocs,'butterfly','no','individualcolormap','yes','individualcontour','no','time',[-150 450]);
cellfun(@(x)colormap(x,gray(128)),ax.topo.topo{1}.image)
set(gcf,'Position',[996,1270,1066, 68]);delete(ax.topo.ax_colorbar{1})
%% 
% Going back to individual colormaps, but keeping the same contours: This 
% helps already a lot, I seem to abstract the colormapping away a bit and use 
% the contours for comparison

ax = plot_main(EEG.data(:,:,[1]),EEG.times,EEG.chanlocs,'butterfly','no','individualcontour','yes','time',[-150 450]);
cellfun(@(x)colormap(x,gray(128)),ax.topo.topo{1}.image)
set(gcf,'Position',[996,1270,1066, 68]);delete(ax.topo.ax_colorbar{1})
%% 
% The opposite way, same colormapping but individual contours. Again I seem 
% to rely more on the contours, in this case this is more confusing than before.


ax = plot_main(EEG.data(:,:,[1]),EEG.times,EEG.chanlocs,'butterfly','no','individualcontour','no','time',[-150 450]);
cellfun(@(x)colormap(x,gray(128)),ax.topo.topo{1}.image)
set(gcf,'Position',[996,1270,1066, 68]);delete(ax.topo.ax_colorbar{1})

%% 
% In the final plot colormap and contour are aligned. This enhances comparison 
% between topoplots.
% 
% 
% 
% A problem is that large deflections could hide small ones. As in many cases, 
% it depends on what you want to show. I recommend the final plot where contour 
% and colormap align as the default.