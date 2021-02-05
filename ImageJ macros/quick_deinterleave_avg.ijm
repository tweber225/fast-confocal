rename("to_process");
run("Deinterleave", "how=4");
selectWindow("to_process #1");
run("Z Project...", "projection=[Average Intensity]");
selectWindow("to_process #1");
close();
selectWindow("to_process #2");
run("Z Project...", "projection=[Average Intensity]");
selectWindow("to_process #2");
close();
selectWindow("to_process #3");
run("Z Project...", "projection=[Average Intensity]");
selectWindow("to_process #3");
close();
selectWindow("to_process #4");
run("Z Project...", "projection=[Average Intensity]");
selectWindow("to_process #4");
close();

run("Images to Stack", "name=[z planes avg] title=[] use");

