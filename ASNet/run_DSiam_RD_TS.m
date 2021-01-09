function [results1, results2, results3] = run_DSiam_RD_TS(seq1, seq2, seq3)

% Path initial setting
addpath(genpath('./matconvnet/matlab/'));
vl_setupnn ;
addpath('./utils');
addpath('./models');


% the pretrained network for Dynamic Siamese Network 
netname = 'siamfc';
% '1res' denotes the multi-layer DSiam (DSiamM in paper) and uses two layers for tracking
% '0res' denotes the single-layer DSiam (DSiam in paper) and uses the last layer for tracking
nettype = '0res';
[results1, results2, results3] = DSiam_RD_TS(seq1,seq2,seq3,netname,nettype);
