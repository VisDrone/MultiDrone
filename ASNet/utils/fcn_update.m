function [state, state2, state3] = fcn_update(state, state2, state3, img, img2, img3, opts, opts2, opts3);

%load state
[targetsz, pos, s_x, corrfeat, isfail, net_conv, net_obj, scaledInstance, scaledTarget] = load_state(state, opts);
[targetsz2, pos2, s_x2, corrfeat2, isfail2, net_conv2, net_obj2, scaledInstance2, scaledTarget2] = load_state(state2, opts2);
[targetsz3, pos3, s_x3, corrfeat3, isfail3, net_conv3, net_obj3, scaledInstance3, scaledTarget3] = load_state(state3, opts3);

tic;

% extract scaled crops for search region x at previous target position
x_crops = make_scale_pyramid(img, pos, scaledInstance, opts.instanceSize, opts.avgChans, opts);%, opts,saliency_map);
x_crops2 = make_scale_pyramid(img2, pos2, scaledInstance2, opts2.instanceSize, opts2.avgChans, opts2);
x_crops3 = make_scale_pyramid(img3, pos3, scaledInstance3, opts3.instanceSize, opts3.avgChans, opts3);

% evaluate the offline-trained network for exemplar x features
[responseMaps11, t_feat] = tracker_eval(net_conv, corrfeat, x_crops, opts);
[newTargetPosition, newScale, score] = get_results(responseMaps11, round(s_x), pos, opts.window, opts);

[responseMaps21, t_feat2] = tracker_eval(net_conv2, corrfeat2, x_crops2, opts2);
[newTargetPosition2, newScale2, score2] = get_results(responseMaps21, round(s_x2), pos2, opts2.window, opts2);

[responseMaps31, t_feat3] = tracker_eval(net_conv3, corrfeat3, x_crops3, opts3);
[newTargetPosition3, newScale3, score3] = get_results(responseMaps31, round(s_x3), pos3, opts3.window, opts3);

% % Re-detection
n1 = 30;
n2 = 30;
n3 = 30;
threshold1 = 1.25;
threshold2 = 1.25;
threshold3 = 1.25;
bigger1 = 1.2;
bigger2 = 1.2;
bigger3 = 1.2;

if state2.seq.frame > n1  
    [score_threshold_min1] = compute_threshold(state, n1, threshold1);
    [score_threshold_min2] = compute_threshold(state2, n2, threshold2);
    [score_threshold_min3] = compute_threshold(state3, n3, threshold3);
    if score < min(score_threshold_min1, 0.5)
        s_x_RD = s_x * bigger1;
        scaledInstance_RD = scaledInstance * bigger1;
        x_crops_RD = make_scale_pyramid(img, pos, scaledInstance_RD, opts.instanceSize, opts.avgChans, opts);
        [responseMaps1_RD, ~] = tracker_eval(net_conv, corrfeat, x_crops_RD, opts);
        [newTargetPosition_RD, newScale_RD, score_RD] = get_results(responseMaps1_RD, round(s_x_RD), pos, opts.window, opts);
        if score < score_RD
            score = score_RD;
            newTargetPosition = newTargetPosition_RD;
            newScale = newScale_RD;
        end
    end
        
    if score2 < min(score_threshold_min2, 0.5) 
        s_x2_RD = s_x2 * bigger2;
        scaledInstance2_RD = scaledInstance2 * bigger2;
        x_crops2_RD = make_scale_pyramid(img2, pos2, scaledInstance2_RD, opts2.instanceSize, opts2.avgChans, opts2);
        [responseMaps2_RD, ~] = tracker_eval(net_conv2, corrfeat2, x_crops2_RD, opts2);
        [newTargetPosition2_RD, newScale2_RD, score2_RD] = get_results(responseMaps2_RD, round(s_x2_RD), pos2, opts2.window, opts2);
        if score2 < score2_RD
            score2 = score2_RD;
            newTargetPosition2 = newTargetPosition2_RD;
            newScale2 = newScale2_RD;
        end
    end
    
    if score3 < min(score_threshold_min3, 0.5) 
        s_x3_RD = s_x3 * bigger3;
        scaledInstance3_RD = scaledInstance3 * bigger3;
        x_crops3_RD = make_scale_pyramid(img3, pos3, scaledInstance3_RD, opts3.instanceSize, opts3.avgChans, opts3);
        [responseMaps3_RD, ~] = tracker_eval(net_conv3, corrfeat3, x_crops3_RD, opts3);
        [newTargetPosition3_RD, newScale3_RD, score3_RD] = get_results(responseMaps3_RD, round(s_x3_RD), pos3, opts3.window, opts3);
        if score3 < score3_RD
            score3 = score3_RD;
            newTargetPosition3 = newTargetPosition3_RD;
            newScale3 = newScale3_RD;
        end
    end
end

% % template sharing
D = zeros(6*6*256, 3);
corrfeat_D = gather(corrfeat{1});
corrfeat_D2 = gather(corrfeat2{1});
corrfeat_D3 = gather(corrfeat3{1});
D(:,1) = reshape(corrfeat_D(:,:,:,1), [6*6*256, 1]);
D(:,2) = reshape(corrfeat_D2(:,:,:,1), [6*6*256, 1]);
D(:,3) = reshape(corrfeat_D3(:,:,:,1), [6*6*256, 1]);

score_tmp = score;
score2_tmp = score2;
score3_tmp = score3;

if score_tmp < 0.75 && score2_tmp > 1 && score3_tmp > 1
    tcorrfeat_D = state.obj.tcorrfeat;
    tcorrfeat_DD = gather(tcorrfeat_D{1});
    tcorrfeat = reshape(tcorrfeat_DD(:,:,:,1), [6*6*256, 1]);
    % U = lsqnonneg(double(D), double(tcorrfeat));
    % U = inv(double(D' * D)) * double(D') * double(tcorrfeat);
    U = double(D) \ double(tcorrfeat);
    
    [responseMaps12] = tracker_eval_tfeat(net_conv, t_feat2, x_crops, opts);
    [responseMaps13] = tracker_eval_tfeat(net_conv, t_feat3, x_crops, opts);
%     responseMaps11 = reshape(responseMaps11, [opts.scoreSize * opts.scoreSize * opts.numScale, 1]);
%     responseMaps12 = reshape(responseMaps12, [opts.scoreSize * opts.scoreSize * opts.numScale, 1]);
%     responseMaps13 = reshape(responseMaps13, [opts.scoreSize * opts.scoreSize * opts.numScale, 1]);
    responseMaps = responseMaps11 * U(1) + responseMaps12 * U(2) + responseMaps13 * U(3);
%     responseMaps = [responseMaps11, responseMaps12, responseMaps13] * U;
%     responseMaps = reshape(responseMaps, [opts.scoreSize opts.scoreSize opts.numScale]);    
    
    [newTargetPosition12, newScale12, score12] = get_results(responseMaps, round(s_x), pos, opts.window, opts);
   
    if score < score12
        score = score12;
        newTargetPosition = newTargetPosition12;
        newScale = newScale12;
    end
end
% 
if score2_tmp < 0.75 && score_tmp > 1 && score3_tmp > 1
    tcorrfeat_D2 = state2.obj.tcorrfeat;
    tcorrfeat_DD2 = gather(tcorrfeat_D2{1});
    tcorrfeat2 = reshape(tcorrfeat_DD2(:,:,:,1), [6*6*256, 1]);
    % U2 = lsqnonneg(double(D), double(tcorrfeat2));
    % U2 = inv(double(D' * D)) * double(D') * double(tcorrfeat2);
    U2 = double(D) \ double(tcorrfeat2);

    [responseMaps22] = tracker_eval_tfeat(net_conv, t_feat, x_crops, opts);
    [responseMaps23] = tracker_eval_tfeat(net_conv, t_feat3, x_crops, opts);
%     responseMaps21 = reshape(responseMaps21, [opts2.scoreSize * opts2.scoreSize * opts2.numScale, 1]);
%     responseMaps22 = reshape(responseMaps22, [opts2.scoreSize * opts2.scoreSize * opts2.numScale, 1]);
%     responseMaps23 = reshape(responseMaps23, [opts2.scoreSize * opts2.scoreSize * opts2.numScale, 1]);
    responseMaps2 = responseMaps21 * U2(1) + responseMaps22 * U2(2) + responseMaps23 * U2(3);
%     responseMaps2 = reshape(responseMaps2, [opts2.scoreSize opts2.scoreSize opts2.numScale]);

    [newTargetPosition22, newScale22, score22] = get_results(responseMaps2, round(s_x2), pos2, opts2.window, opts2);
    
    if score2 < score22
        score2 = score22;
        newTargetPosition2 = newTargetPosition22;
        newScale2 = newScale22;
    end
end

if score3_tmp < 0.75 && score_tmp > 1 && score2_tmp > 1
    tcorrfeat_D3 = state3.obj.tcorrfeat;
    tcorrfeat_DD3 = gather(tcorrfeat_D3{1});
    tcorrfeat3 = reshape(tcorrfeat_DD3(:,:,:,1), [6*6*256, 1]);
    % U2 = lsqnonneg(double(D), double(tcorrfeat2));
    % U2 = inv(double(D' * D)) * double(D') * double(tcorrfeat2);
    U3 = double(D) \ double(tcorrfeat3);

    [responseMaps32] = tracker_eval_tfeat(net_conv, t_feat, x_crops, opts);
    [responseMaps33] = tracker_eval_tfeat(net_conv, t_feat2, x_crops, opts);
%     responseMaps31 = reshape(responseMaps31, [opts3.scoreSize * opts3.scoreSize * opts3.numScale, 1]);
%     responseMaps32 = reshape(responseMaps32, [opts3.scoreSize * opts3.scoreSize * opts3.numScale, 1]);
%     responseMaps33 = reshape(responseMaps33, [opts3.scoreSize * opts3.scoreSize * opts3.numScale, 1]);
    responseMaps3 = responseMaps31 * U3(1) + responseMaps32 * U3(2) + responseMaps33 * U3(3);
%     responseMaps3 = reshape(responseMaps3, [opts3.scoreSize opts3.scoreSize opts3.numScale]);

    [newTargetPosition32, newScale32, score32] = get_results(responseMaps3, round(s_x3), pos3, opts3.window, opts3);
    
    if score3 < score32
        score3 = score32;
        newTargetPosition3 = newTargetPosition32;
        newScale3 = newScale32;
    end
end


pos = gather(newTargetPosition);
pos2 = gather(newTargetPosition2);
pos3 = gather(newTargetPosition3);

[s_x, pos, targetsz, isfail, state] = update(img, s_x, pos, score, targetsz, corrfeat, newScale, scaledInstance, scaledTarget, net_obj, net_conv, isfail, state, opts);
[s_x2, pos2, targetsz2, isfail2, state2] = update(img2, s_x2, pos2, score2, targetsz2, corrfeat2, newScale2, scaledInstance2, scaledTarget2, net_obj2, net_conv2, isfail2, state2, opts2);
[s_x3, pos3, targetsz3, isfail3, state3] = update(img3, s_x3, pos3, score3, targetsz3, corrfeat3, newScale3, scaledInstance3, scaledTarget3, net_obj3, net_conv3, isfail3, state3, opts3);

time = toc / 3;

targetsz = targetsz./opts.targetszrate;
state.obj.s_x = s_x;
state.obj.pos = pos;
state.obj.targetsz = targetsz;
state.obj.targetLoc = [pos([2,1]) - targetsz([2,1])/2, targetsz([2,1])];
state.seq.scores(state.seq.frame) = score;
state.seq.time = state.seq.time + time;
state.seq.isfail = isfail;

targetsz2 = targetsz2./opts2.targetszrate;
state2.obj.s_x = s_x2;
state2.obj.pos = pos2;
state2.obj.targetsz = targetsz2;
state2.obj.targetLoc = [pos2([2,1]) - targetsz2([2,1])/2, targetsz2([2,1])];
state2.seq.scores(state2.seq.frame) = score2;
state2.seq.time = state2.seq.time + time;
state2.seq.isfail = isfail2;

targetsz3 = targetsz3./opts3.targetszrate;
state3.obj.s_x = s_x3;
state3.obj.pos = pos3;
state3.obj.targetsz = targetsz3;
state3.obj.targetLoc = [pos3([2,1]) - targetsz3([2,1])/2, targetsz3([2,1])];
state3.seq.scores(state3.seq.frame) = score3;
state3.seq.time = state3.seq.time + time;
state3.seq.isfail = isfail3;
end

function [score_threshold_min] = compute_threshold(state, n, score_lamda_min)
    scores = state.seq.scores;
    first_index = state.seq.frame - n;
    scores = scores(first_index:state.seq.frame-1);
    scores_mean = mean(scores);
    scores_std = std(scores);
    score_threshold_min = scores_mean - score_lamda_min * scores_std;
end

function [targetsz, pos, s_x, corrfeat, isfail, net_conv, net_obj, scaledInstance, scaledTarget] = load_state(state, opts)

targetsz = state.obj.targetsz.*opts.targetszrate;
pos = state.obj.pos;
s_x = state.obj.s_x;

corrfeat = state.obj.corrfeat;
isfail = state.seq.isfail;

net_conv = state.net.net_conv;
net_obj = state.net.net_obj;

scales = opts.scales;
scaledInstance = s_x .* scales;
scaledTarget = [targetsz(1) .* scales; targetsz(2) .* scales];
end

function [s_x, pos, targetsz, isfail, state] = update(img, s_x, pos, score, targetsz, corrfeat, newScale, scaledInstance, scaledTarget, net_obj, net_conv, isfail, state, opts)
if opts.isupdate  
%     score
    if score >0
        wc_z = targetsz(2) + opts.contextAmount*sum(targetsz);
        hc_z = targetsz(1) + opts.contextAmount*sum(targetsz);
        s_z = sqrt(wc_z*hc_z);
        [z_crop, ~] = get_subwindow_tracking(img, pos, ...
            [opts.exemplarSize opts.exemplarSize], [round(s_z) round(s_z)], opts.avgChans,opts.averageImage);
        z_crop = gpuArray(single(z_crop));
        
        net_obj.eval({opts.netobj_input, z_crop});
        state.seq.scores(state.seq.frame) = score;
        
        tcorrfeat{1} =  net_obj.vars(opts.obj_feat_id(1)).value;
        tcorrfeat{2} =  net_obj.vars(opts.obj_feat_id(2)).value; 
        state.obj.tcorrfeat = tcorrfeat;
        % updating the target variation transformation
        if opts.vartransform
            net_conv = update_v(net_conv,corrfeat,tcorrfeat,opts);
        end
        
        % updating the background suppression transformation
        if opts.backsupression
            [x_back(:,:,:,1), ~] = get_subwindow_tracking(gather(img), pos,...
                [opts.instanceSize opts.instanceSize], [round(scaledInstance(newScale)) round(scaledInstance(newScale))], opts.avgChans);
            x_back(:,:,:,2) = x_back(:,:,:,1).* opts.saliency_window;%state.obj.x_crop;%
            net_obj.eval({opts.netobj_input, gpuArray(x_back)});
            tcorrfeat{1} =  net_obj.vars(opts.obj_feat_id(1)).value;
            tcorrfeat{2} =  net_obj.vars(opts.obj_feat_id(2)).value;
            net_conv = update_w(net_conv,tcorrfeat,opts);
        end

        % scale damping and saturation
        if isfail
            wc_z = targetsz(2) + opts.contextAmount*sum(targetsz);
            hc_z = targetsz(1) + opts.contextAmount*sum(targetsz);
            s_z = sqrt(wc_z*hc_z);
            scale_z = opts.exemplarSize / s_z;
            d_search = (opts.instanceSize - opts.exemplarSize)/2;
            pad = d_search/scale_z;
            s_x = s_z + 2*pad;
            isfail = 0;
        else
            s_x = max(opts.min_s_x, min(opts.max_s_x, (1-opts.scaleLR)*s_x + opts.scaleLR*scaledInstance(newScale)));
            targetsz = (1-opts.scaleLR)*targetsz + opts.scaleLR*[scaledTarget(1,newScale) scaledTarget(2,newScale)];
        end
        
    else
        isfail = 1;
        s_x = max(opts.min_s_x, min(opts.max_s_x, s_x*1.1));
        net_conv.layers(net_conv.getLayerIndex('circonv1_1')).block.enable = false;
        net_conv.layers(net_conv.getLayerIndex('circonv1_2')).block.enable = false;
        if strcmp(opts.nettype,'1res')
            net_conv.layers(net_conv.getLayerIndex('circonv2_1')).block.enable = false;
            net_conv.layers(net_conv.getLayerIndex('circonv2_2')).block.enable = false;
        end
    end
    
else
    % scale damping and saturation
    s_x = max(opts.min_s_x, min(opts.max_s_x, (1-opts.scaleLR)*s_x + opts.scaleLR*scaledInstance(newScale)));
    targetsz = (1-opts.scaleLR)*targetsz + opts.scaleLR*[scaledTarget(1,newScale) scaledTarget(2,newScale)];
end

% validate 
tmp = pos+targetsz./2;
if tmp(1)<0||tmp(2)<0||tmp(1)>opts.imgsz(1)||tmp(2)>opts.imgsz(2)
   state.obj.failframes = state.obj.failframes+1;
   if state.obj.failframes>=2
      pos = [size(img,1),size(img,2)]./2;
      state.obj.failframes =0;
   end
   isfail = 1;
   net_conv.layers(net_conv.getLayerIndex('circonv1_1')).block.enable = false;
   net_conv.layers(net_conv.getLayerIndex('circonv1_2')).block.enable = false;
   if strcmp(opts.nettype,'1res')
       net_conv.layers(net_conv.getLayerIndex('circonv2_1')).block.enable = false;
       net_conv.layers(net_conv.getLayerIndex('circonv2_2')).block.enable = false;
   end
end

end


function [change_alpahf,change_featf] = update_change(corrfeat,new_corrfeat,lambda,issum)
if nargin<4
   issum =false; 
end

% leanring filter from corrfeat to new_corrfeat
cos_window = hann(size(corrfeat,1)) * hann(size(corrfeat,2))';
tcorrfeat = bsxfun(@times, corrfeat, cos_window);

corrfeatf = fft2(tcorrfeat);
numcorr = numel(corrfeatf(:,:,1));
if ~issum
    kcorrfeatf = (corrfeatf .* conj(corrfeatf))./numcorr;
else
    kcorrfeatf = sum(corrfeatf .* conj(corrfeatf),3)./numel(corrfeatf);
end
tnew_corrfeat = bsxfun(@times, new_corrfeat, cos_window);
tnew_corrfeatf = fft2(tnew_corrfeat);
alphaf = tnew_corrfeatf./ (kcorrfeatf+ lambda);   

change_alpahf = alphaf;
change_featf = corrfeatf;
end

% fast online learning for V
function net = update_v(net,feats_1,feats_t,p)

[alphaf,featf] = update_change(feats_1{1}(:,:,:,1),feats_t{1},p.v_lambda);

net.params(net.getParamIndex('cir11_alphaf')).value = alphaf;
net.params(net.getParamIndex('cir11_featf')).value = featf;
net.layers(net.getLayerIndex('circonv1_1')).block.enable = true;

if strcmp(p.nettype,'1res')
    [alphaf,featf] = update_change(feats_1{2}(:,:,:,1),feats_t{2},p.v1_lambda);    
    net.params(net.getParamIndex('cir21_alphaf')).value = alphaf;
    net.params(net.getParamIndex('cir21_featf')).value = featf;
    net.layers(net.getLayerIndex('circonv2_1')).block.enable = true;
end

end

% fast online learning for W
function net = update_w(net,feats,p)

[alphaf,featf] = update_change(feats{1}(:,:,:,1),feats{1}(:,:,:,2),p.w_lambda);
net.params(net.getParamIndex('cir12_alphaf')).value = alphaf;
net.params(net.getParamIndex('cir12_featf')).value = featf;
net.layers(net.getLayerIndex('circonv1_2')).block.enable = true;

if strcmp(p.nettype,'1res')
    [alphaf,featf] = update_change(feats{2}(:,:,:,1),feats{2}(:,:,:,2),p.w1_lambda);
    net.params(net.getParamIndex('cir22_alphaf')).value = alphaf;
    net.params(net.getParamIndex('cir22_featf')).value = featf;
    net.layers(net.getLayerIndex('circonv2_2')).block.enable = true;
end

end

