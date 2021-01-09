function [s_frames, nFrames, initrect, img, state] = data_init(seq)

s_frames = seq.s_frames;
nFrames = numel(s_frames);
initrect = seq.init_rect;

img = single(imread(s_frames{1}));
if size(img,3)==1
    img = repmat(img,1,1,3);
end

state = obj_initialize(img, initrect);
state = seq_initialize(state, nFrames, seq);

end


function [state] = seq_initialize(state, nFrames, seq)

state.seq.frame = 1; 
state.seq.nFrames = nFrames;
state.seq.seqname = seq.name;
state.seq.time = 0;
state.seq.isfail = 0;
state.seq.scores = zeros(nFrames);
state.seq.frame = 1;    
state.seq.scores(1) = 10;

end


function [state] = obj_initialize(I, region, varargin)

gray = double(I(:,:,1));

[height, width] = size(gray);

% If the provided region is a polygon ...
if numel(region) > 4
    x1 = round(min(region(1:2:end)));
    x2 = round(max(region(1:2:end)));
    y1 = round(min(region(2:2:end)));
    y2 = round(max(region(2:2:end)));
    region = round([x1, y1, x2 - x1, y2 - y1]);
else
    region = round([round(region(1)), round(region(2)), ...
        round(region(1) + region(3)) - round(region(1)), ...
        round(region(2) + region(4)) - round(region(2))]);
end;

x1 = max(0, region(1));
y1 = max(0, region(2));
x2 = min(width-1, region(1) + region(3) - 1);
y2 = min(height-1, region(2) + region(4) - 1);

state.obj.pos = [y1 + y2 + 1, x1 + x2 + 1] / 2;
state.obj.targetsz = [y2-y1+1,x2-x1+1];
state.obj.base_targetsz = [y2-y1+1,x2-x1+1];
state.obj.targetLoc = [x1, y1, state.obj.targetsz([2,1])];
state.obj.change_alphaf = [];
state.obj.change_featf = [];

end

