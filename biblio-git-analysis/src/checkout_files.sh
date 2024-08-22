#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <file-path> <branch-1> <branch-2>"
    exit 1
fi

# Assign arguments to variables
FILE_PATH="$1"
BRANCH_1="$2"
BRANCH_2="$3"

# Extract the filename from the file path
FILE_NAME=$(basename "$FILE_PATH")

# Create a directory to store the checked-out files if it doesn't exist
CHECKOUT_DIR="checkout"
mkdir -p "$CHECKOUT_DIR"

# Checkout the file from the first branch and copy it with branch name appended
git show "$BRANCH_1":"$FILE_PATH" > "$CHECKOUT_DIR/${FILE_NAME}_${BRANCH_1}"
if [ $? -ne 0 ]; then
    echo "Failed to check out $FILE_PATH from branch $BRANCH_1"
    exit 1
fi

# Checkout the file from the second branch and copy it with branch name appended
git show "$BRANCH_2":"$FILE_PATH" > "$CHECKOUT_DIR/${FILE_NAME}_${BRANCH_2}"
if [ $? -ne 0 ]; then
    echo "Failed to check out $FILE_PATH from branch $BRANCH_2"
    exit 1
fi

# Output the location of the copied files
echo "Files have been checked out and copied to $CHECKOUT_DIR"
echo "File from $BRANCH_1: ${FILE_NAME}_${BRANCH_1}"
echo "File from $BRANCH_2: ${FILE_NAME}_${BRANCH_2}"
