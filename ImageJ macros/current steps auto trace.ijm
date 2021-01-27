// parameters
frameRate = 457.84;
stepTimes = 0.2;
skippedFrames = 30;
numSlices = nSlices;

// Duplicate stack but skip a few frames at beginning
run("Duplicate...", "title=startedStack duplicate range="+(skippedFrames+1)+"-"+numSlices);

// Run bleach correction
run("Bleach Correction", "correction=[Exponential Fit]");
rename("bleachCorrected");
close("y = a*exp(-bx) + c");
close("startedStack")

// Duplicate bleach corrected stack skipping rest of frames in first resting period
startFrame = round(frameRate*stepTimes)+1-skippedFrames;
numSlices = nSlices;
run("Duplicate...", "title=fromFirstStep duplicate range="+startFrame+"-"+numSlices);

// Average each step period
zScaling = 1/(stepTimes*frameRate);
run("Scale...", "x=1.0 y=1.0 z="+zScaling+" interpolation=Bilinear average process create");
rename("averagedPeriods");
close("fromFirstStep");

// Compute Standard Deviation of signal during step periods
run("Slice Remover", "first=2 last=4 increment=2");
run("Z Project...", "projection=[Standard Deviation]");
rename("stepVariation")
close("averagedPeriods");

// Threshold and select points
run("Median...", "radius=1");
setAutoThreshold("MaxEntropy dark");
run("Convert to Mask");
run("Erode");
run("Dilate");
run("Points from Mask");