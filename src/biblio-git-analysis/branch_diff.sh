#!/bin/bash

# Source the configuration file
source "$(dirname "$0")/config.sh"

# Check if the old branch is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <old-branch>"
    exit 1
fi

# Define the branches
BRANCH_OLD="$1"
BRANCH_NEW=$(git rev-parse --abbrev-ref HEAD)

# Create the diff and files directories if they don't exist
mkdir -p "$ATOMIC_DIFF_DIR"
mkdir -p "$TINY_DIFF_DIR"
mkdir -p "$SMALL_DIFF_DIR"
mkdir -p "$MEDIUM_DIFF_DIR"
mkdir -p "$LARGE_DIFF_DIR"
mkdir -p "$FILES_DIR"

# Initialize the markdown files
echo "# New Files in $BRANCH_NEW Branch" > "$NEW_FILES_MD"
echo "" >> "$NEW_FILES_MD"

echo "# Unchanged Files in $BRANCH_NEW Branch" > "$UNCHANGED_FILES_MD"
echo "" >> "$UNCHANGED_FILES_MD"

echo "# Files with Permission Changes in $BRANCH_NEW Branch" > "$PERMISSION_CHANGED_MD"
echo "" >> "$PERMISSION_CHANGED_MD"

echo "# Files with Only Logger Subroutine Changes" > "$LOGGER_SUBS_MD"
echo "" >> "$LOGGER_SUBS_MD"

echo "# Files with Only Superficial Changes" > "$SUPERFICIAL_MD"
echo "" >> "$SUPERFICIAL_MD"

echo "# Deleted Files in $BRANCH_NEW Branch" > "$DELETED_FILES_MD"
echo "" >> "$DELETED_FILES_MD"

# Get a list of all files in the repository that have changed, are new, or are deleted
FILES=$(git diff --name-status "$BRANCH_OLD" "$BRANCH_NEW")

# Function to check if the diff contains only logger subroutine changes
is_logger_sub_only() {
    diff_content="$1"
    
    # Extract only the added and removed lines, ignore the context lines
    added_removed_lines=$(echo "$diff_content" | grep '^[+-]' | grep -v '^+++' | grep -v '^---')
    
    # Check if all the changes are related to logger subroutine changes
    while IFS= read -r line; do
        # If the line is not related to a logger subroutine change, return false
        if [[ ! "$line" =~ ^[+-][[:space:]]*logger\.[a-zA-Z_]+\(\ ?sub\{return ]] && \
           [[ ! "$line" =~ ^[+-][[:space:]]*logger\.[a-zA-Z_]+\(\ ?.* ]]; then
            return 1
        fi
    done <<< "$added_removed_lines"
    
    return 0
}

# Function to check if the diff contains only permission changes
is_permission_change_only() {
    diff_content="$1"
    
    # Check if the diff contains only mode changes
    if echo "$diff_content" | grep -q "^old mode [0-9]\{6\}$" && echo "$diff_content" | grep -q "^new mode [0-9]\{6\}$" && ! echo "$diff_content" | grep -qvE "^(diff|old mode|new mode)"; then
        return 0
    else
        return 1
    fi
}

is_binary_file() {
    file="$1"
    
    if [[ $file == *.png || $file == *.jpg || $file == *.gif || $file == *.ico ]]; then
        return 0
    else
        return 1
    fi
}

is_file_deleted() {
    file_status="$1"
    
    if [[ $file_status == "D" ]]; then
        return 0
    else
        return 1
    fi
}

file_exists_on_branch() {
    file="$1"
    branch="$2"
    
    if git show "$branch:$file" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

contains_only_superficial_changes() {
    diff_content="$1"
    
    # Get the diff ignoring whitespace
    diff_content_no_whitespace=$(echo "$diff_content" | grep -v '^@@' | sed 's/^[+-]//')
    
    # Check if the diff contains only whitespace changes
    if [[ -z $(echo "$diff_content_no_whitespace" | grep -v '^[[:space:]]*$') ]]; then
        return 0
    else
        return 1
    fi
}

get_magnitude_directory() {
    line_count="$1"
    
    if [[ $line_count -le $ATOMIC_THRESHOLD ]]; then
        echo "$ATOMIC_DIFF_DIR"
    elif [[ $line_count -le $TINY_THRESHOLD ]]; then
        echo "$TINY_DIFF_DIR"
    elif [[ $line_count -le $SMALL_THRESHOLD ]]; then
        echo "$SMALL_DIFF_DIR"
    elif [[ $line_count -le $MEDIUM_THRESHOLD ]]; then
        echo "$MEDIUM_DIFF_DIR"
    else
        echo "$LARGE_DIFF_DIR"
    fi
}

# Create the diffs and copy the files
while IFS= read -r line; do
    FILE_STATUS=$(echo "$line" | awk '{print $1}')
    FILE=$(echo "$line" | awk '{print $2}')
    
    # Skip binary files (images, etc.)
    if is_binary_file "$FILE"; then
        echo "Skipping binary file $FILE"
        continue
    fi
    
    # Check if the file is deleted
    if is_file_deleted "$FILE_STATUS"; then
        echo "- $FILE" >> "$DELETED_FILES_MD"
        echo "Added $FILE to $DELETED_FILES_MD"
        continue
    fi
    
    # Check if the file exists in the old branch
    if file_exists_on_branch "$FILE" "$BRANCH_OLD"; then
        # Get the diff to check for specific changes
        DIFF=$(git diff "$BRANCH_OLD" "$BRANCH_NEW" -- "$FILE")
        
        # Check if the diff only contains permission changes
        if is_permission_change_only "$DIFF"; then
            echo "- $FILE: Permission change detected." >> "$PERMISSION_CHANGED_MD"
            continue
        fi

        # Check if the diff only contains logger subroutine changes
        if is_logger_sub_only "$DIFF"; then
            echo "- $FILE" >> "$LOGGER_SUBS_MD"
            echo "Logger subroutine change detected in $FILE, skipping diff and copy."
            continue
        fi

        # Get the diff ignoring whitespace to check for superficial changes
        if contains_only_superficial_changes "$DIFF"; then
            echo "- $FILE" >> "$SUPERFICIAL_MD"
            echo "Superficial change detected in $FILE, skipping diff and copy."
            continue
        fi

        # Get the number of lines changed, ignoring whitespace
        LINE_COUNT=$(echo "$SUPERFICIAL_DIFF" | grep -E "^\+" | wc -l)

        # Determine the magnitude of the change
        DIFF_PATH=$(get_magnitude_directory "$LINE_COUNT")/"$FILE//\//_}.diff"
        # Save the diff to the appropriate file
        if [[ -n $SUPERFICIAL_DIFF ]]; then
            echo "$SUPERFICIAL_DIFF" > "$DIFF_PATH"
            echo "Created diff for $FILE in $(dirname "$DIFF_PATH")"
            
            # Copy the new version of the file to the diff/files/ directory
            DEST_DIR="$FILES_DIR/$(dirname "$FILE")"
            mkdir -p "$DEST_DIR"
            git show "$BRANCH_NEW:$FILE" > "$DEST_DIR/$(basename "$FILE")"
            echo "Copied $FILE to $DEST_DIR"
        else
            echo "- $FILE" >> "$UNCHANGED_FILES_MD"
            echo "Added $FILE to $UNCHANGED_FILES_MD"
        fi
    else
        # If the file is new, add it to NEW.md and copy it
        echo "- $FILE" >> "$NEW_FILES_MD"
        echo "Added $FILE to $NEW_FILES_MD"
        
        # Copy the new file to the diff/files/ directory
        DEST_DIR="$FILES_DIR/$(dirname "$FILE")"
        mkdir -p "$DEST_DIR"
        git show "$BRANCH_NEW:$FILE" > "$DEST_DIR/$(basename "$FILE")"
        echo "Copied new file $FILE to $DEST_DIR"
    fi
done <<< "$FILES"

echo "Diffs generated for changed files in the '$DIFF_DIR' directory."
echo "List of new files saved to '$NEW_FILES_MD'."
echo "List of unchanged files saved to '$UNCHANGED_FILES_MD'."
echo "Copies of changed and new files are saved in the '$FILES_DIR' directory."
echo "List of files with permission changes saved to '$PERMISSION_CHANGED_MD'."
echo "List of files with only logger subroutine changes saved to '$LOGGER_SUBS_MD'."
echo "List of files with only superficial changes saved to '$SUPERFICIAL_MD'."
echo "List of deleted files saved to '$DELETED_FILES_MD'."
