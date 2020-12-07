function unmirror_blind(fileDirAndName)

% Import the ScanImage TIFF reader, read file, report # channels
import ScanImageTiffReader.ScanImageTiffReader;
reader = ScanImageTiffReader(fileDirAndName);
numChannels = get_num_tiff_channels(reader.metadata);

% Deinterleave the frame stack (mpStack means multi-plane stack)
interleavedStack = permute(reader.data,[2 1 3]);
[numYPix,numXPix,totFrames] = size(interleavedStack);
numTimes = totFrames/numChannels;
mpStack = reshape(interleavedStack,[numYPix,numXPix,numChannels,totFrames/numChannels]); 
clear interleavedStack

% Add flyback lines (number of lines ScanImage skips during flyback)
numFlybackLines = 2;
mpStack = cat(1,mpStack,zeros(numFlybackLines,numXPix,numChannels,numTimes));
numYPix = numYPix + numFlybackLines;


%% "blind" part

% Average over time (dim 4) to get high-SNR images for cross-correlation later
avgImg = mean(single(mpStack),4);

% Rough crop to different scan subimages
downFrameEst = avgImg(1:(round((numYPix)/2)),:,:);
upFrameEst = flipud(avgImg((round((numYPix)/2)+1):end,:,:));

% Cross correlate in Y
FTdownFrame = fft(downFrameEst,[],1);
FTupFrame = fft(upFrameEst,[],1);
XPowSpec = FTdownFrame.*conj(FTupFrame);
XPowSpecNorm = XPowSpec./abs(XPowSpec);
XC = ifft(XPowSpecNorm,[],1);

% Average result of cross correlation across columns (dim 2) and channels
% (dim 3). Then find max. The ammount to shift is half this.
avgXC = mean(XC,[2 3]);
[~,maxIdx] = max(avgXC);
shiftAmount = round(maxIdx/2);


%% Shifting frames and unmirroring "up" frames

% Permute and reshape, which rearranges image lines such that all lines of
% the entire time series are in one giant frame
mpStackAllLines = permute(mpStack,[2 1 4 3]);
mpStackAllLines = reshape(mpStackAllLines,[numXPix,numYPix*numTimes,numChannels]);

mpStackAllLines = circshift(mpStackAllLines,[0 -shiftAmount 0]);

% Reshape so that dim 3 codes the down (=1) or up(=2) frame
mpStackUpDown = reshape(mpStackAllLines,[numXPix,numYPix/2,2,numTimes,numChannels]);
clear mpStackAllLines

% Flip (now left-right) the up frames
mpStackUpDown(:,:,2,:,:) = fliplr(mpStackUpDown(:,:,2,:,:));

% Now reshape to put the flipped sub image into time dimension
mpStackUnmirrored = reshape(mpStackUpDown,[numXPix,numYPix/2,numTimes*2,numChannels]);
clear mpStackUpDown
mpStackUnmirrored = permute(mpStackUnmirrored,[2 1 3 4]);


%% Save
mpStackUnmirrored = single(mpStackUnmirrored);

% Save each channel individually
for chanIdx = 1:numChannels
    % Formulate name
    saveDirAndName = [fileDirAndName(1:(end-4)) '_demir_chan' num2str(chanIdx) '.tif'];

    % Save just the stack corresponding to each channel
    %saveastiff(,saveDirAndName);
    
    fTIF = Fast_Tiff_Write(saveDirAndName,1,0);
    for fIdx = 1:(numTimes*2)
        fTIF.WriteIMG(mpStackUnmirrored(:,:,fIdx,chanIdx));
    end
    fTIF.close;
end

