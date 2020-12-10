function unmirror_blind(fileDirAndName)
% argument fileDirAndName should be the full path to the file needing
% unmirroring.

% Import the ScanImage TIFF reader, read file, get # channels from metadata
import ScanImageTiffReader.ScanImageTiffReader;
reader = ScanImageTiffReader(fileDirAndName);
numChannels = get_num_tiff_channels(reader.metadata);

% Deinterleave the frame stack (mpStack means Multi-Plane stack)
interleavedStack = permute(reader.data,[2 1 3]); % Permute here b/c SI's 1st dim is X/horizontal, but MATLAB's 1st dim is Y/vertical
[numYPix,numXPix,totFrames] = size(interleavedStack);
numTimes = totFrames/numChannels;
mpStack = reshape(interleavedStack,[numYPix,numXPix,numChannels,totFrames/numChannels]);
clear interleavedStack

% Add flyback lines (number of lines ScanImage skips during what it thinks
% is flyback. We would like 0, but the min is 2)
numFlybackLines = 2;
mpStack = cat(1,mpStack,zeros(numFlybackLines,numXPix,numChannels,numTimes));
numYPix = numYPix + numFlybackLines;


%% "Blind" part:
% Cross correlate the top subframe with a flip updown version of the bottom
% subframe

% Average over time (dim 4) to get high-SNR images for cross-correlation later
avgImg = mean(single(mpStack),4); % Make sure to cast into floating point to avoid rounding errors, also FFT uses floats anyway

% Rough crop to different scan subimages
downFrameEst = avgImg(1:(round(numYPix/2)),:,:);
upFrameEst = flipud(avgImg((round(numYPix/2)+1):end,:,:));

% Cross correlate in Y (dim 1)
FTdownFrame = fft(downFrameEst,[],1);
FTupFrame = fft(upFrameEst,[],1);
XPowSpec = FTdownFrame.*conj(FTupFrame);
XPowSpecNorm = XPowSpec./abs(XPowSpec);
XC = ifft(XPowSpecNorm,[],1);

% Average result of cross correlation across columns (dim 2) and channels
% (dim 3). Then find max. The ammount to shift is half this.
avgXC = fftshift(mean(XC,[2 3]));
[~,maxIdx] = max(avgXC);
centerPoint = numYPix/4 + 1; % The position of frequency=0 after fftshift
shiftFromCenter = centerPoint - maxIdx;
shiftAmount = round(shiftFromCenter/2)-0;


%% Shifting frames and unmirroring "up" frames

% Permute and reshape, which rearranges image lines so that all lines of
% the entire time series are lined up (vertically now!) in one enormously
% wide frame
mpStackAllLines = permute(mpStack,[2 1 4 3]);
mpStackAllLines = reshape(mpStackAllLines,[numXPix,numYPix*numTimes,numChannels]);

mpStackAllLines = circshift(mpStackAllLines,[0 shiftAmount 0]);

% Reshape so that dim 3 codes the down (=1) or up(=2) frame
mpStackUpDown = reshape(mpStackAllLines,[numXPix,numYPix/2,2,numTimes,numChannels]);
clear mpStackAllLines

% Flip (now left-right) the up frames
mpStackUpDown(:,:,2,:,:) = fliplr(mpStackUpDown(:,:,2,:,:));

% Now reshape to put the flipped sub image into time dimension, and permute
% back to dim 1 = Y axis convention
mpStackUnmirrored = reshape(mpStackUpDown,[numXPix,numYPix/2,numTimes*2,numChannels]);


%% Save
mpStackUnmirrored = single(mpStackUnmirrored);

% Save each channel individually
for chanIdx = 1:numChannels
    % Formulate name
    saveDirAndName = [fileDirAndName(1:(end-4)) '_demir_chan' num2str(chanIdx) '.tif'];
    
    % Use fast write function
    fTIF = Fast_Tiff_Write(saveDirAndName,1,0);
    for fIdx = 1:(numTimes*2)
        fTIF.WriteIMG(mpStackUnmirrored(:,:,fIdx,chanIdx));
    end
    fTIF.close;
end

% Also save the up and down stacks
saveDirAndName = [fileDirAndName(1:(end-4)) '_demir_down.tif'];
fTIF = Fast_Tiff_Write(saveDirAndName,1,0);
avgImg1 = squeeze(squeeze(mean(mpStackUpDown(:,:,1,:,2),4)));
fTIF.WriteIMG(single(avgImg));
fTIF.close;

saveDirAndName = [fileDirAndName(1:(end-4)) '_demir_up.tif'];
fTIF = Fast_Tiff_Write(saveDirAndName,1,0);
avgImg2 = squeeze(squeeze(mean(mpStackUpDown(:,:,2,:,2),4)));
fTIF.WriteIMG(single(avgImg));
fTIF.close;

imshowpair(avgImg1',avgImg2')




