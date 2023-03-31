% Integrate the non-padded gradients DWx, DWy or the 
% anti-symmetric padded gradients DWx_ASpadded, DWy_ASpadded
% with a complex-plane approach. Optional input arguments allow direct 
% cropping of the retrieved wavefront to initial interferogram size for 
% anti-symmetric padded input gradients.

% The retrieved OPD is quantitatively only correct for our Phasics SID4Bio
% wavefront sensor.

% This function is based on the description of Guillaume Baffou 2021 J. Phys. D: Appl. Phys. 54 294002
% and contains essential elements of the related MATLAB code accessible at
% https://github.com/baffou/CGMprocess with permission of Guillaume Baffou.


function [W] = IntegrateGradients(DWx,DWy,varargin)

    p = inputParser;
    addOptional(p, 'ASpadded', false)
    parse(p,[DWx DWy],varargin{:});

    ASpadded = p.Results.ASpadded;

    [Ny, Nx] = size(DWx);

    % Integration of the OPD gradients with complex-plane approach

    [kx, ky] = meshgrid(1:Nx,1:Ny);
    kx = kx-Nx/2-1;
    ky = ky-Ny/2-1;
    kx(logical((kx==0).*(ky==0)))=Inf;
    ky(logical((kx==0).*(ky==0)))=Inf;

    W_comp = ifft2(ifftshift((fftshift(fft2(DWx)) + 1i*fftshift(fft2(DWy)))./(1i*2*pi*(kx/Nx + 1i*ky/Ny))));

    W0 = real(W_comp);

    qlsi_pitch_term = 0.01887711; %QLSI pitch-term for our SID4Bio for quantification of the OPD values.

    W0 = qlsi_pitch_term * W0;
    
    if ASpadded == true %Crop image if AS padded
        W = W0(size(W0,1)/2+1:size(W0,1),size(W0,2)/2+1:size(W0,2));
        disp('Input was AS padded')
    else
        W = W0;
    end

end

