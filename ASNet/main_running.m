% Tracker performance evaluation tool for MDOT
% 1/23/2019 by Jiayu Zheng

close all;
clear, clc;
warning off all;

disp('**************config***************');

%g=gpuDevice(4);
%reset(g);

addpath(genpath('.')); 

datasetPath = '/root/sot/data/MDOT'; % the dataset path
% datasetPath = 'E:/multi-drone/data/MDOT';
data_type = 'three';
evalType = 'OPE'; % the evaluation type such as 'OPE'

if(strcmp(data_type, 'two'))
    video_num = 2;
elseif(strcmp(data_type, 'three'))
    video_num = 3;
else
    video_num = 0;
end

seqs = configSeqs(fullfile(datasetPath, data_type), data_type); % the set of sequences

resultPath = ['./results/results_' evalType '/' data_type '/'];
if(~exist(resultPath,'dir'))
    mkdir(resultPath);
end

disp('**************begin***************');

for idxSeq = 1:video_num:length(seqs)
    s1 = seqs{idxSeq};
    s2 = seqs{idxSeq + 1};
    s3 = seqs{idxSeq + 2};
    disp(['DSiam_RD_TS---' num2str(ceil(idxSeq / 3)) '---' s1.name '---' s2.name '---' s3.name]);
    
    [res1, res2, res3] = run_DSiam_RD_TS(s1, s2, s3);
    
    if(isempty(res1) || isempty(res2) || isempty(res3))
        disp([s1.name '-' s2.name '-' s3.name ' is wrong']);
        continue;
    end
    
    res1.len = s1.len;
    res1.annoBegin = s1.annoBegin;
    res1.startFrame = s1.startFrame;       
    results = res1;
    save([resultPath s1.name '_DSiam_RD_TS.mat'], 'results');

    res2.len = s2.len;
    res2.annoBegin = s2.annoBegin;
    res2.startFrame = s2.startFrame;
    results = res2;
    save([resultPath s2.name '_DSiam_RD_TS.mat'], 'results');

    res3.len = s3.len;
    res3.annoBegin = s3.annoBegin;
    res3.startFrame = s3.startFrame;
    results = res3;
    save([resultPath s3.name '_DSiam_RD_TS.mat'], 'results');
    
    clear global;
end

disp('**************end***************');
