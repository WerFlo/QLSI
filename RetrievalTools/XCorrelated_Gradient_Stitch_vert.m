% Vertical stitching of two adjoining gradient maps based on the 
% calculation of the cross-correlation. The variable output argument 
% allows to export the calculated stitching parameters as data type cell. 
% The variable input argument allows to feed the function with already 
% calculated stitching parameters to avoid a new calculation of the 
% cross-correlation. The variable input must have the same format as the 
% variable output argument of type cell. Either the use of variable input 
% or variable output argument is possible. The determination of the 
% stitching parameters for the fusion of the corresponding interferograms 
% has to be performed with this function.

% This algorithm is optimized for same input array size only.

function [Stitched_DWx, Stitched_DWy, varargout] = XCorrelated_Gradient_Stitch_vert(DWx_upper,DWx_lower, DWy_upper, DWy_lower, varargin)

    if (nargin) == 5 && (nargout) == 3
    % Either stitching parameters as input or stitching parameters as
    % output are allowed.
        error('Only variable input or variable output arguments allowed!')
    end
    
    Gx_upper = gpuArray(DWx_upper);
    Gx_lower = gpuArray(DWx_lower);
    Gy_upper = gpuArray(DWy_upper);
    Gy_lower = gpuArray(DWy_lower);
    
    if nargin == 5
        % Extraction of stitching parameters from input arguments
        xcorrDWx = varargin{1}.xcorrDWx;
        delta_yy_upper = varargin{1}.delta_yy_upper;
        delta_xx_upper = varargin{1}.delta_xx_upper;
        delta_yy_lower = varargin{1}.delta_yy_lower;
        delta_xx_lower = varargin{1}.delta_xx_lower;
    else
        % If no input stitching parameters provided new Cross-correlation
        % is calculated
        xcorrDWx = xcorr2(Gy_upper, Gy_lower);
        % Displays cross-calculation to doublecheck if prominent peak is
        % given
        figure, imagesc(xcorrDWx), axis image

        [yyDWx,xxDWx]=find(xcorrDWx==max(max(xcorrDWx)));
        delta_yy_upper = yyDWx-size(Gx_lower,1);
        delta_xx_upper = xxDWx-size(Gx_lower,2);
        delta_yy_lower = yyDWx-size(Gx_upper,1);
        delta_xx_lower = xxDWx-size(Gx_upper,2);
    end
    

    if (delta_yy_lower < 0) || (delta_yy_upper < 0)
        error('Argument 1 must be upper Image, Argument 2 must be lower Image')
    else
        % Cut images for stitching according to their horizontal offsets
        if (delta_xx_lower < 0) && (delta_xx_upper < 0)
            ImLower_DWx_horcat = Gx_lower(:,abs(delta_xx_lower)+1:size(Gx_lower,2));
            ImUpper_DWx_horcat = Gx_upper(:,1:(size(Gx_upper,2)-abs(delta_xx_upper)));
            ImLower_DWy_horcat = Gy_lower(:,abs(delta_xx_lower)+1:size(Gy_lower,2));
            ImUpper_DWy_horcat = Gy_upper(:,1:(size(Gy_upper,2)-abs(delta_xx_upper)));
        elseif (delta_xx_lower >= 0) && (delta_xx_upper >= 0)
            ImLower_DWx_horcat = Gx_lower(:,1:(size(Gx_lower,2)-abs(delta_xx_lower)));
            ImUpper_DWx_horcat = Gx_upper(:,abs(delta_xx_upper)+1:size(Gx_upper,2));
            ImLower_DWy_horcat = Gy_lower(:,1:(size(Gy_lower,2)-abs(delta_xx_lower)));
            ImUpper_DWy_horcat = Gy_upper(:,abs(delta_xx_upper)+1:size(Gy_upper,2));
        else
            % This case should not exist
            error('delta_xx_lower and delta_xx_upper have unequal signs, please have a closer look')
        end
        
        % Cut horizontally to stitch images vertically
        ImLower_DWx_cut = ImLower_DWx_horcat(size(Gx_lower,1)-abs(delta_yy_lower)+1:size(Gx_lower,1), :);
        ImUpper_DWx_cut = ImUpper_DWx_horcat(1:delta_yy_upper, :);
        ImLower_DWy_cut = ImLower_DWy_horcat(size(Gy_lower,1)-abs(delta_yy_lower)+1:size(Gy_lower,1), :);
        ImUpper_DWy_cut = ImUpper_DWy_horcat(1:delta_yy_upper, :);
        
        % Stitch twice for taking mean
        Stitched_Gx(:,:,1) = vertcat(ImUpper_DWx_cut, ImLower_DWx_horcat);
        Stitched_Gx(:,:,2) = vertcat(ImUpper_DWx_horcat, ImLower_DWx_cut);
        Stitched_Gy(:,:,1) = vertcat(ImUpper_DWy_cut, ImLower_DWy_horcat);
        Stitched_Gy(:,:,2) = vertcat(ImUpper_DWy_horcat, ImLower_DWy_cut);
        
        % Taking mean to minimize stitching errors
        Stitched_Gx = mean(Stitched_Gx,3);
        Stitched_Gy = mean(Stitched_Gy,3);
        Stitched_DWx = gather(Stitched_Gx);
        Stitched_DWy = gather(Stitched_Gy);
        
        if nargout == 3
            varargout{1}.xcorrDWx = gather(xcorrDWx);
            varargout{1}.delta_yy_upper = gather(delta_yy_upper);
            varargout{1}.delta_xx_upper = gather(delta_xx_upper);
            varargout{1}.delta_yy_lower = gather(delta_yy_lower);
            varargout{1}.delta_xx_lower = gather(delta_xx_lower);
        end
    end
end
