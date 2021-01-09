function seqs = configSeqs(datasetPath, data_type)

if(strcmp(data_type, 'two'))
    video_num = 2;
elseif(strcmp(data_type, 'three'))
    video_num = 3;
else
    video_num = 0;
end

d = dir(datasetPath);
isub = [d(:).isdir];
videoFolds = {d(isub).name}';
videoFolds(ismember(videoFolds,{'.','..'})) = [];

seq_number = 1;
seqs = cell(1, length(videoFolds)*2);
for i = 1:length(videoFolds)
%     att = load(fullfile(datasetPath, videoFolds{i}, [videoFolds{i} '.txt']));
    for j = 1:video_num
        seq.name = [videoFolds{i} '-' num2str(j)];
        seq.path = fullfile(datasetPath, videoFolds{i}, seq.name, 'img');
        seq.startFrame = 1;
        seq.endFrame = length(dir([seq.path '/*.jpg']));
        seq.len = seq.endFrame - seq.startFrame + 1;
        seq.nz = 8;
        seq.ext = 'jpg';
        seq.annoBegin = 1;
        seq.format = 'otb';
        seq.uav = j;
%         seq.att = att;
        seq.att = [0,0,0,0,0,0,0,0];
        seq.s_frames = cell(seq.len,1);
        nz	= strcat('%0',num2str(seq.nz),'d');
        for k = 1:seq.len
            image_no = seq.startFrame + (k-1);
            id = sprintf(nz,image_no);
            seq.s_frames{k} = fullfile(seq.path,[id,'.',seq.ext]);
        end
        
        seq.groundtruth = dlmread(fullfile(datasetPath, videoFolds{i}, seq.name, 'groundtruth.txt'));
        seq.init_rect = seq.groundtruth(1, :);
        
        seqs{seq_number} = seq;
        seq_number = seq_number + 1;
    end
end
