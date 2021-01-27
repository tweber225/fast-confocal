// Set number of channels
channels = 3;

// Deinterleave the stack
run("Duplicate...", "title=processingStack duplicate")
run("Deinterleave", "how="+channels);
close("processingStack");
