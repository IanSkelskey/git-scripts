#!/bin/bash

# Define the branches you want to compare
BRANCH_OLD="master"
BRANCH_NEW="evg-3.11.7"

# Define the directory to store the copied files
COPY_DIR="changed_files"

# Create the directory to store the copied files
mkdir -p "$COPY_DIR"

# Generate the list of changed files
echo "Generating list of changed files between $BRANCH_OLD and $BRANCH_NEW..."
changed_files=$(git diff --name-only "$BRANCH_OLD" "$BRANCH_NEW")

# Copy each changed file while maintaining the directory structure
echo "Copying changed files to $COPY_DIR..."
while IFS= read -r file; do
    if [ -n "$file" ]; then
        # Create the directory structure in the target directory
        mkdir -p "$COPY_DIR/$(dirname "$file")"
        # Copy the file to the target directory
        cp "$file" "$COPY_DIR/$file"
        echo "Copied $file"
    fi
done <<< "$changed_files"

echo "All changed files have been copied to $COPY_DIR."
