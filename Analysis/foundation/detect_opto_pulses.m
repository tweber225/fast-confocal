function pulseStartFrameNum = detect_opto_pulses(mpStack,pulseDur,pulseRate,lineFreq,detrendTime)

numYPix = size(mpStack,1);

% Sum in: X (fast scan) axis dimension, Z planes dimension)
collapsedStack = sum(mpStack,[2,3]);

% Calculate average frame trace along the Y axis
meanFrameTrace = mean(collapsedStack,4);

% Divide out the whole collapsed stack by the average trace
collapsedStackNorm = collapsedStack./meanFrameTrace;

% Smooth the divided trace and detrend it
smoothingNumLines = ceil(pulseDur*lineFreq);
detrendingNumLines = ceil(detrendTime*lineFreq);
collapsedStackSmooth = smooth(collapsedStackNorm,smoothingNumLines)./smooth(collapsedStackNorm,detrendingNumLines);

% Threshold & find start points
threshLevel = 5*std(collapsedStackSmooth) + 1;
pulseStarts = diff(collapsedStackSmooth>threshLevel);
pulseStarts(pulseStarts<0) = 0;
pulseStarts = find(pulseStarts);

% Prune out any detected starts that are too close
corectPulseLocations = diff(pulseStarts) > (1/2)*lineFreq/pulseRate;
pulseStarts = pulseStarts(corectPulseLocations);

% Compute pulse frame #'s (BTW this could be more precise if we broke it
% down into line by line timing)
pulseStartFrameNum = floor(pulseStarts/numYPix);

% Report number of pulses detected
disp(['Detected ' num2str(numel(pulseStartFrameNum)) ' stimulation pulses.'])