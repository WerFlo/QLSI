% Quick-plot command to visualize QLSI interferograms with grayscale colormap.

function PlotItf(Itf)
    fig = figure;
    imagesc(Itf)
    axis image
    colormap('gray')
    drawnow
end

