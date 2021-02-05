function numChannels = get_num_tiff_channels(tiffMetadata)

% Search for the following string in the metadata
searchStr = 'SI.hChannels.channelSave';

% Get the position where found string start
% (start after identified string + couple characters for the equals sign)
startPos = findstr(tiffMetadata,searchStr) + numel(searchStr) + 2;

% grab enough characters so there's no risk of missing anything, but this
% ends up grabbing some of the following line. So split the two lines and
% later use only the first line
twoLines = splitlines(tiffMetadata(startPos:(startPos+20)));

% The active channels are
activeChannels = str2num(strtok(twoLines{1}));

% The total number of channels is..
numChannels = numel(activeChannels);