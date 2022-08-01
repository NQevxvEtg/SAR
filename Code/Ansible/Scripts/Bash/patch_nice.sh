#!/bin/bash

dir=/home/path

echo -ne "\nRed Hat\n" && cat $dir/patch-plan.txt | awk '/Resolving Dependencies/,/Dependencies Resolved/' | grep Package | awk '!a[$0]++' | awk 'gsub("---> Package","")' && echo -ne "\nUbuntu\n" && cat patch-plan.txt | awk '/The following packages will be upgraded:/,/Need to get/' | awk '!/upgraded|standard|Need/' | awk '!a[$0]++' | awk 'gsub("  ","")' && echo -ne "\n"
