%% Setup
% Add the support code
addpath foundation/

% Input the filename and its directory
fileName = 'slice2_field2_00002.tif';
maskFileNames = {[]; ...
    []; ...
    [fileName(1:end-4) '_mask_plane3.tif']; ...
    []};
fileDir = 'G:\temp\2.4';
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


%% Load and concatenate multiplane ROI
mpMask = zeros(size(mpStack,1),size(mpStack,2),size(mpStack,3));
for planeIdx = 1:size(mpStack,3)
    if isempty(maskFileNames{planeIdx})
        continue
    end
    currentMask = double(imread([fileDir filesep maskFileNames{planeIdx}])); % Normalize mask
    mpMask(:,:,planeIdx) = currentMask./max(currentMask,[],'all');
end


%% Compute trace of ROI in each trial
numPulses = numel(pulseStartFrameNum);
trialROITraces = zeros(beforePulseFrames+afterPulseFrame+1,numPulses); % 
for pulseIdx = 1:numPulses
    % Compute the start and end frames
    startFrame = pulseStartFrameNum(pulseIdx) - beforePulseFrames;
    endFrame = pulseStartFrameNum(pulseIdx) + afterPulseFrame;
    
    % Apply mask, and sum all pixels across all planes
    maskedResponse = double(mpStack(:,:,:,startFrame:endFrame)).*mpMask;
    maskedTrial = permute(sum(maskedResponse,[1 2 3]),[4 3 2 1]);
    
    trialROITraces(:,pulseIdx) = maskedTrial;
end


%% Show a 2D representation of each trial's dF/F0
dt = 1000*size(mpStack,1)/lineFrequency;
t = (-beforePulseFrames*dt):dt:(afterPulseFrame*dt);
trials = 1:numPulses;

dF = trialROITraces - mean(trialROITraces(1:beforePulseFrames,:));
dFoverF0 = dF./mean(trialROITraces(1:beforePulseFrames,:));

figure;
imagesc(t-dt,trials,dFoverF0');
cb = colorbar;
set(get(cb,'label'),'string','dF/F_0');
xlabel('Time post-stimulus (ms)')
ylabel('Trial #')
set(gcf,'position',[100,100,400,300])




