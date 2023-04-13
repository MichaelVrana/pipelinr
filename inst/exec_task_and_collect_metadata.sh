#!/bin/sh

exec_task_path="$1"
collect_metadata_path="$2"
task_filename="$3"

Rscript "$exec_task_path" "$task_filename"
Rscript "$collect_metadata_path" "$task_filename" "$?"
