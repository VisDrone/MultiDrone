function [results] = ASNet(seq,seq2,seq3,netname,nettype)

%%
%  This code is a demo for DSiam, a online updated deep tracker for fast tracking
%  If you use this code,please cite:
%  Qing Guo, Wei Feng, Ce Zhou, Rui Huang, Liang Wan, Song Wang. 
%  Learning Dynamic Siamese Network for Visual Object Tracking. In ICCV 2017.
%  
%  Qing Guo, 2017.
%%
[s_frames, nFrames, initrect, img, state] = data_init(seq);
[s_frames2, nFrames2, initrect2, img2, state2] = data_init(seq2);
[s_frames3, nFrames3, initrect3, img3, state3] = data_init(seq3);

if nFrames ~= nFrames2 && nFrames ~= nFrames3
    error('the frame of the video is no equal')
end

% default
if nargin<2
    netname = 'vgg19';
    nettype = '1res';
end

[state, opts] = fcnet_init(img, state, netname, nettype);
[state2, opts2] = fcnet_init(img2, state2, netname, nettype);
[state3, opts3] = fcnet_init(img3, state3, netname, nettype);

res = [initrect]; 
select = [1];
duration = 0;

for it = 2:nFrames

    state.seq.frame = it;
    state2.seq.frame = it;
    state3.seq.frame = it;
%     fprintf('Processing frame %d/%d\n... ', state.seq.frame, nFrames);
    % **********************************
    % VOT: Get next frame
    % **********************************
%     img = imgs{it};
    img = single(imread(s_frames{it}));
    if size(img,3)==1
        img = repmat(img,1,1,3);
    end
    
    img2 = single(imread(s_frames2{it}));
    if size(img2,3)==1
        img2 = repmat(img2,1,1,3);
    end
    
    img3 = single(imread(s_frames3{it}));
    if size(img3,3)==1
        img3 = repmat(img3,1,1,3);
    end
    
    [state, state2, state3] = fcn_update(state, state2, state3, img, img2, img3, opts, opts2, opts3);
    
    
    if state.seq.scores(it) >= state2.seq.scores(it) && state.seq.scores(it) >= state3.seq.scores(it)
        initstate = [state.obj.targetLoc];
        select = [select; 1];
    elseif state2.seq.scores(it) >= state.seq.scores(it) && state2.seq.scores(it) >= state3.seq.scores(it)
        initstate = [state2.obj.targetLoc];
        select = [select; 2];
    else
        initstate = [state3.obj.targetLoc];
        select = [select; 3];
    end
       
    duration =  state.seq.time;
    
    res = [res; initstate];
    
end

state.seq.scores(1) = 10;
state2.seq.scores(1) = 10;
state3.seq.scores(1) = 10;

results.select = select;
results.res=res;
results.type='rect';
results.fps=(seq.len)/duration;

end