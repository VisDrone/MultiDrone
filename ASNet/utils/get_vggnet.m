function [net_obj,net_conv] = get_vggnet(netpath,maxlayer)

net_conv = load(netpath);
net_conv = dagnn.DagNN.fromSimpleNN(net_conv);
maxlayeridx = net_conv.getLayerIndex(maxlayer);

for li = numel(net_conv.layers):-1:maxlayeridx+1
   net_conv.removeLayer(net_conv.layers(li).name); 
end
    
net_obj = load(netpath);
net_obj = dagnn.DagNN.fromSimpleNN(net_obj);
for li = numel(net_obj.layers):-1:maxlayeridx+1
   net_obj.removeLayer(net_obj.layers(li).name); 
end

net_conv.setLayerInputs(net_conv.layers(1).name,{'instance'});
net_obj.setLayerInputs(net_obj.layers(1).name,{'exemplar'});
end