function bfail = checkResult(results, subAnno)
% validate the results
% 
% Some trackers may fail on some sequences so before evaulating the results
% we have to check them.

bfail = 0;
if(isempty(results))
    disp('Empty results!');
    bfail = 1;
else
    if(isempty(results.res))
        disp('Empty result in frame!');
        bfail = 1;
    else
        if(size(results.res,1) < size(subAnno,1))
            disp('Result not match in frame!');
            bfail = 1;
        end
    end
end