#!/bin/bash

# Print the header
echo "Directory Name : Number of Files"
echo "---------------------------------"

# Loop through each directory (including the current directory and all subdirectories)
for dir in . */ ; do
    # Check if it's a directory
    if [ -d "$dir" ]; then
        # Count the number of files in the directory (non-recursive)
        file_count=$(find "$dir" -maxdepth 1 -type f | wc -l)
        # Print the directory name (stripped of the trailing '/') and the file count
        echo "${dir%/} : $file_count"
    fi
done
