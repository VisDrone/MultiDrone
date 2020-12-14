function [subSeqs, subAnno] = splitSeqTRE(seq, segNum, rect_anno)
%20 segments for each sequences
%first, excluding all the occ/out-of-view frames
%then, sampling

minNum = 20;

Idx = 1:seq.len;
           
for i = length(Idx):-1:1
    if seq.len - Idx(i) + 1 >= minNum
        endSegIdx = i;
        break;
    end
end

startFrIdxOne = [floor(1:endSegIdx/(segNum-1):endSegIdx) endSegIdx] ;

subAnno = [];
subSeqs = [];

for i = 1:length(startFrIdxOne)
    index = Idx(startFrIdxOne(i));
    subS.path = seq.path;
    subS.nz = seq.nz;
    subS.ext = seq.ext;
    
    subS.startFrame = index+seq.startFrame-1;
    subS.endFrame = seq.endFrame;
        
    subS.len = subS.endFrame - subS.startFrame + 1;

    subS.annoBegin = seq.startFrame;
    subS.init_rect = rect_anno(index,:);
    anno = rect_anno(index:end,:);
    
    subS.s_frames = seq.s_frames(index:end);
    
    subS.name = seq.name;

    subAnno{i} = anno;
    subSeqs{i} = subS;
    if(size(rect_anno,1) == 1)
        break;
    end
end