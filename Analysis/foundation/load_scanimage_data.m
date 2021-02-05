function mpStack = load_scanimage_data(fullFileNameDir)

% Import the ScanImage Tiff Reader API
import ScanImageTiffReader.ScanImageTiffReader;

% Create the "reader" object
reader = ScanImageTiffReader(fullFileNameDir);

% Get the number of channels
numChannels = get_num_tiff_channels(reader.metadata);

% Deinterleave the frame stack (mpStack means Multi-Plane stack)
% Permute b/c SI's 1st dim is X/horizontal, but MATLAB's 1st dim is Y/vertical
interleavedStack = permute(reader.data,[2 1 3]); 

% Reshape into a hyperstack of dimensions (N_y,N_x,N_channels,N_timepoints)
[numYPix,numXPix,totFrames] = size(interleavedStack);
numTimes = totFrames/numChannels;
mpStack = reshape(interleavedStack,[numYPix,numXPix,numChannels,numTimes]);