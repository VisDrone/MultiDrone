function [state,opts] = fcnet_init(img,state,netname,nettype)
%% 
% Initialize the network, parameters and sequence state
% Qing Guo, 2017.
%%
% initial parameters
opts.prenet = netname; % siamfc, vgg19, jointrain
opts.nettype = nettype; % 1res 0res
opts.useGPU = true;
opts.isupdate =1; 

% netname: siamfc,vgg19,jointtrain
% nettype: 0res,1res
% vlr: learning rate for target variation transformation. when using
% 'jointtrain',this parameter is off-line learnt
% wlr: learning rate for background suppression transformation. when using
% 'jointtrain',this parameter is off-line learnt
% lambda: regularization parameter for all 2 transformation. when using
% 'jointtrain',this parameter is off-line learnt
% contextAmount: context rate

opts.vlr=single(0.49);%
opts.wlr=single(0.29);%
opts.w_lambda = 10;% 
opts.w1_lambda = 10;
opts.contextAmount = 0.5;

opts.vartransform = (opts.vlr>0);     
opts.backsupression = (opts.wlr>0);
opts.fusiontransform =1;

opts.imgsz = size(img);
opts.targetszrate=1;
[opts] = optpars(opts,state.obj.targetsz,opts.imgsz);

pos = state.obj.pos;
targetsz = state.obj.targetsz.*opts.targetszrate;

opts.exemplarSize = 127;
opts.instanceSize = 255;

opts.numScale = 3;
opts.scaleStep = 1.0375;%1.0375;
opts.scalePenalty = 0.9745;
opts.scaleLR = 0.59; % 0.58 for vgg19; 0.59 for siamfc %damping factor for scale update
opts.scales = (opts.scaleStep .^ ((ceil(opts.numScale/2)-opts.numScale) : floor(opts.numScale/2)));
    
opts.wInfluence = 0.176; % windowing influence (in convex sum)

% generate saliency map for background supression transformation
[rs,cs]=ndgrid((1:opts.instanceSize)-floor(opts.instanceSize./2),(1:opts.instanceSize)-floor(opts.instanceSize./2));
dist = rs.^2+cs.^2;
hamming_window = hamming(opts.instanceSize)*hann(opts.instanceSize)';
tsigma = opts.exemplarSize.*100;
opts.saliency_window =  hamming_window.*exp(-0.5/(tsigma^2)*dist);
opts.saliency_window = single(opts.saliency_window/max(opts.saliency_window(:)));
opts.saliency_window = repmat(opts.saliency_window,1,1,3);
             
% get avg for padding
opts.avgChans = gather([mean(mean(img(:,:,1))) mean(mean(img(:,:,2))) mean(mean(img(:,:,3)))]);

wc_z = targetsz(2) + opts.contextAmount*sum(targetsz);
hc_z = targetsz(1) + opts.contextAmount*sum(targetsz);
s_z = sqrt(wc_z*hc_z);
scale_z = opts.exemplarSize / s_z;
d_search = (opts.instanceSize - opts.exemplarSize)/2;
pad = d_search/scale_z;
s_x = s_z + 2*pad;

% arbitrary scale saturation
opts.min_s_x = 0.2*s_x;
opts.max_s_x = 5*s_x;

switch opts.prenet

    % pretrained network: vgg19
    case 'vgg19'   
        % other general parameters
        opts.v_lambda = 10;%
        opts.v1_lambda = 10;%
        
        % vgg network params
        opts.feat_layer= {'relu5_4','relu4_4'};%
        opts.feat_name = {'x36','x27'};%
        opts.netobj_input = 'exemplar';%
        opts.netconv_img = 'instance';%
        opts.netconv_input{1} = 'corr0_input';%
        opts.netconv_input{2} = 'corr1_input';
        opts.scoreSize = 17;
        opts.responseUp = 16;
        opts.totalStride = 8;
        opts.scorelyname = {'score'};  
        netpath = fullfile('./models','vgg19.mat');  
        % initial obj conv net from siamfc net
        [net_obj,net_conv] = get_vggnet(netpath,opts.feat_layer{1});
        sumw_lr = single(0.8);
        net_conv = reshapeNet_vgg(net_conv,opts,sumw_lr);
        opts.averageImage = net_conv.meta.normalization.averageImage;

        for ti=1:numel(opts.feat_name)
            opts.obj_feat_id(ti) = net_obj.getVarIndex(opts.feat_name{ti});
            opts.conv_feat_id(ti) = net_conv.getVarIndex(opts.feat_name{ti});
        end   
        
    case 'siamfc'
        
        opts.v_lambda = 1e-5;%
        opts.v1_lambda = 1e-5;%
        netpath = fullfile('./models','siamfcnet_gray.mat');
        % initial obj conv net from siamfc net
        [net_obj,net_conv] = get_simafcnet(netpath,nettype,opts);
        
        % loading weights for sum_w layer
        if strcmp('1res',nettype)
            swpath = fullfile('./models','sumw.mat');
            load(swpath);
            net_conv.params(net_conv.getParamIndex('sumweights')).value =sumw;
        end
        
        % siamese network params
        opts.feat_layer= {'a_conv5','a_relu4'};%
        opts.feat_name = {'feat','x14'};%
        opts.netobj_input = 'exemplar';
        opts.netconv_img = 'instance';
        opts.netconv_input{1} = 'a_feat';
        opts.netconv_input{2} = 'a_x14';
        opts.netconv_tinput = 'ta_feat';
        opts.scoreSize = 17;
        opts.responseUp = 16;
        opts.totalStride = 8;
        opts.averageImage = [];
        opts.scorelyname = 'score';
        opts.scoreslyname = 'xcorrs';
         
        for ti=1:numel(opts.feat_name)
            opts.obj_feat_id(ti) = net_obj.getVarIndex(['a_',opts.feat_name{ti}]);
            opts.conv_feat_id(ti) = net_conv.getVarIndex(['b_',opts.feat_name{ti}]);
        end
        
    case 'jointrain'
        
        % other general parameters
        opts.v_lambda = 1e-5;%
        opts.v1_lambda = 1e-5;%
        netpath = fullfile('./models/*.mat');
        [net_obj,net_conv,opts] = get_simafcnet_joint(netpath,nettype,opts);
        % siamese network params
        opts.feat_layer= {'a_conv5','a_relu4'};%
        opts.feat_name = {'feat','x14'};%
        opts.netobj_input = 'exemplar';
        opts.netconv_img = 'instance';
        opts.netconv_input{1} = 'a_feat';
        opts.netconv_input{2} = 'a_x14';
        opts.scoreSize = 17;
        opts.responseUp = 16;
        opts.totalStride = 8;
        opts.averageImage = [];
        opts.scorelyname = 'score';
        opts.scoreslyname = 'xcorrs';
        for ti=1:numel(opts.feat_name)
            opts.obj_feat_id(ti) = net_obj.getVarIndex(['a_',opts.feat_name{ti}]);
            opts.conv_feat_id(ti) = net_conv.getVarIndex(['b_',opts.feat_name{ti}]);
        end
end

% initial setting of net_conv, and net_fc
opts.scoreId = net_conv.getVarIndex(opts.scorelyname);
net_conv.vars(opts.scoreId).precious = 1 ;

opts.obj_tfeat_id = net_conv.getVarIndex(opts.netconv_tinput);
net_conv.vars(opts.obj_tfeat_id).precious = 1; 

net_conv.conserveMemory = true;
net_conv.mode= 'test';

for fi =1:numel(opts.obj_feat_id)
   net_obj.vars(opts.obj_feat_id(fi)).precious = 1;
   net_conv.vars(opts.conv_feat_id(fi)).precious = 1; 
end

net_obj.mode = 'test';
net_obj.conserveMemory= true;

% initialize the exemplar
[z_crop, ~] = get_subwindow_tracking(img, pos, ...
    [opts.exemplarSize opts.exemplarSize], [round(s_z) round(s_z)], opts.avgChans,opts.averageImage);

window = single(hann(opts.scoreSize*opts.responseUp) * hann(opts.scoreSize*opts.responseUp)');
% make the window sum 1
opts.window = window / sum(window(:));

% evaluate the offline-trained network for exemplar z features
corrfeat = cell(numel(opts.obj_feat_id),1);
if opts.useGPU
    net_conv.move('gpu');
    net_obj.move('gpu');
    z_crop = gpuArray(single(z_crop));
else
    net_conv.move('cpu');
    net_obj.move('cpu'); 
    z_crop = single(z_crop);
end

net_obj.eval({opts.netobj_input, z_crop});
for fi = 1:numel(opts.obj_feat_id)
    corrfeat{fi} = net_obj.vars(opts.obj_feat_id(fi)).value;
    corrfeat{fi} = repmat(corrfeat{fi}, [1 1 1 opts.numScale]);
end

% initialize the exemplar
[x_crop, ~] = get_subwindow_tracking(img, pos, ...
    [opts.instanceSize opts.instanceSize], [round(s_x) round(s_x)], opts.avgChans,opts.averageImage);
x_crop = x_crop.*opts.saliency_window;
state.obj.s_x = s_x;
state.obj.corrfeat = corrfeat;
state.obj.x_crop = x_crop;
state.obj.failframes = 0;
state.net.net_conv = net_conv;
state.net.net_obj = net_obj;
end

