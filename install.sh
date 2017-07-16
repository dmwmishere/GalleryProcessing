#!/bin/bash

source folder_settings.ini

echo Creating folders...

for folder in ${folders[@]} ; do
    if [ -d $install_path/$folder ]; then
        echo $folder already exists. Skipping...
    else
        echo $folder not exists. Creating...
        mkdir $install_path/$folder
    fi
    
done
