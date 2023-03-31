% Horizontal stitching of two adjoining sample and reference 
% interferograms based on the calculated stitching parameters from the 
% XCorrelated_Gradient_Stitch_hor}-function. HorStitchingParameters input 
% parameters must be of same format as obtained (cell type).

%This algorithm is optimized for same input array size only.

function [Stitched_Itf, Stitched_Ref] = XCorrelated_Itf_Stitch_hor(Itf_left,Itf_right, Ref_left, Ref_right, HorStitchingParameters)

    Itf_left = gpuArray(Itf_left);
    Itf_right = gpuArray(Itf_right);
    Ref_left = gpuArray(Ref_left);
    Ref_right = gpuArray(Ref_right);

    %Read in stitching parameters
    xcorrDWx = HorStitchingParameters.xcorrDWx;
    delta_yy_left = HorStitchingParameters.delta_yy_left;
    delta_xx_left = HorStitchingParameters.delta_xx_left;
    delta_yy_right = HorStitchingParameters.delta_yy_right;
    delta_xx_right = HorStitchingParameters.delta_xx_right;

    % Cut images for stitching according to their vertical offset
    if (delta_yy_right < 0) && (delta_yy_left < 0) 
        ImRight_Itf_vertcut = Itf_right(abs(delta_yy_right)+1:size(Itf_right,1),:);
        ImLeft_Itf_vertcut = Itf_left(1:(size(Itf_left,1)-abs(delta_yy_left)),:);
        ImRight_Ref_vertcut = Ref_right(abs(delta_yy_right)+1:size(Ref_right,1),:);
        ImLeft_Ref_vertcut = Ref_left(1:(size(Ref_left,1)-abs(delta_yy_left)),:);
    elseif (delta_yy_right >= 0) && (delta_yy_left >= 0)
        ImRight_Itf_vertcut = Itf_right(1:(size(Itf_right,1)-abs(delta_yy_right)),:);
        ImLeft_Itf_vertcut = Itf_left(abs(delta_yy_left)+1:size(Itf_left,1), :);
        ImRight_Ref_vertcut = Ref_right(1:(size(Ref_right,1)-abs(delta_yy_right)),:);
        ImLeft_Ref_vertcut = Ref_left(abs(delta_yy_left)+1:size(Ref_left,1), :);
    else
        % This case should not exist
        error('Delta_yy_right and Delta_yy_left have unequal signs, please have a closer look')
    end

    % Stitching of the interferograms without averaging. 
    % Averaging would distroy the fringe pattern of the interferograms.
    
    ImLeft_Itf_cut = ImLeft_Itf_vertcut(:, 1:delta_xx_left);
    ImLeft_Ref_cut = ImLeft_Ref_vertcut(:, 1:delta_xx_left);

    Stitched_Itf = horzcat(ImLeft_Itf_cut, ImRight_Itf_vertcut);
    Stitched_Ref = horzcat(ImLeft_Ref_cut, ImRight_Ref_vertcut);

    Stitched_Itf = gather(Stitched_Itf);
    Stitched_Ref = gather(Stitched_Ref);
end
