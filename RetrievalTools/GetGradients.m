% Retrieves the gradient fields from acquired QLSI interferograms with Fourier side-band filtering.

% This function is based on the description of Guillaume Baffou 2021 J. Phys. D: Appl. Phys. 54 294002
% and contains essential elements of the related MATLAB code accessible at
% https://github.com/baffou/CGMprocess with permission of Guillaume Baffou.

function [DWx, DWy] = GetGradients(Itf, Ref)

    % Perform 2D FFT Fourier transform
    FItf = fftshift(fft2(Itf));
    FRef = fftshift(fft2(Ref));
    
    % Find first Fourier peak
    if size(Itf) == ([1200 1600])
        % Parameters for our SID4Bio camera
        [Ny, Nx] = deal(1200, 1600); % 
        [x,y] = deal(1141, 758); % Initial position of side band Fourier peak for our SID4Bio camera
    else % Inserted for using stitching algorithms, since the peak position will change with array size
        [Ny, Nx] = deal(size(Itf,1),size(Itf,2));
        [y, x] = find(abs(FRef(1:size(FRef,1)/2,1:size(FRef,2)/2)) == max(max(abs(FRef(1:size(FRef,1)/2,1:size(FRef,2)/2))))); % Find one Fourier peak
    end
    
    % Calculation of ellipse size for masking without overlapping each
    % other
    xc = Nx/2 + 1;
    yc = Ny/2 + 1;
    R = sqrt( (xc-x)^2 + (yc-y)^2 )/2;
    
    QLSI_Parameters.crops = FcropParameters(x, y, R, Nx, Ny);
    QLSI_Parameters.theta = QLSI_Parameters.crops.angle;
   
    H = cell(2,1);
    Href = cell(2,1);
    [xx,yy] = meshgrid(1:Nx, 1:Ny);
    
    % Masking of Fourier peaks and shifting to center before inverse
    % Fourier transform
    for ii = 1:2
        R2C = (xx  - QLSI_Parameters.crops.x).^2/QLSI_Parameters.crops.Rx^2 + (yy - QLSI_Parameters.crops.y).^2/QLSI_Parameters.crops.Ry^2;
        circle = (R2C < 1); %circular mask
        FItfc = FItf.*circle;
        FRefc = FRef.*circle;
        H{ii} = circshift(FItfc, [-QLSI_Parameters.crops.shifty, -QLSI_Parameters.crops.shiftx]);
        Href{ii} = circshift(FRefc, [-QLSI_Parameters.crops.shifty, -QLSI_Parameters.crops.shiftx]);
        QLSI_Parameters.crops = QLSI_Parameters.crops.rotate90();
    end
    
    % Inverse Fourier transform for both peaks leading to gradients in
    % rotated coordinate frame
    Ix = ifft2(ifftshift(H{1}));
    Iy = ifft2(ifftshift(H{2}));
    Irefx = ifft2(ifftshift(Href{1}));
    Irefy = ifft2(ifftshift(Href{2}));
    
    % Perform background correction
    DW1 = angle(Ix.*conj(Irefx));
    DW2 = angle(Iy.*conj(Irefy));
    
    % Rotation of the gradients by application of rotation matrix such that
    % x-axis is horizontal and y-axis is vertical
    DWx = QLSI_Parameters.theta.cos*DW1 - QLSI_Parameters.theta.sin*DW2;
    DWy = QLSI_Parameters.theta.sin*DW1 + QLSI_Parameters.theta.cos*DW2;
    
    % Upon retrieval the gradient direction is inversed, hence this need to
    % be compensated
    DWx = -DWx; %Final x-gradient
    DWy = -DWy; %Final y-gradient
end