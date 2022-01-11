# replace line sarting with
awk '{sub(/^Start.*/,"New Start"); replaced=1; print}' file.txt

sed -i "s/START=.*/START=new/g" tmp.txt

sed -i "s/%wheel ALL=(ALL) ALL/# %wheel ALL=(ALL) ALL/g" tmp.txt
