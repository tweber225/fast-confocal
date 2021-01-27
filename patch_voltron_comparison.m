% Load patch data
patchSamplingRate = 10e3;
patchDataFilename = 'C:\Users\twebe\Desktop\2020.12.16\cell1_0001-0025.h5';
s = ws.loadDataFile(patchDataFilename);
patchVoltage = s.sweep_0002.analogScans(:,1);
patchTimes = 0:(patchSamplingRate^-1):(patchSamplingRate^-1)*(length(patchVoltage)-1);


% Load Image Stack
numChannels = 3;
stackFilename = 'C:\Users\twebe\Desktop\2020.12.16\cell1_00001.tif';
import ScanImageTiffReader.ScanImageTiffReader;
reader = ScanImageTiffReader(stackFilename);

% Get timestamps
reader

% Grab 2nd channel
interleavedStack = permute(reader.data,[2 1 3]); % Permute here b/c SI's 1st dim is X/horizontal, but MATLAB's 1st dim is Y/vertical
[numYPix,numXPix,totFrames] = size(interleavedStack);
numTimes = totFrames/numChannels;
vectorizedStack = reshape(interleavedStack,[numYPix*numXPix,numChannels,totFrames/numChannels]);
clear interleavedStack
chan2 = squeeze(vectorizedStack(:,2,:));




