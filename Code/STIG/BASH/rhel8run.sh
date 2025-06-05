#!/bin/bash
# Source the file containing the functions
source /path/to/hardening_functions.sh
# or equivalently:
#. /path/to/hardening_functions.sh

# disk encryption, no solution
# v230224 
v230233
# SELINUX breaks a lot of things, needs system by system change
# v230240 
# docker will cause trouble with temporary files, better stop docker when doing this
v230243 
v230244
# fix does work, the evlation function needs improvements to detect the changes
v230251_230252 
v230253
v230254
v230274
# this ensures 230296 doesn't lock user out by creating an admin account
setup_admin_account
# this should not be fixed, otherwise you will lose root login
# v230296 
# this should not be fixed, otherwise ansible will fail
# v230302
v230311
# docker will cause trouble with temporary files, better stop docker when doing this
v230318 
# docker will cause trouble with temporary files, better stop docker when doing this
v230326_230327 
v230337
v230345
v230346
v230479 
v230481_230482
v230494
v230495
v230496
v230497
v230498
v230499
# this should be fixed case by case
# v230502 
v230503
# this should be tested further, do not run!
# v230504 
# this should not be fixed, otherwise ansible will fail
# v230511_230512_230513
# needs more evlation and testing, do not run!
# v230524 
v230546
v230555
v230561
# this works, stig not detecting changes
v244530 
v244531
v244532

v244548
# this is fine, stig not detecting changes
v250317 
# turn this AIDE off after running once
# v251710
v257258

# Restart services and apply sysctl changes
systemctl restart sshd
sysctl --system
