close all;
clear, clc;
warning off all;
addpath(genpath('.')); 

datasetPath = 'E:/multi-drone/data/MDOT/'; % the dataset path
reEvalFlag = 0; % the flag to re-evaluate trackers
evalType = 'OPE'; % the evaluation type such as 'OPE','SRE','TRE'
dataType = 'test';
rankingType = 'threshold'; %AUC, threshold

% attPath = fullfile(datasetPath, 'attributes'); % the folder that contains the annotation files for sequence attributes
trackers = configTrackers; % the set of trackers

seqs = configSeqs(fullfile(datasetPath, dataType)); % the set of sequences

% the visual attributes in the dataset
% attName = {'Aspect Ratio Change','Background Clutter','Camera Motion','Fast Motion','Full Occlusion','Illumination Variation','Low Resolution',...
%            'Out-of-View','Partial Occlusion','Similar Object','Scale Variation','Viewpoint Change'};
% attFigName = {'Aspect_Ratio_Change','Background_Clutter','Camera_Motion','Fast_Motion','Full_Occlusion','Illumination_Variation','Low_Resolution',...
%            'Out-of-View','Partial_Occlusion','Similar_Object','Scale_Variation','Viewpoint_Change'};
       
numSeq = length(seqs);
numTrk = length(trackers);

nameTrkAll = cell(numTrk,1);
for idxTrk = 1:numTrk
    t = trackers{idxTrk};
    nameTrkAll{idxTrk} = t.namePaper;
end

nameSeqAll = cell(numSeq,1);
numAllSeq = zeros(numSeq,1);

% att = [];
for idxSeq = 1:numSeq
    s = seqs{idxSeq};
    nameSeqAll{idxSeq} = s.name;    
    numAllSeq(idxSeq) = s.len;
%     att(idxSeq,:) = load([attPath '/' s.name '_attr.txt']);
end

% attNum = size(att,2);

figPath = ['results/figs/overall/' dataType '/'];

perfMatPath = ['results/perfMat/overall/' dataType '/'];

if ~exist(figPath,'dir')
    mkdir(figPath);
end

if ~exist(perfMatPath,'dir')
    mkdir(perfMatPath);
end

metricTypeSet = {'error', 'overlap'};

rankNum = 20;%number of plots to show------------------------------------------------------------------------
plotDrawStyle = getDrawStyle(rankNum);

thresholdSetOverlap = 0:0.05:1;
thresholdSetError = 0:50;

for i = 1:length(metricTypeSet)
    metricType = metricTypeSet{i};%error,overlap
    
    switch metricType
        case 'overlap'
            thresholdSet = thresholdSetOverlap;
            rankIdx = 11;
            xLabelName = 'Overlap threshold';
            yLabelName = 'Success rate';
        case 'error'
            thresholdSet = thresholdSetError;
            rankIdx = 21;
            xLabelName = 'Location error threshold';
            yLabelName = 'Precision';
    end  
        
    if(strcmp(metricType,'error') && strcmp(rankingType,'AUC') || strcmp(metricType,'overlap') && strcmp(rankingType,'threshold'))
        continue;
    end
    
    tNum = length(thresholdSet);                    
    plotType = [metricType '_' evalType];

    switch metricType
        case 'overlap'
            titleName = ['Success plots of ' evalType ' for all'];
        case 'error'
            titleName = ['Precision plots of ' evalType ' for all'];
    end

    dataName = [perfMatPath 'aveSuccessRatePlot_' num2str(numTrk) 'alg_'  plotType '.mat'];

    % If the performance Mat file, dataName, does not exist, it will call genPerfMat to generate the file.
    if(~exist(dataName, 'file') || reEvalFlag)
        genPerfMat_selection(datasetPath, seqs, trackers, evalType, dataType, nameTrkAll, perfMatPath, thresholdSetOverlap, thresholdSetError);
    end        

    load(dataName);
    numTrk = size(aveSuccessRatePlot,1);        
    if(rankNum > numTrk || rankNum <0)
        rankNum = numTrk;
    end

    figName = [figPath 'quality_plot_' plotType '_' rankingType];
    idxSeqSet = 1:2:length(seqs);

    %% draw and save the overall performance plot
    plotDrawSave(numTrk,plotDrawStyle,aveSuccessRatePlot,idxSeqSet,rankNum,rankingType,rankIdx,nameTrkAll,thresholdSet,titleName, xLabelName,yLabelName,figName);

    %% draw and save the performance plot for each attribute
%     for uavIdx = 1:2
%         idxSeqSet = [];
%         idx_num = 1;
%         for seq_index = 1:length(seqs)
%             if seqs{seq_index}.uav == uavIdx
%                 idxSeqSet(idx_num) = seq_index;
%                 idx_num = idx_num + 1;
%             end
%         end
%         if(length(idxSeqSet)<2)
%             continue;
%         end
% 
%         figName = [figPath 'uav' num2str(uavIdx) '_'  plotType '_' rankingType];
% 
%         switch metricType
%             case 'overlap'
%                 titleName = ['Success plots of ' evalType ' for uav' num2str(uavIdx)];
%             case 'error'
%                 titleName = ['Precision plots of ' evalType ' for uav' num2str(uavIdx)];
%         end
% 
%         plotDrawSave(numTrk,plotDrawStyle,aveSuccessRatePlot,idxSeqSet,rankNum,rankingType,rankIdx,nameTrkAll,thresholdSet,titleName, xLabelName,yLabelName,figName);
%     end        

    
%     %% draw and save the performance plot for each attribute
%     attTrld = 0;
%     for attIdx = 1:attNum
%         idxSeqSet = find(att(:,attIdx)>attTrld);
%         if(length(idxSeqSet)<2)
%             continue;
%         end
%         disp([attName{attIdx} ' ' num2str(length(idxSeqSet))])
% 
%         figName = [figPath attFigName{attIdx} '_'  plotType '_' rankingType];
%         titleName = ['Plots of ' evalType ': ' attName{attIdx} ' (' num2str(length(idxSeqSet)) ')'];
% 
%         switch metricType
%             case 'overlap'
%                 titleName = ['Success plots of ' evalType ' - ' attName{attIdx} ' (' num2str(length(idxSeqSet)) ')'];
%             case 'error'
%                 titleName = ['Precision plots of ' evalType ' - ' attName{attIdx} ' (' num2str(length(idxSeqSet)) ')'];
%         end
% 
%         plotDrawSave(numTrk,plotDrawStyle,aveSuccessRatePlot,idxSeqSet,rankNum,rankingType,rankIdx,nameTrkAll,thresholdSet,titleName, xLabelName,yLabelName,figName);
%     end        
end
