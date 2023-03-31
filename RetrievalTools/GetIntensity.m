% Retrieves the intensity map from acquired QLSI interferograms with Fourier zero-order filtering.

% This function is based on the description of Guillaume Baffou 2021 J. Phys. D: Appl. Phys. 54 294002
% and contains essential elements of the related MATLAB code accessible at
% https://github.com/baffou/CGMprocess with permission of Guillaume Baffou.

function [I] = GetIntensity(Itf, Ref)
    % Parameters for our SID4Bio camera
    [Ny, Nx] = deal(1200, 1600);
    
    % Calculate size of ellipse for masking from distance to one Fourier
    % peak
    [x,y] = deal(1141, 758); % InitPosition of one peak
    xc = Nx/2 + 1;
    yc = Ny/2 + 1;
    R = sqrt( (xc-x)^2 + (yc-y)^2 )/2;
    
    QLSI_Parameters.crops = FcropParameters(x, y, R, Nx, Ny);
    
    % Fast Fourier transform
    FItf = fftshift(fft2(Itf));
    FRef = fftshift(fft2(Ref));
    
    % Masking with ellipse
    [xx,yy] = meshgrid(1:Nx, 1:Ny);
    R2C = (xx  -Nx/2-1).^2/QLSI_Parameters.crops.Rx^2 + (yy - Ny/2-1).^2/QLSI_Parameters.crops.Ry^2;
    circle = (R2C < 1); %circular mask
    H = FItf.*circle;
    Href = FRef.*circle;
    
    %Inverse fast Fourier transform and normalization with reference image
    I = ifft2(ifftshift(H))./ifft2(ifftshift(Href));
end

