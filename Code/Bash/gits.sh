#!/bin/bash

path="/path"

for i in $(ls -d $path/*/);
do
  case $i in
     
  *)
      pushd $i
      rm .git/index
      rm .git/ORIG_HEAD
      if git fetch origin master ; then
      	git reset --hard origin/master
      else 
      	git fetch origin main
      	git reset --hard origin/main
      fi
      	
      popd
      ;;
  esac
done
