% -------------------------------------------------------------------------------------------------------------------------
function [newTargetPosition, bestScale, score] = get_results(responseMaps, s_x, targetPosition, window, p)

%TRACKER_STEP
%   runs a forward pass of the search-region branch of the pre-trained Fully-Convolutional Siamese,
%   reusing the features of the exemplar z computed at the first frame.
%
%   Luca Bertinetto, Jack Valmadre, Joao F. Henriques, 2016
% -------------------------------------------------------------------------------------------------------------------------
% forward pass, using the pyramid of scaled crops as a "batch"
%     net_x.conserveMemory = false;

responseMaps = reshape(responseMaps, [p.scoreSize p.scoreSize p.numScale]);

responseMapsUP =single(zeros(p.scoreSize*p.responseUp, p.scoreSize*p.responseUp, p.numScale));

if p.numScale>1
    currentScaleID = ceil(p.numScale/2);
    bestScale = currentScaleID;
    bestPeak = -Inf;
    for s = 1:p.numScale
        if p.responseUp > 1
            responseMaps_(:,:,s) =  imresize(responseMaps(:,:,s), p.responseUp, 'bicubic');
            responseMapsUP(:,:,s) = responseMaps_(:,:,s);
            thisResponse = responseMapsUP(:,:,s);
            % penalize change of scale
            if s~=currentScaleID, thisResponse = thisResponse * p.scalePenalty; end
            thisPeak = max(thisResponse(:));
            if thisPeak > bestPeak, bestPeak = thisPeak; bestScale = s; end
            score = bestPeak;
        else
            responseMapsUP(:,:,s) = responseMaps{1}(:,:,s);
        end
    end
    responseMap = responseMapsUP(:,:,bestScale);
else
    responseMap = responseMapsUP;
    bestScale = 1;    
    score = max(responseMap(:));
end



% make the response map sum to 1
responseMap = responseMap - min(responseMap(:));
responseMap = responseMap / sum(responseMap(:));

% apply windowing
responseMap = (1-p.wInfluence)*responseMap + p.wInfluence*window;

[r_max, c_max] = find(responseMap == max(responseMap(:)), 1);
[r_max, c_max] = avoid_empty_position(r_max, c_max, p);
p_corr = [r_max, c_max];

score_pos = p_corr./p.responseUp;
% Convert to crop-relative coordinates to frame coordinates
% displacement from the center in instance final representation ...
disp_instanceFinal = p_corr - ceil(p.scoreSize*p.responseUp/2);
% ... in instance input ...
disp_instanceInput = disp_instanceFinal * p.totalStride / p.responseUp;

% ... in instance original crop (in frame coordinates)
disp_instanceFrame = disp_instanceInput * s_x / p.instanceSize;

% position within frame in frame coordinates
newTargetPosition = targetPosition + disp_instanceFrame;
end

function [r_max, c_max] = avoid_empty_position(r_max, c_max, params)
if isempty(r_max)
    r_max = ceil(params.scoreSize/2);
end
if isempty(c_max)
    c_max = ceil(params.scoreSize/2);
end
end

% function corrfeat = add_change(corrfeat,change_alphaf,chang_featf,iscp)
% if nargin<4
%     iscp = 1;
% end
% cos_window = hann(size(corrfeat,1)) * hann(size(corrfeat,2))';
% corrfeat = bsxfun(@times, corrfeat, cos_window);
% corrfeatf = fft2(corrfeat);
% numcorr = numel(corrfeatf(:,:,1));
% kcorrfeatf = (corrfeatf .* conj(chang_featf))./numcorr ;
% corrfeat = single(real(ifft2(change_alphaf.* kcorrfeatf)));
% 
% if iscp
%     corrfeat = repmat(corrfeat,1,1,1,3);
% end
% end
