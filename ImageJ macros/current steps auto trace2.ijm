 // parameters
frameRate = 457.84;
stepTimes = 0.2;
channels = 3;

// Deinterleave the stack
run("Duplicate...", "title=processingStack duplicate")
run("Deinterleave", "how="+channels);
close("processingStack");

 // Get stack dimensions
selectWindow("processingStack #1");
getDimensions(width, height, channels, slices, frames)

// Duplicate from 1st (non resting) step onward
startFrame = round(frameRate*stepTimes)+1;
selectWindow("processingStack #1");
run("Duplicate...", "title=fromFirstStepCh1 duplicate range="+startFrame+"-"+slices);
close("processingStack #1");
selectWindow("processingStack #2");
run("Duplicate...", "title=fromFirstStepCh2 duplicate range="+startFrame+"-"+slices);
close("processingStack #2");
selectWindow("processingStack #3");
run("Duplicate...", "title=fromFirstStepCh3 duplicate range="+startFrame+"-"+slices);
close("processingStack #3");


// Bleach correction
selectWindow("fromFirstStepCh1");
run("Bleach Correction", "correction=[Exponential Fit]");
rename("bleachCorrectedCh1");
close("y = a*exp(-bx) + c");
close("fromFirstStepCh1");
selectWindow("fromFirstStepCh2");
run("Bleach Correction", "correction=[Exponential Fit]");
rename("bleachCorrectedCh2");
close("y = a*exp(-bx) + c");
close("fromFirstStepCh2");
selectWindow("fromFirstStepCh3");
run("Bleach Correction", "correction=[Exponential Fit]");
rename("bleachCorrectedCh3");
close("y = a*exp(-bx) + c");
close("fromFirstStepCh3");


// Average step periods and compute SD
zScaling = 1/(stepTimes*frameRate);
selectWindow("bleachCorrectedCh1");
run("Scale...", "x=1.0 y=1.0 z="+zScaling+" interpolation=Bilinear average process create");
run("Z Project...", "projection=[Standard Deviation]");
selectWindow("bleachCorrectedCh2");
run("Scale...", "x=1.0 y=1.0 z="+zScaling+" interpolation=Bilinear average process create");
run("Z Project...", "projection=[Standard Deviation]");
selectWindow("bleachCorrectedCh3");
run("Scale...", "x=1.0 y=1.0 z="+zScaling+" interpolation=Bilinear average process create");
run("Z Project...", "projection=[Standard Deviation]");



// Threshold
//run("Median...", "radius=1");
//setAutoThreshold("MaxEntropy dark");
//run("Convert to Mask");





