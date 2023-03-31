% Minimal script to direct retrieve and visualize the wavefront from the 
% raw interferograms Itf and Ref without any padding approach.

% This function follows the description of Guillaume Baffou 2021 J. Phys. D: Appl. Phys. 54 294002

function [W] = QLSIretrieve(Itf, Ref)
    % Retrieve the wavefront gradients from the interferograms
    [DWx, DWy] = GetGradients(Itf, Ref);
    % Integrate the gradients to obtain the wavefront
    W = IntegrateGradients(DWx, DWy);
    % Plot wavefront
    PlotWavefront(W)
end