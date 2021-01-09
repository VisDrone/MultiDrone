% -------------------------------------------------------------------------------------------------------------------------
classdef CirConv < dagnn.Layer
%CirConv
%   circulant convolution operation, this version is not used for BP
%
%   Qing Guo, 2017
% -------------------------------------------------------------------------------------------------------------------------
    properties
        opts = {'cuDNN'}
        enable = false
        calsum = false
        isrep = false % whether to only transform one sample or all samples
    end

    methods
        function outputs = forward(obj, inputs, params)
            assert(numel(inputs) <= 2, 'one input is needed');
            
            if obj.enable % enable transformation or not
                ofeat = inputs{1}; % deep feature
                
                if obj.isrep
                   numsamp = 1; 
                else
                   numsamp =  size(ofeat,4);
                end
                
                for fi = 1:numsamp
                    feat = ofeat(:,:,:,fi);
                    trans_alphaf = params{1};
                    trans_featf = params{2};
                    trans_lr = params{3};
                    
                    % add transformation to feat
                    cos_window = hann(size(feat,1)) * hann(size(feat,2))';
                    feat = bsxfun(@times, feat, cos_window); 
                    featf = fft2(feat);
                    numcorr = numel(featf(:,:,1));
                    if ~obj.calsum
                        kfeatf = (featf .* conj(trans_featf))./numcorr;
                        t_feat = real(ifft2(trans_alphaf.* kfeatf));
                        assert(ndims(feat) == ndims(t_feat), 'feat and t_feat have different number of dimensions');
                        toutputs(:,:,:,fi)= (1-trans_lr).*ofeat(:,:,:,fi)+trans_lr.*t_feat;
                    else
                        kfeatf = sum(featf .* conj(trans_featf),3)./numel(featf);
                        t_feat = real(ifft2(trans_alphaf.* kfeatf));
                        toutputs(:,:,:,fi) = (1-trans_lr).*inputs{2}(:,:,:,fi)+trans_lr.*t_feat;
                    end
                end
                if obj.isrep
                    outputs{1} = repmat(toutputs,1,1,1,size(ofeat,4));
                else
                    outputs{1} = toutputs;
                end
            else
                if obj.calsum
                   outputs{1} = inputs{2};%(:,:,1,:); 
                else
                   outputs{1} = inputs{1}; 
                end
            end
            
        end

        function [derInputs, derParams] = backward(obj, inputs, params, derOutputs)
            assert(numel(inputs) == 1, 'one input are needed');
            assert(numel(derOutputs) == 1, 'only one gradient should be flowing in this layer (dldy)');
            derInputs{1} = derOutputs{1}; 
            derParams = {};
        end

        function outputSizes = getOutputSizes(obj, inputSizes)
            outputSizes = inputSizes{1};
        end
    
        function rfs = getReceptiveFields(obj)
            rfs(1,1).size = [inf inf]; % could be anything
            rfs(1,1).stride = [1 1];
            rfs(1,1).offset = 1;
            rfs(2,1).size = [inf inf];
            rfs(2,1).stride = [1 1];
            rfs(2,1).offset = 1;
        end

        function obj = CirConv(varargin)
            obj.load(varargin);
        end

    end

end
