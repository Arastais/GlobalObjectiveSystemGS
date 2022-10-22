#!python

import os
import re

# ----------------------------------
# Definitions:
# ----------------------------------

# Game Script name
gs_name = "Global Objective System GS"
gs_pack_name = gs_name.replace(" ", "-")

# ----------------------------------


# Script:
version = -1
for line in open("version.nut"):

	r = re.search('SELF_VERSION\s+<-\s+([0-9]+)', line)
	if(r != None):
		version = r.group(1)

if(version == -1):
	print("Couldn't find " + gs_name + " version in info.nut!")
	exit(-1)

dir_name = gs_pack_name + "-v" + version
tar_name = dir_name + ".tar"
os.system("mkdir " + dir_name);
os.system("robocopy . " + dir_name + " *.* /s /xf make_tar.py /xd " + dir_name);
os.system("tar -cf " + tar_name + " " + dir_name);
os.system("rmdir /s " + dir_name);
