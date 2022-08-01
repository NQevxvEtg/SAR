
# install scap zip
/opt/scc/cscc --installScap --force path/U_RHEL_X_STIG_SCAP_1-2_Benchmark.zip

/opt/scc/cscc --config

# start scan
# first start a screen scession
# this will allow you close the terminal and let it run in the background

screen -S scan1

/opt/scc/cscc 

# to detach from the current screen session you can press ‘Ctrl-A’ and ‘Ctrl-D’

# list screens

screen -ls

# reattach 
screen -r scan1

# lock
# press ‘Ctrl-A’ and ‘x’ shortcut

# terminate 
# press ‘Ctrl-D’ or use the ‘exit’ line command
