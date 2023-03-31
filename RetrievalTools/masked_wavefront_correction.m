% Background correction of the wavefront with 2D interpolation over 
% sample region. The sample-specific mask for interpolation is manually 
% created by drawing a polygon. For valid results, the sample must be 
% surrounded by a no-sample region from all sides. If not available, 
% the input array must be mirrored accordingly. Variable output argument 
% can be used to return the drawn logical 2D mask and can be used as a 
% variable input argument to reconstruct the result at a later point. 
% Either variable input or variable output arguments are allowed.\\

function [W_corr,varargout] = masked_wavefront_correction(W, varargin)
% Background correction with 2D interpolation over sample region

    if nargin == 2 && nargout == 2
        error('Either second input or second output argument, not both.')
    end

    if nargin == 2
        mask2comp = varargin{1};
    else
        % Create manual mask with polygon shape
        fig4masking = figure; 
        imagesc(W), axis image
        colormap(viridis())
        title('Please draw polygon for masking and end with double-click or at starting point')
        p = drawpolygon('LineWidth',2,'Color','red','FaceAlpha',0);

        mask2comp = createMask(p);
        close(fig4masking)
    end
    
    figMask = figure;
    imshow(mask2comp), axis image
    title('Compensation background is calculated, please wait')
    
    % Interpolation for background correction
    W_2comp = regionfill(W,mask2comp);
    close(figMask)
    
    % Calculate corrected wavefront
    W_corr = W - W_2comp;
    PlotWavefront(W_corr)
    title('Corrected wavefront')

    if nargout == 2
        % If wanted mask for later reconstruction
        varargout{1} = mask2comp;
    end
end

