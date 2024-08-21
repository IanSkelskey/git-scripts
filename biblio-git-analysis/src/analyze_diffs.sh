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
LOGGER_PATCH_DIR="$DIFF_DIR/logger_patch"
XUL_DIR="$DIFF_DIR/xul"

# Create the necessary directories if they don't exist
mkdir -p "$UNCHANGED_DIR" "$NEW_DIR" "$PERMISSION_CHANGED_DIR" "$LOGGER_PATCH_DIR" "$XUL_DIR"

# Function to check if a file is new (exists in the new branch but not in the old)
is_new_file() {
    local file_path="$1"

    # Check if the file exists in the old branch
    if ! git ls-tree -r "$BRANCH_OLD" --name-only | grep -qx "$file_path" && git ls-tree -r "$BRANCH_NEW" --name-only | grep -qx "$file_path"; then
        return 0  # New file
    else
        return 1  # Not a new file
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

# Function to detect logger changes using anonymous subroutines
detect_logger_patch_changes() {
    local diff_file="$1"
    
    # Check if the diff file contains logger changes with anonymous subroutines
    if grep -qE '\$logger->\w+\(sub\{' "$diff_file" || grep -qE '\$log->(debug|info|warn|error|fatal|trace)\(sub\{return' "$diff_file"; then
        return 0  # Contains logger patch changes
    else
        return 1  # Does not contain logger patch changes
    fi
}

# Function to check if the file path contains "xul" and move to xul directory
detect_xul_files() {
    local diff_file="$1"
    local file_path="$2"

    if [[ "$file_path" == *xul* ]]; then
        mv "$diff_file" "$XUL_DIR/"
        echo "Moved XUL-related diff file: $diff_file"
        return 0
    else
        return 1
    fi
}

# Iterate over all diff files in the diff directory and its subdirectories
find "$DIFF_DIR" -type f -name "*.diff" | while IFS= read -r diff_file; do
    # Extract the file path from the diff file name (remove the diff directory prefix and .diff suffix)
    relative_file_path=$(basename "$diff_file" .diff | sed 's/_/\//g')

    # Check for XUL files first
    if detect_xul_files "$diff_file" "$relative_file_path"; then
        continue
    fi

    # Check if the file is new
    if is_new_file "$relative_file_path"; then
        # Move new diff files to the new directory
        mv "$diff_file" "$NEW_DIR/"
        echo "Moved new file diff: $diff_file"
    elif contains_only_permission_changes "$diff_file"; then
        # Move permission-only diff files to the permission_changed directory
        mv "$diff_file" "$PERMISSION_CHANGED_DIR/"
        echo "Moved permission-only diff file: $diff_file"
    elif detect_logger_patch_changes "$diff_file"; then
        # Move logger patch diff files to the logger_patch directory
        mv "$diff_file" "$LOGGER_PATCH_DIR/"
        echo "Moved logger patch diff file: $diff_file"
    elif is_unchanged_diff "$diff_file"; then
        # Move unchanged diff files to the unchanged directory
        mv "$diff_file" "$UNCHANGED_DIR/"
        echo "Moved unchanged diff file: $diff_file"
    fi
done

echo "All diff files categorized."
