% Quick-plot command to visualize retrieved wavefront or gradients map with viridis colormap.
% The vididis colormaps are taken from Ander Biguri (2023). Perceptually uniform colormaps 
% (https://www.mathworks.com/matlabcentral/fileexchange/51986-perceptually-uniform-colormaps), 
% MATLAB Central File Exchange. Retrieved March 7, 2023. Copyright (c) 2016, Ander Biguri

function PlotWavefront(W)
    fig = figure;
    imagesc(W)
    axis image
    colormap(viridis())
    drawnow
end

