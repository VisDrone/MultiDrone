close all;
clear, clc;
warning off all;
addpath(genpath('.')); 

datasetPath = 'data/'; % the dataset path
evalType = 'OPE'; % the evaluation type such as 'OPE','SRE','TRE'
dataType = 'test';

trackers = configTrackers; % the set of trackers
seqs = configSeqs(fullfile(datasetPath, dataType)); % the set of sequences

rpAll = ['./results/results_' evalType '/' dataType '/'];

numSeq = length(seqs);
numTrk = length(trackers);

for idxTrk=1:numTrk
    t = trackers{idxTrk};
    fps_all = 0;
    fps_exist = 0;
    for idxSeq=1:numSeq
        s = seqs{idxSeq};
        res_mat = [rpAll s.name '_' t.name '.mat'];
        if(~exist(res_mat, 'file'))
            disp(["the " res_mat " is not exist"]);
            continue;
        else
            load(res_mat);
        end
        res = results;
        fps_all = fps_all + res.fps;
        fps_exist = fps_exist + 1;
    end
    fps = fps_all / fps_exist;
    disp([t.name " fps is " fps]);
end