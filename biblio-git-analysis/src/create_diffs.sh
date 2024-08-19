#!/bin/bash

# Check if the old branch is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <old-branch>"
    exit 1
fi

# Define the branches
BRANCH_OLD="$1"
BRANCH_NEW=$(git rev-parse --abbrev-ref HEAD)

# Directory to store diff files
DIFF_DIR="diff"
ATOMIC_DIFF_DIR="$DIFF_DIR/atomic"
TINY_DIFF_DIR="$DIFF_DIR/tiny"
SMALL_DIFF_DIR="$DIFF_DIR/small"
MEDIUM_DIFF_DIR="$DIFF_DIR/medium"
LARGE_DIFF_DIR="$DIFF_DIR/large"

# Markdown file to store the table
TABLE_MD="$DIFF_DIR/CHANGED_FILES.md"

# Thresholds for categorizing changes
ATOMIC_THRESHOLD=5    # Atomic changes: 1-5 lines
TINY_THRESHOLD=20      # Tiny changes: 6-20 lines
SMALL_THRESHOLD=50     # Small changes: 21-50 lines
MEDIUM_THRESHOLD=250   # Medium changes: 51-250 lines

# Create the diff directories if they don't exist
mkdir -p "$ATOMIC_DIFF_DIR" "$TINY_DIFF_DIR" "$SMALL_DIFF_DIR" "$MEDIUM_DIFF_DIR" "$LARGE_DIFF_DIR"

# Initialize the markdown table
echo "# Files Changed in $BRANCH_NEW Branch" > "$TABLE_MD"
echo "" >> "$TABLE_MD"
echo "| File | Lines Changed |" >> "$TABLE_MD"
echo "|------|---------------|" >> "$TABLE_MD"

# Get a list of all changed files
FILES=$(git diff --name-status "$BRANCH_OLD" "$BRANCH_NEW")

is_image_file() {
    file="$1"
    
    if [[ $file == *.png || $file == *.jpg || $file == *.gif || $file == *.ico || $file == *.jpeg || $file == *.bmp || $file == *.tiff || $file == *.svg ]]; then
        return 0
    else
        return 1
    fi
}

is_font_file() {
    file="$1"
    
    if [[ $file == *.ttf || $file == *.otf || $file == *.woff || $file == *.woff2 || $file == *.eot || $file == *.svg ]]; then
        return 0
    else
        return 1
    fi
}

# Create diffs, sort them by size, and add entries to the table
while IFS= read -r line; do
    FILE_STATUS=$(echo "$line" | awk '{print $1}')
    FILE=$(echo "$line" | awk '{print $2}')
    
    if [[ $FILE_STATUS == "D" ]]; then
        continue
    fi

    if is_image_file "$FILE" || is_font_file "$FILE"; then
        continue
    fi
    
    DIFF=$(git diff "$BRANCH_OLD" "$BRANCH_NEW" -- "$FILE")
    LINE_COUNT=$(echo "$DIFF" | grep -E "^\+" | wc -l)

    # Determine the directory for the diff based on the line count
    if [ "$LINE_COUNT" -le "$ATOMIC_THRESHOLD" ]; then
        DIFF_PATH="$ATOMIC_DIFF_DIR/${FILE//\//_}.diff"
    elif [ "$LINE_COUNT" -le "$TINY_THRESHOLD" ]; then
        DIFF_PATH="$TINY_DIFF_DIR/${FILE//\//_}.diff"
    elif [ "$LINE_COUNT" -le "$SMALL_THRESHOLD" ]; then
        DIFF_PATH="$SMALL_DIFF_DIR/${FILE//\//_}.diff"
    elif [ "$LINE_COUNT" -le "$MEDIUM_THRESHOLD" ]; then
        DIFF_PATH="$MEDIUM_DIFF_DIR/${FILE//\//_}.diff"
    else
        DIFF_PATH="$LARGE_DIFF_DIR/${FILE//\//_}.diff"
    fi

    # Save the diff
    echo "$DIFF" > "$DIFF_PATH"
    echo "Created diff for $FILE in $(dirname "$DIFF_PATH")"

    # Add an entry to the markdown table
    echo "| $FILE | $LINE_COUNT |" >> "$TABLE_MD"

done <<< "$FILES"

echo "Diffs generated and sorted by size in the '$DIFF_DIR' directory."
echo "Table of changed files and line counts saved to '$TABLE_MD'."
