# replace line sarting with
awk '{sub(/^Start.*/,"New Start"); replaced=1; print}' file.txt
