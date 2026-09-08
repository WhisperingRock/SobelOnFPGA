#!/bin/bash

# ~~~~ Python Env ~~~~

# diff between images
printf "|---- Diff between I/O images ...."
python3 img_diff.py testimg1.bmp blurred_testimg1.bmp diff_testimg1.png
printf ".... done!"

 
