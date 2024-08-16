#!/bin/bash

# Function to prompt for input if not provided
prompt_for_input() {
    local var_name="$1"
    local prompt_msg="$2"
    local default_value="$3"
    
    if [ -z "${!var_name}" ]; then
        read -p "$prompt_msg" $var_name
    fi
    
    if [ -z "${!var_name}" ]; then
        eval "$var_name=\"$default_value\""
    fi
}

# Function to read file list from a file
read_file_list() {
    local file_list="$1"
    mapfile -t FILES < "$file_list"
}

# Function to get all files in the repository
get_all_files() {
    mapfile -t FILES < <(git ls-files)
}

# Parse arguments for branches and file list
BRANCH_OLD="$1"
BRANCH_NEW="$2"
FILE_LIST="$3"

# Prompt for branches if not provided
prompt_for_input BRANCH_OLD "Enter the old branch name: " "evg-3.11.7"
prompt_for_input BRANCH_NEW "Enter the new branch name: " "test"

# If file list is provided, read it, otherwise use all files
if [ -n "$FILE_LIST" ]; then
    if [ -f "$FILE_LIST" ]; then
        read_file_list "$FILE_LIST"
    else
        echo "File list '$FILE_LIST' does not exist."
        exit 1
    fi
else
    # Get all files in the repository
    echo "Getting all files in the repository..."
    get_all_files
fi

# Directory to store diff files and copies of changed/new files
DIFF_DIR="diff"
FILES_DIR="$DIFF_DIR/files"
NEW_FILES_MD="$DIFF_DIR/NEW.md"
UNCHANGED_FILES_MD="$DIFF_DIR/UNCHANGED.md"

# Create the diff and files directories if they don't exist
mkdir -p "$DIFF_DIR"
mkdir -p "$FILES_DIR"

# Initialize the NEW.md and UNCHANGED.md files
echo "# New Files in $BRANCH_NEW Branch" > "$NEW_FILES_MD"
echo "" >> "$NEW_FILES_MD"
echo "# Unchanged Files in $BRANCH_NEW Branch" > "$UNCHANGED_FILES_MD"
echo "" >> "$UNCHANGED_FILES_MD"

# Create the diffs and copy the files
for FILE in "${FILES[@]}"; do
    # Skip binary files (images, etc.)
    if [[ $FILE == *.png || $FILE == *.jpg || $FILE == *.gif || $FILE == *.ico ]]; then
        echo "Skipping binary file: $FILE"
        continue
    fi
    
    # Check if the file exists in the old branch
    if git show "$BRANCH_OLD:$FILE" &>/dev/null; then
        # Generate the diff and check if there are any differences
        DIFF=$(git diff "$BRANCH_OLD" "$BRANCH_NEW" -- "$FILE")
        if [[ -n $DIFF ]]; then
            echo "$DIFF" > "$DIFF_DIR/${FILE//\//_}.diff"
            echo "Created diff for $FILE"
            
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
done

echo "Diffs generated for changed files in the '$DIFF_DIR' directory."
echo "List of new files saved to '$NEW_FILES_MD'."
echo "List of unchanged files saved to '$UNCHANGED_FILES_MD'."
echo "Copies of changed and new files are saved in the '$FILES_DIR' directory."
