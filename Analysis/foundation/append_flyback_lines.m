function mpStack = append_flyback_lines(mpStack,numFlybackLines)


numXPix = size(mpStack,2);
numChannels = size(mpStack,3);
numTimes = size(mpStack,4);

% Generate some data (a bunch of 1's) to fill into the flyback lines
fillerChunk = ones(numFlybackLines,numXPix,numChannels,numTimes);

% Append the lines
mpStack = [mpStack;fillerChunk];

