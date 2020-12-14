function plotDrawSave(numTrk,plotDrawStyle,aveSuccessRatePlot,idxSeqSet,rankNum,rankingType,rankIdx,nameTrkAll,thresholdSet,titleName,xLabelName,yLabelName,figName)

for idxTrk = 1:numTrk
    %each row is the sr plot of one sequence
    tmp = aveSuccessRatePlot(idxTrk, idxSeqSet,:);
    aa = reshape(tmp,[length(idxSeqSet),size(aveSuccessRatePlot,3)]);
    aa = aa(sum(aa,2)>eps,:);
    bb = mean(aa, 1);
    switch rankingType
        case 'AUC'
            perf(idxTrk) = mean(bb);
        case 'threshold'
            perf(idxTrk) = bb(rankIdx);
    end
end

[~,indexSort] = sort(perf,'descend');

i=1;
fontSize = 20;
fontSizeLegend = 12;

figure1 = figure;
set(gcf,'position',[600, 100, 800, 750])
axes1 = axes('Parent',figure1,'FontSize',12);

for idxTrk = indexSort(1:rankNum)
    tmp = aveSuccessRatePlot(idxTrk,idxSeqSet,:);
    aa = reshape(tmp,[length(idxSeqSet),size(aveSuccessRatePlot,3)]);
    aa = aa(sum(aa,2)>eps,:);
    bb = mean(aa, 1);
    switch rankingType
        case 'AUC'
            score = mean(bb);
            tmp=sprintf('%.1f', score);
        case 'threshold'
            score = bb(rankIdx);
            tmp=sprintf('%.1f', score);
    end    
    
    tmpName{i} = [nameTrkAll{idxTrk} ' [' tmp ']'];
    h(i) = plot(thresholdSet,bb,'color',plotDrawStyle{i}.color, 'lineStyle', plotDrawStyle{i}.lineStyle,'lineWidth', 4,'Parent',axes1);
    hold on
    i=i+1;
end


legend(tmpName,'Interpreter', 'none','fontsize',fontSizeLegend);
title(titleName,'fontsize',fontSize);
xlabel(xLabelName,'fontsize',fontSize);
ylabel(yLabelName,'fontsize',fontSize);
hold off

saveas(gcf,figName,'png');

end