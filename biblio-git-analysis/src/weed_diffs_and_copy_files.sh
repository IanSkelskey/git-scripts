#!/bin/bash

# Define the directories
DIFF_DIR="diff"
PERMISSION_CHANGED_DIR="$DIFF_DIR/permission_changed"
UNCHANGED_DIR="$DIFF_DIR/unchanged"
NEW_DIR="$DIFF_DIR/new"
LOGGER_PATCH_DIR="$DIFF_DIR/logger_patch"
XUL_DIR="$DIFF_DIR/xul"
SIGNIFICANT_DIR="$DIFF_DIR/significant"
INSIGNIFICANT_DIR="$DIFF_DIR/insignificant"
RELEVANT_FILES_DIR="relevant_files"

# Create directories for significant and insignificant diffs
mkdir -p "$SIGNIFICANT_DIR" "$INSIGNIFICANT_DIR" "$RELEVANT_FILES_DIR"

# List of exceptions for logger_patch directory
declare -A LOGGER_PATCH_EXCEPTIONS=(
    ["diff/logger_patch/Open-ILS/src/perlmods/lib/OpenILS/Application/Actor/Container.pm.diff"]=1
    ["diff/logger_patch/Open-ILS/src/perlmods/lib/OpenILS/WWW/EGCatLoader/Register.pm.diff"]=1
    ["diff/logger_patch/Open-ILS/src/perlmods/lib/OpenILS/WWW/SuperCat.pm.diff"]=1
)

# List of exceptions for size-based directories
declare -A SIZE_BASED_EXCEPTIONS=(
    ["diff/atomic/Open-ILS/src/eg2/src/app/staff/admin/server/org-unit.component.html.diff"]=1
    ["diff/atomic/Open-ILS/src/eg2/src/app/staff/cat/volcopy/volcopy.service.ts.diff"]=1
    ["diff/atomic/Open-ILS/src/eg2/src/app/staff/share/holdings/copy-tags-dialog.component.ts.diff"]=1
    ["diff/atomic/Open-ILS/src/eg2/src/app/staff/catalog/record/copies.component.html.diff"]=1
    ["diff/atomic/Open-ILS/src/perlmods/lib/OpenILS/Application/Storage/QueryParser.pm.diff"]=1
    ["diff/atomic/Open-ILS/src/sql/Pg/000.english.pg10.fts-config.sql.diff"]=1
    ["diff/atomic/Open-ILS/src/sql/Pg/000.english.pg11.fts-config.sql.diff"]=1
    ["diff/atomic/Open-ILS/src/sql/Pg/000.english.pg12.fts-config.sql.diff"]=1
    ["diff/atomic/Open-ILS/src/sql/Pg/000.english.pg13.fts-config.sql.diff"]=1
    ["diff/atomic/Open-ILS/src/sql/Pg/000.english.pg14.fts-config.sql.diff"]=1
    ["diff/atomic/Open-ILS/src/sql/Pg/000.english.pg15.fts-config.sql.diff"]=1
    ["diff/atomic/Open-ILS/src/sql/Pg/000.english.pg95.fts-config.sql.diff"]=1
    ["diff/atomic/Open-ILS/src/sql/Pg/upgrade/0529.data.merge_user-ou_settings.sql.diff"]=1
    ["diff/atomic/Open-ILS/web/opac/common/js/fm_table_conf.js.diff"]=1
    ["diff/atomic/Open-ILS/xul/staff/client/defaults/preferences/chrome/list.js.diff"]=1
    ["diff/atomic/Open-ILS/src/perlmods/lib/OpenILS/WWW/EGKPacLoader.pm.diff"]=1
    ["diff/atomic/Open-ILS/src/support-scripts/set_pbx_holidays.pl.diff"]=1
    ["diff/large/Open-ILS/examples/web/css/skin/kpac2/kpac_style.css.diff"]=1
    ["diff/large/Open-ILS/web/css/skin/default/kpac_style.css.diff"]=1
    ["diff/large/Open-ILS/xsl/MARC21slim2FGDC.xsl.diff"]=1
    ["diff/large/Open-ILS/xsl/MARC21slim2MADS.xsl.diff"]=1
    ["diff/medium/Open-ILS/web/images/portal/LICENSE.diff"]=1
    ["diff/medium/Open-ILS/web/js/file-saver/demo/demo.css.diff"]=1
    ["diff/medium/Open-ILS/web/js/file-saver/demo/index.xhtml.diff"]=1
    ["diff/medium/Open-ILS/web/js/ui/default/kpac/functions.js.diff"]=1
    ["diff/medium/Open-ILS/web/opac/common/js/jscalendar/lang/calendar-bg.js.diff"]=1
    ["diff/medium/Open-ILS/web/opac/common/js/jscalendar/lang/calendar-el.js.diff"]=1
    ["diff/medium/Open-ILS/web/opac/common/js/jscalendar/lang/calendar-si.js.diff"]=1
    ["diff/medium/Open-ILS/web/opac/common/js/jscalendar/lang/cn_utf8.js.diff"]=1
    ["diff/medium/Open-ILS/xul/staff/client/components/clh.js.diff"]=1
    ["diff/medium/Open-ILS/xul/staff/client/server/skin/media/images/portal/LICENSE.diff"]=1
    ["diff/small/Open-ILS/examples/Makefile.in.diff"]=1
    ["diff/small/Open-ILS/src/sql/Pg/t_lp1849736_at_email_self_register.pg.diff"]=1
    ["diff/small/Open-ILS/web/opac/common/js/jscalendar/lang/calendar-hr-utf8.js.diff"]=1
    ["diff/small/Open-ILS/web/opac/common/js/jscalendar/lang/calendar-tr.js.diff"]=1
    ["diff/small/Open-ILS/xul/staff/client/custom/images/DCO.diff"]=1
    ["diff/tiny/Open-ILS/src/sql/Pg/upgrade/1309.schema.update_course_module_term_constraints.sql.diff"]=1
    ["diff/tiny/Open-ILS/src/sql/Pg/version-upgrade/3.8.0-3.8.1-upgrade-db.sql.diff"]=1
)

# Helper function to classify a diff file as significant or insignificant
classify_diff() {
    local diff_file="$1"
    
    # Check if the diff file is in logger_patch and is an exception
    if [[ "$diff_file" == "$LOGGER_PATCH_DIR"* ]]; then
        if [[ -z "${LOGGER_PATCH_EXCEPTIONS[$diff_file]}" ]]; then
            mv "$diff_file" "$INSIGNIFICANT_DIR/"
        else
            mv "$diff_file" "$SIGNIFICANT_DIR/"
        fi
    # Files in the NEW_DIR are always significant
    elif [[ "$diff_file" == "$NEW_DIR"* ]]; then
        mv "$diff_file" "$SIGNIFICANT_DIR/"
    # Files in the PERMISSION_CHANGED_DIR and XUL_DIR are always insignificant
    elif [[ "$diff_file" == "$PERMISSION_CHANGED_DIR"* || "$diff_file" == "$XUL_DIR"* ]]; then
        mv "$diff_file" "$INSIGNIFICANT_DIR/"
    # Check if the diff file is in a size-based directory and is an exception
    elif [[ -n "${SIZE_BASED_EXCEPTIONS[$diff_file]}" ]]; then
        mv "$diff_file" "$INSIGNIFICANT_DIR/"
    else
        mv "$diff_file" "$SIGNIFICANT_DIR/"
    fi
}

# Iterate over all diff directories and classify diffs
for dir in "$PERMISSION_CHANGED_DIR" "$UNCHANGED_DIR" "$NEW_DIR" "$LOGGER_PATCH_DIR" "$XUL_DIR" "$DIFF_DIR"/atomic "$DIFF_DIR"/tiny "$DIFF_DIR"/small "$DIFF_DIR"/medium "$DIFF_DIR"/large; do
    find "$dir" -type f -name "*.diff" | while IFS= read -r diff_file; do
        classify_diff "$diff_file"
    done
done

# Copy all significant files to the relevant_files directory
while IFS= read -r diff_file; do
    # Extract the original file path from the first line of the diff
    original_file_path=$(awk '/^diff --git a\// {print $3}' "$diff_file" | sed 's/^a\///')

    destination_dir="$RELEVANT_FILES_DIR/$(dirname "$original_file_path")"

    if [ -f "$original_file_path" ]; then
        mkdir -p "$destination_dir"
        cp "$original_file_path" "$destination_dir/"
    else
        echo "Warning: $original_file_path does not exist. Skipping copy."
    fi
done < <(find "$SIGNIFICANT_DIR" -type f -name "*.diff")

# Count and print the totals
significant_count=$(find "$SIGNIFICANT_DIR" -type f -name "*.diff" | wc -l)
insignificant_count=$(find "$INSIGNIFICANT_DIR" -type f -name "*.diff" | wc -l)

echo "Total significant diffs: $significant_count"
echo "Total insignificant diffs: $insignificant_count"
