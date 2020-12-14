function genPerfMat_IFS(datasetPath, seqs, trackers, evalType, dataType, rpAll, perfMatPath, thresholdSetOverlap, thresholdSetError, nameTrkAll)

if(strcmp(dataType, 'two'))
    video_num = 2;
elseif(strcmp(dataType, 'three'))
    video_num = 3;
else
    video_num = 0;
end

numTrk = length(trackers);

for idxSeq=1:video_num:length(seqs)
    
    s1 = seqs{idxSeq};
    anno1 = s1.groundtruth;
    s2 = seqs{idxSeq+1};
    anno2 = s2.groundtruth;
    if(video_num == 3)
        s3 = seqs{idxSeq+2};
        anno3 = s3.groundtruth;
    end
    
    name = strsplit(s1.name, '-');
    name = name{1};
    
    for idxTrk = 1:numTrk       
        t = trackers{idxTrk};
        % check the result format
        res_mat = [rpAll name '_' t.name '.mat'];
        if(~exist(res_mat, 'file'))
            res_txt = [rpAll name '_' t.name '.txt'];
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
        
        if(video_num == 3)
            select3 = (select == 3);
            anno_res3 = anno3 .* select3;
            anno = anno_res1 + anno_res2 + anno_res3;
        else
            anno = anno_res1 + anno_res2;
        end
        
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
                

        aveSuccessRatePlot(idxTrk, idxSeq,:) = successNumOverlap/(lenALL+eps) * 100;
        aveSuccessRatePlot(idxTrk, idxSeq+1,:) = successNumOverlap/(lenALL+eps) * 100;
        aveSuccessRatePlotErr(idxTrk, idxSeq,:) = successNumErr/(lenALL+eps) * 100;
        aveSuccessRatePlotErr(idxTrk, idxSeq+1,:) = successNumErr/(lenALL+eps) * 100;
        if(video_num == 3)
            aveSuccessRatePlot(idxTrk, idxSeq+2,:) = successNumOverlap/(lenALL+eps) * 100;
            aveSuccessRatePlotErr(idxTrk, idxSeq+2,:) = successNumErr/(lenALL+eps) * 100;
        end
    end
end


dataName1 = [perfMatPath 'aveSuccessRatePlot_' num2str(numTrk) 'alg_overlap_' evalType '_IFS.mat'];
save(dataName1,'aveSuccessRatePlot','nameTrkAll');

dataName2 = [perfMatPath 'aveSuccessRatePlot_' num2str(numTrk) 'alg_error_' evalType '_IFS.mat'];
aveSuccessRatePlot = aveSuccessRatePlotErr;
save(dataName2,'aveSuccessRatePlot','nameTrkAll');
