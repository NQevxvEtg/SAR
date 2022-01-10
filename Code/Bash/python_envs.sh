#!/usr/bin/env bash

wget https://bootstrap.pypa.io/get-pip.py

path="/path/env"

a=(2.7 3.6 3.7 3.8 3.9)

for i in "${a[@]}"
do
  sudo /usr/local/bin/python$i get-pip.py
  sudo /usr/local/bin/pip$i install -U pip
  sudo /usr/local/bin/pip$i install -U virtualenv
  mkdir -p $path/py$i/venv
  pushd $path/py$i/
  /usr/local/bin/python$i -m virtualenv ./venv
  popd
done
