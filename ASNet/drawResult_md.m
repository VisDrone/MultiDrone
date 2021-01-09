close all;
clear, clc;
warning off all;
addpath(genpath('.')); 

datasetPath = 'E:/multi-drone/data/MDOT'; % the dataset path
evalType = 'OPE'; % the evaluation types such as OPE, SRE and TRE
dataType = 'test';
trks = configTrackers; % the set of trackers
seqs = configSeqs(fullfile(datasetPath, dataType)); % the set of sequences
pathRes = ['./results/results_' evalType '/'  dataType '/']; % the folder containing the tracking results

pathDraw = ['./tmp/' evalType '/'  dataType '/'];% the folder that will stores the images with overlaid bounding box

plotSetting;

lenTotalSeq = 0;

for i = 1:length(trks)
    trk = trks{i};
    trk_name = trk.name;
    LineStyle = plotDrawStyle{i}.lineStyle;
    color = plotDrawStyle{i}.color;
    LineWidth = 2;
    for j = 1:2:length(seqs)
%     for j = 1
        seq = seqs{j};
        seq_name = seq.name;
        seq_length = seq.endFrame-seq.startFrame+1;
        
        seq2 = seqs{j+1};
        seq2_name = seq2.name;
        seq2_length = seq.endFrame-seq.startFrame+1;
        
        if(seq_length ~= seq2_length)
            error("seq_length is not equal to seq2_length");
        end
        
        pathSave = [pathDraw seq_name '/'];
        if(~exist(pathSave,'dir'))
            mkdir(pathSave);
        end
        
        lenTotalSeq = lenTotalSeq + seq_length + seq2_length;
        
        result = load_results(pathRes, seq_name, trk_name);
        result2 = load_results(pathRes, seq2_name, trk_name);
        
        for index = 1:seq_length
%         for index = 20
            fileName = seq.s_frames{index};
            fileName2 = seq2.s_frames{index};
%             set(gcf,'position',[0 0 1960 1280])
            subplot(2,1,1);
            draw_result(fileName, index, result, color, LineWidth, LineStyle);
            subplot(2,1,2);
            draw_result(fileName2, index, result2, color, LineWidth, LineStyle);
%             pic=cat(2,img,img2);
%             imshow(pic);
            pause(0.05);
%             imwrite(frame2im(getframe(gcf)), [pathSave  num2str(index) '.jpg']);
        end
        
    end
    
end

function res = load_results(pathRes, seq_name, trk_name)
res_mat = [pathRes seq_name '_' trk_name '.mat'];
if(~exist(res_mat, 'file'))
    error("the res_mat is not exist")
else
    load(res_mat);
end
res = results;

if(~isfield(res,'type') && isfield(res,'transformType'))
    res.type = res.transformType;
    res.res = res.res';
end

if strcmp(res.type,'rect')
    for i = 2:res.len
        r = res.res(i,:);
        if(isnan(r) | r(3)<=0 | r(4)<=0)
            res.res(i,:)=res.res(i-1,:);
        end
    end
end
end

function draw_result(fileName, i, result, color, LineWidth, LineStyle)
img = imread(fileName);
imshow(img);
switch result.type
    case 'rect'
        rectangle('Position', result.res(i,:), 'EdgeColor', color, 'LineWidth', LineWidth,'LineStyle',LineStyle);
    case 'ivtAff'
        drawbox(result.tmplsize, result.res(i,:), 'Color', color, 'LineWidth', LineWidth,'LineStyle',LineStyle);
    case 'L1Aff'
        drawAffine(result.res(i,:), result.tmplsize, color, LineWidth, LineStyle);
    case 'LK_Aff'
        [corner, c] = getLKcorner(result.res(2*i-1:2*i,:), result.tmplsize);
        hold on,
        plot([corner(1,:) corner(1,1)], [corner(2,:) corner(2,1)], 'Color', color,'LineWidth',LineWidth,'LineStyle',LineStyle);
    case '4corner'
        corner = result.res(2*i-1:2*i,:);
        hold on,
        plot([corner(1,:) corner(1,1)], [corner(2,:) corner(2,1)], 'Color', color,'LineWidth',LineWidth,'LineStyle',LineStyle);
    case 'SIMILARITY'
        warp_p = parameters_to_projective_matrix(result.type,result.res(i,:));
        [corner, c] = getLKcorner(warp_p, result.tmplsize);
        hold on,
        plot([corner(1,:) corner(1,1)], [corner(2,:) corner(2,1)], 'Color', color,'LineWidth',LineWidth,'LineStyle',LineStyle);
    otherwise
        disp('The type of output is not supported!')
        return;
end
end