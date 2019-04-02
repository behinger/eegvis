% cyan-blue
CyBu        = [linspace(0,0,65)',linspace(1,0,65)',linspace(1,1,65)'];

% blue-black
BuBk        = [linspace(0,0,65)',linspace(0,0,65)',linspace(1,0,65)'];

% black-red
BkRd        = [linspace(0,1,65)',linspace(0,0,65)',linspace(0,0,65)'];

% red-yellow
RdYl        = [linspace(1,1,65)',linspace(0,1,65)',linspace(0,0,65)'];

% blue-gray
BuGy        = [linspace(0,0.5,65)',linspace(0,0.5,65)',linspace(1,0.5,65)'];

% gray-red
GyRd        = [linspace(0.5,1,65)',linspace(0.5,0,65)',linspace(0.5,0,65)'];

% Make colormaps and save them
CyBuBkRdYl  = [CyBu(1:64,:);BuBk(1:64,:);BkRd(1:64,:);RdYl(1:64,:)];
CyBuGyRdYl  = [CyBu(1:64,:);BuGy(1:64,:);GyRd(1:64,:);RdYl(1:64,:)];
cmap_file   = fullfile(fileparts(which('sd_display')),'colormaps.mat');
save(cmap_file,'CyBuBkRdYl','CyBuGyRdYl');