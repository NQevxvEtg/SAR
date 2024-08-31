ps aux --sort=-%cpu | awk \
'NR==1 {printf \
"%-10s %-6s %-6s %-6s %-11s %-8s %-8s %-8s %-8s %-8s %-20s\n", \
"USER", "PID", "%CPU", "%MEM", "VSZ", "RSS", "TTY", "STAT", "START", "TIME", "COMMAND"} \
NR>1 {printf \
"%-10s %-6s %-6s %-6s %-11s %-8s %-8s %-8s %-8s %-8s %-20s\n", \
$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, substr($11, 1, 20)}' | \
head -n 11

ps aux --sort=-%mem | awk \
'NR==1 {printf \
"%-10s %-6s %-6s %-6s %-11s %-8s %-8s %-8s %-8s %-8s %-20s\n", \
"USER", "PID", "%CPU", "%MEM", "VSZ", "RSS", "TTY", "STAT", "START", "TIME", "COMMAND"} \
NR>1 {printf \
"%-10s %-6s %-6s %-6s %-11s %-8s %-8s %-8s %-8s %-8s %-20s\n", \
$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, substr($11, 1, 20)}' | \
head -n 11

ps -ef --sort=-pid | awk \
'NR==1 {printf \
"%-10s %-6s %-6s %-6s %-8s %-8s %-8s %-20s\n", \
"UID", "PID", "PPID", "C", "STIME", "TTY", "TIME", "CMD"} \
NR>1 {printf \
"%-10s %-6s %-6s %-6s %-8s %-8s %-8s %-20s\n", \
$1, $2, $3, $4, $5, $6, $7, substr($8, 1, 20)}' | \
head -n 11
