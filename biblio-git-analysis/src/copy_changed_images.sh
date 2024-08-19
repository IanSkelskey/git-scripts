#!/bin/bash

# Check if both branch arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <branch1> <branch2>"
    echo "Example: $0 master feature-branch"
    exit 1
fi

# Set the branches
BRANCH_OLD=$1
BRANCH_NEW=$2

# Define the directory to store the copied image files
COPY_DIR="changed_images"

# Create the directory to store the copied image files
mkdir -p "$COPY_DIR"

# Generate the list of changed or new image files
echo "Finding changed or new image files between $BRANCH_OLD and $BRANCH_NEW..."
changed_files=$(git diff --name-only "$BRANCH_OLD" "$BRANCH_NEW" | grep -E '\.(jpg|jpeg|png|gif|bmp|tiff|svg|ico)$')

# Copy each changed or new image file while maintaining the directory structure
echo "Copying changed or new image files to $COPY_DIR..."
while IFS= read -r file; do
    if [ -n "$file" ]; then
        # Create the directory structure in the target directory
        mkdir -p "$COPY_DIR/$(dirname "$file")"
        # Copy the image file to the target directory
        git show "$BRANCH_NEW:$file" > "$COPY_DIR/$file"
        echo "Copied $file"
    fi
done <<< "$changed_files"

echo "All changed or new image files have been copied to $COPY_DIR."
