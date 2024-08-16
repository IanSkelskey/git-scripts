# Git Scripts

A collection of git related scripts I've written.

## Contents

### [src/branch_diff.sh](src/branch_diff.sh)

Creates diff files for all files that have changed between two branches. I created this script to help me identify and analyze changes between an open source project and a customized version of the project. 

#### Usage

1. Move the script to the root of the git repository.

2. Run the script.

    ```bash
    ./branch_diff.sh <old_branch> <new_branch> <file_list>
    ```
    
    The `old_branch` and `new_branch` arguments are required. The file list is optional. If the `file_list` is not provided, all files that have changed between the two branches will be diffed.

#### Output

The script will create a diff file for each file that has changed between the two branches. The diff files will be placed in a directory named `diff` in the root of the git repository.

All new and changed files will be copied from the new branch to the `diff/files` directory.

`NEW.md` will contain a list of all new files.
`CHANGED.md` will contain a list of all changed files.

#### Problem

The customized version didn't keep a record of its changes, so I needed a way to identify and analyze the changes between the two branches. Further the customized repository didn't share the same commit history as the open source repository.

This is part of an effort to identify and document the changes between the two repositories. I plan to create a new repository that will contain only the customized files and changes so that my team can more easily update the customized repository with changes from the open source repository.