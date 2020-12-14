close all;
clear, clc;
warning off all;
addpath(genpath('.')); 

datasetPath = 'G:/multi-drone-sot/data/MDOT'; % the dataset path
reEvalFlag = 0; % the flag to re-evaluate trackers
evalType = 'OPE'; % the evaluation type such as 'OPE','SRE','TRE'
dataType = 'two'; % two or three
rankingType = 'AUC'; %AUC, threshold
show_att = 1;
show_drone = 0;

if(strcmp(dataType, 'two'))
    video_num = 2;
    showType = ' on Two-MDOT';
elseif(strcmp(dataType, 'three'))
    video_num = 3;
    showType = ' on Three-MDOT';
else
    video_num = 0;
    showType = '';
end 

trackers = configTrackers_ifs; % the set of trackers
seqs = configSeqs(fullfile(datasetPath, dataType), dataType); % the set of sequences

% the visual attributes in the dataset
% attName = {'Night','Day','Camera Motion','Partial Occlusion','Full Occlusion','Out-of-View','Similar Object','Viewpoint Change', 'Illumination Variation', 'low Resolution'};
attName = {'NIGHT','DAY','CM','POC','FOC','OV','SO','VC', 'IV', 'LR'};
          
numSeq = length(seqs);
numTrk = length(trackers);

nameTrkAll = cell(numTrk,1);
for idxTrk = 1:numTrk
    t = trackers{idxTrk};
    nameTrkAll{idxTrk} = t.namePaper;
end

rpAll = ['./results_IFS/results_' evalType '/' dataType '/'];
figPath = ['./results_IFS/figs/overall/' dataType '/'];
perfMatPath = ['./results_IFS/perfMat/overall/' dataType '/'];

if ~exist(figPath,'dir')
    mkdir(figPath);
end

if ~exist(perfMatPath,'dir')
    mkdir(perfMatPath);
end

metricTypeSet = {'error', 'overlap'};

rankNum = 40;%number of plots to show------------------------------------------------------------------------
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

    % If the performance Mat file, dataName, does not exist, it will call genPerfMat to generate the file.
    switch metricType
        case 'overlap'
            titleName = ['Success plots for all' showType];
        case 'error'
            titleName = ['Precision plots for all' showType];
    end
    dataName = [perfMatPath 'aveSuccessRatePlot_' num2str(numTrk) 'alg_'  plotType '_IFS.mat'];
    if(~exist(dataName, 'file') || reEvalFlag)
        genPerfMat_IFS(datasetPath, seqs, trackers, evalType, dataType, rpAll, perfMatPath, thresholdSetOverlap, thresholdSetError, nameTrkAll);
    end
   
    load(dataName);
    numTrk = size(aveSuccessRatePlot,1);        
    if(rankNum > numTrk || rankNum <0)
        rankNum = numTrk;
    end

    figName = [figPath 'quality_plot_' plotType '_' rankingType];
    idxSeqSet = 1:length(seqs);

    %% draw and save the overall performance plot
    plotDrawSave(numTrk,plotDrawStyle,aveSuccessRatePlot,idxSeqSet,rankNum,rankingType,rankIdx,nameTrkAll,thresholdSet,titleName, xLabelName,yLabelName,figName);

    if show_att == 1
        for attIdx = 1:length(attName)
            idxSeqSet_att = [];
            for idx_num = 1:length(idxSeqSet)
                if seqs{idxSeqSet(idx_num)}.att(attIdx) == 1
                    idxSeqSet_att(end+1) = idxSeqSet(idx_num);
                end
            end
            figName_att = [figPath 'quality_plot_' plotType '_' rankingType '_' attName{attIdx}];
            switch metricType
                case 'overlap'
                    titleName_att = ['Success plots' showType ' - ' attName{attIdx}];
                case 'error'
                    titleName_att = ['Precision plots' showType ' - ' attName{attIdx}];
            end
            plotDrawSave(numTrk,plotDrawStyle,aveSuccessRatePlot,idxSeqSet_att,rankNum,rankingType,rankIdx,nameTrkAll,thresholdSet,titleName_att, xLabelName,yLabelName,figName_att);
        end
    end
    

    %% draw and save the performance plot for each drone
    if show_drone == 1
        for droneIdx = 1:video_num
            idxSeqSet = [];
            idx_num = 1;
            for seq_index = 1:length(seqs)
                if seqs{seq_index}.uav == droneIdx
                    idxSeqSet(idx_num) = seq_index;
                    idx_num = idx_num + 1;
                end
            end
            if(length(idxSeqSet)<2)
                continue;
            end

            figName = [figPath 'drone' num2str(droneIdx) '_'  plotType '_' rankingType];
            if show_IFS
                switch metricType
                    case 'overlap'
                        titleName = ['Success plots for drone' num2str(droneIdx) showType];
                    case 'error'
                        titleName = ['Precision plots for drone' num2str(droneIdx) showType];
                end
            else
                switch metricType
                    case 'overlap'
                        titleName = ['Success plots for drone' num2str(droneIdx) showType];
                    case 'error'
                        titleName = ['Precision plots for drone' num2str(droneIdx) showType];
                end
            end

            plotDrawSave(numTrk,plotDrawStyle,aveSuccessRatePlot,idxSeqSet,rankNum,rankingType,rankIdx,nameTrkAll,thresholdSet,titleName, xLabelName,yLabelName,figName);
            %% draw and save the performance plot for each attribute
    %         if show_att == 1
    %             for attIdx = 1:length(attName)
    %                 idxSeqSet_att = [];
    %                 for idx_num = 1:length(idxSeqSet)
    %                     if seqs{idxSeqSet(idx_num)}.att(attIdx) == 1
    %                         idxSeqSet_att(end+1) = idxSeqSet(idx_num);
    %                     end
    %                 end
    %                 figName_att = [figPath 'drone' num2str(droneIdx) '_'  plotType '_' rankingType '_' attName{attIdx}];
    %                 switch metricType
    %                     case 'overlap'
    %                         titleName_att = ['Success plots of ' evalType ' for drone' num2str(droneIdx) showType ' - ' attName{attIdx} ];
    %                     case 'error'
    %                         titleName_att = ['Precision plots of ' evalType ' for drone' num2str(droneIdx) showType ' - ' attName{attIdx} ];
    %                 end
    %                       plotDrawSave(numTrk,plotDrawStyle,aveSuccessRatePlot,idxSeqSet_att,rankNum,rankingType,rankIdx,nameTrkAll,thresholdSet,titleName_att, xLabelName,yLabelName,figName_att);
    %             end
    %         end
        end
        
    end        
   
end
