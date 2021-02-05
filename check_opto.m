% Input the filename and its directory
fileName = 'slice2_cell1_00001.tif';
fileDir = 'Q:\wsdata\2021.02.04';
fullFileNameDir = [fileDir filesep fileName];

% Scanner/experiment parameters
lineFrequency = 117.2e3; % Hz
optoPulseDuration = 500e-6; % sec
expectedPulseRate = 5;      % Hz

% Processing Parameters
numCutFrames = 20;
detrendingTime = 100e-3;
beforePulseFrames = 20;
afterPulseFrame = 70;



%% Import the ScanImage TIFF reader, read file, get # channels from metadata
import ScanImageTiffReader.ScanImageTiffReader;
reader = ScanImageTiffReader(fullFileNameDir);
numChannels = get_num_tiff_channels(reader.metadata);

% Deinterleave the frame stack (mpStack means Multi-Plane stack)
interleavedStack = permute(reader.data,[2 1 3]); % Permute here b/c SI's 1st dim is X/horizontal, but MATLAB's 1st dim is Y/vertical
interleavedStack = interleavedStack(:,:,(numCutFrames*numChannels+1):end);
[numYPix,numXPix,totFrames] = size(interleavedStack);
numTimes = totFrames/numChannels;
mpStack = reshape(interleavedStack,[numYPix,numXPix,numChannels,totFrames/numChannels]);
clear interleavedStack

% Add blank flyback lines (number of lines ScanImage skips during what it thinks
% is flyback. We would like 0, but the min is 2)
numFlybackLines = 2;
mpStack = cat(1,mpStack,ones(numFlybackLines,numXPix,numChannels,numTimes));
numYPix = numYPix + numFlybackLines;



%% Detect opto pulses in data
% Sum in: X (fast scan) axis dimension, Z planes dimension)
collapsedStack = sum(mpStack,[2,3]);

% Calculate average frame trace to divide it out
meanFrameTrace = mean(collapsedStack,4);
collapsedStackNorm = collapsedStack./(meanFrameTrace);

% Smooth a bit and detrend
smoothingNumLines = ceil(optoPulseDuration*lineFrequency);
detrendingNumLines = ceil(detrendingTime*lineFrequency);
collapsedStackSmooth = smooth(collapsedStackNorm,smoothingNumLines)./smooth(collapsedStackNorm,detrendingNumLines);

% Threshold & find start points
threshLevel = 5*std(collapsedStackSmooth) + 1;
pulseStarts = diff(collapsedStackSmooth>threshLevel);
pulseStarts(pulseStarts<0) = 0;
pulseStarts = find(pulseStarts);

% Prune out any detected starts that are too close
corectPulseLocations = diff(pulseStarts) > (1/2)*lineFrequency/expectedPulseRate;
pulseStarts = pulseStarts(corectPulseLocations);

% Compute pulse frame #'s (BTW this could be more precise if we broke it
% down into line by line timing)
pulseFrameNum = round(pulseStarts/numYPix);

%% Average pulse responses
numPulses = numel(pulseFrameNum);
avgMpStack = zeros(numYPix,numXPix,numChannels,beforePulseFrames+afterPulseFrame+1);
for pulseIdx = 1:numPulses
    startFrame = pulseFrameNum(pulseIdx) - beforePulseFrames;
    endFrame = pulseFrameNum(pulseIdx) + afterPulseFrame;
    avgMpStack = avgMpStack + double(mpStack(:,:,:,startFrame:endFrame));
end


%% Save the average response data
saveDirAndName = [fullFileNameDir(1:(end-4)) '_opto_avg_response.tif'];
fTIF = Fast_Tiff_Write(saveDirAndName,1,0);
avgReponse = single(squeeze(sum(avgMpStack,3)));
for fIdx = 1:size(avgReponse,3)
    fTIF.WriteIMG(avgReponse(:,:,fIdx)');
end
fTIF.close;





