classdef Sum_w < dagnn.ElementWise
  %SUM DagNN sum layer
  %   The SUM layer takes the sum of all its inputs and store the result
  %   as its only output.
  %   Qing Guo, 2017.
  properties (Transient)
    numInputs
  end

  methods
    function outputs = forward(obj, inputs, params)
      obj.numInputs = numel(inputs) ;
      for ri=1:size(inputs{1},4)
          outputs{1}(:,:,:,ri) = imresize(gather(inputs{1}(:,:,:,ri)),[size(inputs{2},1),size(inputs{2},2)]);
      end
      outputs{1} = gpuArray(outputs{1});
%       outputs{1} = inputs{1} ;
      weights = repmat(params{1},1,1,1,size(outputs{1},4));
      for k = 2:obj.numInputs
        outputs{1} = weights.*outputs{1} + (1-weights).*inputs{k} ;
      end
    end

    function [derInputs, derParams] = backward(obj, inputs, params, derOutputs)
      for k = 1:obj.numInputs
        derInputs{k} = derOutputs{1} ;
      end
      derParams{1} = (inputs{1}-inputs{2}).*derOutputs{1};
      derParams{1} = sum(derParams{1},4)./size(inputs{1},4);
%       derParams = {} ;
    end

    function outputSizes = getOutputSizes(obj, inputSizes)
      outputSizes{1} = inputSizes{1} ;
      for k = 2:numel(inputSizes)
        if all(~isnan(inputSizes{k})) && all(~isnan(outputSizes{1}))
          if ~isequal(inputSizes{k}, outputSizes{1})
            warning('Sum layer: the dimensions of the input variables is not the same.') ;
          end
        end
      end
    end

    function rfs = getReceptiveFields(obj)
      numInputs = numel(obj.net.layers(obj.layerIndex).inputs) ;
      rfs.size = [1 1] ;
      rfs.stride = [1 1] ;
      rfs.offset = [1 1] ;
      rfs = repmat(rfs, numInputs, 1) ;
    end

    function obj = Sum_w(varargin)
      obj.load(varargin) ;
    end
  end
end
