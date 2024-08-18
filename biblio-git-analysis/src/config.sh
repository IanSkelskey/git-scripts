#!/bin/bash

# Directory to store diff files and copies of changed/new files
DIFF_DIR="diff"
ATOMIC_DIFF_DIR="$DIFF_DIR/atomic"
TINY_DIFF_DIR="$DIFF_DIR/tiny"
SMALL_DIFF_DIR="$DIFF_DIR/small"
MEDIUM_DIFF_DIR="$DIFF_DIR/medium"
LARGE_DIFF_DIR="$DIFF_DIR/large"
FILES_DIR="$DIFF_DIR/files"
NEW_FILES_MD="$DIFF_DIR/NEW.md"
UNCHANGED_FILES_MD="$DIFF_DIR/UNCHANGED.md"
PERMISSION_CHANGED_MD="$DIFF_DIR/PERMISSION_CHANGED.md"
LOGGER_SUBS_MD="$DIFF_DIR/LOGGER_SUBS.md"
SUPERFICIAL_MD="$DIFF_DIR/SUPERFICIAL.md"
DELETED_FILES_MD="$DIFF_DIR/DELETED.md"

# Thresholds for categorizing changes
ATOMIC_THRESHOLD=5    # Atomic changes: 1-5 lines
TINY_THRESHOLD=20      # Tiny changes: 6-20 lines
SMALL_THRESHOLD=50     # Small changes: 21-50 lines
MEDIUM_THRESHOLD=250   # Medium changes: 51-250 lines
# Large changes: anything above the medium threshold
