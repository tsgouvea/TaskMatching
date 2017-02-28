function BlockLen = drawBlockLen(TaskParameters)
if TaskParameters.GUI.blockLenMax < TaskParameters.GUI.blockLenMin
    TaskParameters.GUI.blockLenMax = TaskParameters.GUI.blockLenMax + TaskParameters.GUI.blockLenMin;
    warning('Bpod:Matching:blockLenMinMax','Minimum greater than maximum. Maximum interpreted as offset from minimum.')
end
BlockLen = 0;
iDraw = 0;
while BlockLen < TaskParameters.GUI.blockLenMin || BlockLen > TaskParameters.GUI.blockLenMax
    BlockLen = ceil(exprnd(sqrt(TaskParameters.GUI.blockLenMin*TaskParameters.GUI.blockLenMax)));
    iDraw = iDraw+1;
    if iDraw > 1000
        BlockLen = ceil(random('unif',TaskParameters.GUI.blockLenMin,TaskParameters.GUI.blockLenMax));
        warning('Bpod:Matching:blockLenDraw',['Drawing block length from exponential distribution is taking too long.'...
            'Using uniform distribution instead. If exponential is important for you, set reasonable minimum and maximum values and try again.'])
    end
end
end