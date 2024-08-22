# Biblio Git Analysis

Creates diff files for all files that have changed between two branches. I created this script to help me identify and analyze changes between an open source project and a customized version of the project. 

#### Usage

Run the script with the following command:

```bash
./create_diffs.sh evg-3.11.7
./analyze_diffs.sh evg-3.11.7
./weed_diffs_and_copy_files.sh
./copy_changed_images.sh evg-3.11.7 biblio-3.11.7
```