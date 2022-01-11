# replace line sarting with
awk '{sub(/^Start.*/,"New Start"); replaced=1; print}' file.txt

sed -i "s/START=.*/START=new/g" tmp.txt

sed -i "s/%wheel ALL=(ALL) ALL/# %wheel ALL=(ALL) ALL/g" tmp.txt

# swap gsub for sub if not global
awk '/^TEST=/{gsub(".*","TEST=MY LINE",$0)}1' filename

#!/usr/bin/python
import re
k=re.compile(r'^TEST=')
y=open('p.txt','r')

def modLine(i)
    if re.search(k,i):
        o=re.sub("k.*","kMY LINE",i)
        print o.strip()
    else:
        print i.strip()

list(map(lambda i: modLine(i), y))
