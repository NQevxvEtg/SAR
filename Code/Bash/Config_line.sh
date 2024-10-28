
To check if a line with `port 443` is immediately above the first occurrence of `servername`, and then make the desired change if this condition is true, you can use the following script:# Check if a line with `port 443` exists directly above the first occurrence of `servername`
if grep -B 1 '^servername' /path/to/config.file | grep -q '^port 443$'; then
    # If the condition is met, modify the first occurrence of `servername`
    sed -i '0,/^servername/{s/old_value/new_value/}' /path/to/config.file
else
    echo "The line with 'port 443' is not directly above 'servername'. Please check the configuration file."
fi

Explanation:

1. grep -B 1 '^servername' /path/to/config.file finds the first occurrence of servername and includes the line immediately above it (-B 1).


2. grep -q '^port 443$' checks if this preceding line is port 443.


3. If the condition is met, sed modifies only the first match of servername using 0,/^servername/.



Replace old_value and new_value with the text you want to replace and the new text, respectively. This approach ensures that the edit only happens when the port 443 line is directly above the target servername line. </output>

