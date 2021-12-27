#!/bin/bash

echo "DANGER, YOU ARE DELETING IMPORTANT FILES, ARE YOU SURE?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) echo -e "\nOk\n"; break;;
        No ) exit;;
    esac
done

rm -fr
