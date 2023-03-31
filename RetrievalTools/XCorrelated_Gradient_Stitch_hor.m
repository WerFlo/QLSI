% Horizontal stitching of two adjoining gradient maps based on the 
% calculation of the cross-correlation. The variable output argument 
% allows to export the calculated stitching parameters as data type cell. 
% The variable input argument allows to feed the function with already 
% calculated stitching parameters to avoid a new calculation of the 
% cross-correlation. The variable input must have the same format as the 
% variable output argument of type cell. Either the use of variable input 
% or variable output argument is possible. The determination of the 
% stitching parameters for the fusion of the corresponding interferograms 
% has to be performed with this function.

%This algorithm is optimized for same input array size only.

function [Stitched_DWx, Stitched_DWy, varargout] = XCorrelated_Gradient_Stitch_hor(DWx_left,DWx_right, DWy_left, DWy_right, varargin)

    if (nargin) == 5 && (nargout) == 3 
        % Either stitching parameters as input or stitching parameters as
        % output are allowed.
        error('Only variable input or variable output arguments allowed!')
    end
    
    Gx_left = gpuArray(DWx_left);
    Gx_right = gpuArray(DWx_right);
    Gy_left = gpuArray(DWy_left);
    Gy_right = gpuArray(DWy_right);
       
    
    if nargin == 5
        % Extraction of stitching parameters from input arguments
        xcorrDWx = varargin{1}.xcorrDWx;
        delta_yy_left = varargin{1}.delta_yy_left;
        delta_xx_left = varargin{1}.delta_xx_left;
        delta_yy_right = varargin{1}.delta_yy_right;
        delta_xx_right = varargin{1}.delta_xx_right;
    else
        % If no input stitching parameters provided new Cross-correlation
        % is calculated
        xcorrDWx = xcorr2(Gy_left, Gy_right);
        % Displays cross-calculation to doublecheck if prominent peak is
        % given
        figure, imagesc(xcorrDWx), axis image

        [yyDWx,xxDWx]=find(xcorrDWx==max(max(xcorrDWx)));

        delta_yy_left = yyDWx-size(Gx_right,1);
        delta_xx_left = xxDWx-size(Gx_right,2);

        delta_yy_right = yyDWx-size(Gx_left,1);
        delta_xx_right = xxDWx-size(Gx_left,2);
    end

    if (delta_xx_right < 0) || (delta_xx_left < 0)
        error('Argument 1 must be left Image, Argument 2 must be right Image')
    else
        % Cut images for stitching according to their vertical offset
        if (delta_yy_right < 0) && (delta_yy_left < 0)
            ImRight_DWx_vertcut = Gx_right(abs(delta_yy_right)+1:size(Gx_right,1),:);
            ImLeft_DWx_vertcut = Gx_left(1:(size(Gx_left,1)-abs(delta_yy_left)),:);
            ImRight_DWy_vertcut = Gy_right(abs(delta_yy_right)+1:size(Gy_right,1),:);
            ImLeft_DWy_vertcut = Gy_left(1:(size(Gy_left,1)-abs(delta_yy_left)),:);
        elseif (delta_yy_right >= 0) && (delta_yy_left >= 0)
            ImRight_DWx_vertcut = Gx_right(1:(size(Gx_right,1)-abs(delta_yy_right)),:);
            ImLeft_DWx_vertcut = Gx_left(abs(delta_yy_left)+1:size(Gx_left,1), :);
            ImRight_DWy_vertcut = Gy_right(1:(size(Gy_right,1)-abs(delta_yy_right)),:);
            ImLeft_DWy_vertcut = Gy_left(abs(delta_yy_left)+1:size(Gy_left,1), :);
        else
            % This case should not exist
            error('Delta_yy_right and Delta_yy_left have unequal signs, please have a closer look')
        end
        
        % Cut horizontally to stitch images horizontally
        ImRight_DWx_cut = ImRight_DWx_vertcut(:, size(Gx_right,2)-abs(delta_xx_right)+1:size(Gx_right,2));
        ImLeft_DWx_cut = ImLeft_DWx_vertcut(:, 1:delta_xx_left);
        ImRight_DWy_cut = ImRight_DWy_vertcut(:, size(Gy_right,2)-abs(delta_xx_right)+1:size(Gy_right,2));
        ImLeft_DWy_cut = ImLeft_DWy_vertcut(:, 1:delta_xx_left);
        
        % Stitch twice for taking mean
        Stitched_DWx(:,:,1) = horzcat(ImLeft_DWx_cut, ImRight_DWx_vertcut);
        Stitched_DWx(:,:,2) = horzcat(ImLeft_DWx_vertcut, ImRight_DWx_cut);
        Stitched_DWy(:,:,1) = horzcat(ImLeft_DWy_cut, ImRight_DWy_vertcut);
        Stitched_DWy(:,:,2) = horzcat(ImLeft_DWy_vertcut, ImRight_DWy_cut);
        
        % Taking mean to minimize stitching errors
        Stitched_DWx = gather(mean(Stitched_DWx,3));
        Stitched_DWy = gather(mean(Stitched_DWy,3));
        
        
        if nargout == 3
            % Stitching parameters as variable output parameter if no input
            % stitching parameters provided
            varargout{1}.xcorrDWx = gather(xcorrDWx);
            varargout{1}.delta_yy_left = gather(delta_yy_left);
            varargout{1}.delta_xx_left = gather(delta_xx_left);
            varargout{1}.delta_yy_right = gather(delta_yy_right);
            varargout{1}.delta_xx_right = gather(delta_xx_right);
        end

    end
end
