function [net_z,net_x] = get_simafcnet(netpath,nettype,opts)

% get two network for obj and search region respectively
net_z = load_pretrained(netpath, []);
net_x = load_pretrained(netpath, []);

%pretrain the siam net with the first frame


prefix_z = 'a_'; % used to identify the layers of the exemplar
prefix_x = 'b_'; % used to identify the layers of the instance
prefix_join = 'xcorr';
prefix_adj = 'adjust';

% exemplar branch (used only once per video) computes features for the target
remove_layers_from_prefix(net_z, prefix_x);
remove_layers_from_prefix(net_z, prefix_join);
remove_layers_from_prefix(net_z, prefix_adj);

% instance branch computes features for search region x and cross-correlates with z features
remove_layers_from_prefix(net_x, prefix_z);


% add target variation transformation for a_feat
net_x.addLayer('circonv1_1',...
    CirConv('isrep',true),{'a_feat'},{'ta_feat'},...
    {'cir11_alphaf','cir11_featf','cir11_lr','v_enable'});

% add background suppression transformation for b_feat
net_x.addLayer('circonv1_2',...
    CirConv(),{'b_feat'},{'tb_feat'},...
    {'cir12_alphaf','cir12_featf','cir12_lr','w_enable'});

net_x.setLayerInputs('xcorr',{'ta_feat','tb_feat'});

net_x.params(net_x.getParamIndex('cir11_lr')).value = opts.vlr;
net_x.params(net_x.getParamIndex('cir12_lr')).value = opts.wlr;

if strcmp(nettype,'1res')
    
    net_x.setLayerOutputs('xcorr',{'xcorr0_out'});
    % add target variation transformation for a_feat
    net_x.addLayer('circonv2_1',...
        CirConv('isrep',true),{'a_x14'},{'ta_x14'},...
        {'cir21_alphaf','cir21_featf','cir21_lr','v_enable'});
    
    % add background suppression transformation for b_feat
    net_x.addLayer('circonv2_2',...
        CirConv(),{'b_x14'},{'tb_x14'},...
        {'cir22_alphaf','cir22_featf','cir22_lr','w_enable'});
    
    net_x.addLayer('xcorr1',...
        XCorr(),...
        {'ta_x14','tb_x14'},...
        {'xcorr1_out'},...
        {});
    
    net_x.addLayer('sumw',...
        Sum_w(),{'xcorr0_out','xcorr1_out'},{'xcorr_out'},{'sumweights'});
    
    net_x.params(net_x.getParamIndex('cir21_lr')).value = opts.vlr;
    net_x.params(net_x.getParamIndex('cir22_lr')).value = opts.wlr;
    
end

net_x.rebuild();

end

