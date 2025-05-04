#!/bin/bash

# Get the root folder from the user
read -p "Enter the root folder path: " ROOT_FOLDER

# Prompt the user to enter the number of top folders to display
read -p "Enter the number of top folders to display: " NUM_FOLDERS

# Display the top folders
default_num_folders=20
NUM_FOLDERS=${NUM_FOLDERS:-$default_num_folders}

echo "Top $NUM_FOLDERS folders in $ROOT_FOLDER:"
du -ah $ROOT_FOLDER | sort -hr | head -n $NUM_FOLDERS


