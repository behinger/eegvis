### Rastering problems

It is a commonly observed problem with topoplots, that exporting them to .ai or .eps or .pdf results in huge vector files. The reason is, that matlab converts surface objects to small vector-triangles instead of exporting them as bitmaps (this is true if the vector renderer is active).

A solution for fieldtrip can be found at [Anne Urai's Blog](https://anneurai.net/2016/11/08/rasterised-topoplots-in-fieldtrip/). A solution to eeglab is used in this toolbox or here:

```matlab
topo_init = gca
topo_image = axes('Position',get(topo_init,'Position'))
[~,cdata] = topoplot(data(k,:),chanlocs,topoargin{:});


% We delete the surface and replace it with a imagesc plot. This
% allows for better exporting.
delete(findobj(topo_init,'Type','surface'))

% Generate a new axis to plot the imagesc plot
h = imagesc(topo_image,cdata);
set(topo_image,'YDir','normal');
axis(topo_image,'square','off')
set(h,'alphadata',~isnan(cdata))
caxis(topo_image,scale)
% Change the respective colormap
colormap(topo_image,squeeze(cMap.topo(row,:,:)))
```
