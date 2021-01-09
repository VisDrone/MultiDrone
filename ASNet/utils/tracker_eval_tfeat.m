% -------------------------------------------------------------------------------------------------------------------------
function [responseMaps] = tracker_eval_tfeat(net_x, t_feat, x_crops, p)

%TRACKER_STEP
%   runs a forward pass of the search-region branch of the pre-trained Fully-Convolutional Siamese,
%   reusing the features of the exemplar z computed at the first frame.
%
%   Luca Bertinetto, Jack Valmadre, Joao F. Henriques, 2016
% -------------------------------------------------------------------------------------------------------------------------
% forward pass, using the pyramid of scaled crops as a "batch"
%     net_x.conserveMemory = false;

net_x.eval({p.netconv_tinput, t_feat, p.netconv_img, x_crops});

responseMaps = gather(net_x.vars(p.scoreId).value);
% responseMaps = reshape(responseMaps, [p.scoreSize p.scoreSize p.numScale]);
        
end

