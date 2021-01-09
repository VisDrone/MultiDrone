function genPerfMat_selection(datasetPath, seqs, trackers, evalType, dataType, nameTrkAll, perfMatPath, thresholdSetOverlap, thresholdSetError)

numTrk = length(trackers);

rpAll = ['./results/results_' evalType '/' dataType '/'];

for idxSeq=1:2:length(seqs)
    
    s1 = seqs{idxSeq};
    anno1 = s1.groundtruth;
    s2 = seqs{idxSeq+1};
    anno2 = s2.groundtruth;
    
    name = strsplit(s1.name, '-');
    name = name{1};
    
    for idxTrk = 1:numTrk       
        t = trackers{idxTrk};        
        % check the result format
        res_mat = [rpAll name '_' t.name '.mat'];
        if(~exist(res_mat, 'file'))
            res_txt = [rpAll name '.txt'];
            results = cell(1,1);
            results.res = load(res_txt);
            results.type = 'rect';
            results.annoBegin = 1;
            results.startFrame = 1;
            results.len = size(results{1}.res, 1);
        else
            load(res_mat);
        end
        
        select = results.select;
        select1 = (select == 1);
        select2 = (select == 2);
        anno_res1 = anno1 .* select1;
        anno_res2 = anno2 .* select2;
        anno = anno_res1 + anno_res2;
        
        disp([name ' ' t.name]);
        
        lenALL = 0;
        
        idxNum = 1;
        
        successNumOverlap = zeros(idxNum,length(thresholdSetOverlap));
        successNumErr = zeros(idxNum,length(thresholdSetError));
        
        for idx = 1:idxNum
            res = results;                      
            len = size(anno,1);            
            if isempty(res.res)
                break;
            end
            
            if(~isfield(res,'type') && isfield(res,'transformType'))
                res.type = res.transformType;
                res.res = res.res';
            end
            
            [aveCoverage, aveErrCenter, errCoverage, errCenter] = calcSeqErrRobust(res, anno);

            for tIdx = 1:length(thresholdSetOverlap)
                successNumOverlap(idx,tIdx) = sum(errCoverage >thresholdSetOverlap(tIdx));
            end
            
            for tIdx = 1:length(thresholdSetError)
                successNumErr(idx,tIdx) = sum(errCenter <= thresholdSetError(tIdx));
            end
            
            lenALL = lenALL + len;
        end
                

        aveSuccessRatePlot(idxTrk, idxSeq,:) = successNumOverlap/(lenALL+eps);
        aveSuccessRatePlotErr(idxTrk, idxSeq,:) = successNumErr/(lenALL+eps);
    end
end

dataName1 = [perfMatPath 'aveSuccessRatePlot_' num2str(numTrk) 'alg_overlap_' evalType '.mat'];
save(dataName1,'aveSuccessRatePlot','nameTrkAll');

dataName2 = [perfMatPath 'aveSuccessRatePlot_' num2str(numTrk) 'alg_error_' evalType '.mat'];
aveSuccessRatePlot = aveSuccessRatePlotErr;
save(dataName2,'aveSuccessRatePlot','nameTrkAll');
