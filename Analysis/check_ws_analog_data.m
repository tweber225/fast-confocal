s = ws.loadDataFile('U:\eng_research_economo\Imaging\Voltron Confocal\wsdata\2021.02.04\slice1_cell1_0101.h5');

fieldNames = fields(s);
numSweeps = numel(fieldNames)-1;
numTimePoints = size(s.(fieldNames{2}).analogScans,1);

allVoltageData = zeros(numTimePoints,numSweeps);
for sweepIdx = 1:numSweeps
    aData = s.(fieldNames{sweepIdx+1}).analogScans;
    allVoltageData(:,sweepIdx) = aData(:,1);
end
