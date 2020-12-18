s = ws.loadDataFile('Q:\wsdata\2020.12.16\cell3_0001-0025.h5');

fieldNames = fields(s);
numSweeps = numel(fieldNames)-1;
numTimePoints = size(s.sweep_0001.analogScans,1);

allVoltageData = zeros(numTimePoints,numSweeps);
for sweepIdx = 1:numSweeps
    aData = s.(['sweep_' sprintf('%04d',sweepIdx)]).analogScans;
    allVoltageData(:,sweepIdx) = aData(:,1);
end
