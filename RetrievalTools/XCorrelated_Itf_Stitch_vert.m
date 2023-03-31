% Vertical stitching of two adjoining sample and reference interferograms 
% based on the calculated stitching parameters from the 
% XCorrelated_Gradient_Stitch_vert}-function. VertStitchingParameters input
% parameters must be of same format as obtained (cell type).

%This algorithm is optimized for same input array size only.

function [Stitched_Itf, Stitched_Ref] = XCorrelated_Itf_Stitch_vert(Itf_upper,Itf_lower, Ref_upper, Ref_lower, VertStitchingParameters)

    Itf_upper = gpuArray(Itf_upper);
    Itf_lower = gpuArray(Itf_lower);
    Ref_upper = gpuArray(Ref_upper);
    Ref_lower = gpuArray(Ref_lower);

    %Read in stitching parameters
    xcorrDWx = VertStitchingParameters.xcorrDWx;
    delta_yy_upper = VertStitchingParameters.delta_yy_upper;
    delta_xx_upper = VertStitchingParameters.delta_xx_upper;
    delta_yy_lower = VertStitchingParameters.delta_yy_lower;
    delta_xx_lower = VertStitchingParameters.delta_xx_lower;
    
    % Cut images for stitching according to their vertical offset
    if (delta_xx_lower < 0) && (delta_xx_upper < 0)
        ImLower_DWx_horcat = Itf_lower(:,abs(delta_xx_lower)+1:size(Itf_lower,2));
        ImUpper_DWx_horcat = Itf_upper(:,1:(size(Itf_upper,2)-abs(delta_xx_upper)));
        ImLower_DWy_horcat = Ref_lower(:,abs(delta_xx_lower)+1:size(Ref_lower,2));
        ImUpper_DWy_horcat = Ref_upper(:,1:(size(Ref_upper,2)-abs(delta_xx_upper)));
    elseif (delta_xx_lower >= 0) && (delta_xx_upper >= 0)
        ImLower_DWx_horcat = Itf_lower(:,1:(size(Itf_lower,2)-abs(delta_xx_lower)));
        ImUpper_DWx_horcat = Itf_upper(:,abs(delta_xx_upper)+1:size(Itf_upper,2));
        ImLower_DWy_horcat = Ref_lower(:,1:(size(Ref_lower,2)-abs(delta_xx_lower)));
        ImUpper_DWy_horcat = Ref_upper(:,abs(delta_xx_upper)+1:size(Ref_upper,2));
    else
        % This case should not exist
        error('delta_xx_lower and delta_xx_upper have unequal signs, please have a closer look')
    end

    % Stitching of the interferograms without averaging. 
    % Averaging would distroy the fringe pattern of the interferograms.
        
    ImLower_DWx_cut = ImLower_DWx_horcat(size(Itf_lower,1)-abs(delta_yy_lower)+1:size(Itf_lower,1), :);
    ImUpper_DWx_cut = ImUpper_DWx_horcat(1:delta_yy_upper, :);
    ImLower_DWy_cut = ImLower_DWy_horcat(size(Ref_lower,1)-abs(delta_yy_lower)+1:size(Ref_lower,1), :);
    ImUpper_DWy_cut = ImUpper_DWy_horcat(1:delta_yy_upper, :);

    Stitched_Gx(:,:,1) = vertcat(ImUpper_DWx_cut, ImLower_DWx_horcat);
    Stitched_Gy(:,:,1) = vertcat(ImUpper_DWy_cut, ImLower_DWy_horcat);

    Stitched_Itf = gather(Stitched_Gx);
    Stitched_Ref = gather(Stitched_Gy);

end
