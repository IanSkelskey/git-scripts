#!/bin/bash

# Source the configuration file
source "$(dirname "$0")/config.sh"

# Source the utility functions
source "$(dirname "$0")/util.sh"

# Check if the old branch is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <old-branch>"
    exit 1
fi

# Define the branches
BRANCH_OLD="$1"
BRANCH_NEW=$(git rev-parse --abbrev-ref HEAD)

# Create the diff and files directories if they don't exist
mkdir -p "$ATOMIC_DIFF_DIR" "$TINY_DIFF_DIR" "$SMALL_DIFF_DIR" "$MEDIUM_DIFF_DIR" "$LARGE_DIFF_DIR" "$FILES_DIR"

# Initialize the markdown files
for file in "$NEW_FILES_MD" "$UNCHANGED_FILES_MD" "$PERMISSION_CHANGED_MD" "$LOGGER_SUBS_MD" "$SUPERFICIAL_MD" "$DELETED_FILES_MD"; do
    echo "# ${file%.*} Files in $BRANCH_NEW Branch" > "$file"
    echo "" >> "$file"
done

# Get a list of all files in the repository that have changed, are new, or are deleted
FILES=$(git diff --name-status "$BRANCH_OLD" "$BRANCH_NEW")

# Function to handle new files
process_new_file() {
    local file="$1"
    echo "- $file" >> "$NEW_FILES_MD"
    echo "Added $file to $NEW_FILES_MD"
    
    local dest_dir="$FILES_DIR/$(dirname "$file")"
    copy_file_to "$file" "$dest_dir"
}

# Create the diffs and copy the files
process_file() {
    local file_status="$1"
    local file="$2"
    local diff

    # Skip binary files
    if is_binary_file "$file"; then
        echo "Skipping binary file $file"
        return
    fi

    # Handle deleted files
    if is_file_deleted "$file_status"; then
        echo "- $file" >> "$DELETED_FILES_MD"
        echo "Added $file to $DELETED_FILES_MD"
        return
    fi

    # Check if file exists on old branch
    if ! file_exists_on_branch "$file" "$BRANCH_OLD"; then
        process_new_file "$file"
        return
    fi

    # Get the diff and check for specific changes
    diff=$(git diff "$BRANCH_OLD" "$BRANCH_NEW" -- "$file")

    # Handle permission changes
    if is_permission_change_only "$diff"; then
        echo "- $file: Permission change detected." >> "$PERMISSION_CHANGED_MD"
        return
    fi

    # Handle logger subroutine changes
    if is_logger_sub_only "$diff"; then
        echo "- $file" >> "$LOGGER_SUBS_MD"
        echo "Logger subroutine change detected in $file, skipping diff and copy."
        return
    fi

    # Handle superficial changes
    if contains_only_superficial_changes "$diff"; then
        echo "- $file" >> "$SUPERFICIAL_MD"
        echo "Superficial change detected in $file, skipping diff and copy."
        return
    fi

    # Save the diff and copy the file
    local line_count
    line_count=$(echo "$diff" | grep -E "^\+" | wc -l)
    save_diff_and_copy_file "$file" "$diff" "$line_count"
}

# Loop through all files and process them
while IFS= read -r line; do
    process_file "$(echo "$line" | awk '{print $1}')" "$(echo "$line" | awk '{print $2}')"
done <<< "$FILES"

echo "Diffs generated for changed files in the '$DIFF_DIR' directory."
echo "List of new files saved to '$NEW_FILES_MD'."
echo "List of unchanged files saved to '$UNCHANGED_FILES_MD'."
echo "Copies of changed and new files are saved in the '$FILES_DIR' directory."
echo "List of files with permission changes saved to '$PERMISSION_CHANGED_MD'."
echo "List of files with only logger subroutine changes saved to '$LOGGER_SUBS_MD'."
echo "List of files with only superficial changes saved to '$SUPERFICIAL_MD'."
echo "List of deleted files saved to '$DELETED_FILES_MD'."