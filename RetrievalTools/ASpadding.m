% This function performs antisymmetric padding of the input gradient fields according to 
% Pierre Bon, Serge Monneret, and Benoit Wattellier, Appl. Opt. 51, 5698-5704 (2012)

function [DWx_ASpadded, DWy_ASpadded] = ASpadding(DWx,DWy)
    for ii = 1:size(DWx,3)
        grad_x = DWx(:,:,ii);
        DWxLL = -fliplr(grad_x);
        DWxUL = -rot90(grad_x,2);
        DWxUR = flipud(grad_x);
        

        DWxU = horzcat(DWxUL, DWxUR);
        DWxL = horzcat(DWxLL, grad_x);
        DWx_ASpadded(:,:,ii) = vertcat(DWxU, DWxL);

        grad_y = DWy(:,:,ii);
        DWyLL = fliplr(grad_y);
        DWyUL = -rot90(grad_y,2);
        DWyUR = -flipud(grad_y);
        

        DWyU = horzcat(DWyUL, DWyUR);
        DWyL = horzcat(DWyLL, grad_y);
        DWy_ASpadded(:,:,ii) = vertcat(DWyU, DWyL);
    end
end