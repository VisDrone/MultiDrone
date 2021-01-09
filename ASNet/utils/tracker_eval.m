% -------------------------------------------------------------------------------------------------------------------------
function [responseMaps, t_feat] = tracker_eval(net_x, corrfeat, x_crops, p)

%TRACKER_STEP
%   runs a forward pass of the search-region branch of the pre-trained Fully-Convolutional Siamese,
%   reusing the features of the exemplar z computed at the first frame.
%
%   Luca Bertinetto, Jack Valmadre, Joao F. Henriques, 2016
% -------------------------------------------------------------------------------------------------------------------------
% forward pass, using the pyramid of scaled crops as a "batch"
%     net_x.conserveMemory = false;

if strcmp(p.nettype,'1res')        
    net_x.eval({p.netconv_input{1}, corrfeat{1},p.netconv_input{2},corrfeat{2},p.netconv_img, x_crops});
    % get score maps before fusion
%     scoreMaps = gather(net_x.vars(p.scoresId).value);
 
else
    net_x.eval({p.netconv_input{1}, corrfeat{1},p.netconv_img, x_crops});
    % get score maps before fusion
%     scoreMaps = gather(net_x.vars(p.scoreId).value);
end

t_feat = net_x.vars(p.obj_tfeat_id).value;

responseMaps = gather(net_x.vars(p.scoreId).value);
% responseMaps = reshape(responseMaps, [p.scoreSize p.scoreSize p.numScale]);
        
end
