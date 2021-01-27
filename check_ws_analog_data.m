s = ws.loadDataFile('C:\Users\twebe\Desktop\2020.12.16\cell1_0001-0025.h5');

fieldNames = fields(s);
numSweeps = numel(fieldNames)-1;
numTimePoints = size(s.(fieldNames{2}).analogScans,1);

allVoltageData = zeros(numTimePoints,numSweeps);
for sweepIdx = 1:numSweeps
    aData = s.(fieldNames{sweepIdx+1}).analogScans;
    allVoltageData(:,sweepIdx) = aData(:,1);
end
