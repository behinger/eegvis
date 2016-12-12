### Rastering problems

It is a commonly observed problem with topoplots, that exporting them to .ai or .eps or .pdf results in huge vector files. The reason is, that matlab converts surface objects to small vector-triangles instead of exporting them as bitmaps (this is true if the vector renderer is active).

A solution for fieldtrip can be found at [Anne Urai's Blog](https://anneurai.net/2016/11/08/rasterised-topoplots-in-fieldtrip/). A solution to eeglab is used in this toolbox:


We take the interpolated data and replot it as an imagesc plot. We then have to adapt the axis/scales and delete the surface.

```matlab
function topoplot_vectorized(varargin)
    % figure,topoplot_vectorized(1:64,EEG.chanlocs)
    topo_init = gca;
    [~,cdata] = topoplot(varargin{:});
    topo_image = axes('Position',get(topo_init,'Position'));
    uistack(topo_image,'bottom')
    % We delete the surface and replace it with a imagesc plot. This
    % allows for better exporting.
    delete(findobj(topo_init,'Type','surface'))

    % Generate a new axis to plot the imagesc plot
    h = imagesc(topo_image,cdata);
    set(topo_image,'YDir','normal');
    axis(topo_image,'square','off')
    set(h,'alphadata',~isnan(cdata))
    caxis(topo_image,caxis(topo_init))
    % Change the respective colormap
    colormap(topo_image,colormap(topo_init))
end
```

Be sure to force the renderer to be 'painters' (vector format). In the figure use File - Export Setup - Rendering - Custom Renderer

You could use ``` 'gridscale',120``` (67 default) for higher resolution in the rastered part of the vector file.
