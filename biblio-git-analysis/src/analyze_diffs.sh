#!/bin/bash

# Check if the old branch is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <old-branch>"
    exit 1
fi

# Define the branches
BRANCH_OLD="$1"
BRANCH_NEW=$(git rev-parse --abbrev-ref HEAD)

# Directory containing diff files
DIFF_DIR="diff"
PERMISSION_CHANGED_DIR="$DIFF_DIR/permission_changed"
UNCHANGED_DIR="$DIFF_DIR/unchanged"
NEW_DIR="$DIFF_DIR/new"
SUPERFICIAL_DIR="$DIFF_DIR/superficial"

# Create the necessary directories if they don't exist
mkdir -p "$UNCHANGED_DIR" "$NEW_DIR" "$PERMISSION_CHANGED_DIR" "$SUPERFICIAL_DIR"

# Function to check if a file is new (exists in the new branch but not in the old)
is_new_file() {
    local file_path="$1"
    local branch_old="$2"
    local branch_new="$3"
    
    # Check if the file exists in the old branch
    if ! git show "$branch_old:$file_path" &>/dev/null && git show "$branch_new:$file_path" &>/dev/null; then
        return 0  # New file
    else
        return 1  # Not a new file
    fi
}

# Function to check if a diff contains only superficial changes
contains_only_superficial_changes() {
    local file_path="$1"

    # Generate the regular diff
    local diff_regular=$(git diff "$BRANCH_OLD" "$BRANCH_NEW" -- "$file_path")
    # Generate the diff ignoring whitespace changes
    local diff_ignoring_whitespace=$(git diff -w "$BRANCH_OLD" "$BRANCH_NEW" -- "$file_path")
    
    # Detect changes other than whitespace or formatting
    if [ -n "$diff_regular" ] && [ "$diff_regular" != "$diff_ignoring_whitespace" ]; then
        return 1  # Contains significant changes
    elif [ -n "$diff_regular" ] && [ "$diff_regular" == "$diff_ignoring_whitespace" ]; then
        # At this point, we know that only whitespace or formatting changes occurred.
        # However, we should still ensure that no significant code modifications were made.

        # Additional check for content differences using a minimal diff ignoring line breaks
        local diff_no_whitespace=$(git diff --ignore-blank-lines --ignore-space-at-eol --ignore-space-change "$BRANCH_OLD" "$BRANCH_NEW" -- "$file_path")

        # If there are no significant changes when ignoring line breaks and space changes
        if [ -z "$diff_no_whitespace" ]; then
            return 0  # Only superficial changes
        else
            return 1  # Contains significant changes
        fi
    else
        return 0  # No changes or only superficial changes
    fi
}

# Function to check if a diff file contains only permission changes
contains_only_permission_changes() {
    local diff_file="$1"
    
    # Check if the diff file contains only permission changes
    if grep -qE '^(diff|old mode|new mode)' "$diff_file" && ! grep -qE '^\+\+\+|---|@@' "$diff_file"; then
        return 0  # Only permission changes
    else
        return 1  # Contains other changes
    fi
}

# Function to check if a diff file represents an unchanged file
is_unchanged_diff() {
    local diff_file="$1"
    
    # Check if the diff file is empty or contains only the diff header (no changes)
    if [ ! -s "$diff_file" ] || ! grep -qE '^\+\+\+|---|@@' "$diff_file"; then
        return 0  # Unchanged
    else
        return 1  # Changed
    fi
}

# Iterate over all diff files in the diff directory and its subdirectories
find "$DIFF_DIR" -type f -name "*.diff" | while IFS= read -r diff_file; do
    # Extract the file path from the diff file name (remove the diff directory prefix and .diff suffix)
    relative_file_path=$(basename "$diff_file" .diff | sed 's/_/\//g')

    # Check if the file is new
    if is_new_file "$relative_file_path" "$BRANCH_OLD" "$BRANCH_NEW"; then
        # Move new diff files to the new directory
        mv "$diff_file" "$NEW_DIR/"
        echo "Moved new file diff: $diff_file"
    elif contains_only_permission_changes "$diff_file"; then
        # Move permission-only diff files to the permission_changed directory
        mv "$diff_file" "$PERMISSION_CHANGED_DIR/"
        echo "Moved permission-only diff file: $diff_file"
    elif contains_only_superficial_changes "$relative_file_path"; then
        # Move superficial diff files to the superficial directory
        mv "$diff_file" "$SUPERFICIAL_DIR/"
        echo "Moved superficial diff file: $diff_file"
    elif is_unchanged_diff "$diff_file"; then
        # Move unchanged diff files to the unchanged directory
        mv "$diff_file" "$UNCHANGED_DIR/"
        echo "Moved unchanged diff file: $diff_file"
    fi
done

echo "All diff files categorized."
