% Tracker performance evaluation tool for MDOT
% 1/23/2019 by Jiayu Zheng

close all;
clear, clc;
warning off all;

disp('**************config***************');

% g=gpuDevice(4);
% reset(g);

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
    name = strsplit(s1.name, '-');
    name = name{1};
    
    if exist([resultPath name '_ASNet.mat'],'file')
        continue;
    end
    
    disp(['ASNet---' num2str(ceil(idxSeq / 3)) '---' name]);
    
    [res] = run_ASNet(s1, s2, s3);
    
    if(isempty(res))
        disp([s1.name '-' s2.name '-' s3.name ' is wrong']);
        continue;
    end
    
    res.len = s1.len;
    res.annoBegin = s1.annoBegin;
    res.startFrame = s1.startFrame;       
    results = res;
    save([resultPath name '_ASNet.mat'], 'results');

    clear global;
end

disp('**************end***************');
