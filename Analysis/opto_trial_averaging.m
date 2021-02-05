%% Setup
% Add the support code
addpath foundation/

% Input the filename and its directory
fileName = 'field2_opto_00001.tif';
fileDir = 'C:\Users\Tim\Desktop';
fullFileNameDir = [fileDir filesep fileName];

% Scanner/experiment parameters
lineFrequency = 117.2e3; % Hz
optoPulseDuration = 500e-6; % sec
expectedPulseRate = 5;      % Hz

% Processing parameters
numCutFrames = 20; % Frames to cut out at the beginning (usually ~13)
detrendTime = 100e-3;    % sec
beforePulseFrames = 20;
afterPulseFrame = 70;



%% Import the image data using scanimage API
mpStack = load_scanimage_data(fullFileNameDir); % BTW: mp = multi-plane

% Crop the first few time points out
mpStack = mpStack(:,:,:,numCutFrames:end);

% Add blank flyback lines (number of lines ScanImage skips during what it
% thinks is flyback. We would like 0, but the min is 2)
mpStack = append_flyback_lines(mpStack,2);


%% Detect opto pulses in data
pulseStartFrameNum = detect_opto_pulses(mpStack,optoPulseDuration,expectedPulseRate,lineFrequency,detrendTime);


%% Average pulse responses
numPulses = numel(pulseStartFrameNum);
avgMpStack = zeros(size(mpStack,1),size(mpStack,2),size(mpStack,3),beforePulseFrames+afterPulseFrame+1);
for pulseIdx = 1:numPulses
    startFrame = pulseStartFrameNum(pulseIdx) - beforePulseFrames;
    endFrame = pulseStartFrameNum(pulseIdx) + afterPulseFrame;
    avgMpStack = avgMpStack + double(mpStack(:,:,:,startFrame:endFrame));
end


%% Save the average response data
avgMpStack = single(avgMpStack);

% Make file for each plane
for planeIdx = 1:size(mpStack,3)

    saveDirAndName = [fullFileNameDir(1:(end-4)) '_opto_avg_plane' num2str(planeIdx) '.tif'];
    fTIF = Fast_Tiff_Write(saveDirAndName,1,0);
    for fIdx = 1:size(avgMpStack,4)
        fTIF.WriteIMG(avgMpStack(:,:,planeIdx,fIdx)');
    end
    fTIF.close;
    
end





