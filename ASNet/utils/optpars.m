function [opts] = optpars(opts,targetsz,im_sz)

asp_ratio = targetsz(1)/targetsz(2);
szratio = prod(targetsz)/prod(im_sz(1:2));

if(asp_ratio>2)
    opts.targetszrate =0.98;    
elseif(szratio>0.05)
    opts.targetszrate = 1;   
else
    opts.targetszrate = 1;
end