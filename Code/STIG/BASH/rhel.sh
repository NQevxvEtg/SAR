# Red Hat Enterprise Linux 7 Security Technical Implementation Guide :: Version 3, Release: 8 Benchmark Date: 27 Jul 2022

# Vul ID: V-204392
# for i in `rpm -Va | egrep '^.{1}M|^.{5}U|^.{6}G' | cut -d " " -f 4,5`;do for j in `rpm -qf $i`;do rpm -ql $j --dump | cut -d " " -f 1,5,6,7 | grep $i;done;done
# send output to output.txt first
while read p; do
FILENAME=$(awk '{ print $1 }')
RPMNAME=$(rpm -qf $FILENAME)
rpm --setugids $RPMNAME
done < output.txt
