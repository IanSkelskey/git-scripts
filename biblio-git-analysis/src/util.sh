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

copy_file_to() {
    file="$1"
    dest_dir="$2"
    
    mkdir -p "$dest_dir"
    git show "$BRANCH_NEW:$file" > "$dest_dir/$(basename "$file")"
    echo "Copied $file to $dest_dir"
}

save_diff_and_copy_file() {
	file="$1"
	diff_content="$2"
	
	# Get the line count of the diff
	line_count=$(echo "$diff_content" | grep -c '^[-+]')
	
	# Get the magnitude directory based on the line count
	magnitude_dir=$(get_magnitude_directory "$line_count")
	
	# Save the diff to the appropriate magnitude directory
	echo "$diff_content" > "$magnitude_dir/$file.diff"
	echo "Saved diff for $file to $magnitude_dir"
	
	# Copy the file to the files directory
	copy_file_to "$file" "$FILES_DIR/$(dirname "$file")"
}